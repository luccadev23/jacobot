/** Raised on any breaking change to the commands, the events or the HTTP binding. */
export const PROTOCOL_VERSION = 1 as const;

export const PATH_COMMANDS = "/v1/commands";
export const PATH_EVENTS = "/v1/events";
export const PATH_BOTS = "/v1/bots";
export const HEADER_AUTHORIZATION = "authorization";

/** Opaque identifiers: bots, sessions, turns, steps, approvals and tool calls. */
export const ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/;
export const TIMESTAMP_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
/** Longest text a user may send in one message. */
export const MAX_TEXT_LENGTH = 20_000;
/** Longest text the server may put in one item (a model answer or a tool result). */
export const MAX_ITEM_TEXT_LENGTH = 1_000_000;
