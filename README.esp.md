# ZeMobida

> Un juego de aventuras y decisiones donde tus conversaciones tienen consecuencias.

**Estado:** prototipo / desarrollo activo  
**Motor:** Godot 4.7  
**Renderizado:** GL Compatibility  
**Licencia:** GNU GPLv3  
**Revisión auditada:** `12ea5386c03d53dd51dae26fd172775e281544f8`

## Descripción

ZeMobida es un videojuego de código abierto desarrollado con Godot y centrado en exploración, interacción con PNJ, diálogos ramificados, inventario, experiencia y decisiones del jugador.

## Funcionalidades actuales

- Mundo 2D explorable (`aldea`).
- `Player` persistente propiedad de `Game`.
- Spawn y límites de cámara por mapa.
- Interacción y seguimiento de PNJ.
- Diálogos ramificados en `.txt`.
- Condiciones de inventario y efectos.
- XP y niveles `a1`, `a2`, `b1`, `b2`, `c1`.
- HUD y estado/inventario global.
- Guardado local en `user://`.
- Sincronización de guiones desde GitHub.
- Parser y validador de diálogos.

## Requisitos

- Godot **4.7**.
- Conexión de red para la sincronización online.
- Presets de Windows Desktop y Android.

## Ejecutar

```bash
git clone https://github.com/aik3n/ZeMobida.git
cd ZeMobida
```

Abre `godot/project.godot` con Godot 4.7 y ejecuta `res://escenas/Game.tscn`.

## Arquitectura

| Componente | Responsabilidad |
|---|---|
| `Game` | Coordinación global, mapas, Player persistente y UI |
| `Player` | Movimiento, XP y nivel |
| `DialogueManager` | Diálogos, efectos, inventario y persistencia |
| `DialogueParser` | Parser de guiones |
| `DialogueValidator` | Validación |
| `DialogueUI` | Presentación |
| `DialogueUpdater` | Sincronización GitHub |
| `PNJ` | Movimiento y diálogos |

Consulta [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Documentación

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/DECISIONS.md`](docs/DECISIONS.md)
- [`docs/DIALOGUE_FORMAT.md`](docs/DIALOGUE_FORMAT.md)
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)
- [`docs/AUDIT.md`](docs/AUDIT.md)

## Hallazgos principales

1. Android tiene Internet desactivado aunque el juego usa HTTP para GitHub.
2. La sincronización depende de la rama mutable `main`.
3. El contenido descargado no se valida completamente antes de activarse.
4. No se detectan ciclos automáticos de diálogo.
5. Persisten valores de prototipo y una ruta local absoluta.
6. El package Android es un placeholder.
7. No se observa una suite automatizada de CI/tests.

## Licencia

GNU GPL v3.0.
