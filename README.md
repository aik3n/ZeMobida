# ZeMobida

> An adventure and decision-driven game where conversations have consequences.

**Status:** prototype / active development
**Engine:** Godot 4.7
**Rendering:** GL Compatibility
**License:** GNU GPLv3

**Documentation baseline:** `c4c1e27bb36db74d039615da24d1f62fd1db80df`
**Original code audit baseline:** `12ea5386c03d53dd51dae26fd172775e281544f8`

## Overview

ZeMobida is an open-source Godot game built around exploration, NPC interaction, branching dialogue, inventory, experience and player decisions.

## Current features

* Exploratory 2D map (`aldea`).
* Persistent player instance owned by `Game`.
* Spawn points and camera limits per map.
* NPC interaction and follow modes.
* Branching dialogue from `.txt` files.
* Inventory conditions and dialogue effects.
* XP and progression levels (`a1`, `a2`, `b1`, `b2`, `c1`).
* Global HUD/status UI.
* Local save data under `user://`.
* GitHub-based dialogue synchronization.
* Dialogue parser and validator.

## Repository layout

```text
.
├── godot/
│   ├── escenas/
│   ├── scripts/
│   ├── project.godot
│   └── export_presets.cfg
├── docs/
│   ├── ARCHITECTURE.md
│   ├── AUDIT.md
│   ├── DECISIONS.md
│   ├── DEVELOPMENT.md
│   └── DIALOGUE_FORMAT.md
├── README.md
├── README.esp.md
├── README.eus.md
└── LICENSE
```

## Requirements

* Godot **4.7**.
* Network connection for online dialogue synchronization.
* Windows Desktop and Android export presets are present.

## Run locally

```bash
git clone https://github.com/aik3n/ZeMobida.git
cd ZeMobida
```

Open `godot/project.godot` with Godot 4.7 and run the project. The configured main scene is `res://escenas/Game.tscn`.

## Architecture

| Component           | Responsibility                                         |
| ------------------- | ------------------------------------------------------ |
| `Game`              | Global orchestration, maps, persistent Player and UI   |
| `Player`            | Movement, XP and level                                 |
| `DialogueManager`   | Dialogue execution, effects, inventory and persistence |
| `DialogueParser`    | Parses dialogue text                                   |
| `DialogueValidator` | Validates dialogue structure and destinations          |
| `DialogueUI`        | Dialogue presentation                                  |
| `DialogueUpdater`   | GitHub content synchronization                         |
| `PNJ`               | NPC movement/following and dialogue initiation         |

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Dialogue format

Dialogue content lives in the separate repository `aik3n/ZeMobida_guiones`; `.txt` files are stored at its root. See [`docs/DIALOGUE_FORMAT.md`](docs/DIALOGUE_FORMAT.md).

## Development

See [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

## Architecture decisions

Long-term architectural decisions are documented as ADRs in [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Audit

The original technical audit was performed against commit `12ea5386c03d53dd51dae26fd172775e281544f8`.

The documentation was subsequently migrated, cleaned and reorganized in commit `c4c1e27bb36db74d039615da24d1f62fd1db80df`.

See [`docs/AUDIT.md`](docs/AUDIT.md).

## Known limitations

Several findings from the original audit have since been addressed, including incremental dialogue synchronization, temporary-set validation, cache fallback, unified persistence, dynamic map selection and separation of dialogue content into its own repository.

Remaining areas to review before release include the mutable `main` reference used for dialogue content, automatic dialogue-cycle detection, distribution metadata and automated tests/CI.

See [`docs/AUDIT.md`](docs/AUDIT.md) for the current status.

## License

GNU GPLv3. See [`LICENSE`](LICENSE).
