# ZeMobida — Architecture Decision Records

Estados: Proposed, Accepted, Deprecated, Superseded, Rejected.

## ADR-001 — Persistent Player owned by Game
**Status:** Accepted

`Game` mantiene un único `Player` persistente.

## ADR-002 — Game is the map and global UI orchestrator
**Status:** Accepted

`Game` coordina mapas, Player, spawn, cámara y UI global.

## ADR-003 — Dialogue content is externalized into text files
**Status:** Accepted

Los diálogos se almacenan como `.txt` UTF-8.

## ADR-004 — Dialogue execution is separated from presentation
**Status:** Accepted

`DialogueManager` ejecuta el diálogo y `DialogueUI` lo presenta.

## ADR-005 — DialogueManager owns dialogue runtime state
**Status:** Accepted

`DialogueManager` es autoload y gestiona runtime de diálogo, condiciones, saltos y efectos.

## ADR-006 — Dialogue uses a lightweight custom text format
**Status:** Accepted

El proyecto utiliza nodos, texto, opciones, destinos, condiciones, saltos y efectos.

## ADR-007 — Player level is derived from XP
**Status:** Accepted

El nivel se deriva de XP.

## ADR-008 — Inventory is gameplay state
**Status:** Accepted

El inventario forma parte del estado del jugador y puede cambiar mediante diálogo.

## ADR-009 — Dialogue content can be synchronized from GitHub
**Status:** Accepted

`guiones/` puede sincronizarse desde GitHub hacia `user://dialogues/`.

## ADR-010 — NPC dialogue resolution uses map, NPC and Player level
**Status:** Accepted

```text
<mapa>_<npc>_<nivel>.txt
<mapa>_<npc>.txt
generico.txt
```

## ADR-011 — Save data uses a simple human-readable text format
**Status:** Accepted

El estado se guarda en `user://save/status.txt`.

## ADR-012 — Architectural changes should be incremental
**Status:** Accepted

Se prefieren cambios pequeños que preserven responsabilidades existentes.

## ADR-013 — Incremental dialogue synchronization with local fallback
**Status:** Accepted

### Context

Descargar todos los guiones en cada arranque es innecesario. GitHub proporciona un SHA por archivo y permite identificar cambios individualmente.

La actualización tampoco debe destruir una caché local válida ante errores.

### Decision

El sistema:
1. ofrece `Actualizar guiones al iniciar: Sí / No`;
2. con `Sí`, comprueba GitHub antes de entrar al mapa;
3. compara SHA remoto y manifest local;
4. descarga sólo archivos nuevos o modificados;
5. usa almacenamiento temporal;
6. valida antes de activar;
7. conserva la caché anterior ante error o timeout;
8. usa timeout global configurable, `30.0` segundos por defecto;
9. con `No`, no consulta GitHub y utiliza la caché local.

### Consequences

Se reducen descargas, se mantiene el último contenido válido y el arranque no queda bloqueado indefinidamente.

### Verification

La implementación fue probada en ejecución el 2026-08-29 y se confirmó su funcionamiento.

## ADR-014 — `guiones/` is repository content, not the runtime cache
**Status:** Accepted

### Context

`guiones/` contiene contenido versionado. El runtime utiliza `user://dialogues/`.

### Decision

La ruta actual es:

```text
GitHub guiones/
       ↓
user://dialogues/
       ↓
runtime
```

No se introduce una copia automática de `res://guiones/` como sustituto de la caché remota.

### Consequence

La documentación debe distinguir entre contenido versionado y caché runtime.
