# ZeMobida — Technical Audit

**Fecha:** 2026-08-29  
**Estado:** sincronización incremental implementada y validada en ejecución.

## Resultado

La sincronización de guiones ahora incluye:

- `Actualizar guiones al iniciar: Sí / No`;
- manifest local con SHA por archivo;
- descargas incrementales;
- almacenamiento temporal;
- validación antes de activar;
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

La documentación actual refleja el comportamiento implementado, incluyendo sincronización por SHA, opción de usuario, timeout, validación previa y fallback a caché.

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

### Pendiente de validación runtime

La implementación debe probarse en Godot con los casos descritos en `DEVELOPMENT.md`. No se considera verificado por una mera revisión estática del código.

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

La lógica de SHA, manifest, carpeta temporal, validación y fallback a `user://dialogues/` no cambia.

**Estado:** implementado y validado manualmente en runtime.
