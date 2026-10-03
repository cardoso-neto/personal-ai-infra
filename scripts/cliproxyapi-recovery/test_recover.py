import json
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

import pytest


@pytest.mark.parametrize(
    "fixture",
    sorted((Path(__file__).parent / "fixtures").glob("*.json")),
    ids=lambda path: path.stem,
)
def test_recovery(fixture: Path, tmp_path: Path) -> None:
    case = json.loads(fixture.read_text())
    calls: list[str] = []
    errors: list[str] = []
    listings = 0

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args: Any) -> None:
            pass

        def do_GET(self) -> None:
            nonlocal listings
            calls.append("auth-files")
            value = case.get("refetch", case["auth"]) if listings else case["auth"]
            listings += 1
            self.reply({"files": [value]})

        def do_POST(self) -> None:
            payload = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            if self.path.endswith("reset-quota"):
                calls.append("reset-quota")
                self.reply({"status": "ok", "auth_index": payload["auth_index"]})
                return
            if payload["header"].get("Authorization") != "Bearer $TOKEN$":
                errors.append("missing-server-token-injection")
            if (
                case["auth"]["provider"] == "codex"
                and payload["header"].get("ChatGPT-Account-Id") != "test-account"
            ):
                errors.append("missing-account-header")
            stage = "quota" if payload["method"] == "GET" else "probe"
            calls.append(stage)
            if (
                stage == "quota"
                and payload["header"].get("Accept") != "application/json"
            ):
                errors.append("incorrect-quota-accept")
            if stage == "probe" and "expected_probe" in case:
                if json.loads(payload["data"]) != case["expected_probe"]:
                    errors.append("incorrect-probe-body")
                if payload["header"].get("OpenAI-Beta") != "responses=experimental":
                    errors.append("incorrect-probe-beta")
                if "User-Agent" in payload["header"] or "Accept" in payload["header"]:
                    errors.append("unexpected-probe-header")
            response = case[stage]
            time.sleep(response.get("delay", 0))
            self.reply(
                {"status_code": response.get("status", 200), "body": response["body"]}
            )

        def reply(self, payload: dict[str, Any]) -> None:
            if self.headers.get("Authorization") != "Bearer management-test-secret":
                errors.append("incorrect-management-key")
            self.send_response(200)
            self.end_headers()
            try:
                self.wfile.write(json.dumps(payload).encode())
            except BrokenPipeError:
                pass

    key = tmp_path / "key"
    key.write_text("management-test-secret")
    with ThreadingHTTPServer(("127.0.0.1", 0), Handler) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        command = [
            sys.executable,
            str(Path(__file__).with_name("recover.py")),
            "--base",
            f"http://127.0.0.1:{server.server_port}",
            "--key",
            str(key),
            "--timeout",
            "0.1",
        ]
        command.extend(case.get("arguments", []))
        result = subprocess.run(
            command, capture_output=True, text=True, timeout=5, check=False
        )
        server.shutdown()
        thread.join()
    assert {"calls": calls, "exit": result.returncode} == case["expected"]
    assert errors == []
    if "error_stage" in case:
        assert case["error_stage"] + "-failed" in result.stdout
    assert "management-test-secret" not in result.stdout + result.stderr
    assert "UPSTREAM_SECRET" not in result.stdout + result.stderr
    assert "test-account" not in result.stdout + result.stderr
