# ZeMobida — Architecture Decision Records

This document records architectural decisions with long-term consequences.

- Current implementation → `ARCHITECTURE.md`
- Development process → `DEVELOPMENT.md`
- Dialogue syntax → `DIALOGUE_FORMAT.md`
- Risks → `AUDIT.md`
- Rationale/history → this document

**Audited revision:** `12ea5386c03d53dd51dae26fd172775e281544f8`

---

## ADR-001 — Persistent Player owned by Game

**Status:** Accepted

`Game` owns a single persistent `Player`. Maps provide `SpawnPlayer` nodes used to reposition it. This preserves player state across map transitions.

---

## ADR-002 — Game is the map and global UI orchestrator

**Status:** Accepted

`Game` coordinates map loading, Player lifecycle/spawn, camera limits and global HUD/status UI. Gameplay-specific rules remain in their owning components.

---

## ADR-003 — Dialogue content is externalized into text files

**Status:** Accepted

Dialogue is stored as UTF-8 `.txt` files under `guiones/` and parsed at runtime. This keeps content editable independently of gameplay code.

---

## ADR-004 — Dialogue execution is separated from presentation

**Status:** Accepted

`DialogueManager` owns dialogue execution/state. `DialogueUI` owns presentation and user interaction.

---

## ADR-005 — DialogueManager owns dialogue runtime state

**Status:** Accepted

`DialogueManager` owns active dialogue, nodes, conditions, jumps, options and effects and is registered as an autoload. Inventory and persistence are currently coupled to it.

---

## ADR-006 — Dialogue uses a lightweight custom text format

**Status:** Accepted

The project uses labels, text, numbered options, destinations, conditions, jumps and effects. The syntax is documented independently in `DIALOGUE_FORMAT.md`.

---

## ADR-007 — Player level is derived from XP

**Status:** Accepted

XP is authoritative. Level is derived from XP thresholds and recalculated after loading rather than persisted independently.

---

## ADR-008 — Inventory is gameplay state

**Status:** Accepted

Inventory is runtime state and can be modified by dialogue effects. Item identifiers are normalized to lowercase.

---

## ADR-009 — Dialogue content can be synchronized from GitHub

**Status:** Accepted

`DialogueUpdater` retrieves `.txt` content through the GitHub Contents API and stores it under `user://dialogues/`.

This records current architecture, not production readiness. Integrity/versioning risks are tracked in `AUDIT.md`.

---

## ADR-010 — NPC dialogue resolution uses map, NPC and Player level

**Status:** Accepted

Resolution order:

```text
<map>_<npc>_<level>.txt
        ↓
<map>_<npc>.txt
        ↓
generico.txt
```

---

## ADR-011 — Save data uses a simple human-readable text format

**Status:** Accepted

Current persistence uses `user://save/status.txt` with fields such as `xp=<integer>` and `inventory=<comma-separated-items>`.

Before major schema evolution, explicit save versioning should be introduced.

---

## ADR-012 — Architectural changes should be incremental

**Status:** Accepted

Prefer small changes that preserve existing responsibilities. Significant changes should be proposed, implemented minimally, tested, documented and committed.

---

# Decision lifecycle

Allowed states:

- Proposed
- Accepted
- Deprecated
- Superseded
- Rejected

When an accepted decision changes, create a new ADR referencing the previous one rather than silently rewriting history.

# What does not belong here

Do not use ADRs for ordinary implementation details, TODOs, bug lists, release notes or dialogue syntax.

# Source of truth

The repository implementation remains the ultimate source of truth. When documentation and implementation disagree, verify the implementation, determine which side is stale, and update the appropriate document.
