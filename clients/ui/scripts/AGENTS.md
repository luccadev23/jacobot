# AGENTS.md · scripts

Command-line tools for the repository.

| Script | Role |
| --- | --- |
| `generate_tokens.py` | `design/tokens.json` → `Sources/JacoDesignSystem/Generated/Tokens.swift` |

## Rules

- Plain Python 3, standard library only. No installable dependencies.
- Resolve paths from the script itself (`Path(__file__)`), never from the current directory.
- Deterministic output: running twice without changing the input must not produce a diff.
- No side effects outside the repository and no network.
- For other platforms (Windows, Linux, Android), create a sibling generator that reads the same `tokens.json` instead of branching this one.
- New script: one line in the table above and a docstring explaining input and output.
