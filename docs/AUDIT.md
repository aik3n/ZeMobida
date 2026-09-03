# ZeMobida — Technical Audit

> **Nota de vigencia (2026-09-03):** este documento conserva contexto histórico.  
> Para el comportamiento actual consultar `ARCHITECTURE.md`, `DEVELOPMENT.md`, `GUIONES.md` y `DIALOGUE_FORMAT.md`.  
> Las decisiones antiguas sobre progresión del Player, variantes de guion por nivel y límites alternativos de cámara quedaron supersedidas.


**Revisión:** 2026-09-01  
**Base GitHub revisada:** `bb3f058e68a24140375e8b28fb9fb282bef50a4c` (`mejoras y bug fix`).  
**Estado:** prototipo funcional; deuda localizada. No se recomienda una reescritura general.

## Resumen

La arquitectura se mantiene coherente y deliberadamente sencilla:

- `Game` conserva un único Player persistente.
- mapas dinámicos dentro de `SceneContainer`;
- niveles/XP centralizados;
- identidad técnica de PNJ basada en el nombre del nodo;
- identidad técnica de mapa derivada del nombre de escena y normalizada a minúsculas;
- sprite de PNJ configurable desde Inspector con reflejo `@tool`;
- diálogo oficial/local separado;
- sincronización remota con temporal + backup;
- persistencia consolidada en `user://settings.cfg`;
- persistencia inmediata cuando un efecto modifica realmente XP o inventario;
- regreso global al selector de mapas;
- posición independiente recordada por mapa;
- envío voluntario de guiones locales mediante la aplicación de correo del jugador.

Los dos riesgos altos de diálogo revisados anteriormente quedan resueltos sin ampliar la arquitectura: A-02 mediante una contingencia runtime y A-03 aceptado por diseño.

El commit `bb3f058` cierra además A-04, A-18 y A-19 con cambios pequeños en `DialogueManager`, `Game` y `PNJ`: guardado inmediato de efectos reales, nivel de diálogo fijado al comenzar la conversación y normalización a minúsculas del identificador técnico de mapa.

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

### Persistencia inmediata de efectos

`DialogueManager._apply_effects()` distingue entre intentar un efecto y producir un cambio real.

Sólo cuando XP o inventario cambian realmente se guarda de inmediato la sección `[player]` de `user://settings.cfg`. Añadir un objeto ya existente, retirar uno inexistente o aplicar XP sin variación efectiva no provoca un guardado innecesario.

`end_dialogue()` deja de ser el punto del que depende la persistencia de recompensas.

### Nivel estable para el archivo del editor

Al comenzar un diálogo, `DialogueManager` conserva el nivel actual del Player en `current_dialogue_level`.

Si un efecto modifica XP y el Player cambia de nivel durante esa misma conversación, `EDITAR` continúa apuntando al archivo exacto correspondiente al nivel con el que comenzó el diálogo.

### ID técnico de mapa normalizado

`Game._get_map_id()`, `PNJ.get_map_name()` y el cálculo del archivo objetivo del editor usan el basename de la escena normalizado con `.to_lower()`.

Ejemplo:

```text
Arauzo_de_salce.tscn → arauzo_de_salce
```

No se renombra físicamente la escena. La normalización evita que posición persistente y nombres de guion dependan de diferencias de mayúsculas/minúsculas entre plataformas.

### Preset Web y empaquetado Windows

`export_presets.cfg` incorpora un preset Web y el preset Windows pasa a exportar con PCK embebido. Esto amplía la configuración disponible, pero no equivale a una validación funcional Web: la validación de dispositivo documentada sigue siendo Android.

## Backlog actual

### A-01 — Permiso INTERNET en Android
**Prioridad:** Alta  
**Estado:** CERRADO — VALIDADO

Android exporta con permiso de Internet y la sincronización remota fue probada en dispositivo.

---

### A-02 — Protección frente a ciclos automáticos de diálogo
**Prioridad:** Alta  
**Estado:** CERRADO — VALIDADO EN RUNTIME

`DialogueManager.show_node()` limita a `100` las transiciones automáticas consecutivas dentro de una misma cadena de ejecución.

Las transiciones automáticas se recorren iterativamente, sin recursión entre nodos. Al intentar superar el límite:

- se detiene la cadena;
- se escribe un mensaje normal en Output;
- no se muestran opciones ni se aplican efectos del nodo de contingencia;
- el diálogo permanece activo con el panel abierto y `EDITAR` disponible.

Así el jugador no queda bloqueado y quien esté probando el guion puede abrir el editor y corregirlo inmediatamente.

Una elección del jugador inicia una nueva cadena y, por tanto, un nuevo conteo. Los ciclos que requieren intervención del jugador siguen siendo válidos.

No se añade análisis de grafos ni un validator adicional: Parser interpreta, Validator comprueba la estructura y Runtime garantiza la contingencia de ejecución.

---

### A-03 — Propiedad del diálogo entre PNJ
**Prioridad:** Alta (evaluación original)  
**Estado:** ACEPTADO POR DISEÑO — NO ACTUAR

Cualquier PNJ puede cerrar un diálogo activo al detectar que el Player sale de su `InteractionArea`, incluso si otro PNJ inició ese diálogo.

En el ritmo actual del juego se acepta este comportamiento: un cierre accidental no bloquea progreso y el jugador puede acercarse de nuevo al PNJ deseado.

No se añade propiedad explícita del diálogo ni complejidad adicional mientras este comportamiento no produzca un problema real de jugabilidad.

---

### A-04 — Persistencia inmediata de efectos importantes
**Prioridad:** Media  
**Estado:** CERRADO — IMPLEMENTADO EN `bb3f058`

Cada conjunto de efectos guarda inmediatamente el estado de Player cuando existe una variación real de XP o inventario.

Los efectos sin cambio real no disparan escritura. `end_dialogue()` ya no es necesario para consolidar la recompensa de un efecto aplicado.

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

Existen presets de Windows Desktop, Android y Web; Windows utiliza actualmente PCK embebido. Persisten valores de prototipo en outputs, package ID, versión y otros metadatos.

El preset Web existe como configuración, pero todavía no hay una validación funcional Web documentada equivalente a la realizada en Android.

Resolver los metadatos y la validación de las plataformas objetivo antes de distribución real.

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
**Estado:** CERRADO — IMPLEMENTADO EN `bb3f058`

`start_dialogue()` captura el nivel del Player al comenzar la conversación. El editor utiliza ese valor estable para construir `<mapa>_<pnj>_<nivel>.txt`.

Un efecto que cambie XP/nivel durante el diálogo ya no cambia el archivo objetivo de `EDITAR`.

---

### A-19 — Normalización del ID técnico de mapa
**Prioridad:** Media  
**Estado:** CERRADO — IMPLEMENTADO EN `bb3f058`

El identificador técnico de mapa se deriva del basename de la escena y se normaliza con `.to_lower()` en los puntos que lo consumen para posición persistente y diálogos.

Ejemplo:

```text
Arauzo_de_salce.tscn → arauzo_de_salce
```

No se añade una capa de IDs separada ni se exige renombrar inmediatamente las escenas existentes.

**Compatibilidad del prototipo:** no existe migración automática de claves `[map_positions]` ni de archivos locales creados anteriormente con un prefijo de mapa que conservara mayúsculas. Si se necesitara conservar datos de testers anteriores a `bb3f058`, habría que tratar esa migración explícitamente.

---

### A-20 — Deriva de documentación
**Prioridad:** Media  
**Estado:** CERRADO CON REVISIÓN 2026-09-01

Se actualiza la documentación vigente para reflejar el comportamiento de `bb3f058`: A-04/A-18/A-19, preset Web, persistencia por mapa y flujo actual del editor.

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

---

### A-24 — Ciclo de vida de guiones oficiales y locales
**Prioridad:** Media  \
**Estado:** PENDIENTE DE DISEÑO

El flujo de participación en guiones ha puesto de manifiesto una cuestión conceptual que todavía no está resuelta.

Flujo real:

```text
guion oficial
→ jugador pulsa EDITAR
→ guarda una copia local
→ prueba y puede ENVIAR la propuesta
→ la propuesta se revisa externamente
→ puede publicarse tal cual o con modificaciones
→ el juego descarga posteriormente una nueva versión oficial
```

Actualmente una copia exacta en `user://custom_dialogues/` tiene prioridad sobre el archivo oficial equivalente en `user://dialogues/`.

Esto permite probar inmediatamente una edición local, pero también puede provocar que el jugador siga utilizando indefinidamente su copia aunque exista posteriormente una versión oficial nueva.

No se modifica todavía esta política. Quedan abiertos dos debates independientes.

#### Qué significa que local y oficial sean el mismo guion

La igualdad byte a byte puede ser demasiado estricta para texto narrativo.

Dos archivos podrían ser funcionalmente equivalentes aunque cambien elementos no interpretados por runtime, por ejemplo:

```text
comentarios '
líneas vacías
espacios de formato irrelevantes
```

Debe decidirse si la comparación futura será:

```text
igualdad exacta de archivo
```

o una:

```text
igualdad funcional / normalizada
```

Si se adopta una normalización, debe apoyarse sólo en reglas ya compatibles con el parser y evitar alterar texto narrativo significativo.

También debe considerarse que los comentarios pueden ser irrelevantes para runtime pero útiles para quien está editando, por lo que una coincidencia funcional no implica necesariamente que sea correcto borrar automáticamente la copia local.

#### Puede caducar o perder prioridad un guion local

No está decidido si una copia local debe:

```text
mantener prioridad indefinidamente
```

```text
perder prioridad cuando aparece una versión oficial nueva
```

```text
caducar según alguna regla
```

o si el sistema debe permitir alternar explícitamente entre oficial y local manteniendo ambos.

Una caducidad basada únicamente en tiempo no se considera decidida ni implícitamente aceptada: el paso del tiempo no demuestra por sí mismo si una propuesta sigue siendo útil, fue rechazada o continúa en revisión.

Tampoco puede inferirse de forma fiable que una nueva versión oficial signifique que la propuesta local fue aceptada, rechazada o moderada, porque el envío se realiza mediante correo y no existe un backend de estados.

#### Alcance inmediato: sólo feedback visual

Antes de resolver el ciclo de vida se implementará únicamente una señal visual mínima sobre la versión que está usando el diálogo:

```text
halo verde
→ se está usando el guion oficial

halo azul
→ se está usando una copia local
```

`EDITAR` permanece siempre disponible. No se intenta detectar quién tiene o no un rol de guionista: cualquier jugador puede decidir participar pulsando `EDITAR`.

No se añaden etiquetas permanentes `OFICIAL` / `LOCAL`, evitando ruido visual y dependencia innecesaria del idioma.

El halo informa únicamente de la procedencia activa del guion. No implica por sí mismo estados editoriales como:

```text
pendiente
aceptado
rechazado
moderado
```

Esos estados no pueden conocerse de forma fiable con la arquitectura actual.

La prioridad, alternancia, eliminación, posible acción `VOLVER A OFICIAL` y criterio de equivalencia entre archivos quedan expresamente fuera de este cambio y deberán cerrarse en una decisión posterior.

### A-23 — Un archivo remoto inválido puede bloquear toda la sincronización
**Prioridad:** Media  \
**Estado:** PENDIENTE DE DISEÑO

Se ha comprobado un caso real en `ZeMobida_guiones`: un archivo `.txt` con un nombre no utilizable en todas las plataformas puede impedir que se active una actualización que contiene otros guiones correctos.

Ejemplo observado:

```text
fwd: aldea_limpiador_a2.txt
```

El carácter `:` no es válido en nombres de archivo de Windows.

El comportamiento actual del updater es deliberadamente atómico:

```text
listar .txt remotos
→ preparar carpeta temporal
→ copiar/descargar todos
→ comprobar que el conjunto temporal coincide con el remoto
→ sólo entonces sustituir la caché activa
```

Si uno de los `.txt` no puede guardarse en la carpeta temporal:

```text
un archivo falla
→ sync_failed
→ se descarta el temporal completo
→ se conserva user://dialogues/ anterior
```

Esta política protege contra una caché parcialmente actualizada, pero actualmente cualquier archivo remoto terminado en `.txt` se considera parte obligatoria de la colección. Como consecuencia, un archivo con nombre accidental, incompatible con la plataforma o ajeno al convenio de guiones puede bloquear la actualización de todos los demás.

El problema a debatir no es si mantener la actualización atómica; esa propiedad sigue siendo valiosa. La decisión pendiente es **qué archivos del repositorio deben considerarse guiones oficiales sincronizables**.

Opciones a valorar:

1. filtrar antes de sincronizar y aceptar sólo nombres compatibles con el convenio técnico de guiones;
2. ignorar nombres no admitidos y emitir un warning;
3. considerar cualquier nombre inválido un error editorial del repositorio y mantener el bloqueo global;
4. introducir otra regla explícita de publicación si aparece una necesidad real.

Una posible convención mínima sería admitir únicamente nombres formados por caracteres portables, por ejemplo:

```text
a-z
0-9
_
.txt
```

pero **esta regla no está aceptada todavía** y no debe implementarse hasta cerrar el debate.

La validación del nombre y la validación del contenido son responsabilidades distintas. Aunque se adopte un filtro de nombres, `DialogueUpdater` no debería empezar a interpretar la sintaxis narrativa; Parser/Validator seguirían siendo responsables del contenido cuando el guion se utiliza.

Caso que originó el punto:

```text
casco_viejo_juan_a1.txt
→ archivo correcto y descargable

fwd: aldea_limpiador_a2.txt
→ nombre no portable

resultado actual
→ la colección temporal no puede completarse
→ Juan tampoco llega a activarse en la caché local
```

## Observaciones adicionales

### Seguimiento PNJ

El movimiento de seguimiento es directo hacia el Player y no usa navegación. Puede atascarse con obstáculos complejos. No añadir `NavigationAgent` hasta comprobar que los mapas reales lo necesitan.

### ID de mapa y posición persistente

La posición se guarda usando el nombre base normalizado a minúsculas de la escena como clave. Renombrar un archivo de mapa continúa creando, de hecho, una nueva identidad para esa posición guardada.

La normalización evita diferencias de case entre plataformas, pero el cambio introducido en `bb3f058` no migra claves antiguas que conservaran mayúsculas. Lo mismo aplica a variantes locales de diálogo cuyo nombre utilizara el ID antiguo.

Durante el prototipo puede aceptarse la pérdida de esa compatibilidad. Si se decide preservar datos anteriores, debe resolverse mediante una migración pequeña y explícita, no mediante una segunda fuente de identidad.

### PCK / ZIP externos — experimento cerrado

Se probó la carga de mapas externos mediante resource packs PCK y ZIP.

La prueba funcional fue válida, pero se descartó su incorporación al
prototipo: todos los packs comparten el mismo `res://`, de modo que dos
proyectos independientes pueden exportar rutas iguales y entrar en
conflicto sin que sus autores sean conscientes.

No se añade un sistema de namespaces, reescritura de paquetes ni otra capa
de aislamiento. El runtime vuelve a utilizar exclusivamente
`res://mapas/`.

El experimento queda registrado en `MAP_PACKS_FUTURE.md` y no forma parte
del backlog activo.

## Orden de trabajo recomendado

1. Debatir A-09 antes de introducir semántica de recompensas de un solo uso.
2. Tests/CI mínimos cuando el núcleo deje de cambiar con tanta frecuencia.
3. Metadatos, validación de plataformas y versionado de contenido al acercarse a distribución.
4. Mantener A-03 sin cambios salvo que aparezca un problema real de jugabilidad.

No se recomienda abordar varios puntos a la vez si no existe dependencia entre ellos.
