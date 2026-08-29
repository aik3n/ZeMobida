# ZeMobida — Development Guide

**Estado:** sincronización de guiones validada en ejecución el 2026-08-29.  
**Godot:** 4.7.

## Reglas

- El código implementado es la fuente de verdad del comportamiento.
- `guiones/` es contenido versionado.
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

Ante timeout, error de red, descarga o validación, se conserva la caché anterior.

Con `No`, no se contacta con GitHub.

## Regla de actualización segura

```text
descargar → temporal → validar → activar
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

Antes de modificar `guiones/`:
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
