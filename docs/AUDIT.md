# ZeMobida — Technical Audit

**Revisión:** 2026-08-31  
**Base GitHub revisada:** `411e173221f6462c46be8444d7aa1a4788b76cc3` más la función `ENVIAR` del editor validada inmediatamente después en runtime.  
**Estado:** prototipo funcional; deuda localizada. No se recomienda una reescritura general.

## Resumen

La arquitectura se mantiene coherente y deliberadamente sencilla:

- `Game` conserva un único Player persistente.
- mapas dinámicos dentro de `SceneContainer`;
- niveles/XP centralizados;
- identidad técnica de PNJ basada en el nombre del nodo;
- sprite de PNJ configurable desde Inspector con reflejo `@tool`;
- diálogo oficial/local separado;
- sincronización remota con temporal + backup;
- persistencia consolidada en `user://settings.cfg`;
- regreso global al selector de mapas;
- posición independiente recordada por mapa;
- envío voluntario de guiones locales mediante la aplicación de correo del jugador.

Las prioridades altas pendientes continúan concentradas en robustez del runtime de diálogo, no en la arquitectura general.

## Cambios cerrados desde la auditoría anterior

### Niveles centralizados

`res://scripts/niveles.gd` es la fuente de verdad de los niveles `a1` a `c2`. Se elimina la necesidad de mantener umbrales duplicados.

### Identidad técnica del PNJ

El nombre del nodo de la instancia es la identidad técnica. No existe un `nombre` exportado redundante.

### Sprite del PNJ

Se recuperó una propiedad exportada `Texture2D` por ergonomía del editor. `@tool` refleja la textura en el `Sprite2D` interno; el creador del mapa sigue eligiendo manualmente el recurso y la lógica de gameplay no se ejecuta en el editor.

Esto también resuelve la incompatibilidad de escenas que todavía serializaban `sprite = ...`.

### Tamaños/colisiones

Se sustituyeron las colisiones circulares por cápsulas ajustadas al arte actual:

```text
Player: cuerpo       radio 21, altura 150
PNJ: cuerpo          radio 20, altura 152
PNJ: interacción     radio 22, altura 160
```

### Navegación a selección de mapas

`VOLVER A MAPAS` vive dentro del panel `ESTADO`, propiedad de `Game`. No se duplica código en cada mapa.

Un diálogo activo se cierra antes de salir. La salida se bloquea mientras el editor de diálogos está abierto.

### Posición persistente por mapa

`SpawnPlayer` es el punto inicial/fallback. Tras visitar un mapa, se restaura la última posición guardada.

Las posiciones se conservan en `[map_positions]` dentro de `user://settings.cfg` y se guardan al abandonar el mapa, en cierre normal de ventana y al pausar la aplicación.

El botón Stop del editor puede matar externamente el proceso y no se considera una ruta de cierre fiable.


### Envío de guiones locales

El editor incorpora `ENVIAR` junto a `GUARDAR` y `CERRAR`.

Contrato validado:

```text
ENVIAR
→ guardar primero en user://custom_dialogues/
→ si falla el guardado, no abrir correo
→ si funciona, preparar mailto: a zemobida@gmail.com
→ mantener abierto el editor
```

El asunto contiene el nombre del archivo y el cuerpo contiene el texto exacto guardado. No se incluyen credenciales ni se conecta directamente con Gmail/SMTP. El usuario confirma o cancela el envío desde su propia aplicación de correo.


## Backlog actual

### A-01 — Permiso INTERNET en Android
**Prioridad:** Alta  
**Estado:** CERRADO — VALIDADO

Android exporta con permiso de Internet y la sincronización remota fue probada en dispositivo.

---

### A-02 — Protección frente a ciclos automáticos de diálogo
**Prioridad:** Alta  
**Estado:** PENDIENTE

`DialogueManager.show_node()` sigue condiciones/saltos automáticos recursivamente. Un ciclo automático puede producir recursión indefinida.

Los ciclos que requieren seleccionar opciones del jugador no son el mismo problema y pueden ser intencionados.

**Siguiente solución preferida:** límite runtime sencillo de transiciones automáticas antes que análisis de grafos complejo.

---

### A-03 — Propiedad del diálogo entre PNJ
**Prioridad:** Alta  
**Estado:** PENDIENTE

Cualquier PNJ puede cerrar un diálogo activo al detectar que el Player sale de su `InteractionArea`.

**Riesgo:** áreas solapadas o PNJ móviles pueden cerrar el diálogo iniciado por otro PNJ.

**Objetivo:** registrar el interlocutor propietario del diálogo y permitir que sólo él lo cierre por salida de área.

---

### A-04 — Persistencia inmediata de efectos importantes
**Prioridad:** Media  
**Estado:** PENDIENTE DE DECISIÓN

XP/inventario se guardan normalmente al terminar diálogo. Un cierre inesperado justo después de un efecto puede perder ese cambio.

La nueva persistencia de posición no resuelve este caso; son responsabilidades diferentes.

---

### A-05 — Tests automatizados y CI
**Prioridad:** Media  
**Estado:** PENDIENTE

No existe suite automática ni workflow CI.

Smoke test de alto valor futuro:

- cargar todos los mapas;
- verificar instanciación;
- comprobar contrato mínimo;
- validar todos los guiones oficiales;
- tests de parser/validator/efectos/persistencia.

No se propone una infraestructura grande mientras el proyecto siga en prototipo.

---

### A-06 — Configuración y metadatos de release
**Prioridad:** Media  
**Estado:** PENDIENTE

Persisten valores de prototipo en nombre de aplicación, outputs/presets, package ID y metadatos.

Resolver antes de distribución real.

---

### A-07 — Referencia mutable a `ZeMobida_guiones/main`
**Prioridad:** Media  
**Estado:** PENDIENTE

Una actualización publicada en `main` puede ser consumida por builds antiguos.

Antes de releases reproducibles valorar tag, commit SHA o canal/versionado de contenido.

---

### A-08 — Contenido narrativo provisional
**Prioridad:** Baja  
**Estado:** PENDIENTE

El repositorio de guiones contiene textos/recompensas claramente provisionales. Mantener la limpieza editorial separada del motor.

---

### A-09 — Recompensas repetibles
**Prioridad:** Media  
**Estado:** PENDIENTE DE DISEÑO

Los efectos pueden volver a ejecutarse al repetir un flujo.

No debe introducirse una mecánica “one-shot” hasta decidir qué recompensas deben ser repetibles y cómo se representa esa intención.

---

### A-10 — Centralizar tabla de niveles/XP
**Prioridad:** Baja  
**Estado:** CERRADO

Fuente única: `res://scripts/niveles.gd`.

Niveles actuales: `a1`, `a2`, `b1`, `b2`, `c1`, `c2`.

---

### A-11 — Acoplamiento por nombres del SceneTree
**Prioridad:** Baja  
**Estado:** ACEPTADO POR AHORA

Existen contratos como `Player`, `SpawnPlayer`, `Fondo`, `CameraBounds` y nodos concretos de UI.

Para el tamaño actual del proyecto la simplicidad compensa. Encapsular sólo si empieza a generar fallos reales.

---

### A-12 — `nombre` por defecto en PNJ
**Prioridad:** Baja  
**Estado:** SUPERADO / CERRADO

La propiedad exportada `nombre` ya no forma parte del modelo. La identidad técnica procede del nombre del nodo.

---

### A-13 — Pruebas de UI en múltiples resoluciones
**Prioridad:** Baja  
**Estado:** PENDIENTE

Conviene validar HUD, diálogo, editor, Estado y gestos en varias relaciones de aspecto/dispositivos antes de release.

---

### A-14 — Limpieza de contenido provisional de mapas
**Prioridad:** Baja  
**Estado:** PENDIENTE

Varios mapas/assets continúan siendo de prueba. No es deuda del motor.

---

### A-15 — Descubrimiento de mapas limitado a una carpeta
**Prioridad:** Baja  
**Estado:** PENDIENTE SÓLO SI ESCALA

`CarruselMapas` descubre `.tscn` directamente dentro de `res://mapas/`, sin subcarpetas.

Mantener mientras sea suficiente.

---

### A-16 — Preview mediante instanciación temporal del mapa
**Prioridad:** Baja  
**Estado:** PENDIENTE SÓLO SI ESCALA

El carrusel carga/instancia temporalmente la escena completa para obtener `Preview`, por lo que también resuelve dependencias del mapa.

Con pocos mapas es aceptable. Cambiar sólo si aparecen costes de memoria/carga.

---

### A-17 — Mapas con propiedad `sprite` antigua
**Prioridad:** Alta  
**Estado:** CERRADO POR CAMBIO DE MODELO

La propiedad exportada `sprite: Texture2D` vuelve a existir y es el mecanismo oficial de configuración en editor.

Las escenas que serializan `sprite = ...` vuelven a ser válidas. No se usa `Editable Children` como flujo normal.

---

### A-18 — Nivel objetivo del editor puede cambiar durante un diálogo
**Prioridad:** Media  
**Estado:** PENDIENTE

Si el diálogo comienza en un nivel y un efecto cambia XP/nivel antes de pulsar `EDITAR`, el nombre del archivo objetivo se calcula actualmente con el nivel del Player en ese momento.

Antes de corregirlo hay que fijar semántica. Solución simple probable: recordar el nivel/archivo exacto asociado al inicio del diálogo.

---

### A-19 — Normalización del ID técnico de mapa
**Prioridad:** Media  
**Estado:** PENDIENTE

El identificador de mapa se deriva del nombre del archivo. `Arauzo_de_salce.tscn` conserva mayúscula inicial mientras PNJ se normaliza a minúsculas.

En sistemas sensibles a mayúsculas esto puede afectar nombres de guion y claves de posición.

**Dirección simple recomendada:** convención de nombres de archivo de mapa en minúsculas + guiones bajos, en lugar de añadir lógica compleja.

---

### A-20 — Deriva de documentación
**Prioridad:** Media  
**Estado:** CERRADO CON REVISIÓN 2026-08-31

Se actualizan README, arquitectura, auditoría y decisiones recientes para reflejar niveles centralizados, identidad/sprite PNJ, colisiones, navegación y posición por mapa.

---

### A-21 — Integridad byte a byte / escalabilidad del updater
**Prioridad:** Media-Baja  
**Estado:** PENDIENTE

El updater compara SHA remotos con el manifest, pero cuando considera un archivo sin cambios reutiliza el archivo local sin recalcular su Git blob SHA.

Por tanto, “integridad” significa actualmente integridad del conjunto/transferencia, no verificación criptográfica de cada byte local.

Además, la estrategia API Contents + descarga por archivo es adecuada para el corpus pequeño actual, no necesariamente para cientos de archivos.

---

### A-22 — Orden de profundidad de actores top-down
**Prioridad:** Media-Baja  
**Estado:** PENDIENTE DE PRUEBA VISUAL

No existe `y_sort_enabled` ni otra regla explícita general de profundidad entre Player y PNJ.

Primero probar cruces reales delante/detrás. Implementar Y-sort sólo si el resultado visual es incorrecto.

## Observaciones adicionales

### Seguimiento PNJ

El movimiento de seguimiento es directo hacia el Player y no usa navegación. Puede atascarse con obstáculos complejos. No añadir `NavigationAgent` hasta comprobar que los mapas reales lo necesitan.

### ID de mapa y posición persistente

La posición se guarda usando el nombre base de la escena como clave. Renombrar un archivo de mapa crea, de hecho, una nueva identidad para esa posición guardada.

Esto es coherente con el modelo actual, pero refuerza la conveniencia de estabilizar la convención técnica de nombres de mapa.

### PCK / separación futura de mapas

La propuesta de proyectos independientes y `.pck` está documentada en `MAP_PACKS_FUTURE.md`.

No forma parte del runtime actual y no debe condicionar el desarrollo inmediato.

## Orden de trabajo recomendado

1. A-03 — propiedad del diálogo entre PNJ.
2. A-02 — límite simple de transiciones automáticas.
3. Debatir A-18, A-09 y A-04 antes de implementar.
4. Tests/CI mínimos cuando el núcleo deje de cambiar con tanta frecuencia.
5. Metadatos/versionado de contenido al acercarse a distribución.

No se recomienda abordar varios puntos a la vez si no existe dependencia entre ellos.
