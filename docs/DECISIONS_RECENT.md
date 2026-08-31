# ZeMobida — Recent Architecture Decisions

Este archivo complementa temporalmente `DECISIONS.md` con las decisiones aceptadas después de ADR-024. Se mantiene separado para no reescribir el histórico durante esta actualización documental.

## ADR-025 — Una única tabla central de niveles

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

Los límites de XP estaban duplicados entre cálculo de Player y presentación de UI.

### Decision

`res://scripts/niveles.gd` es la única fuente de verdad para los límites de nivel.

Niveles actuales:

```text
a1 → 70
a2 → 120
b1 → 340
b2 → 410
c1 → 740
c2 → 2000
```

El nivel se deriva siempre de XP.

### Consequences

Añadir/modificar un nivel requiere cambiar una sola tabla. HUD y Player consultan la misma fuente.

---

## ADR-026 — La identidad técnica del PNJ es el nombre del nodo

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

Mantener una propiedad `nombre` separada del nombre de la instancia duplicaba información.

### Decision

El nombre del nodo de la instancia es la identidad técnica.

Convención:

```text
minúsculas + guiones bajos
pedro_luis
```

La presentación sustituye `_` por espacios cuando necesita un nombre visible.

Los nombres de guion se construyen a partir de mapa + PNJ + nivel; no se intenta reconstruir esos componentes separando un filename.

### Consequences

Renombrar el nodo cambia deliberadamente identidad, diálogo asociado y cualquier estado cuya clave dependa del PNJ.

---

## ADR-027 — Sprite del PNJ configurable desde Inspector con reflejo `@tool`

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

Editar directamente `Sprite2D.texture` en una instancia requería habilitar `Editable Children`, exponiendo también colisiones y otros nodos internos.

### Decision

`pnj.gd` expone:

```gdscript
@export var sprite: Texture2D
```

El creador del mapa selecciona manualmente la textura desde el Inspector.

El script usa `@tool` para reflejar esa textura en el `Sprite2D` interno durante la edición. `@tool` no decide qué recurso usar y la lógica de gameplay queda excluida del editor mediante `Engine.is_editor_hint()`.

### Consequences

Se conserva la ergonomía del Inspector y se evita abrir todos los hijos internos de la escena PNJ.

---

## ADR-028 — La navegación de regreso a mapas pertenece a `Game`

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

Todos los mapas necesitan una forma común de volver al selector. Implementarla dentro de cada mapa duplicaría lógica y UI.

### Decision

El panel global `ESTADO` de `Game` contiene `VOLVER A MAPAS`.

Al activarlo:

- se bloquea la salida si el editor de guiones está abierto;
- se termina un diálogo activo;
- se carga `bienvenida.tscn` en `SceneContainer`.

### Consequences

Ningún mapa necesita implementar navegación propia.

---

## ADR-029 — Recordar la última posición del Player por mapa

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

En mapas grandes, volver siempre a `SpawnPlayer` penaliza la exploración.

### Decision

`SpawnPlayer` se usa sólo cuando no existe una posición previa válida para ese mapa.

Al abandonar un mapa se guarda la última posición del Player en:

```ini
[map_positions]
<id_mapa>=Vector2(...)
```

dentro de `user://settings.cfg`.

También se intenta guardar en cierre normal de aplicación y al pasar a segundo plano.

Al restaurar posición se sincroniza igualmente `player_actual.destino`.

### Consequences

Cada mapa recuerda de forma independiente dónde quedó el jugador sin introducir checkpoints ni un sistema de respawn más complejo.

El Stop del editor de Godot puede finalizar el proceso externamente y no se considera una ruta de guardado garantizada.
