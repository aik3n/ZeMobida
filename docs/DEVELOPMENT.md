# ZeMobida — Development Guide

**Estado:** guía de trabajo vigente.  
**Godot:** 4.7.x.  
**Responsabilidad:** explicar cómo desarrollar, modificar y comprobar ZeMobida sin duplicar contratos técnicos de otros documentos.

## Reglas de trabajo

- El código ejecutado es la fuente de verdad del comportamiento.
- Antes de cambiar un subsistema, revisar su implementación actual.
- Preferir el cambio mínimo que resuelva una necesidad real.
- No introducir compatibilidad, abstracciones o frameworks preventivos.
- Los guiones oficiales viven únicamente en `aik3n/ZeMobida_guiones`.
- `user://dialogues/` es caché oficial.
- `user://custom_dialogues/` contiene guiones locales y nunca lo modifica el updater.
- Una actualización fallida nunca destruye una caché oficial válida.

## Creación de mapas

Flujo normal:

```text
duplicar un mapa válido
→ renombrar <aventura>_<nivel>.tscn
→ cambiar Fondo
→ editar descripcion
→ editar final
→ añadir/editar PNJ y colisiones
```

Los niveles reconocidos en el nombre son:

```text
_a1  _a2  _b1  _b2  _c1  _c2
```

Si no se reconoce ninguno, el nivel mostrado del mapa es `?`.

`Fondo` es esperado en un mapa terminado. Sin `Fondo`, el mapa sigue funcionando como prototipo con límites de cámara `-1000 .. +1000` en ambos ejes.

`SpawnPlayer` es opcional. Sin posición guardada, se usa `SpawnPlayer` si existe y después `(0,0)`.

## Guiones

El archivo específico de un PNJ es:

```text
<mapa_logico>_<pnj>.txt
```

Ejemplo:

```text
aldea_a1.tscn
Chef
→ aldea_chef.txt
```

La parte de nivel de la escena no forma parte del nombre del guion.

Prioridad:

```text
user://custom_dialogues/<mapa>_<pnj>.txt
→ user://dialogues/<mapa>_<pnj>.txt
→ user://dialogues/generico.txt
```

El nombre técnico del PNJ es el nombre de su nodo en minúsculas.

### Editor

`EDITAR` abre exactamente `<mapa>_<pnj>.txt`.

Si existe versión local, carga la local. Si no, usa la oficial como copia de trabajo. Si tampoco existe específica, abre el boceto.

Acciones:

```text
GUARDAR → escribe local y cierra
ENVIAR  → guarda primero y abre mailto:
CERRAR  → cierra sin guardar cambios pendientes
```

El gutter rojo es informativo y no bloquea guardar o enviar.

Colores del nombre del PNJ:

```text
gris  → sin guion específico
verde → oficial
azul  → local
```

## Formato de guion

El contrato técnico del lenguaje vive únicamente en [`DIALOGUE_FORMAT.md`](DIALOGUE_FORMAT.md).

Esta guía no duplica sus reglas. Si se modifica parser, validator, runtime o editor, los cuatro deben seguir interpretando el mismo formato y la regresión manual debe comprobar el cambio en ejecución.

La marca de fin de aventura forma parte de ese contrato y actualmente se escribe:

```text
[+_EOA_]
```

## Sincronización

Con actualización activada:

```text
GitHub
→ comparar SHA/manifest
→ descargar a temporal
→ comprobar conjunto
→ activar
```

Timeout global actual: `30.0` segundos.

Ante error de red, timeout, descarga incompleta, escritura o sustitución fallida, se conserva la caché anterior.

`DialogueUpdater` no valida sintaxis. Esa validación ocurre al cargar cada diálogo.

## Persistencia

Archivo:

```text
user://settings.cfg
```

Estado actual:

```text
[dialogues]         preferencia del updater
[maps]              último mapa
[map_positions]     posición por mapa
[map_inventories]   inventario por mapa
```

Al cargar una escena de mapa se carga el inventario del mapa que se acaba de cargar, usando su ID completo, por ejemplo `aldea_a1`.

El inventario se guarda cuando un efecto produce un cambio real. Vaciarlo afecta sólo al mapa activo.

El estado de aventura superada no tiene una sección propia: se deriva de la presencia de `_EOA_` en el inventario persistente del mapa. Vaciar el inventario elimina también esa marca.

La posición del Player usa el mismo ID completo de escena, pero posición e inventario se almacenan en secciones distintas.

No se migran ni se eliminan automáticamente entradas antiguas o pertenecientes a mapas que ya no existan.

## Output y errores

Mensajes propios de ZeMobida:

```text
Output → print()
```

Warnings/errors internos de Godot:

```text
Debugger
```

No se introduce un framework de logging.

Los fallos críticos propios pueden hacerse visibles con varios `print()` claros. No se pretende convertir todos los `push_error()` históricos en esta guía.

## Regresión manual mínima

Después de cambios en mapas/diálogo comprobar:

- bienvenida y carrusel;
- mapa con `Fondo`;
- mapa sin `Fondo`;
- restauración de posición;
- diálogo oficial;
- diálogo local;
- fallback `generico.txt`;
- `EDITAR` sobre el archivo correcto;
- guardar local y volver a interactuar;
- inventario `+objeto` / `-objeto`;
- `[+_EOA_]`, persistencia y reinicio al vaciar inventario;
- carrusel: `descripcion` antes de superar y `final` + sello después;
- volver a mapas con diálogo abierto;
- rueda sobre paneles de diálogo sin zoom del mapa;
- tap, arrastre y zoom de cámara.

Las pruebas siguen siendo manuales y centradas en la experiencia real; no existe un framework de tests obligatorio.
