import { ID_PATTERN, MAX_TEXT_LENGTH } from "./version.ts";
import { fail, hasKeys, isPlainObject, pass, type ParseResult } from "./result.ts";

export type Command =
  | { readonly type: "message.send"; readonly botId: string; readonly sessionId: string; readonly text: string }
  | { readonly type: "approval.decide"; readonly botId: string; readonly sessionId: string; readonly approvalId: string; readonly decision: "approved" | "rejected" }
  | { readonly type: "turn.cancel"; readonly botId: string; readonly sessionId: string };

export const COMMAND_TYPES = ["message.send", "approval.decide", "turn.cancel"] as const;

function id(record: Record<string, unknown>, key: string): string | undefined {
  const value = record[key];
  return typeof value === "string" && ID_PATTERN.test(value) ? value : undefined;
}

/** Validates one command received from a client. Strict: unknown keys and wrong types are errors. */
export function parseCommand(input: unknown): ParseResult<Command> {
  if (!isPlainObject(input)) return fail("command");
  const type = input["type"];
  if (typeof type !== "string" || !(COMMAND_TYPES as readonly string[]).includes(type)) return fail("type");
  const extra: Record<string, readonly string[]> = {
    "message.send": ["text"], "approval.decide": ["approvalId", "decision"], "turn.cancel": [],
  };
  const fields = extra[type] ?? [];
  const problem = hasKeys(input, ["type", "botId", "sessionId", ...fields]);
  if (problem !== undefined) return fail(problem === "" ? "command" : problem);
  const botId = id(input, "botId");
  if (botId === undefined) return fail("botId");
  const sessionId = id(input, "sessionId");
  if (sessionId === undefined) return fail("sessionId");
  if (type === "turn.cancel") return pass({ type: "turn.cancel", botId, sessionId });
  if (type === "message.send") {
    const text = input["text"];
    if (typeof text !== "string" || text.length < 1 || text.length > MAX_TEXT_LENGTH || text.includes("\0")) return fail("text");
    return pass({ type: "message.send", botId, sessionId, text });
  }
  const approvalId = id(input, "approvalId");
  if (approvalId === undefined) return fail("approvalId");
  const decision = input["decision"];
  if (decision !== "approved" && decision !== "rejected") return fail("decision");
  return pass({ type: "approval.decide", botId, sessionId, approvalId, decision });
}
