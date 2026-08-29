# ZeMobida — Dialogue Format

Dialogue files are UTF-8 `.txt` files under `guiones/`.

## Labels

```text
# INICIO
Hola.
```

## Text

Non-empty ordinary lines become dialogue text. Multiple lines are joined.

## Comments

Everything after `--` is ignored by the parser.

## Options

```text
1 Comprar bolsa > BOLSA
2 Salir > FIN
```

## Effects

```text
1 Comprar > FINAL [+bolsa, xp+5]
2 Perder > FINAL [-bolsa, xp-10]
```

Supported effects:

| Syntax | Meaning |
|---|---|
| `+item` | Add item |
| `-item` | Remove item |
| `xp+N` | Add XP |
| `xp-N` | Remove XP |

## Conditions

```text
?llave ?moneda > TIENDA
```

Multiple conditions are AND.

## Automatic jumps

```text
> TARGET
```

Random jump:

```text
> RANDOM
```

## Fallback

```text
<map>_<npc>_<level>.txt
<map>_<npc>.txt
generico.txt
```

## Validation

The current validator checks parser errors and destination existence. It does not yet detect automatic graph cycles, unreachable nodes, duplicate option numbers or deeper semantic content problems.

## Example

```text
# INICIO
Hola.

?llave > PUERTA

1 Comprar > TIENDA [+pocion, xp+5]
2 Salir > FIN

# TIENDA
Aquí tienes tu objeto.

1 Gracias > INICIO

# PUERTA
Puedes pasar.

1 Abrir > FINAL [-llave, xp+10]

# FINAL
Fin.
```
