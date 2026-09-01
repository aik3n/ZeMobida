# ZeMobida — Architecture

**Estado:** arquitectura funcional revisada el 2026-09-01.  
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
│   ├── HUD
│   └── BotonEstado
├── EstadoUI                   CanvasLayer 20
│   └── Estado/Panel
│       ├── datos de Player
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
└── persistencia de XP/inventario

DialogueUpdater (autoload)
└── GitHub → user://dialogues/
```

`Game` permanece vivo durante toda la sesión. No se cambia la escena raíz al entrar o salir de un mapa: sólo se sustituye el contenido de `SceneContainer`.

## Selección y carga de mapas

La bienvenida contiene `carrusel_mapas.tscn`. El carrusel descubre automáticamente escenas `.tscn` directamente dentro de:

```text
res://mapas/
```

Todos los mapas descubiertos son seleccionables. `Preview` es opcional y puede ser `Sprite2D` o `TextureRect`.

Al pulsar `JUGAR`, el carrusel comunica la ruta a `Game`, que carga la escena dentro de `SceneContainer`.

El último mapa seleccionado se conserva en `user://settings.cfg`, sección `[maps]`.

### Volver al selector

Durante el juego, el panel global `ESTADO` contiene:

```text
VOLVER A MAPAS
```

La navegación pertenece a `Game`, no a cada mapa. Por ello cualquier mapa actual o futuro dispone del mismo mecanismo sin implementar código propio.

Al volver:

1. si el editor de guiones está abierto, la salida se bloquea;
2. si hay un diálogo activo, se finaliza mediante `DialogueManager.end_dialogue()`;
3. se cierra el panel de estado;
4. `Game` carga `bienvenida.tscn` dentro de `SceneContainer`;
5. Player y cámara quedan ocultos/inactivos mientras no haya mapa.

## Posición persistente por mapa

`SpawnPlayer` sigue siendo parte del contrato del mapa, pero ya no significa “aparecer siempre aquí”.

Regla:

```text
primera entrada / sin posición guardada
→ SpawnPlayer

entradas posteriores
→ última posición guardada del Player
```

Antes de abandonar un mapa, `Game` guarda `player_actual.global_position`.

También intenta guardar la posición cuando:

- la aplicación recibe un cierre normal de ventana;
- la aplicación pasa a segundo plano/pausa.

El botón **Stop** del editor de Godot puede terminar el proceso externamente y no se considera un cierre normal garantizado.

Las posiciones se almacenan en:

```ini
[map_positions]
<id_mapa>=Vector2(...)
```

dentro de `user://settings.cfg`.

El identificador técnico usado actualmente es el nombre base del archivo de escena normalizado a minúsculas:

```text
Arauzo_de_salce.tscn → arauzo_de_salce
aldea.tscn           → aldea
```

La normalización se realiza en runtime; no requiere renombrar físicamente la escena. Renombrar el archivo sí cambia deliberadamente la identidad técnica del mapa.

No existe migración automática de claves antiguas que conservaran mayúsculas antes de `bb3f058`.

Tras restaurar una posición, `Game` sincroniza también `player_actual.destino` para impedir que el Player intente volver a un destino anterior.

## Contrato actual de mapa

Un mapa puede contener:

```text
mapa
├── Fondo                 Sprite2D, preferido en mapas ilustrados
├── colisiones            StaticBody2D + shapes/polígonos
├── PNJ                   instancias de pnj.tscn
├── SpawnPlayer           obligatorio como entrada/fallback
├── Frontal               Sprite2D transparente, opcional
├── Preview               opcional
└── CameraBounds          fallback para mapas sin Fondo
```

### Fondo y cámara

Cuando existe `Fondo` con textura, `Game` obtiene de su rectángulo transformado los límites de `Camera2D`.

Los mapas sin `Fondo` pueden usar:

```text
CameraBounds
└── CollisionShape2D
    └── RectangleShape2D
```

Si un mapa no tiene ni `Fondo` válido ni `CameraBounds`, no existe una fuente válida para limitar la cámara.

`Fondo` se usa normalmente a escala `1:1` y con `centered = false`.

### Frontal

`Frontal` es una capa PNG transparente opcional:

```text
Fondo      z bajo
Player/PNJ z medio
Frontal    z alto
```

No requiere lógica de entrada/salida ni recorte dinámico.

## Player

Existe una única instancia persistente de `Player` propiedad de `Game`.

El nivel no es un estado independiente: se deriva de XP mediante la tabla central:

```text
res://scripts/niveles.gd
```

Niveles actuales:

| Nivel | límite superior inclusivo |
| --- | ---: |
| a1 | 70 |
| a2 | 120 |
| b1 | 340 |
| b2 | 410 |
| c1 | 740 |
| c2 | 2000 |

La tabla central es la única fuente de verdad para cálculo de nivel y progreso del HUD.

### Colisión actual

`player.tscn` utiliza `CapsuleShape2D`:

```text
radio  = 21
altura = 150
```

Los valores son parte del ajuste visual/jugable actual y pueden revisarse si cambia el arte.

## PNJ

### Identidad

El nombre del nodo de la instancia, normalizado a minúsculas, es la identidad técnica del PNJ.

Ejemplo:

```text
Pedro_Luis → pedro_luis
```

- identidad técnica: `pedro_luis`;
- nombre visible: `pedro luis`;
- diálogo: se construye usando mapa + identidad + nivel.

No existe una propiedad exportada adicional para el nombre. Renombrar el nodo cambia deliberadamente la identidad técnica.

Los nombres se construyen; no se intenta analizar el nombre de un archivo para reconstruir mapa/PNJ/nivel.

### Sprite

La textura visual se configura desde la instancia del PNJ en el Inspector mediante:

```gdscript
@export var sprite: Texture2D
```

El creador del mapa elige manualmente la textura. El juego no deduce qué imagen corresponde al PNJ.

`pnj.gd` usa `@tool` únicamente para reflejar el valor de la propiedad exportada sobre el `Sprite2D` interno mientras se edita la escena. La lógica de gameplay no se ejecuta en el editor (`Engine.is_editor_hint()`).

Esto evita usar `Editable Children` como flujo normal y mantiene encapsuladas las colisiones/áreas internas.

### Colisiones actuales

`pnj.tscn`:

```text
cuerpo
CapsuleShape2D
radio  = 20
altura = 152

interacción
CapsuleShape2D
radio  = 22
altura = 160
```

Los nodos internos se llaman actualmente:

```text
Collision
InteractionArea/Collision_Interaccion
```

### Seguimiento

Modos actuales:

```text
NUNCA_SEGUIR
SEGUIR_Y_QUEDARSE
SEGUIR_Y_VOLVER
```

El seguimiento utiliza movimiento directo con `move_and_slide()`. No existe navegación/pathfinding; sólo debe introducirse si los mapas reales demuestran que es necesario.

## Diálogos

Fuentes:

```text
oficial → user://dialogues/
local   → user://custom_dialogues/
```

Prioridad para un PNJ/nivel:

```text
1. local    <mapa>_<pnj>_<nivel>.txt
2. oficial  <mapa>_<pnj>_<nivel>.txt
3. oficial  <mapa>_<pnj>.txt
4. oficial  generico.txt
```

Los componentes técnicos `<mapa>` y `<pnj>` se normalizan a minúsculas antes de resolver el nombre del archivo.

Los guiones oficiales se versionan exclusivamente en:

```text
aik3n/ZeMobida_guiones
```

`DialogueUpdater` transporta/sincroniza archivos oficiales; no interpreta la sintaxis.

El editor local usa `CodeEdit`, resaltado visual y un gutter rojo informativo. Los avisos no bloquean ninguna acción.

Acciones actuales del editor:

```text
GUARDAR → guarda en user://custom_dialogues/ y cierra el editor
ENVIAR  → guarda primero; si el guardado funciona, abre el correo y mantiene el editor abierto
CERRAR  → cierra sin guardar cambios posteriores
```

`GUARDAR` y `ENVIAR` reutilizan la misma lógica de escritura. `ENVIAR` nunca intenta enviar una versión que no se haya guardado correctamente antes.

El envío no utiliza SMTP, credenciales de Gmail, OAuth ni backend. Tras guardar, el juego abre una URI `mailto:` mediante `OS.shell_open()` con:

```text
Para:    zemobida@gmail.com
Asunto:  ZeMobida - <nombre_archivo>
Cuerpo:  nombre del archivo + contenido exacto guardado
```

El `.txt` no se adjunta automáticamente: el contenido se incluye en el cuerpo del correo. La aplicación de correo del jugador es la que muestra y confirma el envío. Cancelar ese correo no deshace el guardado local realizado previamente.

### Nivel objetivo del editor

Al iniciar una conversación, `DialogueManager.start_dialogue()` captura el nivel actual del Player en `current_dialogue_level`.

Ese valor representa el contexto del diálogo abierto y permanece estable hasta que la conversación termina. Si un efecto cambia XP y con ello el nivel del Player antes de pulsar `EDITAR`, el archivo objetivo continúa siendo:

```text
<mapa>_<pnj>_<nivel_al_inicio>.txt
```

No se recalcula con el nivel posterior al efecto.

El runtime continúa usando `DialogueParser` y `DialogueValidator` al iniciar un diálogo. La responsabilidad conceptual del parser es interpretar el formato; el validator actual comprueba la coherencia estructural del diccionario resultante.

### Contingencia de saltos automáticos

`DialogueManager.show_node()` recorre iterativamente las condiciones y saltos automáticos. Una cadena puede realizar como máximo:

```text
100 transiciones automáticas consecutivas
```

El conteo termina cuando el diálogo llega a un nodo que devuelve el control al jugador. Una opción seleccionada por el jugador inicia una nueva cadena.

Si se intenta superar el límite, el runtime detiene la cadena sin aplicar efectos ni continuar saltando, escribe el diagnóstico como mensaje normal en Output y mantiene el diálogo activo con el panel visible, sin opciones y con `EDITAR` disponible.

Esta protección no declara inválidos los ciclos interactivos ni intenta analizar el grafo completo del guion. Es una contingencia runtime contra guiones accidentales o maliciosos que no devuelven el control.

## Persistencia

Archivo común:

```text
user://settings.cfg
```

Secciones actuales:

```text
[dialogues]       preferencia de sincronización de guiones
[maps]            último mapa seleccionado
[player]          XP e inventario
[map_positions]   última posición del Player por mapa
```

Los efectos de diálogo que producen una variación real de XP o inventario guardan inmediatamente la sección `[player]`. El guardado no depende de que el diálogo llegue posteriormente a `end_dialogue()`.

Un efecto que no cambia el estado final —por ejemplo añadir un objeto ya presente, retirar uno ausente o intentar superar un límite de XP sin variación— no provoca una escritura adicional.

El manifest de sincronización de guiones permanece separado porque describe el estado de la caché remota, no la partida.

## Cámara y control táctil

Controles actuales:

```text
tap y soltar       → mover Player
arrastrar          → explorar desplazando cámara
pinch              → zoom móvil
rueda ratón        → zoom escritorio
teclado/mando      → recentrar inmediatamente
```

Umbral de arrastre: `28 px`.

Zoom temporal:

```text
0.7 … 1.4
```

Después de explorar, un nuevo tap calcula primero el destino en coordenadas de mundo y después restaura cámara y zoom con Tween cúbico `EASE_OUT` de `0.8 s`.

## Feedback de XP e inventario

Los cambios reales muestran mensajes flotantes:

```text
ganancia → verde, sube
pérdida  → rojo, baja
```

Se utilizan canales positivo/negativo independientes con separación aproximada de `0.25 s` por canal. Cada mensaje dura aproximadamente `1.2 s`.

La carga de estado persistido no genera feedback.

## Exportación

`godot/export_presets.cfg` contiene actualmente presets para:

```text
Windows Desktop
Android
Web
```

Android mantiene permiso de Internet para la sincronización de guiones y su flujo básico fue validado en dispositivo.

Windows utiliza actualmente PCK embebido en el ejecutable.

El preset Web forma parte de la configuración del proyecto, pero todavía no existe en esta documentación una validación funcional equivalente de ejecución en navegador. Su presencia no debe interpretarse por sí sola como soporte Web cerrado para release.

## Mapas externos: experimento cerrado

La arquitectura actual utiliza exclusivamente mapas integrados en:

```text
res://mapas/
```

Se probó la carga de proyectos de mapas independientes mediante paquetes
PCK/ZIP. El experimento se descartó para el prototipo porque todos los
resource packs comparten `res://` y dos autores independientes pueden
exportar rutas de recursos iguales, provocando colisiones.

No existe soporte runtime para mapas externos y esta posibilidad no debe
condicionar la arquitectura actual.

El resultado del experimento se conserva en
[`MAP_PACKS_FUTURE.md`](MAP_PACKS_FUTURE.md).

## Límites y deuda deliberada

No se pretende resolver de forma anticipada problemas que aún no se han manifestado. Permanecen deliberadamente simples:

- descubrimiento de mapas sólo en la carpeta directa `res://mapas/`;
- preview obtenida mediante carga/instanciación temporal del mapa;
- seguimiento PNJ sin navegación;
- contratos de SceneTree por nombres;
- contenido visual provisional en varios mapas.

Los riesgos técnicos activos y su prioridad están registrados en [`AUDIT.md`](AUDIT.md).
