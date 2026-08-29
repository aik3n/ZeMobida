# ZeMobida — Dialogue Format

## Estado

**Especificación implementada y validada en runtime.**

Esta versión sustituye la sintaxis anterior de opciones numeradas y está implementada en parser, validador, runtime e interfaz.

Los archivos de guion son UTF-8 `.txt`.

## Ubicación

Contenido versionado:

```text
GitHub: aik3n/ZeMobida_guiones
raíz del repositorio: *.txt
```

Caché runtime:

```text
user://dialogues/
```

---

## 1. Regla general

Cada línea se interpreta según su primer carácter.

Si una línea **no empieza** por ninguno de estos caracteres:

```text
# ? > ' = [
```

se considera **texto del PNJ**.

Por tanto, el texto normal no necesita ningún marcador.

---

## 2. Comentarios

El carácter `'` inicia un comentario. Todo lo que aparece desde `'` hasta el final de esa línea se ignora.

Ejemplos:

```text
' comentario de guionista
# INICIO ' comentario de guionista
= Comprar tren > TREN [+tren, xp+5] ' comentario
```

`'` es el único marcador de comentario del formato.

---

## 3. Nodos

El carácter `#` indica que comienza un nodo nuevo.

```text
# INICIO
Hola, aventurero.
```

El texto posterior a `#` es la etiqueta del nodo.

Las etiquetas de nodo se comparan **sin distinguir mayúsculas y minúsculas**. Por ejemplo, `TODO`, `ToDo` y `toDO` hacen referencia al mismo nodo.

---

## 4. Texto del PNJ

Cualquier línea que no empiece por un marcador reservado es texto del PNJ.

```text
# INICIO

Hola, aventurero.
Soy Charo.
¿Quieres comprar algo?
```

El texto pertenece al nodo actual y se presenta siguiendo el flujo normal del diálogo.

---

## 5. Condiciones

El carácter `?` introduce una condición.

Pueden aparecer varias condiciones seguidas en una misma línea y se combinan mediante **AND**.

```text
?avion ?tren > TODO
```

El salto se realiza a `TODO` únicamente si se cumplen `avion` **y** `tren`.

Si una línea de condiciones no tiene una etiqueta de salto después de las condiciones, se ignora:

```text
?avion ?tren
```

---

## 6. Saltos

El carácter `>` indica un salto a otro nodo.

### Salto incondicional

```text
> AGUR
```

Salta directamente al nodo `AGUR`.

### Salto condicionado

Las condiciones aparecen antes del salto:

```text
?avion ?tren > TODO
```

### RANDOM

```text
> RANDOM
```

Selecciona aleatoriamente un nodo distinto del nodo actual.

`RANDOM` es una palabra reservada del formato.

---

## 7. Opciones del jugador

El carácter `=` introduce una opción que se presenta al jugador.

```text
= Comprar avion > AVION
```

El texto posterior a `=` es el texto que verá el jugador.

### Opción sin salto

```text
= No, gracias
```

Si no hay un salto después de la opción, su destino es `null` y seleccionar la opción no cambia de nodo.

### Opción con salto

```text
= Comprar avion > AVION
```

Al seleccionar la opción se salta al nodo `AVION`.

El orden de las opciones en el archivo no tiene significado para su presentación al jugador: **las opciones se muestran en orden aleatorio** cada vez que se presentan.

---

## 8. Efectos

Los efectos se escriben entre `[` y `]` y modifican el estado del inventario y/o la experiencia.

```text
= Comprar avion > AVION [+AvioN, xp+1]
```

Pueden combinarse varios efectos separados por comas:

```text
= Comprar objeto > TIENDA [+objeto, -moneda, xp+5]
```

Los efectos pueden asociarse a una opción o al texto mostrado por un nodo.

Los efectos definidos actualmente son:

- `+item`
- `-item`
- `xp+N`
- `xp-N`

---

### Efectos en texto del PNJ

Los efectos pueden escribirse al final de una línea de texto:

```text
Has elegido bien [xp+30]
Gracias por ayudarme [+llave, xp+5]
```

El bloque `[ ]` no forma parte del texto mostrado. Sus efectos se ejecutan cuando el nodo llega realmente a mostrarse. Si una condición o un salto automático desvía el flujo antes de mostrar el nodo, esos efectos no se ejecutan.

## 9. Flujo entre nodos

La posición física de un nodo dentro del archivo **no provoca avance automático**.

Un nodo permanece activo hasta que una regla cambia explícitamente el destino. El nodo actual sólo cambia mediante:

- una condición cumplida con destino: `?item > DESTINO`;
- un salto: `> DESTINO`;
- `> RANDOM`;
- una opción elegida que tenga destino: `= texto > DESTINO`.

Ejemplo:

```text
# A
Texto A.

# B
Texto B.
```

Entrar en `A` muestra `Texto A.` y permanece en `A`. El motor no avanza automáticamente a `B`.

Una opción sin destino tampoco cambia de nodo:

```text
= No hacer nada
```

Pulsar el panel de texto del PNJ **no cambia de nodo**. Sólo muestra u oculta el panel de opciones.


## 9.1. Panel de opciones

El panel de opciones empieza oculto al iniciar un diálogo.

Cuando el nodo actual contiene opciones:

- aparece el indicador `▼` en el panel de texto del PNJ;
- pulsar el panel de texto muestra u oculta el panel de opciones;
- si el jugador cambia a otro nodo que también tiene opciones, se conserva el estado abierto/cerrado del panel.

Cuando el nodo nuevo no contiene opciones:

- el indicador `▼` se oculta;
- el panel de opciones se oculta.

Ocultar o finalizar el diálogo oculta también el panel de opciones. El clic sobre el panel del PNJ nunca cambia de nodo.



## 10. Ejemplo completo

```text
' texto trivial que sirve de comentario
# INICIO ' comentario de guionista

Hola, aventurero, soy Charo.
Quieres comprar algo.

?avion ?tren > ToDo ' condiciones inventario, salta automáticamente a TODO

= Comprar avion > AVION [+AvioN, xp+1]
= Comprar tren > TREN [+TrEn, xp+5] ' otro comentario de guion

# AVION
Aquí tienes tu bolsa.

= agur > AGUR
= comprar mas > INICIO

# TREN
Aquí tienes tu GUANTE.

= agur > AGUR
= comprar mas > INICIO

# toDO
¡Ya tienes todo!

= Salir > AGUR

# AGUR
Agur.
```

En este ejemplo, `ToDo`, `TODO` y `toDO` representan el mismo nodo.

---

## 11. Reglas de simplicidad

La sintaxis básica queda reducida a:

```text
texto → texto del PNJ
#     → nodo
?     → condición
>     → salto
=     → opción
[ ]   → efectos
'     → comentario
```

No se añaden mecanismos adicionales al formato mientras puedan resolverse con estas reglas.

---

## 12. Validación

La sintaxis anterior define el comportamiento del formato, pero no pretende resolver todavía todos los errores semánticos.

La validación de casos como los siguientes se tratará en el validador:

- opciones duplicadas;
- destinos inexistentes;
- etiquetas inválidas o vacías;
- efectos inválidos;
- otras inconsistencias semánticas.

El formato no incorpora identificadores numéricos para las opciones.

---

## 13. Sincronización

GitHub proporciona un SHA por archivo. El updater compara esos SHA con el manifest local y descarga únicamente archivos nuevos o modificados.

Los cambios se descargan temporalmente. Antes de sustituir la caché, `DialogueUpdater` comprueba que el temporal contiene exactamente el conjunto de archivos `.txt` publicado por GitHub y que la transferencia no ha fallado.

`DialogueUpdater` no parsea ni valida el contenido de los guiones. La validación sintáctica y semántica se realiza en `DialogueManager` cuando se inicia cada diálogo; si falla, se usa `fallo.txt` como fallback.


## 14. Implementación

La sintaxis descrita en este documento está implementada en:

- `godot/scripts/dialogue_parser.gd`
- `godot/scripts/dialogue_validator.gd`
- `godot/scripts/dialogue_manager.gd`
- `godot/scripts/dialogue_ui.gd`

Los guiones se mantienen en el repositorio independiente `aik3n/ZeMobida_guiones`, en la raíz del repositorio.

Las etiquetas de nodo se normalizan para que sean case-insensitive y las opciones se mezclan antes de mostrarse al jugador.

