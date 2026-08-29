# ZeMobida — Development Guide

**Estado:** sincronización de guiones validada en ejecución el 2026-08-29. El subsistema de diálogo y su interacción de opciones también fueron validados en runtime tras la revisión final.  
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
