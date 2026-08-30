# ZeMobida — Development Guide

**Estado:** subsistemas de guiones y diálogo validados; maquetación, mapa piloto ilustrado, control táctil, feedback del Player y creador local de guiones revisados en runtime hasta el 2026-08-30.  
**Godot:** 4.7.

## Reglas

- El código implementado es la fuente de verdad del comportamiento.
- Los guiones se versionan en el repositorio independiente `aik3n/ZeMobida_guiones`.
- `user://dialogues/` es la caché oficial sincronizada utilizada por runtime.
- `user://custom_dialogues/` contiene únicamente guiones locales del jugador.
- `DialogueUpdater` nunca debe modificar `user://custom_dialogues/`.
- Una actualización fallida nunca debe destruir una caché oficial válida.

## Sincronización

Preferencia:

```text
Actualizar guiones al iniciar: Sí / No
```

Con `Sí`:

```text
caché local
   ↓
GitHub
   ↓
SHA por archivo
   ↓
comparar manifest
   ↓
descargar sólo cambios
   ↓
comprobar conjunto descargado
   ↓
activar
   ↓
entrar al mapa
```

Timeout global:

```gdscript
const SYNC_TIMEOUT_SECONDS: float = 30.0
```

Ante timeout, error de red, descarga incompleta, escritura fallida o sustitución fallida, se conserva la caché anterior.

Con `No`, no se contacta con GitHub.

## Regla de actualización segura

```text
descargar/copiar → temporal → comprobar conjunto de archivos → activar
```

Nunca borrar la caché activa antes de saber que la nueva colección es válida.

## Regresión recomendada

Comprobar:
- primera ejecución;
- ejecución sin cambios;
- archivo modificado;
- archivo nuevo;
- archivo eliminado;
- GitHub inaccesible;
- timeout;
- contenido inválido;
- caché conservada tras error;
- `Actualizar = No` sin petición remota.

## Desarrollo de guiones

Antes de modificar los `.txt` de `aik3n/ZeMobida_guiones`:
1. comprobar `DIALOGUE_FORMAT.md`;
2. verificar destinos;
3. verificar condiciones y efectos;
4. evitar ciclos automáticos;
5. comprobar continuidad narrativa.


## Creador local de guiones

El creador reutiliza el mismo formato `.txt` que los guiones oficiales. No existe un segundo formato ni una fase especial de exportación.

### Archivo editable

El jugador sólo puede editar:

```text
<mapa>_<pnj>_<nivel>.txt
```

Los fallbacks:

```text
<mapa>_<pnj>.txt
generico.txt
```

son oficiales y no se editan desde el juego.

### Prioridad runtime

La resolución es:

```text
local exacto
→ oficial exacto
→ oficial PNJ
→ oficial genérico
```

Por ejemplo:

```text
user://custom_dialogues/aldea_ibon_a1.txt
```

sustituye localmente sólo a:

```text
user://dialogues/aldea_ibon_a1.txt
```

No sustituye a otros niveles ni modifica el archivo oficial.

### Flujo de edición

El botón `EDITAR` aparece junto al nombre del PNJ durante el diálogo.

```text
EDITAR
  ↓
¿existe local exacto?
  sí → cargar local
  no
  ↓
¿existe oficial exacto?
  sí → cargar su contenido como copia de trabajo
  no → cargar boceto
```

La copia local sólo existe después de un guardado correcto.

El editor utiliza `CodeEdit` y sólo expone:

```text
GUARDAR
CERRAR
```

`GUARDAR` escribe el `.txt` en `user://custom_dialogues/` y cierra inmediatamente después de una escritura correcta. Si no puede crear la carpeta o abrir el archivo para escritura, no cierra el editor.

`CERRAR` no guarda cambios pendientes.

### Highlight

`res://scripts/dialogue_syntax_highlighter.gd` colorea el lenguaje de forma visual:

```text
' comentario → verde
# nodo       → violeta
= opción     → azul
? condición  → amarillo
> salto      → cyan
[efectos]    → naranja
```

El resaltado no altera el contenido ni sustituye al parser.

### Validación

**Guardar no valida el guion.**

El flujo es deliberadamente:

```text
editar
→ guardar
→ volver al juego
→ interactuar con el PNJ
→ DialogueParser
→ DialogueValidator
```

Por tanto, el propio flujo normal del juego sirve para probar y validar el guion. Si el archivo local es inválido, se aplica el mismo comportamiento de error que para un oficial inválido.

### Regresión recomendada

Comprobar:

- oficial exacto sin local → se usa el oficial;
- local exacto + oficial exacto → se usa el local;
- borrar el local → vuelve a usarse el oficial;
- no existe exacto local/oficial → se mantienen los fallbacks oficiales;
- `EDITAR` sobre oficial exacto → carga exactamente su contenido;
- `EDITAR` sin exacto oficial → muestra el boceto;
- abrir oficial exacto y cerrar sin guardar → no crea archivo local;
- modificar y pulsar `CERRAR` → cambios descartados;
- `GUARDAR` → escribe local y cierra;
- siguiente interacción → usa la versión local guardada;
- reabrir `EDITAR` → muestra la versión local;
- guion local inválido → runtime lo detecta al cargarlo;
- comentarios, nodos, opciones, condiciones, saltos y efectos → colores diferenciados.


## Selección de mapas

La selección está implementada como la escena reutilizable:

```text
res://escenas/carrusel_mapas.tscn
```

y está instanciada dentro de `bienvenida.tscn`.

El carrusel busca automáticamente archivos `.tscn` directamente en:

```text
res://mapas/
```

Para añadir un mapa al juego no es necesario modificar el selector:

```text
res://mapas/nuevo_mapa.tscn
```

aparecerá automáticamente.

Todos los mapas descubiertos están disponibles; no existe lógica de desbloqueo.

### Nombre visible

Se toma el nombre del archivo:

```text
nuevo_mapa.tscn → nuevo mapa
```

### Preview

La escena puede contener un nodo opcional `Preview`. Si el nodo es `Sprite2D` o `TextureRect` y tiene textura, ésta se muestra en el carrusel. Si no existe o no tiene textura, se muestra sólo el nombre.

### Persistencia

El último mapa se guarda al pulsar `JUGAR`, no al desplazarse por el carrusel. Se almacena como ruta de escena en `user://settings.cfg`.
XP e inventario también se almacenan en `user://settings.cfg`; no se contempla migración desde formatos anteriores.

La persistencia de jugador comparte ese mismo archivo. La XP y el inventario se guardan en la sección `[player]`; no se crea un archivo de partida separado.

Al iniciar se intenta recuperar esa ruta. Si el archivo ya no existe, se selecciona el primer mapa disponible.

### Regresión recomendada

Además de las pruebas generales, comprobar:

- un mapa;
- varios mapas;
- ordenación estable por nombre;
- navegación con botones;
- navegación con teclado;
- desplazamiento horizontal con ratón;
- mapa con `Preview`;
- mapa sin `Preview`;
- recordar último mapa tras reiniciar;
- último mapa eliminado → primer mapa;
- añadir un nuevo `.tscn` → aparece sin modificar el selector;
- `JUGAR` → `Game` carga la escena seleccionada.


## Creación de mapas top-down

La dirección artística vigente es:

```text
imagen de fondo + colisiones + elementos dinámicos encima
```

No se exige `TileMap`. El objetivo es que el equipo de arte pueda diseñar cada localización como una ilustración completa con libertad de composición.

### Fondo

Un mapa ilustrado puede incluir en su raíz:

```text
Fondo (Sprite2D)
```

Reglas:

- textura de la ilustración completa;
- escala `1:1`;
- `centered = false`;
- no redimensionar el fondo desde Godot para adaptar el mapa al teléfono.

El viewport y el tamaño del mapa son conceptos distintos. El viewport lógico actual es `1080 × 1920`; una ilustración puede ser mayor, menor o tener otra proporción.

El mapa piloto es `aldea` y utiliza:

```text
res://art/mapas/aldea.PNG
```

`Game` obtiene automáticamente los límites de cámara desde el rectángulo transformado de `Fondo`. Si un mapa no incluye este nodo, se mantiene el sistema anterior basado en `CameraBounds`.

En un mapa ilustrado ya convertido, como `aldea`, `CameraBounds` es redundante y puede eliminarse.

### Preview del carrusel

La imagen de carrusel es independiente del fondo jugable.

Por ejemplo, `aldea` puede utilizar:

```text
Fondo   → res://art/mapas/aldea.PNG
Preview → res://art/preview/aldea.PNG
```

Esto evita usar una imagen grande del mundo como miniatura.

### Colisiones

Las colisiones se dibujarán en Godot encima de la ilustración.

Reglas prácticas:

- bloquear sólo el espacio que realmente debe impedir el paso;
- pensar en la posición de los pies del personaje;
- no perseguir el contorno exacto de cada píxel;
- agrupar la geometría por zonas comprensibles cuando ayude al mantenimiento.

La incorporación de colisiones al mapa piloto es el siguiente paso del modelo visual.

### Frontal

Los elementos que deban ocultar parcialmente a Player o PNJ se suministran mediante una imagen PNG transparente opcional.

Flujo recomendado:

```text
aldea.PNG
aldea_frontal.PNG
```

En la escena:

```text
Fondo      → Sprite2D, z bajo
Player/PNJ → z medio
Frontal    → Sprite2D, z alto
```

`Fondo` y `Frontal` deben compartir:

```text
position = (0, 0)
scale = (1, 1)
centered = false
```

La imagen frontal sólo contiene los píxeles que deben quedar por encima de los actores, por ejemplo copas de árboles, tejados, arcos o toldos.

No se utiliza recorte dinámico ni `Polygon2D` para generar esta capa en runtime. Esa posibilidad se probó y se descartó por complejidad innecesaria.


### SpawnPlayer

Al cargar un mapa, `Game` coloca el Player persistente en `SpawnPlayer` y sincroniza su variable `destino` con esa misma posición.

La regla es:

```text
global_position = SpawnPlayer
destino         = SpawnPlayer
```

Así el personaje aparece quieto en el nuevo spawn aunque conserve estado entre escenas.


## Control táctil del mapa

El control vigente de Player y cámara está orientado a móvil.

### Tap

Un toque no ordena movimiento al presionar.

```text
presionar → esperar intención
soltar sin arrastrar → mover Player
```

El destino se calcula en coordenadas de mundo en el momento de soltar.

### Arrastre

Si el puntero recorre al menos:

```gdscript
const DRAG_THRESHOLD := 28.0
```

el gesto pasa a exploración.

Durante el arrastre:

- no se ordena movimiento al Player;
- el mapa sigue visualmente el dedo;
- la cámara queda limitada al área válida del mapa.

Al soltar, la cámara permanece en la posición explorada.

### Zoom de exploración

El zoom es temporal y forma parte del modo de exploración:

```gdscript
const ZOOM_MIN := 0.7
const ZOOM_MAX := 1.4
```

Controles:

- móvil: pinch con dos dedos;
- escritorio: rueda del ratón.

Durante el pinch, el Player permanece quieto. Al finalizar un pinch se ignora cualquier dedo que siga apoyado hasta que todos se hayan soltado, evitando un tap accidental.

### Volver al jugador

Al hacer un nuevo tap después de explorar:

1. se calcula el destino usando la cámara todavía desplazada y con su zoom actual;
2. el Player comienza a caminar hacia ese destino;
3. la cámara restaura posición y zoom en paralelo.

Estado estándar:

```text
camera.position = Vector2.ZERO
camera.zoom     = Vector2.ONE
```

El recentrado actual usa:

```gdscript
const CAMERA_RECENTER_TIME := 0.8
```

con `Tween.TRANS_CUBIC`, `Tween.EASE_OUT` y propiedades animadas en paralelo.

Un nuevo gesto cancela el Tween en curso para mantener respuesta directa.

Teclado o mando restauran inmediatamente posición y zoom estándar.

### Ratón

El botón izquierdo reproduce tap/arrastre para pruebas de escritorio. La rueda controla el zoom. Los eventos de ratón generados por un dispositivo táctil se ignoran cuando ya se está procesando un toque.

### Regresión recomendada

Comprobar:

- tap sin desplazamiento → Player se mueve al soltar;
- mantener pulsado → Player no se mueve;
- desplazamiento menor que el umbral → sigue siendo tap;
- desplazamiento mayor que el umbral → sólo mueve cámara;
- soltar arrastre → cámara permanece desplazada;
- tap con cámara desplazada → destino correcto;
- rueda del ratón → zoom `0.7 … 1.4`;
- pinch de dos dedos → zoom sin mover Player;
- terminar pinch → no producir tap accidental;
- conservar posición y zoom al explorar;
- nuevo tap → posición y zoom vuelven juntos a estado estándar;
- recentrado de `0.8 s` suave y sin salto;
- iniciar otro gesto durante el recentrado → se cancela correctamente;
- no poder desplazar la cámara fuera de los límites con distintos niveles de zoom;
- teclado/mando → posición y zoom vuelven inmediatamente a estado estándar;
- interacción con UI → no debe generar un movimiento no manejado del Player.

### Responsabilidad de validación

`DialogueUpdater` no valida la sintaxis de los `.txt`; sólo sincroniza el conjunto remoto. `DialogueManager` valida el archivo cuando inicia el diálogo y recurre a `fallo.txt` si el guion es inválido.

### Efectos asociados al texto

Una línea de texto puede terminar en un bloque de efectos, por ejemplo `Has elegido bien [xp+30]`. El parser separa el texto de los efectos y `DialogueManager` los aplica únicamente cuando el nodo alcanza la fase de presentación.


## Feedback flotante de XP e inventario

Cuando un efecto modifica realmente XP o inventario, el jugador recibe un mensaje flotante junto al Player.

Contrato visual actual:

```text
positivo
  color verde
  comienza encima del Player
  sube
  escala 0.72 → 1.18 → 1.0

negativo
  color rojo
  comienza 60 px más abajo que el positivo
  baja
  escala 1.24 → 0.86
```

Los mensajes tienen borde oscuro para conservar legibilidad sobre el mapa. La duración visual actual es de aproximadamente `1.2 s`.

### Dos colas independientes

Los mensajes positivos y negativos no comparten cola:

```text
cola positiva → intervalo 0.25 s → mensajes que suben
cola negativa → intervalo 0.25 s → mensajes que bajan
```

Dentro de cada tipo se conserva el orden. Entre tipos no existe bloqueo: una ganancia y una pérdida pueden comenzar a la vez.

Cada mensaje duplica el `Label` de plantilla, ejecuta su propio `Tween` y se destruye con `queue_free()` al finalizar. La cola sólo regula la cadencia de lanzamiento.

### Regla de cambio real

No debe generarse feedback si el estado final no cambia.

Comprobar:

- XP positiva → texto `+N XP`;
- XP negativa → texto `-N XP`;
- XP en límite → mostrar sólo la variación real;
- variación real `0` → no mostrar nada;
- objeto nuevo → `+ Objeto`;
- objeto eliminado → `- Objeto`;
- objeto repetido al añadir → no mostrar;
- objeto inexistente al quitar → no mostrar;
- varios positivos → salida cada `0.25 s`;
- varios negativos → salida cada `0.25 s`;
- positivo y negativo simultáneos → ambos canales comienzan sin esperarse;
- carga de partida → no genera feedback.

### Orden visual

El feedback utiliza `CanvasLayer 15`.

```text
HUD / UI normal → 5
Diálogo         → 10
Feedback Player → 15
Estado          → 20
```

El layer sigue la posición del Player en pantalla. Esto evita que el diálogo tape los mensajes y mantiene su tamaño legible independientemente del zoom de cámara.


## Backlog técnico

La lista priorizada de mejoras y riesgos pendientes se mantiene en `docs/AUDIT.md`, sección **Backlog de auditoría completa — 2026-08-29**.

Los puntos se resolverán individualmente siguiendo el ciclo:

```text
especificar → implementar → probar en runtime → documentar → cerrar
```


## Exportación Android y sincronización de guiones

El preset Android debe mantener:

```text
permissions/internet=true
```

`DialogueUpdater` utiliza `HTTPRequest` para consultar y descargar los guiones desde GitHub. En una instalación Android nueva no existe todavía `user://dialogues/`, por lo que el permiso de Internet es necesario para obtener la caché inicial.


### Descubrimiento de mapas en exportación

Los recursos bajo `res://mapas/` se enumeran con `ResourceLoader.list_directory()` y no con `DirAccess`. Esto es necesario porque los recursos pueden quedar remapeados en el PCK de una build exportada, mientras `ResourceLoader` conserva sus nombres originales.

El contrato sigue siendo el mismo: sólo se descubren escenas `.tscn` directamente dentro de `res://mapas/`.


### Validación Android completada

Validado en dispositivo Android:

- acceso a GitHub mediante `HTTPRequest`;
- descarga inicial de guiones;
- disponibilidad de caché runtime;
- descubrimiento de mapas exportados mediante `ResourceLoader.list_directory()`;
- visualización del carrusel;
- carga del mapa seleccionado.

La funcionalidad está confirmada. Los ajustes de maquetación/responsive se tratarán por separado.
