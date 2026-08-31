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

---

## ADR-030 — Enviar guiones mediante correo local después de guardarlos

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

Se quiere permitir que el jugador envíe un guion creado o modificado para su revisión sin introducir cuentas de usuario, servidor, SMTP ni credenciales dentro de ZeMobida.

Además, enviar una versión no guardada podría crear confusión si después se cierra el editor y el contenido enviado no coincide con el archivo local.

### Decision

El editor muestra:

```text
GUARDAR | ENVIAR | CERRAR
```

`ENVIAR` reutiliza exactamente la misma lógica de escritura que `GUARDAR` y sigue este orden:

1. guardar el contenido actual en `user://custom_dialogues/<archivo>`;
2. si el guardado falla, abortar;
3. si funciona, abrir una URI `mailto:` mediante `OS.shell_open()`;
4. mantener abierto el editor.

El correo se prepara con:

```text
Para:   zemobida@gmail.com
Asunto: ZeMobida - <nombre_archivo>
Cuerpo: nombre del archivo + contenido exacto guardado
```

No se adjunta automáticamente el `.txt`. No se almacenan credenciales de la cuenta receptora ni se envía correo directamente desde el juego. El usuario conserva la confirmación final en su aplicación de correo.

### Consequences

La versión que se intenta enviar siempre existe ya como copia local. Cancelar el correo no pierde esa edición.

El mecanismo depende de que el sistema disponga de una aplicación capaz de manejar `mailto:`. Si no puede abrirla, el guion permanece guardado y sólo falla la apertura del correo.

### Verification

Se validó manualmente que `ENVIAR` guarda el contenido antes de abrir el cliente de correo y que el texto permanece guardado incluso si se cancela el envío.

---

## ADR-031 — Mantener los mapas dentro del proyecto principal

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

Se probó la separación de mapas en proyectos Godot independientes cargados
como resource packs PCK y ZIP.

Aunque la carga funciona, todos los paquetes comparten el espacio virtual
`res://`. Dos autores independientes pueden exportar recursos con las mismas
rutas internas y provocar sustituciones o colisiones sin saberlo.

Garantizar aislamiento exigiría imponer namespaces a los diseñadores o
introducir reescritura/carga especial de recursos.

### Decision

Durante la fase de prototipo, ZeMobida utiliza exclusivamente los mapas
integrados directamente en:

```text
res://mapas/
```

Se elimina del runtime el experimento de carga externa PCK/ZIP.

### Consequences

El sistema de mapas vuelve al modelo simple y ya validado.

La investigación se conserva en `MAP_PACKS_FUTURE.md` como experimento
cerrado, pero los mapas externos no forman parte de la arquitectura prevista
ni del backlog activo.
