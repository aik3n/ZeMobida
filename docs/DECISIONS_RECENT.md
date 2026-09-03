# ZeMobida — Recent Architecture Decisions

> **Nota de vigencia (2026-09-03):** este documento conserva contexto histórico.  
> Para el comportamiento actual consultar `ARCHITECTURE.md`, `DEVELOPMENT.md`, `GUIONES.md` y `DIALOGUE_FORMAT.md`.  
> Las decisiones antiguas sobre progresión del Player, variantes de guion por nivel y límites alternativos de cámara quedaron supersedidas.


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

---

## ADR-032 — Limitar cadenas automáticas de diálogo en runtime

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

Un guion puede ser sintáctica y estructuralmente válido y, aun así, formar un ciclo de saltos automáticos que nunca devuelve el control al jugador.

Analizar todos los ciclos posibles en Validator añadiría complejidad y podría confundir ciclos interactivos legítimos con errores de ejecución.

### Decision

`DialogueManager.show_node()` recorre los saltos automáticos de forma iterativa y permite un máximo de `100` transiciones automáticas consecutivas por cadena.

Al superar el límite:

- se detiene la ejecución automática;
- se escribe un mensaje normal en Output;
- no se aplican efectos del nodo de contingencia;
- el diálogo permanece activo, sin opciones, con `EDITAR` disponible.

Una intervención del jugador inicia una nueva cadena y un nuevo conteo.

No se añade un validator previo del texto ni análisis estático de grafos.

### Consequences

Un guion accidental o malicioso no puede bloquear el runtime mediante una cadena automática infinita.

Los ciclos que dependen de elecciones del jugador siguen siendo posibles.

Quien esté probando el guion puede abrir inmediatamente el editor desde el propio panel detenido y corregir el archivo.

### Verification

Se validó manualmente con un ciclo automático entre dos nodos: el runtime alcanza el límite, se detiene, escribe el diagnóstico en Output y mantiene accesible `EDITAR`.

---

## ADR-033 — No introducir propiedad exclusiva del diálogo entre PNJ

**Status:** Accepted  
**Fecha:** 2026-08-31

### Context

Actualmente cualquier PNJ puede cerrar un diálogo activo cuando el Player sale de su `InteractionArea`, aunque otro PNJ haya iniciado ese diálogo.

Resolverlo exigiría registrar y comprobar explícitamente el PNJ propietario de cada diálogo.

### Decision

Se mantiene el comportamiento actual.

El ritmo del juego permite asumir un cierre accidental: el jugador puede volver a acercarse al PNJ deseado y reiniciar la conversación.

### Consequences

No se añade estado ni acoplamiento adicional al sistema de diálogo.

La decisión puede revisarse si los mapas reales demuestran que áreas solapadas o PNJ móviles provocan cierres frecuentes o confusos.

---

## ADR-034 — Persistir inmediatamente los efectos que cambian el estado

**Status:** Accepted  
**Fecha:** 2026-09-01

### Context

XP e inventario se guardaban al terminar un diálogo. Si la aplicación se cerraba después de aplicar una recompensa pero antes de alcanzar esa ruta de cierre, el efecto visible podía no quedar persistido.

Guardar tras cualquier intento de efecto introduciría escrituras innecesarias para operaciones que no cambian el estado, como añadir un objeto ya existente.

### Decision

`DialogueManager._apply_effects()` mantiene un indicador de cambio real.

Se considera cambio cuando:

- `add_item()` añade realmente un objeto;
- `remove_item()` retira realmente un objeto;
- `Player.add_xp()` produce una XP final distinta de la anterior.

Si al menos un efecto cambia el estado, se llama inmediatamente a `_save_player_status()`.

`end_dialogue()` deja de ser el mecanismo del que depende el guardado de recompensas.

### Consequences

Una recompensa aplicada queda persistida en el mismo flujo que la produjo.

Los efectos sin variación real no generan escrituras adicionales ni feedback falso.

---

## ADR-035 — El editor conserva el nivel con el que comenzó el diálogo

**Status:** Accepted  
**Fecha:** 2026-09-01

### Context

El nombre editable es `<mapa>_<pnj>_<nivel>.txt`.

Un diálogo puede conceder XP suficiente para cambiar de nivel antes de que el jugador pulse `EDITAR`. Recalcular el nivel en ese momento haría que el editor abriera un archivo distinto del contexto que originó la conversación.

### Decision

`DialogueManager.start_dialogue()` captura el nivel actual del Player en `current_dialogue_level`.

Mientras esa conversación permanece activa, `open_current_dialogue_editor()` utiliza ese nivel capturado para construir el nombre exacto del archivo.

El valor se limpia al terminar el diálogo.

### Consequences

`EDITAR` representa de forma estable el diálogo que se inició, aunque sus propios efectos cambien posteriormente XP o nivel.

No se crea una identidad adicional para la conversación ni se congela el nivel global del Player; sólo se conserva el contexto necesario para elegir el archivo editable.

---

## ADR-036 — Normalizar a minúsculas el ID técnico de mapa

**Status:** Accepted  
**Fecha:** 2026-09-01

### Context

El ID de mapa se deriva del nombre del archivo de escena. Una escena como `Arauzo_de_salce.tscn` conservaba la mayúscula inicial mientras la identidad de PNJ ya se normalizaba a minúsculas.

Esto hacía que nombres de guion y claves persistentes dependieran del case del filename y podía producir diferencias entre plataformas.

### Decision

El ID técnico de mapa es:

```text
scene_file_path.get_file().get_basename().to_lower()
```

La misma normalización se utiliza para:

- claves de `[map_positions]` en `Game`;
- resolución de diálogo desde `PNJ`;
- cálculo del archivo exacto del editor.

No se introduce una propiedad `map_id` separada y no es necesario renombrar físicamente las escenas existentes.

### Consequences

Un mismo mapa utiliza una identidad técnica coherente para persistencia y diálogo independientemente de diferencias de mayúsculas/minúsculas.

El cambio no migra automáticamente datos creados antes de `bb3f058`: una clave de posición o variante local de diálogo que conservara mayúsculas puede dejar de resolverse. Durante el prototipo se acepta esta compatibilidad limitada; si fuera necesario preservar esos datos, la migración deberá ser pequeña y explícita.
