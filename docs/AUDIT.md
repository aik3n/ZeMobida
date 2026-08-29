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


## Backlog de auditoría completa — 2026-08-29

Los siguientes puntos quedan registrados para resolverlos de forma individual.  
La prioridad indica el riesgo técnico actual, no el orden obligatorio de implementación.

### A-01 — Permiso INTERNET en Android
**Prioridad:** Alta  
**Estado:** CERRADO — VALIDADO EN ANDROID

El preset Android tiene `permissions/internet=false`, mientras `DialogueUpdater` utiliza `HTTPRequest` para sincronizar guiones desde GitHub.

**Riesgo:** en Android la sincronización remota puede quedar bloqueada; en una instalación nueva sin caché local podría impedir disponer de guiones.

**Objetivo:** habilitar el permiso de Internet y validar una exportación Android real.

**Implementación:** `permissions/internet=true` en el preset Android.

**Validación:** probado en dispositivo Android con instalación/exportación real. La aplicación descarga los guiones correctamente y muestra `Guiones disponibles`.

---

### A-02 — Protección frente a ciclos automáticos de diálogo
**Prioridad:** Alta  
**Estado:** PENDIENTE

`DialogueValidator` comprueba que los destinos existan, pero no detecta ciclos automáticos como:

```text
# A
> B

# B
> A
```

`DialogueManager.show_node()` sigue estos saltos de forma recursiva.

**Riesgo:** un guion válido estructuralmente puede provocar recursión infinita.

**Objetivo:** añadir una protección simple, preferiblemente un límite de transiciones automáticas por resolución de nodo, y valorar detección de ciclos en el validator.

---

### A-03 — Propiedad del diálogo entre PNJ
**Prioridad:** Alta  
**Estado:** PENDIENTE

Actualmente cualquier PNJ ejecuta `DialogueManager.end_dialogue()` al perder al Player de su `InteractionArea` si existe algún diálogo activo.

**Riesgo:** con áreas solapadas o PNJ móviles, salir del área de un PNJ puede cerrar el diálogo iniciado por otro.

**Objetivo:** asociar el diálogo al PNJ que lo inició o comprobar explícitamente el interlocutor activo antes de cerrarlo.

---

### A-04 — Persistencia inmediata de efectos importantes
**Prioridad:** Media  
**Estado:** PENDIENTE

XP e inventario se guardan actualmente al finalizar el diálogo.

**Riesgo:** un cierre inesperado después de recibir un efecto y antes de finalizar el diálogo puede perder progreso.

**Objetivo:** estudiar guardado tras cambios de XP/inventario o un punto de autosave común, evitando escrituras innecesarias.

---

### A-05 — Tests automatizados y CI
**Prioridad:** Media  
**Estado:** PENDIENTE

No existe una suite automática visible para parser, validator, updater, persistencia y contratos básicos de mapas.

**Objetivo mínimo:**
- tests de `DialogueParser`;
- tests de `DialogueValidator`;
- casos de ciclos y destinos inválidos;
- efectos de texto y opciones;
- persistencia de XP/inventario;
- validación headless de todos los `.txt` de `ZeMobida_guiones`;
- ejecución automática en CI.

---

### A-06 — Limpieza de configuración y metadatos de release
**Prioridad:** Media  
**Estado:** PENDIENTE

Persisten valores de prototipo:
- `config/name="test"`;
- export Windows `test.exe`;
- Android `com.example.$genname`;
- metadatos de versión/producto incompletos;
- ruta local de `movie_writer` dentro de `project.godot`.

**Objetivo:** definir identidad definitiva de aplicación y eliminar rutas/localizaciones específicas de una máquina antes de publicar builds.

---

### A-07 — Referencia mutable a `ZeMobida_guiones/main`
**Prioridad:** Media  
**Estado:** PENDIENTE

`DialogueUpdater` consume directamente la rama `main` del repositorio de guiones.

**Riesgo:** cualquier commit publicado en `main` pasa a ser contenido disponible para jugadores inmediatamente.

**Objetivo:** valorar tags, releases, commit SHA o una versión de contenido configurable cuando se necesiten builds reproducibles.

---

### A-08 — Separar contenido narrativo de prueba y contenido definitivo
**Prioridad:** Baja  
**Estado:** PENDIENTE

El repositorio de guiones contiene todavía textos claramente de prueba o reutilizados entre PNJ.

**Objetivo:** revisar cabeceras, nombres, textos, condiciones y recompensas antes de considerar el contenido narrativo listo para release. Mantener el motor y el contenido editorial como responsabilidades separadas.

---

### A-09 — Control de recompensas repetibles
**Prioridad:** Media  
**Estado:** PENDIENTE

Los efectos de opciones y texto pueden ejecutarse de nuevo si el jugador vuelve a entrar en el mismo flujo de diálogo.

**Riesgo:** XP u objetos pensados como recompensa única pueden farmearse indefinidamente.

**Objetivo:** decidir a nivel de diseño qué recompensas son repetibles. Si se necesitan recompensas únicas, definir una mecánica explícita y simple para representarlo, sin cambiar el comportamiento actual hasta especificarla.

---

### A-10 — Centralizar tabla de niveles/XP
**Prioridad:** Baja  
**Estado:** PENDIENTE

Los umbrales de nivel están duplicados actualmente en `player.gd` y `game.gd`.

**Riesgo:** modificar una copia y olvidar la otra puede producir HUD y nivel real inconsistentes.

**Objetivo:** mantener una única fuente de verdad para niveles y umbrales XP.

---

### A-11 — Reducir acoplamiento por nombres del SceneTree
**Prioridad:** Baja  
**Estado:** PENDIENTE

Existen contratos implícitos mediante nombres como:
- `Player`;
- `SpawnPlayer`;
- `CameraBounds`;
- `CollisionShape2D`;
- nodos concretos de UI.

**Objetivo:** mantener estos contratos mientras el proyecto sea pequeño, pero documentarlos o encapsularlos si empiezan a producir errores al crecer el número de escenas.

---

### A-12 — Valores por defecto de la escena PNJ
**Prioridad:** Baja  
**Estado:** PENDIENTE

La escena base `pnj.tscn` serializa actualmente `nombre = null`.

**Objetivo:** usar un valor por defecto seguro y detectar PNJ sin nombre/configuración al entrar en runtime.

---

### A-13 — Pruebas de UI en diferentes resoluciones
**Prioridad:** Baja  
**Estado:** PENDIENTE

Varias interfaces utilizan offsets absolutos y tamaños fijos.

**Objetivo:** probar como mínimo las resoluciones/aspect ratios objetivo de escritorio y Android y corregir únicamente los casos que produzcan problemas reales.

---

### A-14 — Limpieza de contenido provisional de mapas
**Prioridad:** Baja  
**Estado:** PENDIENTE

Quedan detalles provisionales:
- raíces de varios mapas con nombre `aldea`;
- sprites basados todavía en `icon.svg`;
- previews reutilizados entre mapas;
- diferencias de visibilidad del nodo `Preview`.

**Objetivo:** limpiar estos detalles durante la preparación de contenido final; no requieren refactorización del sistema de mapas.

---

### A-15 — Escalabilidad del descubrimiento de mapas
**Prioridad:** Baja  
**Estado:** PENDIENTE

`CarruselMapas` sólo descubre `.tscn` directamente dentro de `res://mapas/`.

**Objetivo:** mantener el comportamiento actual mientras sea suficiente. Añadir búsqueda recursiva sólo si la organización futura en subcarpetas lo necesita.

---

### A-16 — Instanciación temporal para Preview
**Prioridad:** Baja  
**Estado:** PENDIENTE

El carrusel instancia temporalmente cada escena para obtener el nodo `Preview`.

**Riesgo futuro:** si las escenas de mapa adquieren inicialización pesada, esta operación podría tener coste o efectos secundarios.

**Objetivo:** no cambiar mientras sea ligero; migrar a metadatos/recurso de preview sólo si aparece un problema medible.

---


## Validación Android — 2026-08-29

Se realizó una exportación Android real y una prueba en dispositivo.

Resultados confirmados:

- `DialogueUpdater` puede acceder a GitHub con el permiso `INTERNET`;
- los guiones se descargan y el estado pasa a `Guiones disponibles`;
- `CarruselMapas` descubre los `.tscn` incluidos en la build mediante `ResourceLoader.list_directory()`;
- el carrusel muestra los mapas;
- `JUGAR` carga correctamente el mapa seleccionado.

La funcionalidad base queda validada en Android. La maquetación visual para distintas resoluciones permanece como trabajo separado dentro del backlog.

## Orden inicial recomendado

Para las próximas sesiones, el orden técnico recomendado es:

1. `A-02` — ciclos automáticos;
2. `A-03` — propiedad del diálogo PNJ;
3. `A-04` — persistencia más robusta;
4. `A-05` — tests/CI;
5. resto de puntos según necesidades de contenido y preparación de release.

`A-01` y `A-17` están cerrados tras validación real en Android.

Cada punto debe pasar por el flujo habitual: **especificar → implementar → probar en runtime → actualizar documentación → cerrar estado**.


---

### A-17 — Descubrimiento de mapas en builds exportadas
**Prioridad:** Alta  
**Estado:** CERRADO — VALIDADO EN ANDROID

`CarruselMapas` utilizaba `DirAccess` para enumerar `res://mapas/`. En builds exportadas, Godot puede remapear recursos dentro del PCK y la enumeración mediante `DirAccess` no garantiza devolver los `.tscn` con sus nombres originales.

**Síntoma observado:** en Android los guiones quedan disponibles, pero el carrusel informa que no existen mapas.

**Implementación:** el descubrimiento se realiza ahora mediante `ResourceLoader.list_directory()`, manteniendo el resto del comportamiento sin cambios: sólo `.tscn` directos, orden natural, previews y persistencia del último mapa.

**Validación:** probado en dispositivo Android. Tras sustituir `DirAccess` por `ResourceLoader.list_directory()`, el carrusel muestra los mapas exportados y `JUGAR` carga correctamente el mapa seleccionado.
