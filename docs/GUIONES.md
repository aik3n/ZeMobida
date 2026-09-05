# Guiones ZeMobida

**Responsabilidad:** diseño de aventuras y criterios para quien escribe contenido. La sintaxis exacta pertenece a [`DIALOGUE_FORMAT.md`](DIALOGUE_FORMAT.md).

## Propósito

ZeMobida busca que comprender un idioma sirva para **hacer cosas dentro de una aventura**.

El idioma no es una asignatura que el juego examine desde fuera. Es la herramienta con la que el jugador entiende a otras personas, descubre información, interpreta una situación, toma decisiones y consigue resolverla.

El progreso ocurre cuando haber comprendido una conversación cambia lo que el jugador sabe, puede preguntar, puede hacer o puede conseguir.

La pregunta de diseño no es:

> ¿Qué ejercicio lingüístico debe superar el jugador?

sino:

> ¿Qué necesita comprender y utilizar para resolver esta movida?

## Ambición

ZeMobida aspira a crecer como una colección de aventuras pequeñas e independientes, cada una centrada en una situación concreta, un lugar, unos personajes y un nivel lingüístico.

Cada mapa debería poder jugarse como una historia breve con identidad propia. El núcleo del juego se mantiene deliberadamente sencillo para que la variedad venga de las situaciones, las conversaciones y sus consecuencias, no de acumular sistemas.

Las aventuras deben ser fáciles de probar, repetir y crear. Añadir contenido debería significar principalmente imaginar una buena movida, construir el mapa y escribir conversaciones, sin exigir programación al autor.

La profundidad de ZeMobida debe venir del **contexto**: entender quién dice qué, qué significa en esa situación y qué cambia cuando el jugador actúa en consecuencia.

## Principios de diseño

- **El idioma sirve para actuar.** Una conversación debe poder abrir posibilidades, cerrar dudas, entregar pistas, cambiar relaciones o permitir decisiones.
- **Comprender importa más que traducir.** Una frase puede ser entendida palabra por palabra y aun así interpretarse mal dentro de la situación.
- **Cada aventura tiene una movida clara.** Debe existir un problema, deseo, misterio o situación que el jugador pueda explicar en una frase.
- **La progresión es contextual.** Objetos, pistas y flags representan lo que ha ocurrido o lo que el jugador ha descubierto; no existe una progresión numérica del Player.
- **El gameplay físico permanece sencillo.** Moverse y explorar sirven para conectar conversaciones y situaciones; no compiten con ellas por ser la mecánica principal.
- **Equivocarse puede formar parte de comprender.** Una decisión incoherente puede producir una rama distinta, pero se evitan bloqueos permanentes accidentales.
- **El nivel lingüístico pertenece a la aventura.** El mapa define la dificultad del lenguaje y debe mantener una exigencia razonablemente coherente.
- **Crear aventuras debe seguir siendo accesible.** El formato de guion y las herramientas de autoría deben poder utilizarlos personas que no programan.

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
[+_EOA_]
```

`_EOA_` no es un objeto narrativo para el jugador. Se guarda en el inventario persistente del mapa, pero no se muestra en Estado ni genera feedback visual.

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

Sólo se añade sintaxis cuando resuelve una necesidad real. El contrato completo y normativo está en [`DIALOGUE_FORMAT.md`](DIALOGUE_FORMAT.md).
