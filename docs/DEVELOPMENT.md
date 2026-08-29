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
