# ZeMobida — Deep Audit

**Repository:** `https://github.com/aik3n/ZeMobida`  
**Commit:** `12ea5386c03d53dd51dae26fd172775e281544f8`

## Executive summary

The project has a coherent prototype architecture, especially the separation between `Game`, persistent `Player`, `DialogueManager` and `DialogueUI`.

It is not yet production-ready.

## Findings

### P0 — Android networking mismatch

`dialogue_updater.gd` performs HTTP requests to GitHub, while the Android export preset has:

```text
permissions/internet=false
```

**Recommendation:** enable Internet and test on device, or make synchronization optional with bundled offline content.

### P1 — Mutable remote content

The updater follows `main`, so an installed binary can change behavior without a rebuild.

**Recommendation:** pin a commit SHA, tag or versioned content release.

### P1 — Content activated without complete validation

Downloaded scripts should be parsed and validated before replacing the known-good local set.

**Recommendation:**

```text
download → parse all → validate all → activate
```

On failure, retain the previous version.

### P2 — Automatic dialogue cycles

The validator checks destination existence but not graph cycles.

Example:

```text
# A
> B

# B
> A
```

**Recommendation:** detect cycles in automatic transitions.

### P2 — No visible automated test/CI suite

Add unit tests for parser, validator, effects, XP, save/load and dialogue resolution, then a headless smoke test.

### P2 — Prototype metadata

`project.godot` contains prototype values such as `config/name="test"` and a machine-specific absolute video path. The Android package identifier is still a placeholder.

### P3 — Duplicated XP thresholds

XP/level configuration is duplicated and could diverge.

## Security/integrity

No obvious secrets were identified in the reviewed project files. The principal concern is trust in mutable remote content rather than executable code.

## Recommended roadmap

### Phase 1
- fix Android networking/offline fallback;
- clean release metadata;
- remove absolute paths.

### Phase 2
- pin content;
- validate content before activation;
- detect automatic cycles;
- version save/content schemas.

### Phase 3
- automated tests;
- CI;
- release smoke tests.

### Phase 4
- responsive UI;
- platform controls;
- release/signing/versioning.

## Overall assessment

**Maturity:** functional prototype with a solid foundation, not production-ready.

The best next step is to improve deterministic content delivery and automated validation rather than perform a large refactor.
