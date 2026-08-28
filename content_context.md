# CONTEXTO MAESTRO DEL PROYECTO — ZeMobida

VERSIÓN ACTUAL: 13

ESTADO: v12 estable cerrada. v13 en desarrollo.

Este documento es la fuente de contexto para continuar el desarrollo del proyecto en futuras conversaciones.

El código actual de v13 es la fuente de verdad frente a versiones anteriores de este documento.

==================================================

1. ESTADO GENERAL DEL PROYECTO
   ==================================================

Proyecto realizado en Godot 4.7.

La arquitectura actual separa:

* Gestión general del juego: game.gd
* Pantalla inicial: bienvenida.tscn + bienvenida.gd
* Mapas cargados dinámicamente mediante game.gd
* Player: player.gd
* PNJ: pnj.gd
* Sistema de diálogos: DialogueManager
* Interfaz de diálogo: dialogue_ui.gd
* Parser de guiones: DialogueParser
* Validador de guiones: DialogueValidator
* Sincronización de guiones desde GitHub: DialogueUpdater
* UI global de estado dentro de Game/UI

==================================================
2. ESCENAS PRINCIPALES
======================

game.tscn

Nodo raíz:

Game
├── SceneContainer
└── UI
└── Estado
└── Panel
├── Titulo
├── Nivel
├── Progreso
├── BarraXP
├── Inventario
└── Cerrar
└── BotonEstado

Game utiliza game.gd.

SceneContainer contiene dinámicamente la escena actualmente cargada.

UI es un CanvasLayer permanente que pertenece a Game.

==================================================
3. BIENVENIDA
=============

bienvenida.tscn utiliza bienvenida.gd.

Estructura actual:

Inicio
├── PanelGeneral
└── PanelCargaEscenas
└── btn_Aldea

PanelGeneral:

* Siempre permanece habilitado.
* No participa en el bloqueo de sincronización.
* En el futuro puede contener botones que deban permanecer siempre interactivos.

PanelCargaEscenas:

* Contiene actualmente los botones que cargan escenas.
* Se bloquea mientras DialogueUpdater está sincronizando/preparando los guiones.
* Se habilita cuando los guiones ya están disponibles.
* En el futuro puede contener más botones para cargar mapas/escenas.

==================================================
4. SINCRONIZACIÓN DE GUIONES Y BIENVENIDA
=========================================

Durante el arranque, DialogueUpdater prepara los guiones.

Mientras el proceso no haya terminado:

PanelCargaEscenas permanece deshabilitado.

PanelGeneral permanece habilitado.

IMPORTANTE:

No se bloquea toda la escena de bienvenida.

Solo se bloquea PanelCargaEscenas.

Esto permite que en el futuro existan elementos interactivos independientes de la carga de mapas.

---

## 4.1 guiones_disponibles

DialogueUpdater tiene:

var guiones_disponibles: bool = false

Su significado es:

"el juego ya dispone de guiones utilizables y puede continuar".

Por tanto:

guiones_disponibles = false

significa que todavía se está preparando/sincronizando el contenido.

guiones_disponibles = true

significa que el juego ya puede continuar con los guiones disponibles.

Esto ocurre tanto si:

* GitHub funciona correctamente y se descargan los nuevos guiones.
* GitHub falla y se conservan los guiones locales.
* La sustitución de la carpeta falla y se conserva el estado local anterior.

---

## 4.2 sync_failed

DialogueUpdater mantiene también:

var sync_failed: bool = false

sync_failed y guiones_disponibles son conceptos diferentes.

sync_failed:

* Indica si la sincronización con GitHub ha fallado.

guiones_disponibles:

* Indica si el juego tiene contenido de diálogo utilizable y puede continuar.

Ejemplo:

GitHub falla:

sync_failed = true
guiones_disponibles = true

El juego continúa utilizando los guiones locales.

---

## 4.3 Señal de disponibilidad

DialogueUpdater dispone de una señal:

signal guiones_disponibles_changed

Cuando los guiones pasan a estar disponibles:

guiones_disponibles = true

y se emite:

guiones_disponibles_changed.emit()

bienvenida.gd escucha esta señal para habilitar PanelCargaEscenas.

==================================================
5. GAME.GD — SISTEMA DE ESCENAS
===============================

game.gd define:

const BIENVENIDA_SCENE := "res://escenas/bienvenida.tscn"
const ALDEA_SCENE := "res://escenas/aldea.tscn"

La bienvenida se carga inicialmente.

Al pulsar el botón de bienvenida se emite la señal jugar y se carga aldea.tscn.

La arquitectura está preparada para añadir otros mapas en el futuro.

---

## 5.1 Visibilidad de la UI global

REGLA CERRADA:

La UI global NO depende de que el mapa sea aldea.

La condición utilizada es:

ui.visible = scene_path != BIENVENIDA_SCENE

Por tanto:

bienvenida.tscn:
UI oculta.

cualquier otra escena:
UI visible.

Esta decisión queda cerrada y no debe modificarse salvo que se decida explícitamente una nueva arquitectura.

---

## 5.2 cargar_escena()

game.gd:

* Elimina los hijos actuales de SceneContainer.
* Establece mapa_actual.
* Determina la visibilidad de la UI.
* Carga e instancia la nueva escena.
* Si no es bienvenida, guarda la instancia como mapa_actual.
* Añade la instancia a SceneContainer.
* Si no es bienvenida, carga el estado del jugador.
* Conecta la señal jugar si la escena la tiene.

==================================================
6. PANEL DE ESTADO
==================

La UI global contiene:

UI
├── Estado
│   └── Panel
│       ├── Titulo
│       ├── Nivel
│       ├── Progreso
│       ├── BarraXP
│       ├── Inventario
│       └── Cerrar
│
└── BotonEstado

BotonEstado tiene actualmente el texto:

INV

El Panel de Estado empieza oculto.

Al pulsar INV:

* Se consulta el estado actual del Player.
* Se actualiza nivel.
* Se actualiza XP.
* Se actualiza inventario.
* Se muestra el panel.

Al cerrar:

* El panel simplemente se oculta.

---

## 6.1 Regla de actualización

REGLA CERRADA:

El inventario NO necesita actualizarse mientras el panel está oculto.

La actualización del estado es bajo demanda, al abrir el panel.

La XP y el nivel mostrados por este panel también se leen al abrirlo.

No se mantienen sincronizados continuamente mientras el panel está oculto.

Esta decisión queda cerrada.

IMPORTANTE:

Esta regla corresponde al Panel de Estado de la UI global implementada en game.gd.

No debe confundirse con la UI provisional de nivel/XP que existe actualmente dentro de dialogue_ui.gd.

---

## 6.2 Datos mostrados

Nivel:

player.nivel

Se muestra en mayúsculas.

Experiencia:

player.xp

Progreso:

Actualmente muestra:

XP: 35 / 70

La ProgressBar representa el progreso dentro del nivel actual.

Inventario:

Se obtiene directamente de:

DialogueManager.inventory

Cada objeto se muestra en una línea.

Si no hay objetos:

Inventario vacío

==================================================
7. INVENTARIO
=============

El inventario pertenece actualmente a DialogueManager:

var inventory: Array[String] = []

Los objetos se almacenan en minúsculas.

Métodos existentes:

has_item()
add_item()
remove_item()

Los diálogos pueden modificar el inventario mediante:

[+objeto]
[-objeto]

Las condiciones de diálogo pueden comprobar objetos.

El Panel de Estado lee:

DialogueManager.inventory

y muestra los objetos mediante el Label Inventario.

IMPORTANTE:

Si se modifica el sistema de inventario, revisar conjuntamente:

* DialogueManager
* PNJ
* diálogos
* Panel de Estado
* guardado/carga

==================================================
8. XP Y NIVELES
===============

player.gd contiene:

signal xp_changed

@export_enum("a1", "a2", "b1", "b2", "c1")
var nivel: String = "a1"

@export var xp: int = 0

Límites:

const NIVELES := {
"a1": 70,
"a2": 120,
"b1": 340,
"b2": 410,
"c1": 740
}

Orden:

const ORDEN_NIVELES := [
"a1",
"a2",
"b1",
"b2",
"c1"
]

add_xp():

* Modifica XP.
* Recalcula nivel.
* Emite xp_changed.

El máximo actual de XP es:

740

---

## 8.1 Atención futura

Las tablas NIVELES y ORDEN_NIVELES están duplicadas actualmente en:

* player.gd
* game.gd
* dialogue_ui.gd

No es un error actual.

Es un punto de mantenimiento futuro.

Si se modifica el sistema de niveles, hay que revisar las tres implementaciones.

IMPORTANTE:

DialogueManager NO posee una variable XP propia.

DialogueManager aplica los efectos de XP sobre Player.

El estado de XP y nivel pertenece a Player.

==================================================
9. GUARDADO
===========

DialogueManager guarda:

user://save/status.txt

Actualmente se guardan:

xp=...
inventory=...

El guardado se realiza al terminar un diálogo.

Al cargar un mapa, game.gd ejecuta:

DialogueManager.load_player_status()

Después de cargar el estado, el Player recupera:

* XP
* nivel
* inventario

==================================================
10. DIALOGUEMANAGER
===================

DialogueManager es un Autoload.

Gestiona:

* diálogo activo
* nodo actual
* archivo de diálogo
* speaker
* datos parseados
* inventario
* parser
* validator
* efectos
* condiciones
* saltos
* RANDOM
* aplicación de XP
* guardado/carga

Los diálogos se encuentran en:

user://dialogues/

Si un diálogo no existe o contiene errores, se intenta cargar:

user://dialogues/fallo.txt

IMPORTANTE:

DialogueManager no permite iniciar un segundo diálogo mientras ya existe uno activo.

Si:

dialogue_active == true

una nueva llamada a start_dialogue() se ignora.

==================================================
11. FORMATO DE DIÁLOGOS
=======================

DialogueParser reconoce:

Etiquetas:

#inicio

Texto:

Las líneas normales forman el texto del nodo.

Condiciones:

?objeto > nodo

Las condiciones múltiples requieren todos los objetos indicados.

Ejemplo:

?llave ?guante > TODO

Saltos:

> nodo

También existe:

> RANDOM

RANDOM es un comportamiento intencionado.

Selecciona aleatoriamente otro nodo disponible distinto del nodo actual.

Opciones:

1 Texto de la opción > siguiente

Efectos:

[+objeto]
[-objeto]
[xp+20]
[xp-10]

Ejemplo:

1 Completar misión > siguiente [xp+20]

IMPORTANTE:

> RANDOM y RANDOM utilizado como destino de una opción no deben considerarse automáticamente equivalentes.

El comportamiento actualmente implementado distingue entre ambos casos.

==================================================
12. DIALOGUEVALIDATOR
=====================

Comprueba:

* estructura de nodos
* existencia de text
* existencia de conditions
* existencia de options
* existencia de jump
* destinos de condiciones
* destinos de saltos
* destinos de opciones
* errores generados por el parser

El Parser crea normalmente los campos estructurales básicos de los nodos.

El Validator mantiene comprobaciones defensivas sobre esos campos y sobre los destinos.

No modificar sin necesidad.

Forma parte del sistema actual de validación.

No modificar DialogueParser o DialogueValidator sin comprobar compatibilidad con los diálogos existentes.

==================================================
13. DIALOGUE_UI.GD
==================

Existe una UI de diálogo independiente.

Actualmente contiene:

* nombre del personaje
* texto
* opciones
* nivel
* barra de XP

La parte provisional utiliza:

Panel2/lbl_nivel
Panel2/bar_progreso

IMPORTANTE:

La UI de nivel/XP dentro de dialogue_ui.gd sigue siendo PROVISIONAL.

La UI global de estado implementada en game.gd NO sustituye oficialmente a esta UI provisional.

No eliminar, fusionar ni rediseñar automáticamente esta parte.

Su futuro se decidirá posteriormente.

Actualmente dialogue_ui.gd está conectado a:

player.xp_changed

Por tanto, su parte provisional de XP/nivel puede actualizarse automáticamente cuando cambia la XP.

Esto NO cambia la regla cerrada del Panel de Estado global.

==================================================
14. PNJ
=======

pnj.gd gestiona:

* nombre
* sprite
* detección del Player
* interacción
* seguimiento del Player
* regreso a posición
* selección automática de diálogo

Tipos de seguimiento:

enum TipoSeguimiento {
NUNCA_SEGUIR,
SEGUIR_Y_QUEDARSE,
SEGUIR_Y_VOLVER
}

El seguimiento depende actualmente de:

DialogueManager.has_item(nombre.to_lower())

Cuando empieza el seguimiento guarda la posición original.

Cuando termina:

* según el tipo puede quedarse;
* o volver a su posición inicial.

---

## 14.1 SEGUIMIENTO DEL PLAYER — REGLA CERRADA

REGLA CERRADA:

El seguimiento de PNJ utiliza una única distancia de control:

const DISTANCIA_REANUDAR := 120.0

La lógica es:

Si la distancia entre PNJ y Player es MAYOR que DISTANCIA_REANUDAR:

* el PNJ se mueve hacia el Player.

Si la distancia es IGUAL O MENOR que DISTANCIA_REANUDAR:

* el PNJ NO se mueve.
* velocity se establece en Vector2.ZERO.

Esto significa:

Player > 120 px del PNJ
→ PNJ sigue al Player.

Player <= 120 px del PNJ
→ PNJ se detiene.

Esta solución se ha probado y funciona correctamente.

IMPORTANTE:

Se eliminó:

* DISTANCIA_PARAR
* a_distancia_segura

No deben volver a introducirse para solucionar el problema de seguimiento salvo decisión explícita.

No existe actualmente un sistema de:

* NavigationAgent2D
* pathfinding
* navegación
* evitación de obstáculos específica para seguidores

No se debe complicar el sistema de seguimiento introduciendo navegación para este problema.

La solución actual es intencionadamente sencilla.

---

## 14.2 COLISIONES E INTERACCIÓN

El PNJ sigue siendo un CharacterBody2D y mantiene sus colisiones físicas.

Cuando el PNJ está dentro de DISTANCIA_REANUDAR:

* no intenta alejarse del Player;
* no intenta alcanzar una distancia física concreta;
* simplemente deja de moverse.

Esto permite que la colisión con el Player siga funcionando normalmente.

La interacción con el Player se realiza mediante el Area2D de interacción del PNJ.

No modificar las capas/máscaras de colisión ni el Area2D como solución al seguimiento salvo que exista un problema concreto independiente.

---

## 14.3 Interacción

Cuando el Player entra en el área de interacción:

* player_nearby pasa a true.
* Si no hay otro diálogo activo, se selecciona el archivo de diálogo.
* Se inicia el diálogo correspondiente.

Cuando el Player sale del área de interacción:

* player_nearby pasa a false.
* Si hay un diálogo activo, se termina el diálogo.

Por tanto, salir físicamente del área del PNJ termina el diálogo actual.

---

## 14.4 Selección de diálogos

pnj.gd obtiene el nombre del mapa mediante:

mapa_actual.scene_file_path

Después busca dentro de:

user://dialogues/

en este orden:

1. Diálogo específico del nivel:

mapa_nombre_pnj_nivel.txt

Conceptualmente:

aldea_charo_a1.txt

2. Diálogo genérico del PNJ:

mapa_nombre_pnj.txt

3. Diálogo genérico global:

generico.txt

==================================================
15. DIALOGUEUPDATER
===================

DialogueUpdater es un Autoload.

Configuración actual:

GitHub user:

aik3n

GitHub repo:

ZeMobida

branch:

main

folder:

guiones

Descarga los .txt desde GitHub.

Carpeta local definitiva:

user://dialogues/

Carpeta temporal:

user://dialogues_temp/

Copia de seguridad temporal:

user://dialogues_backup/

La sincronización está diseñada para que si falla la descarga o la sustitución se conserve la carpeta local anterior.

---

## 15.1 Comportamiento ante errores

Si GitHub no está disponible:

* sync_failed = true
* se conservan los guiones locales
* guiones_disponibles = true
* el juego puede continuar

Si una descarga individual falla:

* sync_failed = true
* se conservan los guiones locales
* guiones_disponibles = true
* el juego puede continuar

Si falla la sustitución de la carpeta:

* sync_failed = true
* se conserva la carpeta anterior
* guiones_disponibles = true
* el juego puede continuar

Si todo funciona:

* se sustituye la carpeta local por la nueva
* guiones_disponibles = true
* el juego puede continuar

IMPORTANTE:

guiones_disponibles representa disponibilidad de contenido, NO éxito de GitHub.

sync_failed representa el resultado de la sincronización y es independiente de guiones_disponibles.

==================================================
16. PLAYER
==========

player.gd hereda de:

CharacterBody2D

Tiene:

* movimiento por teclado
* movimiento por pantalla/táctil
* XP
* nivel

Movimiento mediante:

ui_left
ui_right
ui_up
ui_down

También acepta:

* click izquierdo
* toque de pantalla

para establecer destino.

==================================================
17. INPUT
=========

Actualmente project.godot contiene:

ui_left
ui_right
ui_up
ui_down

con soporte para:

* flechas
* WASD
* gamepad

==================================================
18. ARCHIVOS DE GUION ACTUALES
==============================

La carpeta remota de GitHub utilizada por DialogueUpdater es:

guiones/

Los archivos descargados se almacenan localmente en:

user://dialogues/

Debe considerarse el contenido actual de la carpeta guiones/ como fuente remota de los diálogos.

---

## 18.1 generico.txt

Contiene nodos genéricos utilizados como fallback.

INICIO utiliza:

> RANDOM

RANDOM selecciona aleatoriamente otro nodo disponible distinto del nodo actual.

Hay opciones comentadas en algunos nodos.

Actualmente algunos nodos pueden ser terminales.

Esto no se considera actualmente un error del sistema.

Debe confirmarse en el futuro si estos nodos son intencionadamente terminales o si tendrán contenido adicional.

---

## 18.2 fallo.txt

Contiene:

# ERROR

Ha ocurrido un error en el guion.

1 Continuar > FIN

# FIN

Fin.

Se utiliza como diálogo de fallback cuando un guion no puede cargarse o validarse.

---

## 18.3 diálogos específicos

Los diálogos específicos de PNJ/nivel siguen la prioridad definida en pnj.gd:

1. mapa_pnj_nivel.txt
2. mapa_pnj.txt
3. generico.txt

Los nombres de objetos se normalizan a minúsculas mediante DialogueManager.

==================================================
19. AUTOLOADS
=============

project.godot contiene:

[autoload]

DialogueManager
DialogueUpdater

Los dos sistemas son globales.

==================================================
20. ESTADO DE LA UI GLOBAL
==========================

Conceptualmente:

Game
│
├── SceneContainer
│
└── UI
│
├── Estado
│   └── Panel
│       ├── Titulo
│       ├── Nivel
│       ├── Progreso
│       ├── BarraXP
│       ├── Inventario
│       └── Cerrar
│
└── BotonEstado

Hay dos conceptos independientes:

UI.visible

determina si la interfaz global existe visualmente.

estado_panel.visible

determina si el Panel de Estado está abierto.

Esto permite:

Bienvenida:
UI oculta

Mapa:
UI visible
Panel Estado oculto

Mapa + INV:
UI visible
Panel Estado visible

==================================================
21. CONEXIONES DEL PANEL DE ESTADO
==================================

game.gd conecta actualmente:

boton_estado.pressed.connect(_abrir_estado)
boton_cerrar.pressed.connect(_cerrar_estado)

No es necesario añadir conexiones equivalentes manualmente en el .tscn.

Esta implementación funciona actualmente.

Si en el futuro se traslada la responsabilidad de la UI a otro script/sistema, habrá que revisar estas conexiones.

==================================================
22. REGLAS CERRADAS
===================

Estas decisiones NO deben cambiarse accidentalmente:

1. La UI global se oculta únicamente en bienvenida.tscn.

Condición:

ui.visible = scene_path != BIENVENIDA_SCENE

2. La UI global no depende del nombre del mapa.

3. PanelGeneral de bienvenida siempre está habilitado.

4. PanelCargaEscenas se bloquea durante la preparación/sincronización de guiones.

5. El juego no se bloquea indefinidamente si GitHub falla.

6. Si GitHub falla, se utilizan los guiones locales.

7. guiones_disponibles representa disponibilidad de contenido y no exclusivamente éxito de GitHub.

8. sync_failed indica fallo de sincronización y no impide necesariamente continuar.

9. El Panel de Estado solo actualiza su contenido cuando se abre.

10. No se actualiza innecesariamente el estado del Panel de Estado mientras está oculto.

11. dialogue_ui.gd mantiene su implementación provisional de nivel/XP.

12. No modificar sistemas no relacionados al realizar una mejora.

13. El seguimiento de PNJ se detiene cuando la distancia al Player es <= DISTANCIA_REANUDAR.

14. DISTANCIA_REANUDAR = 120.0 es la única distancia utilizada actualmente para decidir si el PNJ sigue al Player.

15. DISTANCIA_PARAR ha sido eliminada.

16. a_distancia_segura ha sido eliminada.

17. El PNJ NO debe alejarse del Player como parte de la lógica normal de seguimiento.

18. La colisión y el Area2D de interacción del PNJ deben seguir funcionando normalmente cuando el PNJ está cerca del Player.

19. No introducir NavigationAgent2D, pathfinding o navegación para resolver el seguimiento de PNJ salvo decisión explícita.

20. La solución de seguimiento actual se considera CERRADA.

==================================================
23. VERSIÓN 12 — CAMBIOS REALIZADOS Y CERRADOS
==============================================

La versión 12 se considera ESTABLE.

Durante v12 se realizó la siguiente mejora:

* Se modificó la pantalla de bienvenida para separar los elementos generales de los botones que cargan escenas.
* Se creó/organizó PanelCargaEscenas.
* btn_Aldea pasó a estar dentro de PanelCargaEscenas.
* PanelGeneral permanece independiente y siempre habilitado.
* PanelCargaEscenas se bloquea mientras se preparan los guiones.
* Se introdujo guiones_disponibles en DialogueUpdater.
* Se introdujo la señal guiones_disponibles_changed.
* bienvenida.gd escucha la disponibilidad de los guiones.
* Cuando los guiones están disponibles, PanelCargaEscenas se habilita.
* Un fallo de GitHub no impide continuar.
* Si falla GitHub, se conservan los guiones locales y PanelCargaEscenas termina habilitándose.
* Se diferencia explícitamente entre sync_failed y guiones_disponibles.

La versión 12 queda cerrada.

==================================================
24. VERSIÓN 13 — CAMBIOS REALIZADOS Y CERRADOS
==============================================

La versión 13 comienza desde el estado estable de v12.

Durante v13 se revisó y mejoró el seguimiento de PNJ.

Problema detectado:

Cuando un PNJ seguía al Player, podía quedarse físicamente bloqueado/pegado debido a que intentaba acercarse directamente al Player mediante move_and_slide().

Se probó inicialmente una solución basada en:

* DISTANCIA_PARAR
* a_distancia_segura
* movimiento de alejamiento cuando el PNJ estaba demasiado cerca

Esta solución fue descartada.

Motivo:

Cuando el PNJ se alejaba automáticamente del Player al entrar en DISTANCIA_PARAR, podía interferir con la colisión y con el Area2D de interacción, provocando que no pudiera iniciarse correctamente el diálogo.

Solución definitiva:

El seguimiento se simplificó.

Nueva lógica:

Si:

distancia > DISTANCIA_REANUDAR

el PNJ sigue al Player.

Si:

distancia <= DISTANCIA_REANUDAR

el PNJ se detiene.

La constante utilizada es:

const DISTANCIA_REANUDAR := 120.0

Se eliminaron:

const DISTANCIA_PARAR := 80.0

y:

var a_distancia_segura := false

La nueva lógica no intenta mantener una distancia física exacta respecto al Player.

El PNJ simplemente deja de moverse cuando entra en el radio de 120 px.

Esto permite que:

* la colisión física continúe funcionando;
* el PNJ pueda entrar en el área de interacción;
* el diálogo pueda iniciarse;
* el seguimiento siga siendo sencillo;
* no sea necesario introducir navegación.

La solución fue probada y funciona correctamente.

ESTADO:

CERRADO.

No volver a introducir la solución de alejamiento salvo decisión explícita.

==================================================
25. PUNTOS A PRESTAR ATENCIÓN EN EL FUTURO
==========================================

1. Futuro de la UI provisional de dialogue_ui.gd.

2. Duplicación de NIVELES y ORDEN_NIVELES entre varios scripts.

3. Confirmar en el futuro si los nodos terminales de generico.txt son intencionados.

4. Mantener separadas las responsabilidades de:

   * sync_failed
   * guiones_disponibles

5. No convertir guiones_disponibles en una variable que represente exclusivamente el éxito de GitHub.

6. No bloquear PanelGeneral durante la sincronización.

7. Si se añaden nuevos botones de carga de escenas, deben estar dentro de PanelCargaEscenas o del sistema equivalente que se decida explícitamente.

8. Mantener la UI global independiente de ALDEA_SCENE y de cualquier otro mapa concreto.

9. No modificar DialogueParser o DialogueValidator sin comprobar compatibilidad con los guiones existentes.

10. Si se modifica el sistema de niveles, revisar player.gd, game.gd y dialogue_ui.gd.

11. Si se modifica el sistema de inventario, revisar DialogueManager, PNJ, diálogos y Panel de Estado.

12. Si se modifica la sincronización, comprobar siempre los tres escenarios:

    * sincronización correcta;
    * fallo de GitHub;
    * fallo de sustitución.

13. Si se modifica el seguimiento de PNJ, respetar la decisión CERRADA actual antes de introducir una arquitectura más compleja.

14. No reintroducir DISTANCIA_PARAR ni a_distancia_segura sin una decisión explícita.

==================================================
26. PRINCIPIO DE TRABAJO
========================

Antes de modificar código:

* Revisar la arquitectura existente.
* Identificar exactamente qué archivos necesita el nuevo cambio.
* Evitar modificar sistemas no relacionados.
* Mantener compatibilidad con diálogos, inventario, XP, guardado y carga de mapas.
* Mantener dialogue_ui.gd como implementación provisional hasta que se decida su futuro.
* Mantener la UI global independiente de nombres concretos de mapas.
* No actualizar innecesariamente el estado cuando el Panel de Estado está oculto.
* Entregar archivos completos cuando se solicite código modificado.
* No deshacer decisiones marcadas como CERRADAS.
* No considerar definitiva ninguna parte marcada como PROVISIONAL.
* Tratar el código actual de v13 como fuente de verdad frente a versiones anteriores del contexto.
* Mantener las soluciones sencillas cuando resuelvan correctamente el problema.
* No introducir sistemas de navegación, pathfinding u otras arquitecturas complejas si una solución local y sencilla es suficiente.
* Antes de cambiar una decisión CERRADA, explicar el motivo y esperar confirmación explícita.

La nueva versión debe partir EXACTAMENTE de este estado.

==================================================
FIN DEL CONTEXTO MAESTRO
========================
