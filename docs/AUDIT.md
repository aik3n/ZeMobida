# ZeMobida — Technical Audit

**Fecha:** 2026-08-29  
**Estado:** sincronización incremental implementada y validada en ejecución.

## Resultado

La sincronización de guiones ahora incluye:

- `Actualizar guiones al iniciar: Sí / No`;
- manifest local con SHA por archivo;
- descargas incrementales;
- almacenamiento temporal;
- comprobación del conjunto descargado antes de activar;
- conservación de caché anterior ante fallo;
- timeout global configurable de 30 segundos por defecto;
- comprobación antes de permitir entrar al mapa.

La implementación fue probada en ejecución y confirmada como funcional.

## Riesgos pendientes

### Alto — Referencia remota mutable
Actualmente se utiliza `main`.

**Recomendación:** estudiar una referencia inmutable, como commit SHA o release de contenido.

### Alto — Tests automatizados
No existe una suite automatizada completa visible para parser, validator, updater y persistencia.

**Recomendación:** añadir tests headless y CI.

### Alto — Metadatos de distribución
Persisten elementos de prototipo en configuración/exportación.

**Recomendación:** completar identidad, package ID, versión y firma antes de release.

### Medio — Ciclos automáticos
El runtime sigue saltos automáticos recursivamente y el validator no detecta todos los ciclos.

**Recomendación:** detectar ciclos y añadir límite de transiciones.

### Medio — Tablas de XP duplicadas
Los umbrales aparecen en más de un lugar.

**Recomendación:** centralizar configuración.

### Bajo — Acoplamiento al SceneTree
Algunas partes dependen de nombres concretos y búsquedas dinámicas.

**Recomendación:** mejorar contratos si el proyecto crece.

## Estado documental

La documentación actual refleja el comportamiento implementado, incluyendo sincronización por SHA, opción de usuario, timeout, comprobación de integridad del conjunto descargado y fallback a caché.

Los guiones se versionan exclusivamente en `aik3n/ZeMobida_guiones`; `user://dialogues/` es la caché runtime. El repositorio principal ya no contiene la carpeta `guiones/`.


## Selección de mapas — implementación

Se ha sustituido el botón específico de `aldea` por un carrusel instanciado en `bienvenida.tscn`.

### Hechos verificados en código

- `Game` ya no utiliza `ALDEA_SCENE`.
- `bienvenida.gd` emite `jugar(mapa_path)`.
- `Game.gd` recibe la ruta y carga la escena seleccionada.
- `CarruselMapas` descubre `.tscn` directamente en `res://mapas/`.
- Todos los mapas descubiertos son seleccionables.
- El nombre visible deriva del nombre del archivo, quitando `.tscn` y reemplazando `_` por espacios.
- `Preview` es opcional y puede ser `Sprite2D` o `TextureRect`.
- El último mapa se guarda al pulsar `JUGAR`.
- Si el último mapa ya no existe, se selecciona el primero disponible.
- El desplazamiento puede realizarse con botones, teclado y gesto horizontal de ratón.

### Inferencias

La estructura `res://mapas/` permite incorporar nuevas escenas de mapa sin modificar el código del selector, siempre que sean `.tscn` directamente dentro de esa carpeta.

### Validación runtime

La implementación del selector de mapas fue validada manualmente en Godot con los casos descritos en `DEVELOPMENT.md`.

### Riesgos conocidos

**Medio — Descubrimiento limitado a una carpeta**

Actualmente sólo se descubren `.tscn` directamente dentro de `res://mapas/`, no escenas en subcarpetas.

**Recomendación:** mantenerlo así mientras el número de mapas sea manejable; ampliar recursivamente sólo si la organización futura lo requiere.

**Bajo — Preview mediante instanciación temporal**

Para obtener `Preview`, el selector carga e instancia temporalmente la escena del mapa. Esto funciona para el contrato actual, pero puede ser innecesario si los mapas futuros tienen inicialización pesada.

**Recomendación:** si aparece ese problema, sustituirlo por lectura de metadatos o un recurso de preview dedicado.


## Persistencia consolidada — 2026-08-29

**Estado: implementado y validado en ejecución el 2026-08-29.**

Se consolidó la persistencia de preferencias y estado de partida en `user://settings.cfg`. `DialogueManager` guarda XP e inventario en `[player]`, mientras que el updater y el selector de mapas conservan sus secciones `[dialogues]` y `[maps]`. El manifest de guiones continúa separado por ser metadato de sincronización.

No se mantiene compatibilidad con el antiguo `user://save/status.txt`; la especificación vigente utiliza exclusivamente `user://settings.cfg`.

## Nuevo formato de guiones — especificación

La sintaxis basada en `#`, `?`, `>`, `=`, `[ ]` y `'`, junto con la presentación aleatoria de opciones, quedó aprobada en ADR-017 y posteriormente implementada y validada en runtime.


## Nuevo formato de guiones — implementación

La nueva sintaxis ha sido implementada en parser, validator, runtime e interfaz. El contenido narrativo se mantiene ya con esta sintaxis en el repositorio dedicado `aik3n/ZeMobida_guiones`.

Las opciones se presentan en orden aleatorio.

**Estado:** implementación completada y validada manualmente en runtime. No existe avance automático entre nodos. El clic sobre el panel del PNJ sólo muestra u oculta las opciones.

### Corrección de interacción del diálogo

Se eliminó el avance de nodo mediante clic. El panel de texto sólo alterna la visibilidad de las opciones. Se añadió un indicador `▼` visible únicamente cuando el nodo actual contiene opciones. Validado manualmente en runtime.


## Separación del repositorio de guiones

`DialogueUpdater` apunta a `aik3n/ZeMobida_guiones`, rama `main`, leyendo los `.txt` directamente desde la raíz del repositorio.

Se ha eliminado `guiones/` del repositorio principal para evitar dos fuentes de verdad.

La lógica de SHA, manifest, carpeta temporal y fallback a la caché anterior ante fallos de transferencia se mantiene. El updater no valida el contenido de los guiones; `DialogueManager` lo valida al abrirlos y usa `fallo.txt` como fallback.

**Estado:** implementado y validado manualmente en runtime.

## Efectos en texto del PNJ

El formato admite efectos al final de líneas de texto, por ejemplo `Has elegido bien [xp+30]`. El parser los acumula como efectos del nodo y el runtime los ejecuta sólo si el nodo llega a mostrarse, después de resolver condiciones y saltos automáticos.

**Estado:** implementado y validado manualmente en runtime.

### Persistencia visual del panel de opciones

El panel de opciones sólo empieza oculto al iniciar el diálogo. `show_dialogue()` ya no lo cierra en cada cambio de nodo; su estado abierto/cerrado se conserva entre nodos con opciones y se oculta cuando el nuevo nodo no contiene opciones.

**Estado:** implementado y validado manualmente en runtime.


## Revisión profunda del subsistema de diálogo

Se corrigieron dos problemas de estado:

- `show_dialogue()` cerraba el panel de opciones en cada cambio de nodo aunque el nuevo nodo tuviera opciones;
- los botones antiguos permanecían en el contenedor hasta final de frame al regenerar opciones.

También se reforzó la integridad de sincronización: el updater compara el conjunto local/remoto de nombres `.txt` y comprueba que el temporal coincide exactamente con el conjunto remoto antes de sustituir la caché. Esto permite propagar correctamente eliminaciones de archivos remotos sin validar el contenido del guion.

**Estado:** correcciones implementadas y validadas manualmente en runtime.


## Validación runtime final del subsistema de diálogo

Se validó manualmente el comportamiento conjunto del sistema de diálogo tras la revisión profunda:

- el panel de opciones comienza oculto al iniciar el diálogo;
- su estado abierto/cerrado se conserva al cambiar entre nodos que contienen opciones;
- se oculta cuando el nuevo nodo no tiene opciones;
- el indicador `▼` refleja la disponibilidad de opciones;
- el clic sobre el panel del PNJ sólo muestra u oculta las opciones y nunca cambia de nodo;
- las opciones se presentan en orden aleatorio;
- los efectos asociados a opciones y a texto del PNJ se aplican en el momento definido por el formato;
- no existe avance automático entre nodos;
- `DialogueUpdater` valida la integridad de la transferencia y del conjunto de archivos, pero no interpreta el contenido;
- `DialogueManager` valida el guion cuando se inicia y utiliza `fallo.txt` como fallback;
- altas, cambios y eliminaciones de `.txt` remotos se reflejan correctamente en la caché local.

**Estado:** validado manualmente en runtime.
