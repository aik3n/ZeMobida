# ZeMobida — Architecture

**Estado:** implementación funcional revisada hasta el 2026-08-30. La maquetación, el mapa piloto ilustrado y el control de cámara fueron validados manualmente en runtime.  
**Godot:** 4.7.

## Modelo

```text
Game
├── Player persistente
│   ├── Camera2D
│   └── FeedbackLayer     CanvasLayer 15
├── UI global
│   ├── HUD               CanvasLayer 5
│   └── Estado            CanvasLayer 20
├── DialogueUI            CanvasLayer 10
└── mapa actual
    ├── Fondo             Sprite2D, opcional pero preferido
    ├── Colisiones        StaticBody2D + shapes/polígonos
    ├── PNJ
    ├── SpawnPlayer
    ├── Frontal           Sprite2D transparente, opcional
    ├── Preview           opcional, independiente del Fondo
    └── CameraBounds      fallback sólo para mapas sin Fondo

DialogueManager (autoload)
├── parser
├── validator
├── runtime de diálogo
├── inventario
└── persistencia

DialogueUpdater (autoload)
└── GitHub → user://dialogues/
```

`Game` coordina mapas, Player y UI global. `DialogueManager` ejecuta diálogos y actualmente también gestiona inventario y persistencia.


Al cargar un mapa, `Game` coloca el Player en `SpawnPlayer` y sincroniza también su destino de movimiento con esa misma posición. Esto evita que el Player persistente intente regresar al destino conservado del mapa o posición anterior.

## Contenido

- `aik3n/ZeMobida_guiones`: repositorio independiente que contiene los `.txt` de diálogo en su raíz.
- `user://dialogues/`: caché local utilizada por el runtime.

El repositorio de guiones en GitHub es la fuente de verdad del contenido. El repositorio principal no contiene una copia de los `.txt`. La caché local permite continuar jugando cuando GitHub no está disponible.

## Sincronización

La opción de usuario es:

```text
Actualizar guiones al iniciar: Sí / No
```

Con `Sí`, antes de permitir entrar al mapa se consulta GitHub, se obtiene el `sha` de cada archivo y se compara con el manifest local. Sólo se descargan archivos nuevos o modificados.

Los cambios se descargan temporalmente y se comprueba que el conjunto de `.txt` descargado coincide con el conjunto remoto antes de activar la nueva colección. El updater no valida el contenido de los guiones. Si hay error o timeout, se conserva la caché anterior.

El timeout global es configurable y vale `30.0` segundos por defecto.

Con `No`, no se consulta GitHub y se utiliza la caché local.

## Manifest

El manifest representa los SHA de la colección realmente activa. Esto permite conservar archivos sin cambios, descargar sólo cambios y detectar archivos nuevos o eliminados.

## Resolución

```text
<mapa>_<npc>_<nivel>.txt
        ↓
<mapa>_<npc>.txt
        ↓
generico.txt
```

## Persistencia

La configuración y el estado persistente del jugador se almacenan en un único archivo Godot `ConfigFile`:

```text
user://settings.cfg
```

Las secciones tienen responsabilidades separadas:

```text
[dialogues]  → preferencia de actualización de guiones
[maps]       → último mapa jugado
[player]     → XP e inventario
```

`DialogueManager` mantiene la persistencia de XP e inventario, pero comparte el archivo con las preferencias del updater y el último mapa. El manifest de guiones sigue siendo un archivo independiente porque representa metadatos de sincronización, no configuración ni estado de partida.


## Modelo visual de mapas top-down

La dirección visual aprobada para los mapas es **top-down con ilustración completa de fondo**, no un `TileMap` obligatorio.

El contrato artístico objetivo es:

```text
mapa
├── Fondo
├── Colisiones
├── actores dinámicos
├── Frontal            opcional
├── SpawnPlayer
└── Preview            opcional
```

`Fondo` es un `Sprite2D` que contiene la ilustración principal. Para el mapa piloto `aldea` se utiliza:

```text
res://art/mapas/aldea.PNG
```

La imagen se utiliza a escala `1:1`: un píxel de la ilustración corresponde a una unidad de mundo. El `Sprite2D` se configura con `centered = false`, por lo que la esquina superior izquierda del dibujo coincide con el origen visual del mapa.

El tamaño del mapa es independiente del viewport `1080 × 1920`. La cámara muestra sólo una región del mundo.

### Límites de cámara

`Game` intenta primero obtener los límites de cámara a partir de un nodo `Sprite2D` llamado `Fondo`.

Si existe y tiene textura, se utiliza su rectángulo transformado como límites de `Camera2D`. Esto permite que el tamaño de la ilustración defina automáticamente el área explorable visualmente.

Los mapas que todavía no tengan `Fondo` conservan el contrato anterior:

```text
CameraBounds
└── CollisionShape2D
    └── RectangleShape2D
```

`CameraBounds` es por tanto un mecanismo de compatibilidad para los mapas existentes, no un requisito de los nuevos mapas ilustrados.

`aldea` ya usa `Fondo` como fuente de límites y no necesita `CameraBounds`.

### Preview

`Preview` y `Fondo` tienen responsabilidades distintas:

- `Fondo`: imagen recorrida por el jugador;
- `Preview`: imagen mostrada en el carrusel.

El carrusel no necesita cargar la ilustración completa como preview.

### Colisiones y capa frontal

Las colisiones se construyen en Godot sobre la ilustración mediante `StaticBody2D` y `CollisionShape2D` / `CollisionPolygon2D`. Deben representar el espacio realmente transitable, especialmente la zona de los pies del personaje, sin reproducir necesariamente el contorno exacto de cada elemento dibujado.

`Frontal` es una imagen PNG transparente opcional alineada con `Fondo`. Ambas comparten origen, escala y tamaño de referencia:

```text
Fondo      z bajo
Player/PNJ z medio
Frontal    z alto
```

`Frontal` sólo contiene los elementos que deben ocultar a los actores al pasar por detrás: copas de árboles, tejados, arcos, toldos, etc.

No requiere detección de entrada/salida, recortes dinámicos ni UV generados en runtime. El experimento con `Polygon2D` fue descartado a favor de esta solución más simple.


## Control táctil y exploración de cámara

El control móvil distingue entre intención de movimiento e intención de exploración.

```text
tocar y soltar       → mover Player al punto tocado
arrastrar            → desplazar la cámara
pinch de dos dedos   → zoom en móvil
rueda del ratón      → zoom en escritorio
soltar exploración   → mantener posición y zoom
nuevo tap            → mover Player y restaurar cámara suavemente
teclado/mando        → restaurar cámara estándar inmediatamente
```

El movimiento por tap comienza **al soltar**, no al presionar. Mientras se decide si el gesto es un tap o un arrastre, el Player permanece quieto.

El umbral actual para considerar el gesto un arrastre es:

```text
28 px
```

Durante un arrastre la cámara se desplaza en sentido inverso al movimiento de la propia cámara para que el contenido visual siga al dedo. El desplazamiento se limita a los límites activos del mapa.

El zoom de exploración está limitado actualmente al intervalo `0.7 … 1.4`. Durante un pinch no se ordena movimiento al Player; al terminar, el dedo que pueda quedar apoyado se ignora hasta que todos los dedos se hayan soltado para evitar taps accidentales.

Después de explorar, un nuevo tap calcula primero la posición de mundo correspondiente al punto tocado y después restaura simultáneamente:

```text
camera.position → Vector2.ZERO
camera.zoom     → Vector2.ONE
```

El recentrado usa un `Tween` paralelo, cúbico `EASE_OUT`, de:

```text
0.8 s
```

Así posición y zoom vuelven juntos sin un salto brusco.


## Feedback inmediato de cambios del Player

Los cambios de XP e inventario producen feedback flotante asociado visualmente al Player.

```text
ganancia → verde → sube
pérdida  → rojo  → baja
```

El feedback se muestra sólo cuando el estado cambia realmente. Por ejemplo:

- añadir un objeto ya existente no muestra mensaje;
- quitar un objeto inexistente no muestra mensaje;
- una variación de XP limitada por mínimo/máximo muestra únicamente la variación real;
- cargar XP e inventario desde persistencia no genera mensajes.

El texto usa un `CanvasLayer 15`: queda por encima de `DialogueUI` (`10`) y por debajo de `EstadoUI` (`20`). El origen del layer sigue cada frame la posición visual del Player, por lo que el mensaje permanece asociado al personaje aunque la cámara tenga paneo o zoom.

Ganancias y pérdidas utilizan canales independientes. Cada canal conserva su propio orden, con una separación actual de `0.25 s` entre mensajes, pero un mensaje positivo y uno negativo pueden comenzar simultáneamente.

Cada mensaje dura aproximadamente `1.2 s` y utiliza un `Label` temporal independiente que se elimina al terminar su `Tween`. No existe un gestor complejo de notificaciones ni pooling.


## Pendientes conocidos

- fijar una referencia remota inmutable en lugar de `main`;
- ampliar validación semántica;
- detectar ciclos automáticos;
- añadir tests automatizados;
- reducir acoplamiento al `SceneTree`;
- centralizar tablas de niveles.


## Selección dinámica de mapas

La selección de mapas está integrada en `bienvenida.tscn` mediante una instancia de:

```text
escenas/carrusel_mapas.tscn
```

El carrusel descubre automáticamente las escenas `.tscn` directamente dentro de:

```text
res://mapas/
```

No existe una lista manual de mapas ni un sistema de bloqueo/desbloqueo. Todos los mapas descubiertos están disponibles para jugar.

Para cada escena:

```text
aldea_ibon.tscn → aldea ibon
```

El nombre mostrado se obtiene eliminando `.tscn` y sustituyendo `_` por espacios. La ruta de la escena es la referencia interna del mapa.

### Preview opcional

Una escena de mapa puede incluir un nodo llamado `Preview`. Si es `Sprite2D` o `TextureRect` y tiene una textura, el carrusel utiliza esa textura como imagen de presentación.

La ausencia de `Preview` no impide seleccionar ni jugar el mapa.

### Último mapa jugado

El carrusel guarda la ruta del mapa cuando el jugador pulsa `JUGAR` y la conserva en `user://settings.cfg`.

Al iniciar la bienvenida:

- si el último mapa todavía existe, queda seleccionado;
- si ya no existe, se selecciona el primer mapa disponible.

No se guarda el índice del carrusel, porque el orden puede cambiar cuando se añaden mapas.

`Game` sigue siendo responsable de cargar la escena. El carrusel sólo comunica la ruta del mapa seleccionado.
