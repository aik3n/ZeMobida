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

La configuración y el estado persistente del jugador se almacenan en un único archivo Godot `ConfigFile`:

```text
user://settings.cfg
```

Las secciones tienen responsabilidades separadas:

```text
[dialogues]  → preferencia de actualización de guiones
[maps]       → último mapa jugado
[player]     → XP e inventario
```

`DialogueManager` mantiene la persistencia de XP e inventario, pero comparte el archivo con las preferencias del updater y el último mapa. El manifest de guiones sigue siendo un archivo independiente porque representa metadatos de sincronización, no configuración ni estado de partida.


## Pendientes conocidos

- fijar una referencia remota inmutable en lugar de `main`;
- ampliar validación semántica;
- detectar ciclos automáticos;
- añadir tests automatizados;
- reducir acoplamiento al `SceneTree`;
- centralizar tablas de niveles.


## Selección dinámica de mapas

La selección de mapas está integrada en `bienvenida.tscn` mediante una instancia de:

```text
escenas/carrusel_mapas.tscn
```

El carrusel descubre automáticamente las escenas `.tscn` directamente dentro de:

```text
res://mapas/
```

No existe una lista manual de mapas ni un sistema de bloqueo/desbloqueo. Todos los mapas descubiertos están disponibles para jugar.

Para cada escena:

```text
aldea_ibon.tscn → aldea ibon
```

El nombre mostrado se obtiene eliminando `.tscn` y sustituyendo `_` por espacios. La ruta de la escena es la referencia interna del mapa.

### Preview opcional

Una escena de mapa puede incluir un nodo llamado `Preview`. Si es `Sprite2D` o `TextureRect` y tiene una textura, el carrusel utiliza esa textura como imagen de presentación.

La ausencia de `Preview` no impide seleccionar ni jugar el mapa.

### Último mapa jugado

El carrusel guarda la ruta del mapa cuando el jugador pulsa `JUGAR` y la conserva en `user://settings.cfg`.

Al iniciar la bienvenida:

- si el último mapa todavía existe, queda seleccionado;
- si ya no existe, se selecciona el primer mapa disponible.

No se guarda el índice del carrusel, porque el orden puede cambiar cuando se añaden mapas.

`Game` sigue siendo responsable de cargar la escena. El carrusel sólo comunica la ruta del mapa seleccionado.
