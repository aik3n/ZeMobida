# ZeMobida — Dialogue Format

Los diálogos son archivos UTF-8 `.txt`.

## Ubicación

Contenido versionado:

```text
guiones/
```

Caché runtime:

```text
user://dialogues/
```

## Nodos

```text
# INICIO
Hola.
```

## Opciones

```text
1 Comprar > COMPRA
2 Salir > FIN
```

El número forma parte del texto del guion, pero actualmente no es un identificador único utilizado por el runtime. Deben evitarse números duplicados por claridad editorial.

## Efectos

```text
1 Comprar > FINAL [+pocion, xp+5]
2 Perder > FINAL [-pocion, xp-10]
```

Soportados: `+item`, `-item`, `xp+N`, `xp-N`.

## Condiciones

```text
?llave ?moneda > TIENDA
```

## Saltos

```text
> DESTINO
```

`RANDOM`:

```text
> RANDOM
```

selecciona actualmente un nodo distinto del actual dentro del diálogo.

## Resolución

```text
<mapa>_<npc>_<nivel>.txt
<mapa>_<npc>.txt
generico.txt
```

## Sincronización

GitHub proporciona un SHA por archivo. El updater compara esos SHA con el manifest local y descarga únicamente archivos nuevos o modificados.

Los cambios se descargan temporalmente, se validan y sólo después se activan.

## Limitaciones actuales

El validator no garantiza todavía:
- ausencia de ciclos automáticos;
- ausencia de nodos inalcanzables;
- unicidad de números de opción;
- ausencia de todas las inconsistencias semánticas.
