# AGENTS.md · protocol

The public, versioned contract between Jacobot clients and the backend. General rules: root `AGENTS.md`.

## Rules

- **Zero dependencies**, runtime and development. Tests use `node --test`, which runs the TypeScript sources directly. Do not add a package without asking.
- Nothing here may import harness code, or mention a model provider, a model name or a harness-internal type. The harness maps its own events to these; this package never learns about them.
- Treat every change as breaking unless it only adds an optional field a reader can ignore. A breaking change raises `PROTOCOL_VERSION` and keeps the old parser until clients have moved.
- Parsers are strict: unknown keys, wrong types and out-of-range values are errors. A parse error names the path of the problem and never contains a value from the input, because values can be user text or secrets.
- Ids are opaque strings matching `ID_PATTERN`. Timestamps are `YYYY-MM-DDTHH:MM:SSZ`.
- One message per file when it grows; keep each file under 400 lines. Everything is in English.

## Layout

| File | Role |
| --- | --- |
| `src/version.ts` | `PROTOCOL_VERSION` and the HTTP binding constants (paths, headers) |
| `src/result.ts` | the `ParseResult` shape shared by the parsers |
| `src/commands.ts` | what a client may ask for, and `parseCommand` |
| `src/events.ts` | what the server sends, and `parseServerEvent` |
| `tests/` | `node --test` suites |
