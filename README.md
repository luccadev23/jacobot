# Jacobot

An open source platform for **persistent AI agents ("Bots")** that work for you in the apps you already use, with a human approving what matters. Jacobot is model-agnostic: the agent engine talks to LLMs through a provider layer, so any model with tool use can power a Bot.

![Status](https://img.shields.io/badge/status-early%20development-orange)
![License](https://img.shields.io/badge/license-Apache%202.0-blue)
![macOS client](https://img.shields.io/badge/macOS%20client-SwiftUI-lightgrey)

## Table of contents

- [Overview](#overview)
- [Repository layout](#repository-layout)
- [How the pieces fit](#how-the-pieces-fit)
- [Status](#status)
- [Quick start](#quick-start)
- [License](#license)
- [For AI agents](#for-ai-agents)

## Overview

A Bot is a long-running agent with its own name, tools, memory, skills, routines and a computer it can operate. You talk to it in a chat, watch what it does, approve sensitive actions and take over when it needs you.

This repository is the **product**: the clients, the backend that serves them and the protocol they speak. The agent engine (the harness) lives in a separate repository and is plugged in through the [protocol](protocol/).

## Repository layout

```text
clients/
  ui/            native macOS client in SwiftUI, design system and design tokens
gateway/         client connections, authentication, streaming        (planned)
host/            Bots, conversations, routines and persistent state   (planned)
sandbox/         isolated environment where each Bot runs             (planned)
protocol/        versioned contract between clients and backend       (planned)
```

Folders marked as planned exist as placeholders and have no code yet.

## How the pieces fit

```text
Client ──protocol──▶ Gateway ──▶ Host ──▶ Harness ──▶ LLM provider
                                   └────▶ Sandbox (the Bot's computer)
```

- **Protocol** is a contract, not a service. It is open so that anyone can write a client or a backend.
- **Harness** runs the agent loop, tools, memory and permissions behind a model-agnostic interface. It is not part of this repository.
- Clients contain no agent logic: they render events and send user actions.

## Status

Early development. Only the macOS UI prototype exists, running on sample data. There is no backend yet.

## Quick start

Run the macOS client prototype (macOS 14+ and Swift 6):

```sh
cd clients/ui
swift build
.build/debug/JacoMac
```

See [`clients/ui/README.md`](clients/ui/README.md) for tokens, snapshots and the design workflow.

## License

Licensed under the [Apache License 2.0](LICENSE). See [`NOTICE`](NOTICE) for third-party components (fonts and icons keep their own licenses). The Jaco name, mascot and logo are not covered by the code license.

## For AI agents

Instructions live in [`AGENTS.md`](AGENTS.md). In each folder, `CLAUDE.md` is a symlink to its `AGENTS.md`.
