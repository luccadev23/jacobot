import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { ERROR_CODES, MAX_ITEM_TEXT_LENGTH, PROTOCOL_VERSION, parseServerEvent } from "../src/index.ts";

const at = "2026-01-01T00:00:00Z";
const log = (item: unknown, overrides: Record<string, unknown> = {}) => ({ type: "log.event", botId: "bot-1", sessionId: "main", sequence: 0, at, item, ...overrides });
const path = (input: unknown) => { const result = parseServerEvent(input); return result.ok ? "ok" : result.error.path; };

const items: Record<string, unknown> = {
  session_started: { kind: "session_started", botId: "bot-1" },
  turn: { kind: "turn", turnId: "trn-1", state: "started", trigger: "user" },
  turn_without_trigger: { kind: "turn", turnId: "trn-1", state: "completed" },
  step: { kind: "step", turnId: "trn-1", stepId: "stp-1", state: "ended" },
  message: { kind: "message", role: "assistant", turnId: "trn-1", text: "hi" },
  tool_call: { kind: "tool_call", turnId: "trn-1", stepId: "stp-1", toolCallId: "cal-1", name: "mcp.fs.read", arguments: { path: "a", n: [1, null, true] } },
  tool_result: { kind: "tool_result", toolCallId: "cal-1", outcome: "denied", content: "no" },
  approval_requested: { kind: "approval_requested", approvalId: "apr-1", toolCallId: "cal-1", summary: "Run it?", expiresAt: at },
  approval_resolved: { kind: "approval_resolved", approvalId: "apr-1", decision: "expired" },
  usage: { kind: "usage", turnId: "trn-1", stepId: "stp-1", inputTokens: 10, outputTokens: 0 },
  compacted: { kind: "compacted", summary: "earlier", throughSequence: 4 },
};

describe("parseServerEvent: the stream", () => {
  it("accepts hello with the current version only", () => {
    assert.deepEqual(parseServerEvent({ type: "hello", protocolVersion: PROTOCOL_VERSION }), { ok: true, value: { type: "hello", protocolVersion: 1 } });
    for (const version of [0, 2, "1", null]) assert.equal(path({ type: "hello", protocolVersion: version }), "protocolVersion");
    assert.equal(path({ type: "hello" }), "protocolVersion");
  });

  it("accepts live text, a reset and a finished turn", () => {
    const text = { type: "live.text", botId: "b", sessionId: "s", turnId: "t", stepId: "p", text: "partial" };
    const reset = { type: "live.reset", botId: "b", sessionId: "s", turnId: "t", stepId: "p" };
    assert.deepEqual(parseServerEvent(text), { ok: true, value: text });
    assert.deepEqual(parseServerEvent(reset), { ok: true, value: reset });
    for (const status of ["completed", "failed", "awaiting_approval", "cancelled"]) {
      assert.equal(parseServerEvent({ type: "turn.finished", botId: "b", sessionId: "s", turnId: "t", status }).ok, true);
    }
    assert.equal(parseServerEvent({ type: "turn.finished", botId: "b", sessionId: "s", turnId: "t", status: "failed", failure: "model_error" }).ok, true);
  });

  it("allows a failure reason only for a failed turn", () => {
    const base = { type: "turn.finished", botId: "b", sessionId: "s", turnId: "t" };
    assert.equal(path({ ...base, status: "completed", failure: "max_steps" }), "failure");
    assert.equal(path({ ...base, status: "failed", failure: "other" }), "failure");
    assert.equal(path({ ...base, status: "weird" }), "status");
  });

  it("accepts every error code, with optional ids", () => {
    for (const code of ERROR_CODES) assert.equal(parseServerEvent({ type: "error", code }).ok, true);
    assert.equal(parseServerEvent({ type: "error", code: "turn_open", botId: "b", sessionId: "s" }).ok, true);
    assert.equal(path({ type: "error", code: "nope" }), "code");
    assert.equal(path({ type: "error", code: "turn_open", botId: "bad id" }), "botId");
    assert.equal(path({ type: "error", code: "turn_open", sessionId: 5 }), "sessionId");
  });

  it("rejects unknown types, non-objects and unknown keys", () => {
    for (const input of [null, "x", [], 5]) assert.equal(path(input), "event");
    assert.equal(path({ type: "nope" }), "type");
    assert.equal(path({ type: "constructor" }), "type");
    assert.equal(path({ type: "hello", protocolVersion: 1, extra: 1 }), "event");
    assert.equal(path({ type: "live.reset", botId: "b", sessionId: "s", turnId: "t", stepId: "p", text: "x" }), "event");
  });
});

describe("parseServerEvent: log events", () => {
  it("accepts every kind of item and returns it unchanged", () => {
    for (const [name, item] of Object.entries(items)) {
      assert.deepEqual(parseServerEvent(log(item)), { ok: true, value: log(item) }, name);
    }
  });

  it("checks the envelope", () => {
    assert.equal(path(log(items["message"], { sequence: -1 })), "sequence");
    assert.equal(path(log(items["message"], { sequence: 1.5 })), "sequence");
    assert.equal(path(log(items["message"], { sequence: "0" })), "sequence");
    assert.equal(path(log(items["message"], { at: "2026-01-01" })), "at");
    assert.equal(path(log(items["message"], { botId: "" })), "botId");
    assert.equal(path(log(items["message"], { sessionId: "-" })), "sessionId");
    assert.equal(path(log(undefined)), "item");
    assert.equal(path(log("x")), "item");
  });

  it("checks each item kind and names the field", () => {
    assert.equal(path(log({ kind: "nope" })), "item.kind");
    assert.equal(path(log({ kind: "constructor" })), "item.kind");
    assert.equal(path(log({ kind: "message", role: "system", turnId: "t", text: "x" })), "item.role");
    assert.equal(path(log({ kind: "message", role: "user", turnId: "t" })), "item.text");
    assert.equal(path(log({ kind: "message", role: "user", turnId: "t", text: "x", extra: 1 })), "item.kind");
    assert.equal(path(log({ kind: "turn", turnId: "t", state: "paused" })), "item.state");
    assert.equal(path(log({ kind: "turn", turnId: "t", state: "started", trigger: "cron" })), "item.trigger");
    assert.equal(path(log({ kind: "step", turnId: "t", stepId: "p", state: "x" })), "item.state");
    assert.equal(path(log({ ...(items["tool_call"] as object), name: "bad name" })), "item.name");
    assert.equal(path(log({ ...(items["tool_call"] as object), name: "9x" })), "item.name");
    assert.equal(path(log({ ...(items["tool_call"] as object), arguments: [] })), "item.arguments");
    assert.equal(path(log({ ...(items["tool_call"] as object), arguments: { f: () => 1 } })), "item.arguments");
    assert.equal(path(log({ ...(items["tool_call"] as object), arguments: { n: Number.NaN } })), "item.arguments");
    assert.equal(path(log({ ...(items["tool_result"] as object), outcome: "ok" })), "item.outcome");
    assert.equal(path(log({ ...(items["approval_requested"] as object), expiresAt: "soon" })), "item.expiresAt");
    assert.equal(path(log({ ...(items["approval_resolved"] as object), decision: "maybe" })), "item.decision");
    assert.equal(path(log({ ...(items["usage"] as object), inputTokens: -1 })), "item.inputTokens");
    assert.equal(path(log({ ...(items["usage"] as object), outputTokens: 1.5 })), "item.outputTokens");
    assert.equal(path(log({ ...(items["compacted"] as object), throughSequence: -1 })), "item.throughSequence");
    assert.equal(path(log({ kind: "session_started" })), "item.botId");
  });

  it("limits the text of an item to one million characters", () => {
    assert.equal(MAX_ITEM_TEXT_LENGTH, 1_000_000);
    const message = (text: string) => log({ kind: "message", role: "assistant", turnId: "t", text });
    assert.equal(parseServerEvent(message("x".repeat(MAX_ITEM_TEXT_LENGTH))).ok, true);
    assert.equal(path(message("x".repeat(MAX_ITEM_TEXT_LENGTH + 1))), "item.text");
    assert.equal(path(log({ ...(items["tool_result"] as object), content: "x".repeat(MAX_ITEM_TEXT_LENGTH + 1) })), "item.content");
  });

  it("limits a tool name to 64 characters and every turn state is known", () => {
    const call = (name: string) => log({ ...(items["tool_call"] as object), name });
    assert.equal(parseServerEvent(call(`a${"b".repeat(63)}`)).ok, true);
    assert.equal(path(call(`a${"b".repeat(64)}`)), "item.name");
    for (const state of ["started", "completed", "failed", "cancelled"]) assert.equal(parseServerEvent(log({ kind: "turn", turnId: "t", state })).ok, true);
    for (const role of ["user", "assistant"]) assert.equal(parseServerEvent(log({ kind: "message", role, turnId: "t", text: "x" })).ok, true);
  });

  it("rejects an item nested too deeply to be sane", () => {
    let deep: unknown = 1;
    for (let i = 0; i < 40; i += 1) deep = { a: deep };
    assert.equal(path(log({ ...(items["tool_call"] as object), arguments: deep })), "item.arguments");
  });

  it("never puts a value from the input into the error", () => {
    const hostile = "SECRET-MARKER-123";
    for (const item of [{ kind: hostile }, { kind: "message", role: hostile, turnId: "t", text: "x" }, { kind: "message", role: "user", turnId: "t", text: 5, [hostile]: 1 }]) {
      assert.doesNotMatch(JSON.stringify(parseServerEvent(log(item))), /SECRET-MARKER-123/);
    }
  });
});
