# ZeMobida — Architecture

**Estado:** arquitectura funcional revisada el 2026-09-02.  
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
├── Dialogo                    CanvasLayer 10
└── DiplomaNivel               CanvasLayer 40

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

La imagen del carrusel se resuelve por prioridad:

```text
1. textura de Preview, si existe y es válida
2. textura de Fondo, si Preview no aporta imagen
3. res://art/ui/preview_default.png
```

`Preview` sigue siendo la opción preferida cuando se quiere una miniatura específica. Omitirlo no deja el mapa sin imagen mientras exista `Fondo` o el fallback global.

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
├── objetos visuales      StaticBody2D + 1 CollisionShape2D + Sprite2D(s), opcional
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

### Profundidad visual

La profundidad entre actores y determinados objetos del escenario se resuelve mediante una regla simple basada en la posición vertical de sus colisiones de base. No se utiliza Y-sort general.

El `Player` ocupa la profundidad visual intermedia. Los PNJ cambian automáticamente entre detrás y delante del Player comparando la posición global de sus `CollisionShape2D`, colocadas en los pies.

```text
PNJ con pies por encima del Player
→ PNJ detrás

PNJ con pies por debajo del Player
→ PNJ delante
```

La misma filosofía se aplica automáticamente a objetos estáticos del mapa.

Convención:

```text
StaticBody2D
├── CollisionShape2D
└── Sprite2D
```

Un `StaticBody2D` participa en profundidad automática cuando contiene directamente:

```text
exactamente 1 CollisionShape2D
1 o más Sprite2D
```

La `CollisionShape2D` representa la base visual del objeto. `Game` descubre estos objetos una sola vez al cargar el mapa y durante el juego compara esa referencia con la colisión de los pies del Player.

No importan los nombres de los nodos y el diseñador no necesita asignar scripts, `NodePath` ni valores Z manuales.

La separación visual general es:

```text
Fondo                  z bajo

objetos/PNJ detrás
Player
objetos/PNJ delante

frontales permanentes  z alto
```

Los `StaticBody2D` que sólo contienen colisiones y no tienen `Sprite2D` se ignoran. Los contenedores con varias `CollisionShape2D` tampoco cumplen la convención automática.

Un elemento que deba permanecer siempre por encima de los actores puede seguir siendo un `Sprite2D` con Z fija y sin participar en profundidad automática.

La colisión usada como referencia debe estar colocada donde el personaje u objeto toca visualmente el suelo. Si una colisión no representa correctamente esa base, ese objeto no debe utilizar esta convención automática.

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
tap y soltar       → fijar nuevo destino del Player
arrastrar          → explorar desplazando cámara sin cancelar el destino
pinch              → zoom móvil sin cancelar el destino
rueda ratón        → zoom escritorio
teclado/mando      → recentrar inmediatamente
```

Umbral de arrastre: `28 px`.

Zoom temporal:

```text
0.7 … 1.4
```

Después de explorar, un nuevo tap calcula primero el destino en coordenadas de mundo y después restaura cámara y zoom con Tween cúbico `EASE_OUT` de `0.8 s`.

### Destino y exploración durante movimiento

Un tap válido muestra durante `0.7 s` una marca visual breve en el punto del mundo elegido como nuevo destino. Es feedback de entrada: no modifica navegación, velocidad ni colisiones.

Apoyar el dedo para iniciar un gesto ya no cancela el movimiento en curso. Si el gesto termina siendo arrastre o pinch, el Player conserva su destino y continúa caminando.

Durante la exploración manual, la cámara mantiene el centro del mundo que está observando aunque el Player siga desplazándose por debajo. Al soltar el arrastre, la cámara permanece en esa zona y el Player continúa hacia su destino.

Un nuevo tap desde la vista explorada sustituye el destino anterior, muestra el feedback de destino y activa el recentrado existente.

### Suavizado de seguimiento

El movimiento físico del Player sigue siendo directo: no se añade aceleración ni frenado artificial. La suavidad visual pertenece exclusivamente a `Camera2D`.

Durante el seguimiento normal del Player se utiliza `position_smoothing` para amortiguar los cambios bruscos al empezar y terminar un desplazamiento.

La separación de responsabilidades es:

```text
seguimiento normal del Player
→ smoothing de Camera2D activo

arrastre / pinch / exploración manual
→ smoothing desactivado

recentrado tras explorar
→ smoothing desactivado; se usa el Tween existente

recentrado terminado
→ smoothing activo otra vez
```

Al pasar de seguimiento suavizado a control manual se conserva primero el centro visual actual de la cámara para evitar un salto. Teclado y mando mantienen su recentrado inmediato y después continúan con seguimiento suavizado.

El valor inicial de `position_smoothing_speed` es `6.0`; es un ajuste visual, no un contrato de gameplay.

## Feedback de XP, inventario y nivel

Los cambios reales muestran mensajes flotantes:

```text
ganancia → verde, sube
pérdida  → rojo, baja
```

Se utilizan canales positivo/negativo independientes con separación aproximada de `0.25 s` por canal. Cada mensaje dura aproximadamente `1.2 s`.

Cuando `Player.add_xp()` provoca también un cambio de nivel, se encola un segundo feedback destacado con la transición completa, por ejemplo:

```text
A1 → A2
B1 → A2
```

El cambio puede ser ascendente o descendente y puede saltar varios niveles. La carga de estado persistido no genera estos feedbacks.

### Diploma al terminar un diálogo

`DialogueManager.current_dialogue_level` conserva el nivel con el que comenzó la conversación. Al cerrarse el diálogo se compara ese nivel inicial con el nivel final del Player.

Regla:

```text
nivel final == nivel inicial
→ no mostrar diploma

nivel final != nivel inicial
→ mostrar un único diploma del nivel final
```

Sólo importa el resultado final del diálogo. Si durante una misma conversación el Player atraviesa varios niveles, no se encadenan diplomas; y si termina otra vez en el nivel inicial, no se muestra ninguno. Subidas y bajadas se consideran igualmente relevantes.

El diálogo desaparece antes de presentar el diploma. Los recursos se resuelven por nivel desde:

```text
res://art/diplomas/<nivel>.png
```

El diploma aparece como overlay modal por encima de la UI. Su entrada parte de una escala casi nula y `35°` de rotación y termina a escala normal y `0°` mediante Tween. Mientras dura la entrada no puede cerrarse; después, cualquier toque o clic en la pantalla lo descarta.

La ausencia del PNG correspondiente no bloquea el juego. Los cierres usados para abrir el editor de diálogos o abandonar el mapa no deben presentar el diploma.

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
