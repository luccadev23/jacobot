import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { MAX_TEXT_LENGTH, parseCommand } from "../src/index.ts";

const send = (overrides: Record<string, unknown> = {}) => ({ type: "message.send", botId: "bot-1", sessionId: "main", text: "hello", ...overrides });
const decide = (overrides: Record<string, unknown> = {}) => ({ type: "approval.decide", botId: "bot-1", sessionId: "main", approvalId: "apr-1", decision: "approved", ...overrides });
const cancel = (overrides: Record<string, unknown> = {}) => ({ type: "turn.cancel", botId: "bot-1", sessionId: "main", ...overrides });
const path = (input: unknown) => { const result = parseCommand(input); return result.ok ? "ok" : result.error.path; };

describe("parseCommand", () => {
  it("accepts each command and returns it unchanged", () => {
    for (const command of [send(), decide(), decide({ decision: "rejected" }), cancel()]) {
      assert.deepEqual(parseCommand(command), { ok: true, value: command });
    }
  });

  it("accepts keys in any order and ids at their limits", () => {
    const reordered = Object.fromEntries(Object.entries(send()).reverse());
    assert.equal(parseCommand(reordered).ok, true);
    assert.equal(parseCommand(send({ botId: "a".repeat(128), sessionId: "0" })).ok, true);
  });

  it("rejects anything that is not a plain object", () => {
    for (const input of [null, undefined, "x", 5, [], [send()], new Map(), Object.create({ type: "turn.cancel" })]) assert.equal(path(input), "command");
  });

  it("rejects an unknown or missing type", () => {
    assert.equal(path({}), "type");
    assert.equal(path({ type: "nope" }), "type");
    assert.equal(path({ type: 5 }), "type");
    assert.equal(path({ type: "constructor" }), "type");
    assert.equal(path({ type: "__proto__" }), "type");
  });

  it("names the field that is missing or wrong", () => {
    assert.equal(path(send({ botId: undefined })), "botId");
    assert.equal(path({ type: "message.send", sessionId: "s", text: "t" }), "botId");
    assert.equal(path(send({ botId: "" })), "botId");
    assert.equal(path(send({ botId: "bad id" })), "botId");
    assert.equal(path(send({ botId: "a".repeat(129) })), "botId");
    assert.equal(path(send({ sessionId: "-x" })), "sessionId");
    assert.equal(path(send({ sessionId: 5 })), "sessionId");
    assert.equal(path(decide({ approvalId: "../x" })), "approvalId");
    assert.equal(path(decide({ decision: "expired" })), "decision");
    assert.equal(path(decide({ decision: "APPROVED" })), "decision");
    assert.equal(path(decide({ decision: undefined })), "decision");
  });

  it("limits the text to 1 through 20000 characters without NUL", () => {
    assert.equal(parseCommand(send({ text: "x" })).ok, true);
    assert.equal(parseCommand(send({ text: "x".repeat(MAX_TEXT_LENGTH) })).ok, true);
    assert.equal(MAX_TEXT_LENGTH, 20_000);
    for (const text of ["", "x".repeat(MAX_TEXT_LENGTH + 1), "a\0b", 5, null, ["x"]]) assert.equal(path(send({ text })), "text");
  });

  it("rejects unknown keys, and keys that belong to another command", () => {
    assert.equal(path(send({ extra: 1 })), "command");
    assert.equal(path(cancel({ text: "x" })), "command");
    assert.equal(path(decide({ text: "x" })), "command");
    assert.equal(path({ ...send(), approvalId: "apr-1" }), "command");
  });

  it("never puts a value from the input into the error", () => {
    const hostile = "SECRET-MARKER-123";
    for (const input of [send({ text: 5, botId: hostile }), send({ [hostile]: 1 }), { type: hostile }, send({ sessionId: hostile + " bad" })]) {
      assert.doesNotMatch(JSON.stringify(parseCommand(input)), /SECRET-MARKER-123/);
    }
  });
});
