# Guiones ZeMobida

## Objetivo

Los guiones son contenido del juego independiente del código.
El sistema debe permitir crear y modificar conversaciones sin cambiar la implementación de Godot.

## Estructura general

Los guiones se organizan por:

- mapa
- personaje
- nivel lingüístico

El nivel define la complejidad del lenguaje y la función narrativa del diálogo.

Ejemplo de progresión:

- A1: introducción del mundo, personajes y situaciones básicas.
- A2: ampliación de información y contexto.
- B1 y superiores: situaciones más complejas entre personajes.

## Autor del diálogo

Los guiones pueden incluir una línea de autor:

```text
@ Nombre del autor
```

La línea funciona como firma visual y forma parte de la presentación del diálogo.

El parser debe tratar esta información como metadato del guion, no como texto hablado.

## Reglas del formato

El formato debe mantenerse sencillo y legible en texto plano.

Sólo se añadirá nueva sintaxis cuando sea necesaria para resolver una necesidad real.

La prioridad es que una persona pueda crear y revisar guiones fácilmente.

## Herramientas futuras

La creación de guiones puede evolucionar en el futuro hacia herramientas externas al juego, por ejemplo una aplicación web para crear, revisar y proponer contenido.

El juego debe mantener el formato de guion independiente para permitir estas posibles herramientas.
