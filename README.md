# ZeMobida

> An adventure and decision-driven game where conversations have consequences.

**Status:** prototype / active development  
**Engine:** Godot 4.7  
**Rendering:** GL Compatibility  
**License:** GNU GPLv3

## Overview

ZeMobida is an open-source Godot game built around exploration, NPC interaction, branching dialogue, inventory, experience and player decisions.

## Current features

- Dynamic selection of maps discovered from `res://mapas/`.
- Persistent `Player` owned by `Game`.
- Per-map initial `SpawnPlayer` plus restoration of the last saved Player position.
- Return to the map selector from the global status panel.
- Illustrated top-down maps with optional `Fondo`, `Frontal`, `Preview` and local collisions.
- Touch exploration with tap-to-move, camera drag and pinch zoom.
- NPC interaction and follow modes.
- NPC technical identity derived from the node name.
- NPC sprite selected from the Inspector through an exported `Texture2D` property and reflected in the internal `Sprite2D` in edit time.
- Branching dialogue from UTF-8 `.txt` files.
- Official dialogue synchronization from the separate repository `aik3n/ZeMobida_guiones`.
- Per-file local dialogue overrides under `user://custom_dialogues/`.
- Lightweight in-game dialogue editor.
- Inventory conditions and effects.
- XP-derived progression levels: `a1`, `a2`, `b1`, `b2`, `c1`, `c2`.
- Global HUD/status UI and floating feedback for XP/inventory changes.
- Consolidated local persistence in `user://settings.cfg`.

## Repository layout

```text
.
├── godot/
│   ├── art/
│   ├── escenas/
│   ├── mapas/
│   ├── scripts/
│   ├── project.godot
│   └── export_presets.cfg
├── docs/
│   ├── ARCHITECTURE.md
│   ├── AUDIT.md
│   ├── DECISIONS.md
│   ├── DECISIONS_RECENT.md
│   ├── DEVELOPMENT.md
│   ├── DIALOGUE_FORMAT.md
│   └── MAP_PACKS_FUTURE.md
├── README.md
├── README.esp.md
├── README.eus.md
└── LICENSE
```

## Requirements

- Godot **4.7**.
- Network connection when online dialogue synchronization is enabled.
- Windows Desktop and Android export presets are present.

## Run locally

```bash
git clone https://github.com/aik3n/ZeMobida.git
cd ZeMobida
```

Open `godot/project.godot` and run `res://escenas/Game.tscn`.

## Architecture

| Component | Responsibility |
| --- | --- |
| `Game` | Global orchestration, map loading, persistent Player, map-position persistence and global UI |
| `Player` | Movement, camera interaction, XP and derived level |
| `PNJ` | NPC movement/following, dialogue initiation and editor-time sprite presentation |
| `DialogueManager` | Dialogue runtime, effects, inventory, local override resolution and player-state persistence |
| `DialogueParser` | Interprets the dialogue text format |
| `DialogueValidator` | Current runtime structural validation |
| `DialogueUI` | Dialogue presentation |
| `DialogueUpdater` | Synchronization of official dialogue content |
| `CarruselMapas` | Dynamic map discovery and selection |

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Dialogue content

Official dialogue content is versioned in the separate repository `aik3n/ZeMobida_guiones`. Runtime official files are cached under `user://dialogues/`; local player-created variants live under `user://custom_dialogues/`.

See [`docs/DIALOGUE_FORMAT.md`](docs/DIALOGUE_FORMAT.md).

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — current architecture.
- [`docs/AUDIT.md`](docs/AUDIT.md) — current technical backlog/status.
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — historical ADRs.
- [`docs/DECISIONS_RECENT.md`](docs/DECISIONS_RECENT.md) — recent accepted decisions pending later consolidation into the historical ADR log.
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — development/runtime checks.
- [`docs/DIALOGUE_FORMAT.md`](docs/DIALOGUE_FORMAT.md) — dialogue syntax.
- [`docs/MAP_PACKS_FUTURE.md`](docs/MAP_PACKS_FUTURE.md) — deferred production idea for independent map packages.

## Known limitations

The project is still a prototype. Important remaining areas include automatic dialogue-transition cycle protection, dialogue ownership between overlapping NPCs, automated tests/CI, release metadata and reproducible versioning of remote dialogue content.

See [`docs/AUDIT.md`](docs/AUDIT.md) for the current status.

## License

GNU GPLv3. See [`LICENSE`](LICENSE).
