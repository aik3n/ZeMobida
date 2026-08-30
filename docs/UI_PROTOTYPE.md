# Prototipo de maquetación Android

Base funcional: `c0253d1980960a169fa23ba3ebc2d252511e000c`.

Estado: **prototipo pendiente de validación visual en dispositivo**.

## Resolución de diseño

- viewport lógico: `1080 × 1920`;
- orientación: vertical;
- stretch: `canvas_items`;
- aspect: `expand`.

## Zonas maquetadas

- pantalla inicial y selector de mapas;
- botones táctiles del carrusel;
- preferencia de actualización como botón toggle escalable;
- HUD de nivel/XP;
- panel de estado/inventario;
- panel de diálogo;
- panel y botones de opciones.

La lógica de mapas, persistencia, updater y flujo de diálogo se mantiene. Los cambios están centrados en presentación y tamaños táctiles.

## Previews del prototipo

Para que este paquete sea autocontenido, los cinco mapas usan temporalmente `res://icon.svg` como textura de `Preview`. Las imágenes definitivas pueden restaurarse después sin modificar la lógica del carrusel.
