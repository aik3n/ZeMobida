# ZeMobida — Development Guide

**Estado:** subsistemas de guiones y diálogo validados; maquetación, mapa piloto ilustrado y control táctil de cámara revisados en runtime hasta el 2026-08-30.  
**Godot:** 4.7.

## Reglas

- El código implementado es la fuente de verdad del comportamiento.
- Los guiones se versionan en el repositorio independiente `aik3n/ZeMobida_guiones`.
- `user://dialogues/` es la caché utilizada por runtime.
- Una actualización fallida nunca debe destruir una caché válida.

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
validar
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

Los elementos que deban ocultar parcialmente a Player o PNJ pueden suministrarse en una capa gráfica adicional `Frontal`.

Ejemplos:

- copas de árboles;
- tejados;
- arcos;
- elementos altos de primer plano.

`Frontal` es opcional y se añadirá cuando el arte del mapa lo necesite.


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

### Volver al jugador

Al hacer un nuevo tap después de explorar:

1. se calcula el destino usando la cámara todavía desplazada;
2. el Player comienza a caminar hacia ese destino;
3. la cámara vuelve a `Vector2.ZERO` suavemente.

El recentrado actual usa:

```gdscript
const CAMERA_RECENTER_TIME := 0.38
```

con `Tween.TRANS_CUBIC` y `Tween.EASE_OUT`.

Un nuevo gesto cancela el Tween en curso para mantener respuesta directa.

Teclado o mando restablecen inmediatamente la posición normal de la cámara.

### Ratón

El mismo flujo se admite con botón izquierdo y movimiento de ratón para poder probar en escritorio. Los eventos de ratón generados por un dispositivo táctil se ignoran cuando ya se está procesando un toque.

### Regresión recomendada

Comprobar:

- tap sin desplazamiento → Player se mueve al soltar;
- mantener pulsado → Player no se mueve;
- desplazamiento menor que el umbral → sigue siendo tap;
- desplazamiento mayor que el umbral → sólo mueve cámara;
- soltar arrastre → cámara permanece desplazada;
- tap con cámara desplazada → destino correcto;
- recentrado suave sin salto;
- iniciar otro gesto durante el recentrado → se cancela correctamente;
- no poder desplazar la cámara fuera de los límites;
- teclado/mando → cámara vuelve al seguimiento normal;
- interacción con UI → no debe generar un movimiento no manejado del Player.

### Responsabilidad de validación

`DialogueUpdater` no valida la sintaxis de los `.txt`; sólo sincroniza el conjunto remoto. `DialogueManager` valida el archivo cuando inicia el diálogo y recurre a `fallo.txt` si el guion es inválido.

### Efectos asociados al texto

Una línea de texto puede terminar en un bloque de efectos, por ejemplo `Has elegido bien [xp+30]`. El parser separa el texto de los efectos y `DialogueManager` los aplica únicamente cuando el nodo alcanza la fase de presentación.


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
