# Guiones ZeMobida

## Idea central

ZeMobida son aventuras cortas por mapa que se resuelven comprendiendo y utilizando un idioma.

El gameplay principal no consiste en acumular estadísticas: consiste en entender conversaciones, obtener información, tomar decisiones y usar objetos/pistas para resolver la movida del mapa.

Flujo conceptual:

```text
gancho
→ exploración
→ conversaciones ramificadas
→ pistas / información / objetos
→ nuevas posibilidades
→ resolución
→ cierre del mapa
```

Una respuesta incorrecta puede ser lingüísticamente válida pero incoherente con el contexto. Esa rama puede servir como evidencia de que el jugador no comprendió la conversación.

Principio:

> En ZeMobida avanzas demostrando que has comprendido las conversaciones, no contestando preguntas sobre ellas.

## Nivel lingüístico

El nivel pertenece al mapa, no al Player.

Se expresa en el nombre de la escena:

```text
aldea_a1.tscn
casa_encerrada_a2.tscn
tesoro_b1.tscn
```

Marcadores reconocidos:

```text
_a1  _a2  _b1  _b2  _c1  _c2
```

Si no aparece ninguno, el mapa tiene nivel `?`.

El nivel orienta la dificultad lingüística de toda la aventura. No selecciona variantes de guion durante la partida.

## Organización de archivos

Los guiones oficiales viven en:

```text
aik3n/ZeMobida_guiones
```

Cada PNJ usa:

```text
<mapa_logico>_<pnj>.txt
```

El mapa lógico elimina el marcador de nivel de la escena:

```text
aldea_a1.tscn + chef
→ aldea_chef.txt
```

Por tanto, una escena tiene una identidad completa para persistencia (`aldea_a1`) y un nombre lógico de contenido (`aldea`).

## Autor

Un guion puede incluir:

```text
@ Nombre del autor
```

La firma se muestra de forma discreta durante el diálogo y no forma parte del texto hablado.

## Estado narrativo

El formato permite usar el inventario también como estado narrativo:

```text
+pista_del_pozo
-llave
?perro_encontrado > FINAL
```

Para quien escribe el guion, objetos y pistas usan la misma sintaxis sencilla.

Cada mapa mantiene su propio inventario persistente. Al entrar en una aventura, las condiciones y efectos del guion trabajan únicamente con el inventario de ese mapa.

Para indicar que la aventura está resuelta se usa una marca reservada:

```text
[+__superado__]
```

`__superado__` no es un objeto narrativo para el jugador. Se guarda en el inventario persistente del mapa, pero no se muestra en Estado ni genera feedback visual.

Mientras la marca no exista, el carrusel muestra `descripcion`. Cuando existe, muestra `final` y el sello de aventura superada.

Vaciar el inventario del mapa elimina también esta marca y devuelve la aventura al estado no superado.

Este alcance no cambia la sintaxis general que utiliza quien escribe el guion: la marca aprovecha el efecto `+objeto` ya existente.

## Diseño de una aventura

Una aventura debería poder describirse con una pregunta o problema claro:

```text
¿Cómo vas a salir de aquí?
¿Dónde está el perro perdido?
¿Quién tiene la dentadura?
¿Dónde está el tesoro?
```

La misión no necesita un sistema tradicional de quests. Surge del gancho del mapa y de cómo sus guiones están organizados.

El guionista debería pensar principalmente:

> ¿Qué tiene que comprender, preguntar, decidir o deducir el jugador para resolver la movida?

Se evitan bloqueos permanentes accidentales. Reintentar una conversación o descubrir otra pista es preferible a dejar una aventura irresoluble por una única elección.

## Regla de simplicidad

Los guiones son texto plano y deben poder escribirlos personas que no programan.

Sólo se añade sintaxis cuando resuelve una necesidad real. El formato completo está documentado en `DIALOGUE_FORMAT.md`.
