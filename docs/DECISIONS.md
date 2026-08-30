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

Los guiones se sincronizan desde el repositorio independiente `aik3n/ZeMobida_guiones` hacia `user://dialogues/`.

## ADR-010 — NPC dialogue resolution uses map, NPC and Player level
**Status:** Accepted

```text
<mapa>_<npc>_<nivel>.txt
<mapa>_<npc>.txt
generico.txt
```

## ADR-011 — Save data uses a simple human-readable text format
**Status:** Superseded by ADR-016

El estado se guardaba originalmente en `user://save/status.txt`. La decisión fue reemplazada al consolidar la persistencia local en `user://settings.cfg`.

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
**Status:** Superseded by ADR-018

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


## ADR-015 — Dynamic map selection in the welcome screen
**Status:** Accepted

### Context

La selección original de mapas estaba acoplada a un único botón para `aldea`. El juego debe poder incorporar nuevos mapas sin modificar la lógica del selector.

No se contempla un sistema de bloqueo/desbloqueo: todos los mapas disponibles son jugables.

### Decision

- La selección se implementa como `res://escenas/carrusel_mapas.tscn`.
- `bienvenida.tscn` instancia el carrusel.
- El carrusel descubre automáticamente los `.tscn` directamente contenidos en `res://mapas/`.
- Todos los mapas descubiertos están disponibles.
- El nombre mostrado se obtiene del nombre del archivo, eliminando `.tscn` y sustituyendo `_` por espacios.
- La imagen de presentación es opcional y se obtiene de un nodo `Preview` dentro de la escena del mapa, si es `Sprite2D` o `TextureRect` con textura.
- El último mapa se guarda al pulsar `JUGAR` como ruta de escena en `user://settings.cfg`.
- Al iniciar, se recupera ese mapa si sigue existiendo; si no, se selecciona el primero disponible.
- `Game` sigue siendo responsable de cargar la escena; el carrusel sólo comunica la ruta seleccionada.

### Consequences

Añadir un mapa consiste en incorporar su `.tscn` a `res://mapas/`, sin modificar la lógica del selector.

El orden del carrusel puede cambiar cuando se incorporan mapas. Por ello se persiste la ruta, no el índice.

No existe metadata adicional obligatoria para que un mapa sea seleccionable.

### Verification

La implementación fue validada manualmente en runtime en Godot.


## ADR-016 — Consolidate local settings and player state in one ConfigFile
**Status:** Accepted

### Context

El proyecto utilizaba `user://settings.cfg` para preferencias del actualizador de guiones y el último mapa, mientras que XP e inventario se almacenaban aparte en `user://save/status.txt`. Esto obligaba a mantener dos formatos y dos mecanismos de persistencia locales.

### Decision

Se utiliza un único archivo `user://settings.cfg` para configuración y estado persistente. Las secciones son:

- `[dialogues]`: actualización automática de guiones.
- `[maps]`: último mapa jugado.
- `[player]`: XP e inventario.

El manifest `user://dialogues_manifest.json` permanece separado porque es metadato de sincronización de contenido.

No se implementa migración ni compatibilidad con `user://save/status.txt`; el formato antiguo queda fuera de la especificación vigente.

### Consequences

Se elimina el formato de guardado específico de XP/inventario y se reduce la duplicación de código de lectura/escritura de estado. El archivo sigue siendo legible y editable con las herramientas de Godot. La persistencia continúa separando responsabilidades por sección, aunque comparta soporte físico.

## ADR-017 — Nueva sintaxis simplificada para los guiones
**Status:** Accepted

### Context

El formato anterior utilizaba opciones numeradas y una sintaxis que mezclaba varios conceptos en una misma línea. Se aprobó una sintaxis más sencilla basada en el primer carácter de cada línea, manteniendo los guiones como texto plano UTF-8 fácil de editar y versionar.

### Decision

La nueva sintaxis utiliza:

```text
texto → texto del PNJ
#     → nodo
?     → condición
>     → salto
=     → opción
[ ]   → efectos
'     → comentario
```

Las condiciones consecutivas de una línea se combinan con AND. Un salto sin condiciones es incondicional. `RANDOM` selecciona un nodo distinto del actual. Una opción sin salto tiene destino `null`. Los efectos pueden asociarse a la transición de una opción o al texto mostrado por un nodo. Sin una condición, salto u opción que cambie explícitamente el destino, el nodo actual permanece activo; no existe avance automático al siguiente nodo físico. Las etiquetas de nodo se comparan sin distinguir mayúsculas/minúsculas.

Las opciones se presentan al jugador en orden aleatorio; su orden en el archivo no tiene significado para la presentación.

### Consequences

El parser, validador y runtime se adaptan a esta sintaxis. Los guiones se mantienen fuera del repositorio principal, en el repositorio dedicado. La validación avanzada de errores se mantiene como responsabilidad del validador y no se incorpora complejidad adicional al formato.


## ADR-018 — Separar los guiones del repositorio principal
**Status:** Accepted

### Context

Los `.txt` de diálogo se mantenían dentro del mismo repositorio que el proyecto Godot, aunque el runtime ya los trataba como contenido remoto sincronizable y utilizaba `user://dialogues/` como caché local.

Mantener una copia de los guiones en el repositorio principal y otra fuente remota crea dos posibles fuentes de verdad.

### Decision

Los guiones se versionan exclusivamente en el repositorio:

```text
aik3n/ZeMobida_guiones
```

Los archivos `.txt` están directamente en la raíz de ese repositorio.

`DialogueUpdater` consulta la rama `main` de ese repositorio mediante la API Contents de GitHub, descarga sólo los `.txt` necesarios y sustituye `user://dialogues/` únicamente cuando la transferencia completa termina correctamente. No valida la sintaxis de los guiones; esa responsabilidad pertenece a `DialogueManager` al iniciar cada diálogo.

El repositorio principal `aik3n/ZeMobida` no contiene una carpeta `guiones/` ni una copia empaquetada de esos archivos.

### Consequences

Existe una única fuente de verdad para el contenido narrativo.

El mecanismo local permanece sin cambios:

```text
aik3n/ZeMobida_guiones
        ↓
user://dialogues/
        ↓
runtime
```

`user://dialogues_manifest.json` sigue siendo metadato local de sincronización y `user://settings.cfg` mantiene la preferencia de actualización.


## ADR-019 — Mapas ilustrados top-down como modelo visual principal
**Status:** Accepted

### Context

Los mapas necesitan libertad artística y deben ser sencillos de producir por un equipo de arte. Construir todas las localizaciones mediante tiles limitaría la composición visual y obligaría a mantener un tileset como parte central del flujo de producción.

### Decision

Los mapas principales se diseñan como ilustraciones completas en perspectiva **top-down**.

El contrato visual objetivo es:

```text
Fondo
Colisiones
actores dinámicos
Frontal opcional
SpawnPlayer
Preview opcional
```

`Fondo` es un `Sprite2D` a escala `1:1`; un píxel de la ilustración corresponde a una unidad de mundo. Para facilitar coordenadas y colocación, el fondo se usa con `centered = false`.

Cuando existe un nodo raíz llamado `Fondo` con textura, `Game` obtiene de él los límites de `Camera2D`. Los mapas antiguos pueden seguir usando `CameraBounds` como fallback.

`Preview` es independiente de `Fondo`: el carrusel puede utilizar una miniatura específica sin cargar la imagen completa del mundo.

Las colisiones y una posible capa `Frontal` se añaden en Godot encima de la ilustración según las necesidades jugables. No se impone `TileMap`.

### Consequences

El equipo de arte puede crear escenarios de cualquier tamaño o proporción sin adaptar el dibujo al viewport del teléfono.

La escala visual del personaje, caminos, puertas y edificios debe fijarse a partir de un mapa piloto antes de producir muchas localizaciones.

La primera prueba de este modelo utiliza `res://art/mapas/aldea.PNG`.

### Verification

El fondo real de `aldea` a escala `1:1` y los límites automáticos de cámara fueron validados manualmente en runtime el 2026-08-30.


## ADR-020 — Tap para mover y arrastre para explorar
**Status:** Accepted

### Context

En móvil, un toque sobre el mapa puede expresar dos intenciones distintas: ordenar al personaje que camine a un punto o desplazar la vista para inspeccionar una zona.

Mover al Player inmediatamente al presionar impide distinguir ambas acciones.

### Decision

El gesto se interpreta al soltar:

- toque sin superar el umbral → mover Player al punto de mundo tocado;
- arrastre de al menos `28 px` → desplazar la cámara y no mover Player;
- al terminar un arrastre → mantener la cámara en la posición explorada;
- nuevo tap → calcular el destino con la cámara desplazada y recentrar después;
- recentrado → `Tween` cúbico `EASE_OUT` de `0.8 s`;
- teclado/mando → volver inmediatamente al seguimiento normal.

Mientras se determina si el gesto es tap o arrastre, el Player permanece quieto.

El desplazamiento manual de cámara se limita a los límites activos del mapa.

### Consequences

Explorar el escenario no provoca movimientos accidentales y el jugador puede observar zonas alejadas antes de decidir adónde caminar.

El recentrado suave evita el salto visual que producía volver instantáneamente a `Camera2D.position = Vector2.ZERO`.

Los eventos equivalentes de ratón se mantienen para pruebas de escritorio.

### Verification

El flujo tap/arrastre, permanencia de cámara, cálculo de destino con cámara desplazada y recentrado suave fueron validados manualmente en runtime el 2026-08-30.



## ADR-021 — Capa Frontal como imagen transparente opcional
**Status:** Accepted

### Context

En un mapa top-down algunos elementos deben dibujarse por encima del Player y los PNJ para transmitir profundidad: tejados, copas de árboles, arcos, toldos, etc.

Se probó reutilizar partes del propio `Fondo` mediante `Polygon2D` y coordenadas UV. Aunque técnicamente funciona, convertirlo en una herramienta cómoda requiere lógica adicional de editor y sincronización de UV.

### Decision

Se adopta una solución explícita y simple: cada mapa puede proporcionar una imagen PNG `Frontal` con transparencia.

```text
Fondo      z bajo
Player/PNJ z medio
Frontal    z alto
```

`Fondo` y `Frontal` comparten origen `(0,0)`, escala `1:1` y `centered = false`.

`Frontal` está siempre visible; las zonas transparentes no afectan al dibujo y las zonas opacas ocultan naturalmente a los actores cuando pasan por detrás.

No se requiere detección de entrada/salida ni recorte dinámico en runtime.

### Consequences

El equipo de arte mantiene una segunda capa sólo en los mapas que la necesiten. A cambio, la implementación en Godot permanece trivial, predecible y sin herramientas personalizadas.

### Verification

El concepto fue probado manualmente en runtime el 2026-08-30 y se confirmó el solapamiento correcto sobre el Player.


## ADR-022 — Zoom temporal como parte de la exploración de cámara
**Status:** Accepted

### Context

Los mapas ilustrados pueden ser mayores que el viewport. Además del paneo, resulta útil poder modificar temporalmente cuánto terreno se ve sin convertir el zoom en un estado permanente de gameplay.

### Decision

La cámara permite zoom de exploración:

```text
mínimo: 0.7
normal: 1.0
máximo: 1.4
```

Controles:

- pinch de dos dedos en móvil;
- rueda del ratón en escritorio.

Durante pinch no se ordena movimiento al Player. Al terminar el gesto se evita que el dedo restante genere un tap accidental.

Mientras se explora, posición y zoom se conservan.

Un nuevo tap para mover restaura simultáneamente:

```text
camera.position → Vector2.ZERO
camera.zoom     → Vector2.ONE
```

mediante un Tween paralelo `TRANS_CUBIC / EASE_OUT` de `0.8 s`.

Teclado o mando restauran posición y zoom inmediatamente.

### Consequences

El zoom funciona como herramienta temporal de observación y no altera permanentemente la presentación normal del juego.

El clamp de cámara debe considerar el zoom actual para impedir mostrar terreno fuera de los límites del mapa.

### Verification

Rueda/pinch, conservación del estado de exploración y restauración conjunta de posición y zoom fueron validados manualmente en runtime el 2026-08-30.


## ADR-023 — Feedback flotante inmediato para cambios de XP e inventario
**Status:** Accepted

### Context

Los efectos de diálogo ya podían modificar XP e inventario, pero el jugador sólo veía el resultado al consultar HUD o Estado. La acción narrativa y su consecuencia jugable quedaban visualmente desacopladas.

### Decision

Los cambios reales de XP y objetos generan mensajes flotantes asociados al Player.

```text
ganancia → verde → movimiento hacia arriba
pérdida  → rojo  → movimiento hacia abajo
```

Sólo se genera feedback cuando el estado cambia realmente.

Los mensajes viven en `CanvasLayer 15`, por encima del diálogo (`10`) y por debajo de Estado (`20`), y el origen visual del layer sigue la posición del Player.

Se mantienen dos colas independientes:

- positivos;
- negativos.

Cada cola lanza mensajes con un intervalo de `0.25 s`. Los dos canales pueden ejecutarse simultáneamente. Cada mensaje tiene su propio `Label` y `Tween`, dura aproximadamente `1.2 s` y se elimina al terminar.

Los negativos comienzan ligeramente más abajo que los positivos para separar visualmente ambos sentidos.

### Consequences

El jugador percibe inmediatamente las consecuencias de una opción de diálogo sin abrir otra pantalla.

La separación entre canales permite representar simultáneamente ganancias y pérdidas sin introducir un sistema complejo de notificaciones.

La carga inicial de estado persistido no se trata como una ganancia o pérdida y no produce feedback.

### Verification

XP positiva/negativa, objetos añadidos/eliminados, ausencia de feedback sin cambio real, solapamiento de mensajes y colas positiva/negativa independientes fueron validados manualmente en runtime el 2026-08-30.

