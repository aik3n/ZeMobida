# ZeMobida — UI

**Estado:** comportamiento visible vigente.  
**Responsabilidad:** describir la experiencia de interfaz, controles y presentación; no la arquitectura interna.

## Resolución

```text
viewport lógico: 1080 × 1920
orientación: vertical
stretch: canvas_items
aspect: expand
```

El viewport no define el tamaño del mapa.

## Capas de UI

```text
UI normal       → CanvasLayer 5
Diálogo         → CanvasLayer 10
Feedback Player → CanvasLayer 15
Estado          → CanvasLayer 20
Editor guiones  → CanvasLayer 30
```

## Diálogo

- panel del PNJ arriba;
- texto con scroll propio;
- opciones abajo con scroll propio;
- el panel de opciones empieza oculto;
- pulsar el panel de texto muestra/oculta opciones;
- el clic sobre texto no cambia de nodo;
- la rueda sobre los scrolls del diálogo no hace zoom del mapa.

El nombre del PNJ indica procedencia del guion:

```text
gris  → sin específico
verde → oficial
azul  → local
```

## Editor de guiones

`EDITAR` abre el archivo específico:

```text
<mapa_logico>_<pnj>.txt
```

Ejemplo:

```text
aldea_chef.txt
```

El editor usa `CodeEdit`, resaltado sintáctico y un gutter rojo informativo.

```text
[ GUARDAR ]   [ ENVIAR ]   [ CERRAR ]
```

Las marcas rojas no bloquean ninguna acción.

El highlight diferencia comentario, firma, nodo, opción, condición, salto y bloque de efectos.

## Pantalla inicial

- carrusel dinámico de mapas;
- todos los `.tscn` directos de `res://mapas/` son seleccionables;
- actualización de guiones configurable;
- último mapa jugado persistente;
- `Preview` → `Fondo` → imagen por defecto;
- mapa no superado → mostrar `descripcion`;
- mapa superado → mostrar `final` y `res://art/ui/seal.png` sobre el preview;
- el sello se muestra con rotación de `+35°` y sin transparencia añadida.

## Mapa ilustrado

Dirección visual:

```text
imagen de Fondo
+ colisiones
+ actores/objetos dinámicos
+ frontal opcional
```

`Fondo` usa normalmente escala `1:1` y `centered = false`.

Con `Fondo`, sus dimensiones definen los límites de cámara.

Sin `Fondo`, el mapa se considera prototipo pero no se rompe:

```text
X: -1000 .. +1000
Y: -1000 .. +1000
```

## Control

```text
tap                  → mover Player
arrastre             → explorar mapa
pinch                → zoom táctil
rueda                 → zoom escritorio
soltar exploración   → conservar vista
nuevo tap            → mover y recentrar cámara
```

Parámetros actuales del Player:

```text
umbral de arrastre: 28 px
zoom:                0.5 … 1.8
zoom normal:         1.0
recentrado:          0.8 s
```

La posición inicial sigue:

```text
posición guardada
→ SpawnPlayer
→ (0,0)
```

## Feedback del Player

Los cambios reales de inventario generan feedback junto al personaje:

```text
+objeto → positivo
-objeto → negativo
```

Añadir un objeto que ya existe o retirar uno ausente no genera cambio ni escritura adicional.

El feedback vive en `CanvasLayer 15`, por lo que permanece visible durante un diálogo y no cambia de tamaño con el zoom de cámara.

## Estado

El panel global de Estado muestra el inventario y permite:

```text
vaciar inventario
volver a mapas
```

El panel muestra el inventario del mapa activo. La marca reservada `_EOA_` no aparece en la lista ni genera feedback de inventario.

Vaciar inventario afecta sólo al mapa activo y elimina también `_EOA_`, por lo que ese mapa vuelve a considerarse no superado.
