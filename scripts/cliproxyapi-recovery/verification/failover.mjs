import http from "node:http";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import assert from "node:assert/strict";
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "cpa-failover-"));
const binary = fs.realpathSync(
  process.argv[2] ?? path.join(os.homedir(), ".local/bin/cli-proxy-api"),
);
const calls = [];
let blocked = false;
let resetSeconds = 3;
const mock = http.createServer((req, res) => {
  req.resume();
  const name = req.headers.authorization?.includes("preferred")
    ? "preferred"
    : "fallback";
  calls.push(name);
  if (name === "preferred" && blocked) {
    res.writeHead(429, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        error: {
          type: "usage_limit_reached",
          message: "synthetic quota",
          resets_in_seconds: resetSeconds,
        },
      }),
    );
    return;
  }
  res.writeHead(200, { "Content-Type": "text/event-stream" });
  const response = {
    id: "resp_test",
    object: "response",
    status: "completed",
    model: "gpt-5.4",
    output: [
      {
        id: "msg_test",
        type: "message",
        role: "assistant",
        status: "completed",
        content: [{ type: "output_text", text: name, annotations: [] }],
      },
    ],
    usage: { input_tokens: 1, output_tokens: 1, total_tokens: 2 },
  };
  res.end(
    `event: response.completed\ndata: ${JSON.stringify({ type: "response.completed", response })}\n\n`,
  );
});
await new Promise((r) => mock.listen(0, "127.0.0.1", r));
const upstream = mock.address().port;
const reservation = http.createServer();
await new Promise((r) => reservation.listen(0, "127.0.0.1", r));
const port = reservation.address().port;
await new Promise((r) => reservation.close(r));
fs.mkdirSync(path.join(dir, "auths"));
fs.writeFileSync(
  path.join(dir, "config.yaml"),
  `host: 127.0.0.1\nport: ${port}\nauth-dir: ${dir}/auths\napi-keys: [test-client]\nremote-management:\n  secret-key: test-management\n  disable-control-panel: true\nrequest-retry: 0\nmax-retry-interval: 1\nrouting:\n  strategy: fill-first\ncodex-api-key:\n  - api-key: test-preferred\n    priority: 100\n    base-url: http://127.0.0.1:${upstream}\n    models: [{name: gpt-5.4}]\n  - api-key: test-fallback\n    priority: 0\n    base-url: http://127.0.0.1:${upstream}\n    models: [{name: gpt-5.4}]\n`,
);
const log = fs.openSync(path.join(dir, "proxy.log"), "w");
const child = spawn(
  binary,
  ["--config", path.join(dir, "config.yaml")],
  { cwd: dir, stdio: ["ignore", log, log] },
);
const base = `http://127.0.0.1:${port}`;
async function infer() {
  const before = calls.length;
  const r = await fetch(base + "/v1/responses", {
    method: "POST",
    headers: {
      Authorization: "Bearer test-client",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ model: "gpt-5.4", input: "test", stream: false }),
  });
  const body = await r.text();
  assert.equal(r.status, 200, body);
  return calls.slice(before);
}
try {
  for (let i = 0; i < 100; i++) {
    try {
      const r = await fetch(base + "/v1/models", {
        headers: { Authorization: "Bearer test-client" },
      });
      if (r.ok) break;
    } catch (e) {
      if (e.cause?.code !== "ECONNREFUSED") throw e;
    }
    await new Promise((r) => setTimeout(r, 50));
  }
  assert.deepEqual(await infer(), ["preferred"]);
  blocked = true;
  assert.deepEqual(await infer(), ["preferred", "fallback"]);
  blocked = false;
  assert.deepEqual(await infer(), ["fallback"]);
  await new Promise((r) => setTimeout(r, 10500));
  assert.deepEqual(await infer(), ["preferred"]);
  resetSeconds = 3600;
  blocked = true;
  assert.deepEqual(await infer(), ["preferred", "fallback"]);
  blocked = false;
  assert.deepEqual(await infer(), ["fallback"]);
  const managementHeaders = {
    Authorization: "Bearer test-management",
    "Content-Type": "application/json",
  };
  const keysResponse = await fetch(base + "/v0/management/codex-api-key", {
    headers: managementHeaders,
  });
  assert.equal(keysResponse.status, 200);
  const keys = await keysResponse.json();
  const preferred = keys["codex-api-key"].find((key) => key.priority === 100);
  assert.ok(preferred["auth-index"]);
  const reset = await fetch(base + "/v0/management/reset-quota", {
    method: "POST",
    headers: managementHeaders,
    body: JSON.stringify({ auth_index: preferred["auth-index"] }),
  });
  assert.equal(reset.status, 200, await reset.text());
  assert.deepEqual(await infer(), ["preferred"]);
  console.log(
    JSON.stringify({
      result: "PASS",
      binary,
      checks: [
        "priority selection",
        "same-request 429 fallback",
        "cooldown skips preferred",
        "automatic return after retry expiry",
        "recovered upstream remains skipped before future deadline",
        "management reset restores preferred route",
      ],
      calls,
      artifactDirectory: dir,
    }),
  );
} finally {
  child.kill("SIGTERM");
  mock.close();
}
