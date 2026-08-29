# ZeMobida — Architecture

**Estado:** implementación actual validada en ejecución el 2026-08-29.  
**Godot:** 4.7.

## Modelo

```text
Game
├── Player persistente
├── HUD / estado
├── DialogueUI
└── mapa actual
    ├── PNJ
    ├── SpawnPlayer
    └── CameraBounds

DialogueManager (autoload)
├── parser
├── validator
├── runtime de diálogo
├── inventario
└── persistencia

DialogueUpdater (autoload)
└── GitHub → user://dialogues/
```

`Game` coordina mapas, Player y UI global. `DialogueManager` ejecuta diálogos y actualmente también gestiona inventario y persistencia.

## Contenido

- `guiones/`: contenido de diálogo versionado en el repositorio.
- `user://dialogues/`: caché local utilizada por el runtime.

GitHub es la fuente de actualización. La caché local permite continuar jugando cuando GitHub no está disponible.

## Sincronización

La opción de usuario es:

```text
Actualizar guiones al iniciar: Sí / No
```

Con `Sí`, antes de permitir entrar al mapa se consulta GitHub, se obtiene el `sha` de cada archivo y se compara con el manifest local. Sólo se descargan archivos nuevos o modificados.

Los cambios se descargan temporalmente y se validan antes de activar la nueva colección. Si hay error o timeout, se conserva la caché anterior.

El timeout global es configurable y vale `30.0` segundos por defecto.

Con `No`, no se consulta GitHub y se utiliza la caché local.

## Manifest

El manifest representa los SHA de la colección realmente activa. Esto permite conservar archivos sin cambios, descargar sólo cambios y detectar archivos nuevos o eliminados.

## Resolución

```text
<mapa>_<npc>_<nivel>.txt
        ↓
<mapa>_<npc>.txt
        ↓
generico.txt
```

## Persistencia

```text
user://save/status.txt
```

XP determina el nivel y el inventario forma parte del estado persistente.

## Pendientes conocidos

- fijar una referencia remota inmutable en lugar de `main`;
- ampliar validación semántica;
- detectar ciclos automáticos;
- añadir tests automatizados;
- reducir acoplamiento al `SceneTree`;
- centralizar tablas de niveles.
