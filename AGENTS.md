# AGENTS.md · Jacobot

The open source product repository of Jaco: native clients, the backend that serves them and the protocol between them. The agent engine (harness) is a separate, private repository and does not belong here. General description: `README.md`.

Each important subfolder has its own `AGENTS.md` with local rules; the one closest to the edited file takes precedence. `CLAUDE.md` is a symlink to the `AGENTS.md` in the same folder: always edit `AGENTS.md`.

## Layout

| Folder | Role | State |
| --- | --- | --- |
| `clients/ui` | macOS client (SwiftUI), design system, design tokens | prototype, own `AGENTS.md` |
| `gateway` | client connections, auth, streaming | placeholder |
| `host` | Bots, conversations, routines, persistent state | placeholder |
| `sandbox` | isolated environment where each Bot runs | placeholder |
| `protocol` | versioned contract between clients and backend: commands, events and strict parsers (v1), zero dependencies | package, own `AGENTS.md` |

Placeholder folders only hold a `.gitkeep`. Do not add code, tooling or an `AGENTS.md` to them until their design is agreed. `protocol` is the first one whose design is agreed.

## Architecture

```text
Client ──protocol──▶ Gateway ──▶ Host ──▶ Harness ──▶ LLM provider
                                   └────▶ Sandbox
```

- Dependencies point toward the protocol. Clients and backend depend on `protocol`; `protocol` depends on nothing here.
- The harness (private repository) consumes `protocol` as a versioned package. This repository never imports harness code.
- Clients hold no agent logic: they render protocol events and send user actions.

## Non-negotiable rules

1. **Open source.** Everything committed here is public under Apache 2.0. Never commit API keys, tokens, credentials, personal data or private harness code. Use `.env.example` for configuration templates; real `.env*` files are ignored.
2. **The protocol is a public contract.** Version it and treat changes as breaking unless proven otherwise. Do not leak model-provider types into it.
3. **Model-agnostic.** Nothing outside the harness may depend on a specific LLM provider.
4. **Third-party assets keep their licenses.** When adding a font, icon set or library, add its license next to the files and mention it in `NOTICE`.
5. **Everything is in English**: code, comments, docs and UI text.

## Boundaries

- **Ask first** before adding a dependency, creating a top-level folder or changing the layout above.
- **Never** commit, push or stage without an explicit request from the user.
- **Never** put harness code or secrets in this repository.
- Do not edit `LICENSE`; it is the unmodified Apache 2.0 text.

## Where to look

| To… | See |
| --- | --- |
| Run or change the macOS client | `clients/ui/AGENTS.md` |
| Use or change the protocol | `protocol/AGENTS.md`, `protocol/README.md` |
| Project overview and quick start | `README.md` |
| Third-party licenses | `NOTICE` |
