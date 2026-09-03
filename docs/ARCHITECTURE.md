# ZeMobida — Architecture

**Estado:** arquitectura funcional revisada el 2026-09-03.  
**Godot:** 4.7.x.  
**Principio:** preferir soluciones pequeñas, explícitas y editables desde Godot antes que capas de abstracción innecesarias.

## Modelo general

```text
Game
├── SceneContainer
│   └── bienvenida o mapa actual
├── Player persistente
│   ├── Sprite2D
│   ├── CollisionShape2D
│   ├── Camera2D
│   └── FeedbackLayer          CanvasLayer 15
├── UI                         CanvasLayer 5
│   └── BotonEstado
├── EstadoUI                   CanvasLayer 20
│   └── Estado/Panel
│       ├── inventario
│       └── VolverMapas
└── Dialogo                    CanvasLayer 10

DialogueManager (autoload)
├── runtime de diálogo
├── parser
├── validator
├── resolución oficial/local
├── editor local
├── inventario
└── persistencia de inventario

DialogueUpdater (autoload)
└── GitHub → user://dialogues/
```

`Game` permanece vivo durante toda la sesión. Los mapas se cargan y descargan dentro de `SceneContainer`; el `Player` pertenece a `Game` y persiste entre mapas.

El Player no tiene progresión lingüística propia. El nivel lingüístico pertenece al mapa y se expresa en el nombre de su escena.

## Mapas

El carrusel descubre automáticamente escenas `.tscn` directamente en:

```text
res://mapas/
```

Para crear un mapa nuevo se parte de una escena válida existente y se duplica. No existe registro de mapas, base de datos ni recurso auxiliar obligatorio.

Estructura esperada para mapas nuevos:

```text
mapa
├── descripcion       Label
├── final             Label
├── Fondo             Sprite2D, opcional técnicamente
├── Preview           opcional
├── SpawnPlayer       opcional
├── PNJ...
├── colisiones...
└── objetos...
```

`descripcion` y `final` son texto humano del mapa. Sus nombres forman parte del contrato de contenido. No se utiliza metadata para esos textos ni un script en la raíz del mapa.

El nombre de la raíz no se utiliza como identidad técnica en runtime; las escenas nuevas usan `mapa` por uniformidad.

### Identidad, nivel y nombre lógico

El ID técnico del mapa es el basename de la escena normalizado a minúsculas:

```text
aldea_a1.tscn → aldea_a1
```

Ese ID completo se utiliza para persistencia de posición.

El nivel lingüístico se obtiene buscando en el nombre uno de estos marcadores:

```text
_a1  _a2  _b1  _b2  _c1  _c2
```

Si no aparece ninguno, el nivel del mapa es `?`.

Para los guiones se usa el nombre lógico anterior al marcador:

```text
aldea_a1.tscn
→ ID técnico: aldea_a1
→ nivel: A1
→ mapa lógico de guion: aldea
```

Un mapa sin marcador conserva como nombre lógico su basename completo.

### Entrada y posición persistente

La posición inicial del Player sigue esta prioridad:

```text
posición guardada
→ SpawnPlayer si existe
→ Vector2.ZERO
```

Antes de abandonar un mapa, y también ante cierre/pausa normal de la aplicación, `Game` guarda la última posición en:

```ini
[map_positions]
<id_mapa>=Vector2(...)
```

No se busca automáticamente una posición libre ni se corrigen colisiones de spawn.

### Fondo y cámara

Un mapa ilustrado terminado debe incluir `Fondo` con textura. Cuando existe, `Game` calcula los límites de `Camera2D` desde su rectángulo transformado.

Convención habitual:

```text
Fondo
→ Sprite2D
→ escala 1:1
→ centered = false
```

Un mapa sin `Fondo` se considera prototipo y sigue siendo jugable. En ese caso la cámara usa límites provisionales fijos alrededor del origen:

```text
X: -1000 .. +1000
Y: -1000 .. +1000
```

No existe un segundo nodo de límites para prototipos.

### Preview

La imagen del carrusel se resuelve por prioridad:

```text
Preview válido
→ Fondo válido
→ res://art/ui/preview_default.png
```

`Preview` permite usar una miniatura distinta de la ilustración jugable.

El carrusel reutiliza la escena instanciada para leer también el texto humano del mapa:

```text
sin __superado__ → descripcion
con __superado__ → final + sello
```

El sello usa `res://art/ui/seal.png`, se dibuja sobre el preview con rotación de `+35°` y no recibe transparencia adicional.

### Profundidad visual

No existe Y-sort global.

Player, PNJ y determinados objetos cambian de profundidad usando la posición Y de una colisión colocada en los pies/base.

Para objetos estáticos, `Game` registra automáticamente al cargar el mapa los nodos que cumplen:

```text
StaticBody2D
├── exactamente 1 CollisionShape2D directa
└── 1 o más Sprite2D directos
```

La `CollisionShape2D` representa la base visual del objeto. Los contenedores con varias colisiones o sin sprites se ignoran.

## Player

Existe una sola instancia persistente de `Player`.

Responsabilidades actuales:

```text
movimiento
orientación horizontal
cámara
tap / arrastre / pinch / rueda
feedback visual de cambios de inventario
```

El movimiento conserva aceleración y deceleración. La orientación horizontal usa `Sprite2D.flip_h`; el movimiento vertical mantiene la orientación previa.

La cámara permite exploración manual y vuelve al Player con recentrado suave. Los límites activos siempre pertenecen al mapa actual.

## PNJ

La identidad técnica de un PNJ es el nombre de su nodo normalizado a minúsculas:

```text
Pedro_Luis → pedro_luis
```

Renombrar el nodo cambia deliberadamente su identidad de diálogo.

La textura se configura mediante la propiedad exportada `sprite: Texture2D`. `pnj.gd` usa `@tool` sólo para reflejar esa textura en el editor; la lógica de gameplay no se ejecuta en modo editor.

Modos de seguimiento:

```text
NUNCA_SEGUIR
SEGUIR_Y_QUEDARSE
SEGUIR_Y_VOLVER
```

El seguimiento usa movimiento directo con `move_and_slide()`. No existe pathfinding mientras los mapas reales no lo necesiten.

### Estado visual del guion

El color del nombre indica la procedencia del guion específico:

```text
gris  → no existe guion específico
verde → guion oficial
azul  → guion local
```

`generico.txt` es fallback técnico y no activa color de guion específico.

## Diálogos

Fuentes:

```text
oficial → user://dialogues/
local   → user://custom_dialogues/
```

Un PNJ usa un único archivo específico:

```text
<mapa_logico>_<pnj>.txt
```

Ejemplo:

```text
aldea_a1.tscn + Chef
→ aldea_chef.txt
```

Prioridad runtime:

```text
1. local    <mapa_logico>_<pnj>.txt
2. oficial  <mapa_logico>_<pnj>.txt
3. oficial  generico.txt
```

El editor trabaja con ese mismo archivo específico. No existe una variante distinta según estado del Player.

`DialogueParser` interpreta el formato y `DialogueValidator` comprueba coherencia estructural al iniciar el diálogo. Si el archivo no puede cargarse o validar, se intenta `fallo.txt`.

Las cadenas de condiciones/saltos automáticos tienen un límite runtime de 100 transiciones consecutivas para impedir ciclos que no devuelvan el control.

## Inventario y persistencia

Cada aventura tiene su propio inventario persistente, identificado por el ID completo de su escena.

```text
aldea_a1.tscn → aldea_a1
menzo_a1.tscn → menzo_a1
```

Cada vez que se carga un mapa se carga también el inventario asociado a ese mismo ID. No existe un segundo mecanismo para "recuperar" inventario al volver: cargar el mapa siempre carga su inventario persistente.

Archivo común:

```text
user://settings.cfg
```

Secciones relevantes:

```text
[dialogues]         preferencia de sincronización
[maps]              último mapa seleccionado
[map_positions]     última posición por mapa
[map_inventories]   inventario por mapa
```

Ejemplo conceptual:

```ini
[map_inventories]
aldea_a1=PackedStringArray("llave", "pista_del_pozo")
menzo_a1=PackedStringArray("mapa")
```

Los efectos `+objeto` y `-objeto` modifican únicamente el inventario del mapa activo y lo guardan inmediatamente cuando producen un cambio real.

La marca reservada `__superado__` utiliza ese mismo mecanismo. Un guion cierra una aventura con:

```text
[+__superado__]
```

No existe una persistencia separada para mapas completados: el mapa se considera superado cuando su inventario contiene `__superado__`. La marca no se muestra en el panel Estado ni genera feedback junto al Player.

`Vaciar inventario` afecta únicamente al mapa activo y elimina también `__superado__`, por lo que reinicia el estado de superado de esa aventura.

No existe limpieza automática de datos pertenecientes a mapas eliminados o renombrados.

## Sincronización de guiones

Los guiones oficiales se versionan exclusivamente en:

```text
aik3n/ZeMobida_guiones
```

`DialogueUpdater` sincroniza hacia `user://dialogues/` usando una actualización temporal y atómica. Una actualización fallida conserva la caché oficial anterior.

El updater transporta archivos; no interpreta ni valida su contenido.

## Criterio de arquitectura

La regla de trabajo es deliberadamente pragmática:

```text
cuando duela lo curamos
```

No se añaden abstracciones, identificadores estables, bases de datos, pathfinding, sistemas de quests o frameworks de mapas hasta que una necesidad real los justifique.
