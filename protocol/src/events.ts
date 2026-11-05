import { ID_PATTERN, MAX_ITEM_TEXT_LENGTH, PROTOCOL_VERSION, TIMESTAMP_PATTERN } from "./version.ts";
import { fail, hasKeys, isJsonValue, isPlainObject, pass, type JsonObject, type ParseResult } from "./result.ts";

export type TurnState = "started" | "completed" | "failed" | "cancelled";
export type TurnStatus = "completed" | "failed" | "awaiting_approval" | "cancelled";
export type ToolOutcome = "success" | "error" | "denied";

/** One durable fact of a session. Together they cover every sequence number: there are no gaps. */
export type Item =
  | { readonly kind: "session_started"; readonly botId: string }
  | { readonly kind: "turn"; readonly turnId: string; readonly state: TurnState; readonly trigger?: "user" | "routine" | "subagent" }
  | { readonly kind: "step"; readonly turnId: string; readonly stepId: string; readonly state: "started" | "ended" }
  | { readonly kind: "message"; readonly role: "user" | "assistant"; readonly turnId: string; readonly text: string }
  | { readonly kind: "tool_call"; readonly turnId: string; readonly stepId: string; readonly toolCallId: string; readonly name: string; readonly arguments: JsonObject }
  | { readonly kind: "tool_result"; readonly toolCallId: string; readonly outcome: ToolOutcome; readonly content: string }
  | { readonly kind: "approval_requested"; readonly approvalId: string; readonly toolCallId: string; readonly summary: string; readonly expiresAt: string }
  | { readonly kind: "approval_resolved"; readonly approvalId: string; readonly decision: "approved" | "rejected" | "expired" }
  | { readonly kind: "usage"; readonly turnId: string; readonly stepId: string; readonly inputTokens: number; readonly outputTokens: number }
  | { readonly kind: "compacted"; readonly summary: string; readonly throughSequence: number };

export const ERROR_CODES = [
  "invalid_command", "unauthorized", "unknown_bot", "turn_open", "no_pending_approval", "approval_failed",
  "budget_exceeded", "unavailable", "internal",
] as const;
export type ErrorCode = (typeof ERROR_CODES)[number];

export type ServerEvent =
  | { readonly type: "hello"; readonly protocolVersion: typeof PROTOCOL_VERSION }
  | { readonly type: "log.event"; readonly botId: string; readonly sessionId: string; readonly sequence: number; readonly at: string; readonly item: Item }
  | { readonly type: "live.text"; readonly botId: string; readonly sessionId: string; readonly turnId: string; readonly stepId: string; readonly text: string }
  | { readonly type: "live.reset"; readonly botId: string; readonly sessionId: string; readonly turnId: string; readonly stepId: string }
  | { readonly type: "turn.finished"; readonly botId: string; readonly sessionId: string; readonly turnId: string; readonly status: TurnStatus; readonly failure?: "max_steps" | "model_error" }
  | { readonly type: "error"; readonly code: ErrorCode; readonly botId?: string; readonly sessionId?: string };

type Rec = Record<string, unknown>;
const id = (r: Rec, key: string): string | undefined => { const v = r[key]; return typeof v === "string" && ID_PATTERN.test(v) ? v : undefined; };
const text = (r: Rec, key: string): string | undefined => { const v = r[key]; return typeof v === "string" && v.length <= MAX_ITEM_TEXT_LENGTH ? v : undefined; };
const count = (r: Rec, key: string): number | undefined => { const v = r[key]; return typeof v === "number" && Number.isSafeInteger(v) && v >= 0 ? v : undefined; };
const oneOf = <T extends string>(r: Rec, key: string, values: readonly T[]): T | undefined => values.find((value) => r[key] === value);
const stamp = (r: Rec, key: string): string | undefined => { const v = r[key]; return typeof v === "string" && TIMESTAMP_PATTERN.test(v) ? v : undefined; };

function parseItem(raw: unknown): ParseResult<Item> {
  if (!isPlainObject(raw)) return fail("item");
  const kind = raw["kind"];
  const shape = (required: readonly string[], optional: readonly string[] = []): string | undefined => {
    const problem = hasKeys(raw, ["kind", ...required], optional);
    return problem === undefined ? undefined : `item.${problem === "" ? "kind" : problem}`;
  };
  const bad = (field: string) => fail(`item.${field}`);
  switch (kind) {
    case "session_started": {
      const problem = shape(["botId"]); if (problem) return fail(problem);
      const botId = id(raw, "botId"); return botId === undefined ? bad("botId") : pass({ kind, botId });
    }
    case "turn": {
      const problem = shape(["turnId", "state"], ["trigger"]); if (problem) return fail(problem);
      const turnId = id(raw, "turnId"); if (turnId === undefined) return bad("turnId");
      const state = oneOf(raw, "state", ["started", "completed", "failed", "cancelled"] as const); if (state === undefined) return bad("state");
      if (!Object.hasOwn(raw, "trigger")) return pass({ kind, turnId, state });
      const trigger = oneOf(raw, "trigger", ["user", "routine", "subagent"] as const); return trigger === undefined ? bad("trigger") : pass({ kind, turnId, state, trigger });
    }
    case "step": {
      const problem = shape(["turnId", "stepId", "state"]); if (problem) return fail(problem);
      const turnId = id(raw, "turnId"); if (turnId === undefined) return bad("turnId");
      const stepId = id(raw, "stepId"); if (stepId === undefined) return bad("stepId");
      const state = oneOf(raw, "state", ["started", "ended"] as const); return state === undefined ? bad("state") : pass({ kind, turnId, stepId, state });
    }
    case "message": {
      const problem = shape(["role", "turnId", "text"]); if (problem) return fail(problem);
      const role = oneOf(raw, "role", ["user", "assistant"] as const); if (role === undefined) return bad("role");
      const turnId = id(raw, "turnId"); if (turnId === undefined) return bad("turnId");
      const body = text(raw, "text"); return body === undefined ? bad("text") : pass({ kind, role, turnId, text: body });
    }
    case "tool_call": {
      const problem = shape(["turnId", "stepId", "toolCallId", "name", "arguments"]); if (problem) return fail(problem);
      const turnId = id(raw, "turnId"); if (turnId === undefined) return bad("turnId");
      const stepId = id(raw, "stepId"); if (stepId === undefined) return bad("stepId");
      const toolCallId = id(raw, "toolCallId"); if (toolCallId === undefined) return bad("toolCallId");
      const name = raw["name"]; if (typeof name !== "string" || !/^[A-Za-z][A-Za-z0-9_.-]{0,63}$/.test(name)) return bad("name");
      const args = raw["arguments"]; if (!isPlainObject(args) || !isJsonValue(args)) return bad("arguments");
      return pass({ kind, turnId, stepId, toolCallId, name, arguments: args as JsonObject });
    }
    case "tool_result": {
      const problem = shape(["toolCallId", "outcome", "content"]); if (problem) return fail(problem);
      const toolCallId = id(raw, "toolCallId"); if (toolCallId === undefined) return bad("toolCallId");
      const outcome = oneOf(raw, "outcome", ["success", "error", "denied"] as const); if (outcome === undefined) return bad("outcome");
      const content = text(raw, "content"); return content === undefined ? bad("content") : pass({ kind, toolCallId, outcome, content });
    }
    case "approval_requested": {
      const problem = shape(["approvalId", "toolCallId", "summary", "expiresAt"]); if (problem) return fail(problem);
      const approvalId = id(raw, "approvalId"); if (approvalId === undefined) return bad("approvalId");
      const toolCallId = id(raw, "toolCallId"); if (toolCallId === undefined) return bad("toolCallId");
      const summary = text(raw, "summary"); if (summary === undefined) return bad("summary");
      const expiresAt = stamp(raw, "expiresAt"); return expiresAt === undefined ? bad("expiresAt") : pass({ kind, approvalId, toolCallId, summary, expiresAt });
    }
    case "approval_resolved": {
      const problem = shape(["approvalId", "decision"]); if (problem) return fail(problem);
      const approvalId = id(raw, "approvalId"); if (approvalId === undefined) return bad("approvalId");
      const decision = oneOf(raw, "decision", ["approved", "rejected", "expired"] as const); return decision === undefined ? bad("decision") : pass({ kind, approvalId, decision });
    }
    case "usage": {
      const problem = shape(["turnId", "stepId", "inputTokens", "outputTokens"]); if (problem) return fail(problem);
      const turnId = id(raw, "turnId"); if (turnId === undefined) return bad("turnId");
      const stepId = id(raw, "stepId"); if (stepId === undefined) return bad("stepId");
      const inputTokens = count(raw, "inputTokens"); if (inputTokens === undefined) return bad("inputTokens");
      const outputTokens = count(raw, "outputTokens"); return outputTokens === undefined ? bad("outputTokens") : pass({ kind, turnId, stepId, inputTokens, outputTokens });
    }
    case "compacted": {
      const problem = shape(["summary", "throughSequence"]); if (problem) return fail(problem);
      const summary = text(raw, "summary"); if (summary === undefined) return bad("summary");
      const throughSequence = count(raw, "throughSequence"); return throughSequence === undefined ? bad("throughSequence") : pass({ kind, summary, throughSequence });
    }
    default: return fail("item.kind");
  }
}

/** Validates one event received from the server. Strict: unknown keys and wrong types are errors. */
export function parseServerEvent(input: unknown): ParseResult<ServerEvent> {
  if (!isPlainObject(input)) return fail("event");
  const type = input["type"];
  const shape = (required: readonly string[], optional: readonly string[] = []): string | undefined => {
    const problem = hasKeys(input, ["type", ...required], optional);
    return problem === undefined ? undefined : problem === "" ? "event" : problem;
  };
  switch (type) {
    case "hello": {
      const problem = shape(["protocolVersion"]); if (problem) return fail(problem);
      return input["protocolVersion"] === PROTOCOL_VERSION ? pass({ type, protocolVersion: PROTOCOL_VERSION }) : fail("protocolVersion");
    }
    case "log.event": {
      const problem = shape(["botId", "sessionId", "sequence", "at", "item"]); if (problem) return fail(problem);
      const botId = id(input, "botId"); if (botId === undefined) return fail("botId");
      const sessionId = id(input, "sessionId"); if (sessionId === undefined) return fail("sessionId");
      const sequence = count(input, "sequence"); if (sequence === undefined) return fail("sequence");
      const at = stamp(input, "at"); if (at === undefined) return fail("at");
      const item = parseItem(input["item"]); return item.ok ? pass({ type, botId, sessionId, sequence, at, item: item.value }) : item;
    }
    case "live.text": {
      const problem = shape(["botId", "sessionId", "turnId", "stepId", "text"]); if (problem) return fail(problem);
      const botId = id(input, "botId"); if (botId === undefined) return fail("botId");
      const sessionId = id(input, "sessionId"); if (sessionId === undefined) return fail("sessionId");
      const turnId = id(input, "turnId"); if (turnId === undefined) return fail("turnId");
      const stepId = id(input, "stepId"); if (stepId === undefined) return fail("stepId");
      const body = text(input, "text"); return body === undefined ? fail("text") : pass({ type, botId, sessionId, turnId, stepId, text: body });
    }
    case "live.reset": {
      const problem = shape(["botId", "sessionId", "turnId", "stepId"]); if (problem) return fail(problem);
      const botId = id(input, "botId"); if (botId === undefined) return fail("botId");
      const sessionId = id(input, "sessionId"); if (sessionId === undefined) return fail("sessionId");
      const turnId = id(input, "turnId"); if (turnId === undefined) return fail("turnId");
      const stepId = id(input, "stepId"); return stepId === undefined ? fail("stepId") : pass({ type, botId, sessionId, turnId, stepId });
    }
    case "turn.finished": {
      const problem = shape(["botId", "sessionId", "turnId", "status"], ["failure"]); if (problem) return fail(problem);
      const botId = id(input, "botId"); if (botId === undefined) return fail("botId");
      const sessionId = id(input, "sessionId"); if (sessionId === undefined) return fail("sessionId");
      const turnId = id(input, "turnId"); if (turnId === undefined) return fail("turnId");
      const status = oneOf(input, "status", ["completed", "failed", "awaiting_approval", "cancelled"] as const); if (status === undefined) return fail("status");
      if (!Object.hasOwn(input, "failure")) return pass({ type, botId, sessionId, turnId, status });
      const failure = oneOf(input, "failure", ["max_steps", "model_error"] as const);
      return failure === undefined || status !== "failed" ? fail("failure") : pass({ type, botId, sessionId, turnId, status, failure });
    }
    case "error": {
      const problem = shape(["code"], ["botId", "sessionId"]); if (problem) return fail(problem);
      const code = oneOf(input, "code", ERROR_CODES); if (code === undefined) return fail("code");
      const botId = Object.hasOwn(input, "botId") ? id(input, "botId") : undefined;
      const sessionId = Object.hasOwn(input, "sessionId") ? id(input, "sessionId") : undefined;
      if (Object.hasOwn(input, "botId") && botId === undefined) return fail("botId");
      if (Object.hasOwn(input, "sessionId") && sessionId === undefined) return fail("sessionId");
      return pass({ type, code, ...(botId === undefined ? {} : { botId }), ...(sessionId === undefined ? {} : { sessionId }) });
    }
    default: return fail("type");
  }
}
