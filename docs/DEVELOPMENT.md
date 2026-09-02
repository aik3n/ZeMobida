# ZeMobida — Development Guide

**Estado:** subsistemas de guiones y diálogo, navegación/posición por mapa, creador local de guiones y cambios de persistencia revisados hasta el 2026-09-02; validación de dispositivo documentada para Android.  
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

Los componentes técnicos de mapa y PNJ se normalizan a minúsculas.

Los fallbacks:

```text
<mapa>_<pnj>.txt
generico.txt
```

son oficiales y no se editan desde el juego.

### Nivel objetivo estable

El nivel que forma parte del nombre editable se captura cuando comienza la conversación.

Si un efecto del propio diálogo modifica XP y cambia el nivel antes de pulsar `EDITAR`, el editor sigue apuntando al archivo correspondiente al nivel inicial:

```text
inicio en a1
→ efecto cambia Player a a2
→ EDITAR sigue abriendo <mapa>_<pnj>_a1.txt
```

El nivel global del Player sí cambia normalmente; sólo se conserva el contexto del archivo editable.

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

El editor utiliza `CodeEdit` y expone:

```text
GUARDAR
ENVIAR
CERRAR
```

`GUARDAR` escribe el `.txt` en `user://custom_dialogues/` y cierra inmediatamente después de una escritura correcta. Si no puede crear la carpeta o abrir el archivo para escritura, no cierra el editor.

`ENVIAR` reutiliza el mismo guardado. Sólo después de escribir correctamente prepara un `mailto:` a `zemobida@gmail.com` con el nombre del archivo y su contenido exacto; el editor permanece abierto. Si falla el guardado, no se intenta abrir correo. Si falla o se cancela el cliente de correo, la copia local ya guardada permanece.

`CERRAR` no guarda cambios pendientes posteriores al último guardado.

### Highlight y lectura por línea

`res://scripts/dialogue_syntax_highlighter.gd` colorea el lenguaje de forma visual:

```text
' comentario → verde
# nodo       → violeta
= opción     → azul
? condición  → amarillo
> salto      → cyan
[efectos]    → naranja
```

El `CodeEdit` no usa `wrap`. Cada línea del archivo ocupa una única línea visual y las líneas largas utilizan scroll horizontal. Esto mantiene alineados el highlight y el gutter de diagnóstico.

El resaltado no altera el contenido ni sustituye al parser.

### Diagnóstico local por línea

`DialogueEditor` marca con un `●` rojo las líneas que no cumplen la forma local recomendada del lenguaje.

El diagnóstico:

```text
es local a una única línea
no usa DialogueParser
no usa DialogueValidator
no comprueba otras líneas
no bloquea GUARDAR ni ENVIAR
```

Reglas actuales:

```text
# NODO
→ `#` sólo puede aparecer como declaración de nodo.
→ la etiqueta debe ser un único token.
→ sólo puede coexistir con un comentario `' ...`.

= opción
→ puede contener un único `>`.
→ el salto debe aparecer antes del bloque de efectos.
→ no se admiten marcadores estructurales fuera de orden.

?condición
→ cada condición usa un único `?`.
→ puede contener un único `>`.
→ requiere un destino limpio.

> salto
→ contiene un único `>` y un destino limpio.

[efectos]
→ sólo puede existir un bloque por línea.
→ `[` y `]` deben estar emparejados.
→ máximo un efecto XP por línea.
→ XP usa `xp+N` o `xp-N`.
→ objetos usan `+objeto` o `-objeto`.
```

Ejemplos marcados:

```text
## INICIO
Texto # INICIO
= Sí > A > B
> HOLA = Buenos días
= Comprar [xp+5] > COMPRA
Hola [[xp+20]]
Hola [xp+20, xp+10]
```

No se analiza:

```text
existencia de nodos destino
coherencia narrativa
ciclos
finales
recompensas repetidas
estructura global
```

Un diálogo que no termina puede ser deliberado y no se considera error.

### Guardado y validación

**Guardar o enviar no valida el guion y las marcas rojas no bloquean esas acciones.**

El flujo de prueba sigue siendo deliberadamente:

```text
editar
→ guardar
→ volver al juego
→ interactuar con el PNJ
→ DialogueParser
→ DialogueValidator
```

Por tanto, el propio flujo normal del juego sirve para observar el comportamiento real del guion. El editor permite guardar deliberadamente contenido incompleto o marcado para continuar más adelante.

### Regresión recomendada

Comprobar:

- oficial exacto sin local → se usa el oficial;
- local exacto + oficial exacto → se usa el local;
- borrar el local → vuelve a usarse el oficial;
- no existe exacto local/oficial → se mantienen los fallbacks oficiales;
- `EDITAR` sobre oficial exacto → carga exactamente su contenido;
- `EDITAR` sin exacto oficial → muestra el boceto;
- diálogo iniciado en un nivel + efecto que cambia de nivel → `EDITAR` conserva el nivel inicial;
- abrir oficial exacto y cerrar sin guardar → no crea archivo local;
- modificar y pulsar `CERRAR` → cambios descartados;
- `GUARDAR` → escribe local y cierra;
- `ENVIAR` → guarda primero y mantiene abierto el editor;
- fallo de guardado al pulsar `ENVIAR` → no abre correo;
- cancelar/fallar el cliente de correo → el archivo local guardado permanece;
- siguiente interacción → usa la versión local guardada;
- reabrir `EDITAR` → muestra la versión local;
- guion local inválido → runtime lo detecta al cargarlo;
- comentarios, nodos, opciones, condiciones, saltos y efectos → colores diferenciados;
- línea larga → permanece en una sola línea visual y usa scroll horizontal;
- línea localmente incorrecta → `●` rojo;
- corregir la línea → desaparece el `●`;
- `#` fuera de una declaración de nodo → `●`;
- nodo con contenido adicional distinto de comentario → `●`;
- más de un `>` estructural → `●`;
- más de un bloque `[` / `]` o corchetes desparejados → `●`;
- dos efectos XP en una misma línea → `●`;
- orden estructural incorrecto → `●`;
- diálogo sin final o con ciclos narrativos → no se marca por ese motivo;
- una o muchas líneas con `●` → `GUARDAR` y `ENVIAR` continúan disponibles.


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

### ID técnico

Para persistencia y resolución de diálogo, el ID técnico es el basename de la escena normalizado a minúsculas:

```text
Arauzo_de_salce.tscn → arauzo_de_salce
```

La escena física no se renombra por esta normalización. Cambiar el filename sí cambia la identidad técnica.

No existe migración automática para claves de posición o variantes locales de diálogo creadas antes de `bb3f058` con mayúsculas en el prefijo de mapa.

### Preview

La escena puede contener un nodo opcional `Preview`. Si el nodo es `Sprite2D` o `TextureRect` y tiene textura, ésta es la primera opción del carrusel.

Si `Preview` no existe o no aporta una textura válida, el carrusel intenta reutilizar la textura del nodo raíz `Fondo`. Si tampoco existe un `Fondo` válido, utiliza:

```text
res://art/ui/preview_default.png
```

Prioridad:

```text
Preview
→ Fondo
→ preview_default.png
```

### Persistencia

El último mapa se guarda al pulsar `JUGAR`, no al desplazarse por el carrusel. Se almacena como ruta de escena en `user://settings.cfg`.

La persistencia de jugador comparte ese mismo archivo. XP e inventario se guardan en la sección `[player]`; no se crea un archivo de partida separado.

Cuando un efecto de diálogo produce un cambio real de XP o inventario, `[player]` se guarda inmediatamente. El guardado de la recompensa no espera a que termine la conversación.

La última posición de Player se guarda por ID técnico de mapa en `[map_positions]` y se restaura al volver a entrar. `SpawnPlayer` sólo actúa como entrada/fallback cuando no existe una posición previa.

Al iniciar el carrusel se intenta recuperar la última ruta seleccionada. Si el archivo ya no existe, se selecciona el primer mapa disponible.

### Regresión recomendada

Además de las pruebas generales, comprobar:

- un mapa;
- varios mapas;
- ordenación estable por nombre;
- navegación con botones;
- navegación con teclado;
- desplazamiento horizontal con ratón;
- mapa con `Preview` → usa `Preview`;
- mapa sin `Preview` y con `Fondo` → usa `Fondo`;
- mapa sin `Preview` ni `Fondo` → usa `preview_default.png`;
- recordar último mapa tras reiniciar;
- último mapa eliminado → primer mapa;
- añadir un nuevo `.tscn` → aparece sin modificar el selector;
- `JUGAR` → `Game` carga la escena seleccionada;
- primera entrada sin posición → `SpawnPlayer`;
- salida y reentrada → restaura última posición;
- ID de mapa con mayúsculas en el filename → clave técnica normalizada a minúsculas.


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

`Preview` sigue siendo independiente del fondo jugable y es la opción preferida cuando se quiere controlar expresamente la miniatura.

Por ejemplo, `aldea` puede utilizar:

```text
Fondo   → res://art/mapas/aldea.PNG
Preview → res://art/preview/aldea.PNG
```

Si `Preview` se omite, no hace falta configurar nada adicional: el carrusel usa `Fondo` como fallback. Sólo cuando el mapa no aporta ninguna de esas dos texturas se muestra `res://art/ui/preview_default.png`.

### Colisiones

Las colisiones se dibujan en Godot encima de la ilustración.

Reglas prácticas:

- bloquear sólo el espacio que realmente debe impedir el paso;
- pensar en la posición de los pies del personaje;
- no perseguir el contorno exacto de cada píxel;
- agrupar la geometría por zonas comprensibles cuando ayude al mantenimiento.

El mapa piloto `aldea` ya incorpora colisiones locales sobre la ilustración; su ajuste seguirá evolucionando con el arte y las pruebas de recorrido.

### Objetos con profundidad automática

Para que un objeto del escenario pueda aparecer delante o detrás del Player no es necesario configurar ningún sistema de profundidad desde el Inspector.

Crear el objeto con esta estructura:

```text
Objeto (StaticBody2D)
├── CollisionShape2D
└── Sprite2D
```

También puede contener varios sprites:

```text
Objeto (StaticBody2D)
├── CollisionShape2D
├── Sprite2D
└── Sprite2D
```

Requisitos:

- exactamente una `CollisionShape2D` directa;
- uno o más `Sprite2D` directos;
- colocar la colisión en la base visual del objeto, donde toca el suelo;
- no asignar scripts de profundidad;
- no configurar rutas `NodePath`;
- no configurar Z manual para el comportamiento delante/detrás;
- los nombres de `StaticBody2D`, `CollisionShape2D` y `Sprite2D` son libres.

`Game` descubre automáticamente esta estructura al cargar el mapa.

Ejemplo:

```text
Valla (StaticBody2D)
├── Colision (CollisionShape2D)
└── Imagen (Sprite2D)
```

produce automáticamente:

```text
Player por encima de la base de Valla
→ Valla delante del Player

Player por debajo de la base de Valla
→ Player delante de Valla
```

Un `StaticBody2D` usado únicamente como contenedor de colisiones:

```text
colisiones (StaticBody2D)
├── CollisionShape2D
├── CollisionPolygon2D
└── CollisionShape2D
```

no participa automáticamente porque no cumple el contrato visual.

Los elementos que deban permanecer siempre delante pueden seguir utilizando un `Sprite2D` frontal con Z fija y sin `StaticBody2D` asociado.

La misma regla de profundidad se utiliza entre Player y PNJ: las colisiones situadas en los pies actúan como referencia vertical.

Regresión recomendada:

- Player pasa por arriba y por abajo de un PNJ → cambia correctamente delante/detrás;
- objeto con `StaticBody2D + CollisionShape2D + Sprite2D` → profundidad automática;
- renombrar los nodos → comportamiento sin cambios;
- objeto con varios `Sprite2D` → todos mantienen conjuntamente la profundidad del objeto;
- `StaticBody2D` sin `Sprite2D` → ignorado;
- contenedor con varias colisiones → ignorado;
- frontal permanente con Z fija → permanece siempre delante.

### SpawnPlayer

`SpawnPlayer` es obligatorio como posición inicial/fallback, pero no sustituye la memoria de posición por mapa.

La regla es:

```text
sin posición guardada
→ global_position = SpawnPlayer
→ destino         = SpawnPlayer

con posición guardada
→ global_position = posición guardada
→ destino         = posición guardada
```

Sincronizar `destino` evita que el Player persistente intente caminar hacia una posición perteneciente al mapa anterior.


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

Si esos efectos producen un cambio real en XP o inventario, el nuevo estado se guarda inmediatamente en `user://settings.cfg`.


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

No debe generarse feedback si el estado final no cambia. Esa misma regla decide si hace falta persistir el estado después de los efectos.

Comprobar:

- XP positiva → texto `+N XP`;
- XP negativa → texto `-N XP`;
- XP en límite → mostrar sólo la variación real;
- variación real `0` → no mostrar nada ni guardar por ese efecto;
- objeto nuevo → `+ Objeto` y persistencia inmediata;
- objeto eliminado → `- Objeto` y persistencia inmediata;
- objeto repetido al añadir → no mostrar ni guardar por ese efecto;
- objeto inexistente al quitar → no mostrar ni guardar por ese efecto;
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

La lista priorizada de mejoras, decisiones abiertas y riesgos pendientes se mantiene en `docs/AUDIT.md`.

Los puntos se resuelven individualmente siguiendo el ciclo:

```text
especificar → implementar → probar en runtime → documentar → cerrar
```


## Exportación y sincronización de guiones

### Android

El preset Android debe mantener:

```text
permissions/internet=true
```

`DialogueUpdater` utiliza `HTTPRequest` para consultar y descargar los guiones desde GitHub. En una instalación Android nueva no existe todavía `user://dialogues/`, por lo que el permiso de Internet es necesario para obtener la caché inicial.

### Windows Desktop

El preset Windows Desktop utiliza actualmente PCK embebido en el ejecutable.

### Web

Existe un preset Web en `export_presets.cfg` con salida configurada para `ZeMobida.html`.

Su existencia documenta una configuración de exportación, no una validación cerrada de plataforma. Antes de considerar Web una plataforma soportada para release hay que comprobar en navegador el flujo completo que depende de entrada, persistencia local, `HTTPRequest`, sincronización de guiones y apertura de `mailto:` cuando proceda.

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
