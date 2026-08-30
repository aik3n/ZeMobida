# Prototipo de UI, mapas, control táctil y creador de guiones

**Estado:** maquetación funcional, flujo del mapa piloto y creador local de guiones revisados manualmente en runtime el 2026-08-30.

La sincronización de guiones y el descubrimiento de mapas exportados ya fueron validados previamente en dispositivo Android. El nuevo fondo ilustrado y el control tap/arrastre deben mantenerse dentro de la regresión Android antes de una release.

## Resolución de diseño

- viewport lógico: `1080 × 1920`;
- ventana de prueba de escritorio: `500 × 1000`;
- orientación: vertical;
- stretch: `canvas_items`;
- aspect: `expand`.

El viewport no define el tamaño del mapa. Las localizaciones pueden utilizar ilustraciones de dimensiones y proporciones diferentes.

## Orden de UI

El orden visual global es estático:

```text
HUD / UI normal → CanvasLayer 5
Diálogo         → CanvasLayer 10
Feedback Player → CanvasLayer 15
Estado          → CanvasLayer 20
Editor guiones  → CanvasLayer 30
```

Por ello, abrir Estado durante un diálogo deja la ventana de Estado por encima sin modificar capas dinámicamente.

## Diálogo

- panel del PNJ en la parte superior;
- área de texto con `ScrollContainer`;
- espacio aproximado para cinco líneas antes de desplazar;
- panel de opciones en la parte inferior;
- opciones con scroll propio;
- zona central libre para mantener visible el mapa.


## Edición de guiones durante el diálogo

El panel superior del diálogo incorpora `EDITAR` junto al nombre del PNJ.

```text
IBON                         [EDITAR]
Hola, aventurero...
```

El botón siempre representa el archivo específico del contexto actual:

```text
<mapa>_<pnj>_<nivel>.txt
```

Al pulsarlo, el diálogo se cierra y se abre `DialogueEditor` por encima del resto de UI.

### Editor

El editor ocupa prácticamente toda la pantalla y utiliza `CodeEdit`.

```text
aldea_ibon_a1.txt

┌────────────────────────────┐
│ # INICIO                   │
│ Hola.                      │
│                            │
│ = Salir > FINAL            │
└────────────────────────────┘

[ GUARDAR ]      [ CERRAR ]
```

No existen botones de validar, probar o insertar sintaxis.

El highlight actual diferencia:

```text
' comentario → verde
# nodo       → violeta
= opción     → azul
? condición  → amarillo
> salto      → cyan
[efectos]    → naranja
```

`GUARDAR` escribe el guion local y cierra. `CERRAR` sale sin guardar cambios pendientes. Si la escritura falla, `GUARDAR` no cierra.

La prueba del contenido ocurre al volver al mapa e interactuar de nuevo con el PNJ.

## Pantalla inicial

- selector de mapas adaptado a formato vertical;
- botones táctiles grandes;
- botón toggle escalable `☐ / ☑` para actualizar guiones;
- estado de disponibilidad de guiones;
- selección persistente del último mapa jugado.

## Mapa piloto top-down

La dirección aprobada es:

```text
imagen de fondo + colisiones + elementos dinámicos encima
```

`aldea` es el primer mapa piloto.

Su fondo jugable es:

```text
res://art/mapas/aldea.PNG
```

Se utiliza mediante un `Sprite2D` llamado `Fondo`, a escala `1:1` y con `centered = false`.

La imagen de presentación del carrusel sigue siendo independiente del fondo jugable.

Los límites de cámara se calculan automáticamente desde `Fondo`. Los mapas sin fondo ilustrado pueden seguir usando `CameraBounds`; `aldea` ya no necesita ese nodo.

Las colisiones se construyen en Godot mediante cuerpos estáticos y shapes/polígonos.

La capa `Frontal` se resuelve con un PNG transparente opcional alineado con `Fondo`, dibujado por encima de Player/PNJ. Se descartó el recorte dinámico mediante `Polygon2D` por complejidad innecesaria.

## Control táctil

```text
tocar y soltar       → mover Player
arrastrar            → explorar mapa
pinch                → zoom en móvil
rueda                 → zoom en escritorio
soltar exploración   → conservar posición y zoom
nuevo tap            → mover + restaurar cámara
```

Parámetros actuales:

```text
umbral de arrastre: 28 px
zoom:                0.7 … 1.4
zoom normal:         1.0
recentrado:          0.8 s
Tween:               cubic / ease out, paralelo
```

El destino del nuevo tap se calcula antes del recentrado, por lo que sigue siendo correcto aunque la cámara esté desplazada y con zoom distinto de `1.0`.

Al volver al Player se restauran conjuntamente `camera.position = Vector2.ZERO` y `camera.zoom = Vector2.ONE`.

Un nuevo gesto puede cancelar el recentrado en curso.

El Player persistente sincroniza su destino con `SpawnPlayer` al cargar el mapa, evitando que camine hacia una posición anterior.

El ratón reproduce tap/arrastre con botón izquierdo y zoom con rueda para pruebas de escritorio.

## Feedback del Player

XP e inventario tienen feedback visual inmediato junto al personaje.

```text
positivo → verde → sube
negativo → rojo  → baja
```

Los negativos comienzan algo más abajo que los positivos. Ambos tipos pueden animarse simultáneamente porque utilizan colas independientes.

Parámetros actuales:

```text
duración de cada mensaje: 1.2 s
intervalo por cola:       0.25 s
separación inicial:       60 px entre positivo y negativo
```

Cada mensaje mantiene su propia animación, por lo que varios textos pueden coexistir en pantalla.

La regla funcional es estricta: si XP o inventario no cambian realmente, no aparece ningún mensaje. La restauración de una partida tampoco genera feedback.

El `CanvasLayer 15` permite que el mensaje sea visible durante un diálogo y conserve un tamaño estable aunque la cámara use zoom.

