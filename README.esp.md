# ZeMobida

> Un juego de aventuras y decisiones donde tus conversaciones tienen consecuencias.

**Estado:** prototipo / desarrollo activo  
**Motor:** Godot 4.7  
**Renderizado:** GL Compatibility  
**Licencia:** GNU GPLv3

## Descripción

ZeMobida es un videojuego de código abierto desarrollado con Godot y centrado en exploración, interacción con PNJ, diálogos ramificados, inventario, experiencia y decisiones del jugador.

## Funcionalidades actuales

- Selección dinámica de mapas descubiertos desde `res://mapas/`.
- `Player` persistente propiedad de `Game`.
- `SpawnPlayer` inicial por mapa y restauración posterior de la última posición guardada.
- Regreso al selector de mapas desde el panel global de estado.
- Mapas ilustrados top-down con `Fondo`, `Frontal`, `Preview` y colisiones locales opcionales según el mapa.
- Exploración táctil con tap para mover, arrastre de cámara y pinch zoom.
- Interacción y seguimiento de PNJ.
- Identidad técnica del PNJ derivada del nombre del nodo.
- Sprite del PNJ asignable desde el Inspector mediante una propiedad `Texture2D` exportada y reflejado en `Sprite2D` durante la edición.
- Diálogos ramificados en `.txt` UTF-8.
- Protección runtime frente a cadenas descontroladas de saltos automáticos de diálogo.
- Sincronización de guiones oficiales desde `aik3n/ZeMobida_guiones`.
- Variantes locales por archivo en `user://custom_dialogues/`.
- Editor ligero de guiones dentro del juego con guardado y envío por correo.
- Condiciones de inventario y efectos.
- XP y niveles derivados: `a1`, `a2`, `b1`, `b2`, `c1`, `c2`.
- Persistencia inmediata cuando un efecto de diálogo cambia realmente XP o inventario.
- HUD/estado global y feedback flotante de cambios de XP/inventario.
- Persistencia consolidada en `user://settings.cfg`.

## Requisitos

- Godot **4.7**.
- Conexión de red cuando esté habilitada la sincronización online de guiones.
- Presets de Windows Desktop, Android y Web. Android tiene validación documentada en dispositivo; el preset Web todavía no equivale a soporte de navegador validado.

## Ejecutar

```bash
git clone https://github.com/aik3n/ZeMobida.git
cd ZeMobida
```

Abre `godot/project.godot` y ejecuta `res://escenas/Game.tscn`.

## Arquitectura

| Componente | Responsabilidad |
| --- | --- |
| `Game` | Coordinación global, carga de mapas, Player persistente, posición por mapa y UI |
| `Player` | Movimiento, cámara, XP y nivel derivado |
| `PNJ` | Movimiento/seguimiento, inicio de diálogo y presentación del sprite en edición |
| `DialogueManager` | Runtime de diálogo, efectos, inventario, resolución local/oficial y persistencia |
| `DialogueParser` | Interpreta el formato de guiones |
| `DialogueValidator` | Validación estructural runtime actual |
| `DialogueUI` | Presentación del diálogo |
| `DialogueUpdater` | Sincronización de guiones oficiales |
| `CarruselMapas` | Descubrimiento y selección dinámica de mapas |

Consulta [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Documentación

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/AUDIT.md`](docs/AUDIT.md)
- [`docs/DECISIONS.md`](docs/DECISIONS.md)
- [`docs/DECISIONS_RECENT.md`](docs/DECISIONS_RECENT.md)
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)
- [`docs/DIALOGUE_FORMAT.md`](docs/DIALOGUE_FORMAT.md)
- [`docs/MAP_PACKS_FUTURE.md`](docs/MAP_PACKS_FUTURE.md)
- [`docs/UI_PROTOTYPE.md`](docs/UI_PROTOTYPE.md)

Los guiones oficiales se versionan exclusivamente en `aik3n/ZeMobida_guiones`; `user://dialogues/` es la caché runtime y `user://custom_dialogues/` contiene las variantes locales. Desde el editor, `ENVIAR` guarda primero la versión local y después prepara un correo a `zemobida@gmail.com` mediante la aplicación de correo del jugador.

## Estado técnico

El proyecto sigue en fase de prototipo. Entre los principales puntos pendientes están tests/CI, metadatos de release, una referencia reproducible para el contenido remoto y decisiones aún abiertas sobre recompensas de diálogo repetibles.

Consulta [`docs/AUDIT.md`](docs/AUDIT.md).

## Licencia

GNU GPL v3.0.
