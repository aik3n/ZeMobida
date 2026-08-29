# ZeMobida — Development Guide

**Baseline:** `12ea5386c03d53dd51dae26fd172775e281544f8`  
**Godot:** 4.7

## Principles

Prefer small, isolated changes that preserve existing responsibilities.

Before significant architectural changes:

1. identify the existing responsibility;
2. identify the limitation;
3. propose the change;
4. implement the smallest viable change;
5. test existing behavior;
6. update documentation/ADR;
7. commit.

## Main code areas

```text
godot/scripts/game.gd
godot/scripts/player.gd
godot/scripts/pnj.gd
godot/scripts/dialogue_manager.gd
godot/scripts/dialogue_parser.gd
godot/scripts/dialogue_validator.gd
godot/scripts/dialogue_ui.gd
godot/scripts/dialogue_updater.gd
```

Content lives in:

```text
guiones/
```

## Manual regression matrix

### Startup
- project opens;
- bienvenida loads;
- synchronization completes or fails safely;
- map can be entered.

### Player
- spawn works;
- movement works;
- Player persists across map changes.

### Dialogue
- interaction starts dialogue;
- options work;
- conditions work;
- effects modify state;
- leaving the interaction ends dialogue;
- fallback works.

### Persistence
- XP saves/loads;
- inventory saves/loads;
- level is recalculated.

### Network failure
- GitHub unavailable;
- previous local content remains intact;
- application remains usable.

## Release checklist

- replace prototype application name;
- configure real Android package identifier;
- configure signing;
- enable/test Android Internet if online sync remains;
- pin/version content source;
- validate downloaded content before activation;
- add parser/validator tests;
- remove absolute local paths;
- verify release builds.
