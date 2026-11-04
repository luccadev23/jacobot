# AGENTS.md · design

The project's visual source.

| File | Role |
| --- | --- |
| `jaco.pen` | full design in Pencil (light + dark) |
| `tokens.json` | exported tokens; input of the generator |

## `jaco.pen`

- **Encrypted.** Access it only through the Pencil MCP (`mcp__pencil__*`), with the path `/Users/luccabonim/projetos/jaco/jacobot/clients/ui/design/jaco.pen`. Never `Read`, `grep` or `cat`.
- Structure: `00 Mascot`, `01 Color`, `02 Type & Layout`, `03 Icons`, `04 Platforms`, `05 Components Library` (A0–A7, B1–B4, C1) + dark copy, and the screens per platform (macOS, Windows, iPad, iPhone, Android), in light and dark.
- The dark library is a copy (`Copy`) of the light one, to keep references linked. Changed the light one → redo the dark copy.
- Changed a component: also update its states (A7) and the screens that use it.
- Instance overrides are by child name; a replaced child uses the path `instId/<replacementId>`.
- Keep everything inside the frames; check overflow by bounds after editing.
- Colors and measurements come from variables (with light/dark modes), never loose values.
- No automatic backup: before big changes, copy the file outside the repository.

## `tokens.json`

- Format: `{ "name": { "t": "color|number|string", ... } }`. A single value goes in `"v"`; themed tokens use `"l"` (light) and `"d"` (dark). A value may reference another token with `"$name"`.
- Changed a variable in Pencil → re-export here and run `python3 scripts/generate_tokens.py`.
- Do not edit by hand without reflecting the change in the `.pen`.
