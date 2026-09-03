# ZeMobida — Dialogue Format

## Estado

**Especificación implementada en parser, validador, runtime y editor.**

Los guiones son archivos UTF-8 `.txt`.

Contenido oficial:

```text
aik3n/ZeMobida_guiones
```

Caché runtime:

```text
user://dialogues/
```

Ediciones locales:

```text
user://custom_dialogues/
```

## Nombre del archivo

Cada PNJ de un mapa tiene un único archivo específico:

```text
<mapa_logico>_<pnj>.txt
```

Ejemplo:

```text
aldea_a1.tscn + Chef
→ aldea_chef.txt
```

El nivel lingüístico pertenece al mapa y no crea variantes distintas del guion.

## Regla general

Cada línea se interpreta por su primer carácter.

Si una línea no empieza por un marcador reservado, es texto del PNJ.

Marcadores:

```text
@  firma pública
#  nodo
?  condición
>  salto
=  opción
[ ] efectos
'  comentario
```

## Comentarios

`'` inicia un comentario hasta final de línea:

```text
' comentario
# INICIO ' comentario
= Salir > FINAL ' comentario
```

## Firma pública

Una línea que empieza por `@` define la firma opcional:

```text
@ Nombre del autor
```

La firma se presenta en la UI pero no forma parte del texto hablado ni de los nodos.

La última firma válida encontrada es la utilizada. Una firma vacía es inválida.

## Nodos

`#` inicia un nodo:

```text
# INICIO
Hola.
```

Las etiquetas se normalizan a minúsculas; no distinguen mayúsculas/minúsculas.

## Texto del PNJ

Texto normal:

```text
# INICIO
Hola, aventurero.
Soy Charo.
```

Varias líneas se acumulan como texto del nodo actual.

## Condiciones

`?` comprueba objetos del inventario persistente del mapa activo.

Varias condiciones en la misma línea usan AND:

```text
?llave ?mapa > SALIDA
```

Sólo se salta si están presentes ambos objetos.

Una condición sin destino se ignora.

## Saltos

Salto directo:

```text
> FINAL
```

Salto condicionado:

```text
?llave > PUERTA
```

Aleatorio:

```text
> RANDOM
```

`RANDOM` selecciona un nodo distinto del actual.

## Opciones

`=` crea una opción:

```text
= Abrir la puerta > PUERTA
```

Una opción puede no tener destino:

```text
= No hacer nada
```

En ese caso seleccionar la opción no cambia de nodo.

Las opciones se mezclan antes de mostrarse; su orden físico en el archivo no define el orden visual.

## Efectos

Los efectos se escriben entre `[` y `]`.

Efectos soportados:

```text
+objeto
-objeto
```

### Marca de aventura superada

`__superado__` es un nombre reservado dentro del inventario del mapa.

Para marcar que la aventura actual se ha resuelto:

```text
[+__superado__]
```

No existe un efecto nuevo específico para completar mapas: esta convención utiliza el mismo `+objeto` que cualquier otro efecto.

El runtime guarda la marca con el inventario persistente del mapa, pero la oculta en el panel Estado y no muestra feedback de objeto. El carrusel interpreta su presencia como aventura superada y pasa de `descripcion` a `final`, mostrando además el sello correspondiente.

Como la marca pertenece al inventario, `Vaciar inventario` la elimina también y la aventura vuelve a considerarse no superada.

Ejemplos:

```text
= Coger la llave > PUERTA [+llave]
= Dar la llave > FINAL [-llave]
```

Pueden combinarse:

```text
= Cambiar moneda por llave > FINAL [-moneda, +llave]
```

También pueden aplicarse al texto de un nodo:

```text
Aquí tienes la llave. [+llave]
```

El bloque de efectos no se muestra como texto.

Los efectos de un nodo se ejecutan sólo cuando ese nodo llega realmente a mostrarse. Si una condición o salto automático desvía el flujo antes, no se aplican.

## Flujo

La posición física de los nodos en el archivo no produce avance automático.

El nodo cambia únicamente mediante:

- condición cumplida con destino;
- salto;
- `RANDOM`;
- opción elegida con destino.

Ejemplo:

```text
# A
Texto A.

# B
Texto B.
```

Entrar en `A` no avanza automáticamente a `B`.

Pulsar el panel de texto del PNJ sólo muestra/oculta las opciones; no cambia de nodo.

## Ejemplo completo

```text
@ Ana
' aventura sencilla

# INICIO
He perdido la llave.

?llave > CON_LLAVE

= ¿Dónde la viste por última vez? > PISTA
= Me voy > FINAL

# PISTA
Creo que la dejé junto al pozo.

= He encontrado una llave > ENCONTRADA [+llave]
= Seguir buscando > INICIO

# ENCONTRADA
¡Esa es!

= Devolvértela > FINAL [-llave]

# CON_LLAVE
Ya tienes la llave.

= Devolvértela > FINAL [-llave]

# FINAL
Gracias.
```

## Validación

`DialogueParser` interpreta el texto y `DialogueValidator` comprueba la estructura resultante.

Entre otros casos, se detectan:

- etiquetas vacías o duplicadas;
- destinos inexistentes;
- saltos sin destino;
- opciones sin texto;
- efectos desconocidos o vacíos.

El editor añade además un diagnóstico local por línea mediante un gutter rojo. Ese diagnóstico es informativo: no bloquea `GUARDAR` ni `ENVIAR`.

## Contingencia runtime

Una cadena de condiciones y saltos automáticos admite como máximo 100 transiciones consecutivas.

Si se supera el límite, el runtime detiene la cadena para evitar un bucle que no devuelve el control.

## Sincronización

`DialogueUpdater` sincroniza los `.txt` oficiales hacia `user://dialogues/`.

El updater no parsea ni valida el contenido. La validación ocurre cuando `DialogueManager` inicia el diálogo.

## Regla de simplicidad

El formato se mantiene deliberadamente pequeño. No se añade nueva sintaxis mientras una necesidad real pueda resolverse con las reglas existentes.
