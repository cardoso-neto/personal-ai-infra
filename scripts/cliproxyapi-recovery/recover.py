#!/usr/bin/env python3
import argparse
import json
import math
import sys
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener


class Failure(Exception):
    pass


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(
        self, req: Any, fp: Any, code: int, msg: str, headers: Any, newurl: str
    ) -> None:
        return None


class Management:
    def __init__(self, base: str, key: str, timeout: float) -> None:
        self.base, self.key, self.timeout = base.rstrip("/"), key, timeout
        self.opener = build_opener(ProxyHandler({}), NoRedirect())

    def request(self, route: str, data: dict[str, Any] | None = None) -> Any:
        request = Request(
            self.base + "/v0/management/" + route,
            data=json.dumps(data).encode() if data is not None else None,
            headers={
                "Authorization": "Bearer " + self.key,
                "Content-Type": "application/json",
            },
        )
        with self.opener.open(request, timeout=self.timeout) as response:
            raw = response.read(2_000_001)
        if len(raw) > 2_000_000:
            raise Failure("response-too-large")
        return json.loads(raw)

    def files(self) -> list[dict[str, Any]]:
        response = self.request("auth-files")
        if not isinstance(response, dict) or not isinstance(
            response.get("files"), list
        ):
            raise Failure("invalid-auth-list")
        files = response["files"]
        if not all(isinstance(item, dict) for item in files):
            raise Failure("invalid-auth-list")
        return files

    def upstream(
        self,
        auth: dict[str, Any],
        url: str,
        headers: dict[str, str],
        data: dict[str, Any] | None = None,
    ) -> str:
        payload = {
            "auth_index": auth["auth_index"],
            "url": url,
            "method": "POST" if data is not None else "GET",
            "header": headers,
        }
        if data is not None:
            payload["data"] = json.dumps(data)
        result = self.request("api-call", payload)
        if not isinstance(result, dict):
            raise Failure("invalid-upstream-response")
        status = result.get("status_code")
        if type(status) is not int or not 100 <= status <= 599:
            raise Failure("invalid-upstream-status")
        if status != 200:
            raise Failure(f"upstream-http-{status}")
        if not isinstance(result.get("body"), str):
            raise Failure("invalid-upstream-body")
        return result["body"]


def eligible(auth: dict[str, Any]) -> bool:
    cooldowns = auth.get("cooldowns")
    if (
        auth.get("provider") not in ("codex", "claude")
        or auth.get("disabled") is not False
        or auth.get("unavailable") is not True
        or not isinstance(auth.get("auth_index"), str)
        or not auth["auth_index"]
        or not isinstance(cooldowns, list)
    ):
        return False
    if not cooldowns or not all(isinstance(c, dict) for c in cooldowns):
        return False
    if not all(
        c.get("reason") in ("quota", "credential_quota")
        and c.get("scope") in ("credential", "model")
        for c in cooldowns
    ):
        return False
    try:
        deadlines = [
            (c["scope"], datetime.fromisoformat(c["retry_at"])) for c in cooldowns
        ]
    except (KeyError, TypeError, ValueError):
        return False
    if any(deadline.tzinfo is None for _, deadline in deadlines):
        return False
    credentials = [deadline for scope, deadline in deadlines if scope == "credential"]
    models = [deadline for scope, deadline in deadlines if scope == "model"]
    return bool(credentials) and all(
        deadline <= min(credentials) for deadline in models
    )


def snapshot(auth: dict[str, Any]) -> dict[str, Any]:
    result = {
        key: auth.get(key)
        for key in (
            "id",
            "auth_index",
            "name",
            "path",
            "provider",
            "disabled",
            "unavailable",
            "email",
            "account_type",
            "account",
            "updated_at",
            "last_refresh",
            "modtime",
            "size",
            "id_token",
            "status",
            "status_message",
            "next_retry_after",
        )
    }
    result["cooldowns"] = [
        {k: v for k, v in item.items() if k != "remaining_seconds"}
        for item in auth.get("cooldowns", [])
    ]
    return result


def percent_available(value: Any) -> bool:
    if type(value) not in (int, float) or not math.isfinite(value) or value < 0:
        raise Failure("unknown-quota-schema")
    return value < 100


def codex_allowance(limits: Any) -> bool:
    if (
        not isinstance(limits, dict)
        or type(limits.get("allowed")) is not bool
        or type(limits.get("limit_reached")) is not bool
        or not isinstance(limits.get("primary_window"), dict)
    ):
        raise Failure("unknown-quota-schema")
    windows = [
        limits[k]
        for k in ("primary_window", "secondary_window")
        if limits.get(k) is not None
    ]
    if any(not isinstance(w, dict) for w in windows):
        raise Failure("unknown-quota-schema")
    available = [percent_available(w.get("used_percent")) for w in windows]
    return limits["allowed"] and not limits["limit_reached"] and all(available)


def allowance(provider: str, raw: str) -> bool:
    quota = json.loads(raw)
    if not isinstance(quota, dict):
        raise Failure("unknown-quota-schema")
    if provider == "codex":
        additional = quota.get("additional_rate_limits")
        if additional is None:
            additional = []
        if not isinstance(additional, list) or any(
            not isinstance(limit, dict) for limit in additional
        ):
            raise Failure("unknown-quota-schema")
        available = [codex_allowance(quota.get("rate_limit"))]
        available.extend(
            codex_allowance(limit.get("rate_limit")) for limit in additional
        )
        return all(available)
    required = ("five_hour", "seven_day")
    if any(not isinstance(quota.get(k), dict) for k in required):
        raise Failure("unknown-quota-schema")
    windows = [
        v
        for k, v in quota.items()
        if k.startswith(("five_hour", "seven_day")) and v is not None
    ]
    if any(not isinstance(w, dict) for w in windows):
        raise Failure("unknown-quota-schema")
    available = [percent_available(w.get("utilization")) for w in windows]
    return all(available)


def completed(provider: str, raw: str) -> bool:
    if provider == "claude":
        result = json.loads(raw)
        return (
            isinstance(result, dict)
            and result.get("type") == "message"
            and result.get("role") == "assistant"
            and result.get("stop_reason") in ("end_turn", "max_tokens")
            and isinstance(result.get("content"), list)
            and bool(result["content"])
            and not result.get("error")
        )
    terminal = None
    output_seen = False
    for line in raw.splitlines():
        if not line.startswith("data:") or line[5:].strip() == "[DONE]":
            continue
        event = json.loads(line[5:])
        if not isinstance(event, dict):
            return False
        if event.get("type") in ("error", "response.failed", "response.incomplete"):
            return False
        if event.get("type") == "response.output_text.done":
            text = event.get("text")
            output_seen |= isinstance(text, str) and bool(text.strip())
        if event.get("type") == "response.output_item.done":
            item = event.get("item")
            if (
                isinstance(item, dict)
                and item.get("type") == "message"
                and item.get("role") == "assistant"
                and item.get("status") == "completed"
                and isinstance(item.get("content"), list)
            ):
                output_seen |= any(
                    isinstance(part, dict)
                    and part.get("type") == "output_text"
                    and isinstance(part.get("text"), str)
                    and bool(part["text"].strip())
                    for part in item["content"]
                )
        if event.get("type") == "response.completed":
            terminal = event.get("response")
    return (
        isinstance(terminal, dict)
        and terminal.get("status") == "completed"
        and not terminal.get("error")
        and isinstance(terminal.get("output"), list)
        and (bool(terminal["output"]) or output_seen)
    )


def requests(auth: dict[str, Any]) -> tuple[str, str, dict[str, str], dict[str, Any]]:
    headers = {"Authorization": "Bearer $TOKEN$", "Content-Type": "application/json"}
    if auth["provider"] == "claude":
        headers.update(
            {
                "anthropic-version": "2023-06-01",
                "anthropic-beta": "oauth-2025-04-20",
                "User-Agent": "claude-cli/2.1.0 (external, cli)",
            }
        )
        return (
            "https://api.anthropic.com/api/oauth/usage",
            "https://api.anthropic.com/v1/messages",
            headers,
            {
                "model": "claude-haiku-4-5-20251001",
                "max_tokens": 1,
                "messages": [{"role": "user", "content": "Reply OK."}],
            },
        )
    identity = auth.get("id_token")
    account_id = (
        identity.get("chatgpt_account_id") if isinstance(identity, dict) else None
    )
    if not isinstance(account_id, str) or not account_id.strip():
        raise Failure("missing-account-id")
    headers.update(
        {
            "ChatGPT-Account-Id": account_id,
            "originator": "codex_cli_rs",
            "User-Agent": "codex_cli_rs/0.76.0",
        }
    )
    return (
        "https://chatgpt.com/backend-api/wham/usage",
        "https://chatgpt.com/backend-api/codex/responses",
        headers,
        {
            "model": "gpt-6-luna",
            "instructions": "Reply briefly.",
            "store": False,
            "stream": True,
            "input": [
                {
                    "role": "user",
                    "content": [{"type": "input_text", "text": "Reply OK."}],
                }
            ],
        },
    )


def recover(client: Management, check_auth_index: str | None = None) -> int:
    failed = False
    files = client.files()
    if check_auth_index is None:
        candidates = [auth for auth in files if eligible(auth)]
    else:
        candidates = [
            auth
            for auth in files
            if auth.get("auth_index") == check_auth_index
            and auth.get("disabled") is False
            and auth.get("provider") in ("codex", "claude")
        ]
        if len(candidates) != 1:
            raise Failure("diagnostic-auth-not-found")
    for auth in candidates:
        provider = auth["provider"]
        stage = "prepare"
        try:
            quota_url, probe_url, headers, body = requests(auth)
            stage = "quota"
            quota_headers = {**headers, "Accept": "application/json"}
            if not allowance(provider, client.upstream(auth, quota_url, quota_headers)):
                print(f"{provider}: allowance-exhausted")
                continue
            stage = "probe"
            probe_headers = headers.copy()
            if provider == "codex":
                probe_headers.pop("User-Agent", None)
                probe_headers["OpenAI-Beta"] = "responses=experimental"
            if not completed(
                provider, client.upstream(auth, probe_url, probe_headers, body)
            ):
                raise Failure("probe-not-completed")
            if check_auth_index is not None:
                print(f"{provider}: diagnostic-probe-completed-no-reset")
                continue
            stage = "refetch"
            current = [
                item
                for item in client.files()
                if item.get("auth_index") == auth["auth_index"]
            ]
            if (
                len(current) != 1
                or not eligible(current[0])
                or snapshot(current[0]) != snapshot(auth)
            ):
                print(f"{provider}: state-changed-skip")
                continue
            stage = "reset"
            result = client.request("reset-quota", {"auth_index": auth["auth_index"]})
            if (
                not isinstance(result, dict)
                or result.get("status") != "ok"
                or result.get("auth_index") != auth["auth_index"]
            ):
                raise Failure("reset-not-confirmed")
            print(f"{provider}: quota-recovered")
        except (Failure, OSError, URLError, ValueError, TypeError) as error:
            reason = failure_reason(error)
            print(f"{provider}: {stage}-failed ({reason})")
            failed = True
    if not candidates:
        print("no-recovery-candidates")
    return int(failed)


def failure_reason(error: Exception) -> str:
    if isinstance(error, Failure):
        return str(error)
    if isinstance(error, HTTPError):
        return f"management-http-{error.code}"
    return type(error).__name__


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="http://127.0.0.1:8317")
    parser.add_argument(
        "--key", type=Path, default=Path.home() / ".config/cliproxyapi/admin.key"
    )
    parser.add_argument("--check-auth-index", help="Quota and probe only; never reset")
    parser.add_argument("--timeout", type=float, default=45)
    args = parser.parse_args()
    try:
        key = args.key.read_text().strip()
        if not key:
            raise Failure("empty-management-key")
        return recover(Management(args.base, key, args.timeout), args.check_auth_index)
    except (Failure, OSError, URLError, ValueError, TypeError) as error:
        reason = failure_reason(error)
        print(f"recovery-failed ({reason})", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
