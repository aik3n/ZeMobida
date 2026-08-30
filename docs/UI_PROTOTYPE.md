# Prototipo de UI, mapas y control táctil

**Estado:** maquetación funcional y flujo del mapa piloto validados manualmente en runtime el 2026-08-30.

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
Estado          → CanvasLayer 20
```

Por ello, abrir Estado durante un diálogo deja la ventana de Estado por encima sin modificar capas dinámicamente.

## Diálogo

- panel del PNJ en la parte superior;
- área de texto con `ScrollContainer`;
- espacio aproximado para cinco líneas antes de desplazar;
- panel de opciones en la parte inferior;
- opciones con scroll propio;
- zona central libre para mantener visible el mapa.

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

Los límites de cámara se calculan automáticamente desde `Fondo`. Los mapas sin fondo ilustrado pueden seguir usando `CameraBounds`.

Las colisiones y la capa gráfica `Frontal` son el siguiente paso del mapa piloto; todavía no se consideran terminadas.

## Control táctil

```text
tocar y soltar       → mover Player
arrastrar            → explorar mapa
soltar arrastre      → mantener cámara desplazada
nuevo tap            → mover + recentrado suave
```

Parámetros actuales:

```text
umbral de arrastre: 28 px
recentrado:          0.38 s
Tween:               cubic / ease out
```

El destino del nuevo tap se calcula antes del recentrado, por lo que sigue siendo correcto aunque la cámara esté desplazada.

Un nuevo gesto puede cancelar el recentrado en curso.

El ratón reproduce el mismo comportamiento para pruebas de escritorio.
