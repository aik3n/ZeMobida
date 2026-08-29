# ZeMobida — Architecture

**Audited revision:** `12ea5386c03d53dd51dae26fd172775e281544f8`

## High-level model

```text
Game
├── Player
├── HUD / Status UI
├── DialogueUI
└── SceneContainer
    └── Current map
        ├── PNJ
        ├── SpawnPlayer
        └── CameraBounds
```

`Game` owns the persistent Player and coordinates map lifecycle and global UI.

## Responsibilities

### Game
Map loading, Player lifecycle/spawn, camera limits and global UI.

### Player
Movement, XP, level and `xp_changed`.

### DialogueManager
Active dialogue, nodes, conditions, jumps, options, effects, inventory and persistence. It is an autoload.

### DialogueParser
Converts `.txt` dialogue into internal dictionaries.

### DialogueValidator
Checks parser errors, empty dialogue and destination validity.

### DialogueUI
Presentation of speaker/text/options and user interaction.

### DialogueUpdater
Downloads dialogue content from the GitHub Contents API into `user://dialogues/`.

### PNJ
Movement/follow modes, interaction and dialogue file resolution.

## Runtime flow

```text
Game startup
  → persistent Player
  → bienvenida
  → dialogue synchronization
  → aldea
  → PNJ interaction
  → DialogueManager
  → DialogueUI
```

NPC dialogue resolution:

```text
<map>_<npc>_<level>.txt
        ↓
<map>_<npc>.txt
        ↓
generico.txt
```

## Persistence

```text
user://save/status.txt
```

Current fields include:

```text
xp=<integer>
inventory=item1,item2,...
```

Level is derived from XP.

## Architectural risks

- Scene-tree lookups create coupling.
- `DialogueManager` combines dialogue, inventory and persistence.
- Automatic dialogue cycles are not currently detected.
- Remote content introduces versioning/integrity concerns.

See `DECISIONS.md` for rationale and `AUDIT.md` for risks.
