# Jacobot protocol

The contract between Jacobot clients and the backend. Version **1**.

A client sends **commands** and receives **events**. Commands are plain JSON objects with a `type`; events are the same, delivered as a stream. Both are validated by strict parsers in this package, so a client and a server can reject malformed messages the same way.

## Commands (client to server)

| `type` | Fields | Meaning |
| --- | --- | --- |
| `message.send` | `botId`, `sessionId`, `text` (1 to 20,000 characters) | Say something to a Bot. Starts a turn |
| `approval.decide` | `botId`, `sessionId`, `approvalId`, `decision` (`approved` or `rejected`) | Answer a request for approval |
| `turn.cancel` | `botId`, `sessionId` | Stop the turn in progress |

## Events (server to client)

| `type` | Fields | Meaning |
| --- | --- | --- |
| `hello` | `protocolVersion` | First event on every stream |
| `log.event` | `botId`, `sessionId`, `sequence`, `at`, `item` | A durable fact of a session, in order, never repeated |
| `live.text` | `botId`, `sessionId`, `turnId`, `stepId`, `text` | A piece of the answer being written. Not durable |
| `live.reset` | `botId`, `sessionId`, `turnId`, `stepId` | Discard the live text of this step: it is being retried. Not durable |
| `turn.finished` | `botId`, `sessionId`, `turnId`, `status`, `failure?` | The turn stopped: finished, failed, cancelled, or waiting for an approval |
| `error` | `code`, `botId?`, `sessionId?` | A command could not be carried out |

A `log.event` carries one `item`: a message, a tool call or result, an approval request or decision, a turn change, token usage, or a compaction. The sequence of a session starts at 0 and has no gaps, so a client can resume from the last sequence it saw.

## HTTP binding

| Request | Meaning |
| --- | --- |
| `POST /v1/commands` | Body: one command. Answers `202` when accepted, or an error with a `code` |
| `GET /v1/events?bot=&session=&from=` | Server-sent events. Replays the session from `from` (default 0), then streams live. Each `log.event` has `id: <sequence>` |
| `GET /v1/bots` | The Bots the server hosts |

Every request carries `Authorization: Bearer <token>`.

## Development

```sh
cd protocol
npm test
```
