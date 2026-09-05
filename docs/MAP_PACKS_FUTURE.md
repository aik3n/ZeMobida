# ZeMobida — Experimento histórico de mapas externos

**Estado:** cerrado / descartado.  
**Responsabilidad:** conservar únicamente la conclusión de un experimento ya realizado para no repetir la investigación.

## Qué se probó

Se investigó y probó la carga de mapas desarrollados en proyectos Godot
independientes y distribuidos como paquetes `.pck` y `.zip` mediante:

```gdscript
ProjectSettings.load_resource_pack()
```

La carga funcionó y permitió comprobar que mapas internos y externos podían
ser descubiertos y ejecutados.

También se probó mantener la identidad técnica del mapa separada del nombre
de su escena para diálogos y persistencia.

## Problema encontrado

Los resource packs montados por Godot comparten el mismo espacio virtual:

```text
res://
```

Dos proyectos independientes pueden exportar, sin saberlo, rutas idénticas:

```text
res://aldea.tscn
res://fondo.png
res://personajes/juan.png
```

Al montar ambos paquetes esas rutas entran en conflicto. El problema no
depende de usar PCK o ZIP: ambos utilizan el mismo sistema de recursos.

Evitarlo de forma garantizada exigiría alguna de estas concesiones:

- imponer a todos los diseñadores un namespace interno único;
- reescribir/reubicar automáticamente recursos y referencias del paquete;
- aceptar que unos paquetes puedan sustituir recursos de otros;
- introducir una arquitectura de carga más compleja.

Ninguna de esas opciones compensa en la fase actual del prototipo.

## Decisión actual

ZeMobida **no carga mapas externos**.

Los mapas forman parte del proyecto principal y se descubren directamente en:

```text
res://mapas/
```

El sistema actual se mantiene deliberadamente sencillo.

El experimento PCK/ZIP queda documentado para no repetir la investigación,
pero no constituye una funcionalidad prevista ni un compromiso de
arquitectura futura.

Si Godot incorpora en el futuro aislamiento o namespaces nativos para
resource packs, o si las necesidades de producción cambian de forma
sustancial, el tema podrá reevaluarse desde cero.
