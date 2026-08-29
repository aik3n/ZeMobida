# ZeMobida — content_context.md

PROYECTO: ZeMobida
REPOSITORIO: https://github.com/aik3n/ZeMobida
VERSION: v0.0.3
ESTADO: avance funcional probado y consolidado


==================================================
METODOLOGIA OFICIAL DE TRABAJO
==================================================

Todo cambio en ZeMobida debe seguir obligatoriamente este
flujo:

PROPUESTA
    ↓
CAMBIO
    ↓
IMPLEMENTACION
    ↓
PRUEBA
    ↓
CONFIRMACION
    ↓
ACTUALIZACION DE content_context.md
    ↓
COMMIT


1. PROPUESTA

Antes de modificar código se define qué se quiere conseguir.

Se analiza:

- objetivo del cambio;
- problema que se pretende solucionar;
- arquitectura afectada;
- posibles dependencias;
- posibles consecuencias;
- solución propuesta.

En esta fase no se modifica el proyecto.


2. CAMBIO

Se determina exactamente qué elementos deben cambiar.

Se identifican:

- archivos;
- escenas;
- nodos;
- scripts;
- sistemas afectados.

Se intenta limitar el alcance del cambio a lo estrictamente
necesario.


3. IMPLEMENTACION

Se realizan los cambios definidos en la fase anterior.

La implementación debe partir siempre del estado real del
proyecto.

No se deben inventar estructuras, referencias o código que
no hayan sido comprobados.

Debe conservarse toda funcionalidad existente que no forme
parte del cambio.


4. PRUEBA

Se ejecuta el proyecto y se comprueba el comportamiento real.

Se verifica:

- que el cambio cumple el objetivo;
- que las funcionalidades relacionadas continúan funcionando;
- que no aparecen errores;
- que no existen referencias rotas;
- que la integración con el resto de sistemas es correcta.


5. CONFIRMACION

El cambio solamente se considera terminado cuando ha sido
probado y confirmado como correcto.

Hasta recibir la confirmación:

- no se considera consolidado;
- no debe registrarse como funcionalidad terminada;
- no debe reflejarse en content_context.md como estado final.


6. ACTUALIZACION DE content_context.md

Una vez confirmado el cambio, se actualiza
content_context.md.

Debe registrarse con precisión:

- qué se ha cambiado;
- por qué se ha cambiado;
- qué decisión arquitectónica se ha tomado;
- qué archivos han sido afectados;
- qué resultado se ha obtenido;
- qué pruebas se han realizado;
- cualquier problema encontrado y su solución;
- el estado final del cambio.

content_context.md no debe contener el código fuente completo.

Su función es conservar la memoria técnica, arquitectónica y
evolutiva del proyecto.


7. COMMIT

El commit se realiza después de actualizar
content_context.md.

De esta forma, el código y la memoria del proyecto quedan
sincronizados en el mismo estado.

Un commit representa un estado del proyecto que ha sido
implementado, probado, confirmado y documentado.


REGLA FUNDAMENTAL:

content_context.md nunca debe adelantarse al estado real del
proyecto.

Una propuesta no es una funcionalidad implementada.

Una implementación no es una funcionalidad confirmada.

Solo después de la prueba y confirmación se registra un
cambio como estado consolidado.


OBJETIVO DE LA METODOLOGIA:

Permitir que cualquier sesión futura pueda continuar el
desarrollo de ZeMobida desde un estado conocido, probado y
documentado, evitando suposiciones, pérdida de contexto o
decisiones arquitectónicas contradictorias.


==================================================
1. PROPOSITO DE ESTE ARCHIVO
==================================================

Este archivo es la memoria maestra del proyecto ZeMobida.

Su objetivo es permitir que un chat nuevo pueda continuar el
desarrollo comprendiendo:

- qué es el proyecto;
- cuál es su objetivo;
- cuál es su arquitectura;
- qué decisiones se han tomado;
- qué funcionalidades están implementadas;
- qué problemas se han resuelto;
- qué elementos deben respetarse;
- cuál es el estado actual;
- cómo debe trabajarse en futuras modificaciones.

Este archivo NO contiene el código fuente completo del proyecto.

El código real se encuentra en el repositorio y debe estudiarse
directamente cuando sea necesario.

Este documento registra contexto, arquitectura, decisiones,
estado y metodología de trabajo.


==================================================
2. OBJETIVO GENERAL DEL PROYECTO
==================================================

ZeMobida es un proyecto de videojuego desarrollado en Godot.

El juego se estructura alrededor de mapas explorables, un
Player persistente, PNJ, conversaciones, decisiones, efectos
de diálogo, experiencia, niveles e inventario.

La arquitectura busca mantener separadas las responsabilidades
para evitar que sistemas diferentes acumulen lógica que no les
corresponde.

Principio general:

- Player mantiene el estado del jugador.
- DialogueManager gestiona la lógica de diálogos y sus efectos.
- DialogueUI muestra e interactúa con los diálogos.
- Game coordina escenas, Player persistente y UI global.
- Los mapas contienen el entorno y sus elementos propios.


==================================================
3. VERSION ACTUAL
==================================================

VERSION: v0.0.3

Esta versión representa un avance funcional y arquitectónico
consolidado.

Cambios principales consolidados hasta v0.0.3:

- separación del HUD de XP y nivel respecto a DialogueUI;
- inventario dentro de un ScrollContainer;
- Player único y persistente propiedad de Game;
- SpawnPlayer mediante Marker2D en los mapas;
- Player visible y activo únicamente cuando existe un mapa;
- DialogueUI como elemento común de Game;
- separación visual entre texto y opciones de diálogo;
- mostrar/ocultar opciones mediante interacción con el panel
  de texto;
- ocultación de opciones al terminar el diálogo;
- ocultación de opciones cuando un nodo no contiene opciones.


==================================================
4. ARQUITECTURA GENERAL
==================================================

La arquitectura actual separa las responsabilidades principales:

GAME
  Coordinación global del juego, mapas, Player persistente y UI.

PLAYER
  Estado y lógica propia del jugador.

DIALOGUEMANAGER
  Lógica de conversaciones, opciones, efectos, inventario y
  persistencia del estado.

DIALOGUEUI
  Presentación visual e interacción de los diálogos.

MAPA
  Entorno actual del jugador, PNJ, objetos, escenario y
  SpawnPlayer.


==================================================
5. ESTRUCTURA ACTUAL DE GAME
==================================================

La estructura conceptual actual es:

Game
|
+-- SceneContainer
|   |
|   +-- mapa_actual
|       |
|       +-- SpawnPlayer
|       +-- PNJ
|       +-- objetos
|       +-- escenario
|
+-- Player
|
+-- UI
|   |
|   +-- BotonEstado
|   +-- HUD
|   |   |
|   |   +-- lbl_Nivel
|   |   +-- lbl_Progreso
|   |   +-- bar_Progreso
|   |
|   +-- Estado
|       |
|       +-- Panel
|           +-- Titulo
|           +-- Nivel
|           +-- Progreso
|           +-- BarraXP
|           +-- Scroll
|           |   +-- Inventario
|           +-- Cerrar
|
+-- Dialogo


==================================================
6. PLAYER PERSISTENTE
==================================================

El Player es una única instancia persistente propiedad de Game.

El Player NO pertenece a los mapas.

Los mapas no contienen una instancia propia del Player.

Game mantiene directamente la referencia:

Game/Player


Esto permite conservar la misma instancia del personaje al
cambiar entre mapas.

El Player mantiene su estado durante la partida, incluyendo:

- nivel;
- XP;
- inventario mediante el sistema correspondiente;
- estado propio del personaje;
- posición actual;
- cualquier otra información persistente.


DECISION ARQUITECTONICA:

El Player representa al personaje real y persistente.

El mapa representa únicamente el entorno en el que se encuentra
el Player.


==================================================
7. SPAWNPLAYER
==================================================

Cada mapa puede contener un nodo:

SpawnPlayer

Tipo:

Marker2D


SpawnPlayer representa exclusivamente la posición donde debe
aparecer el Player al cargar el mapa.

SpawnPlayer NO es un Player.

SpawnPlayer NO contiene lógica del personaje.

SpawnPlayer NO modifica el sprite del Player.


Flujo:

Game carga mapa
    |
    v
localiza SpawnPlayer
    |
    v
obtiene su posición
    |
    v
coloca Game/Player
    |
    v
activa y hace visible el Player


DECISION ARQUITECTONICA:

La posición del Player pertenece al sistema de transición entre
Game y el mapa.

La apariencia y lógica del personaje pertenecen exclusivamente
al Player persistente.


==================================================
8. VISIBILIDAD Y ACTIVACION DEL PLAYER
==================================================

El Player debe existir durante toda la partida, pero solamente
debe ser visible y estar activo cuando existe un mapa de juego.

Cuando se encuentra en bienvenida u otra escena que no sea un
mapa:

- Player.visible = false;
- se desactiva su procesamiento físico;
- se desactiva su procesamiento de input correspondiente.

Cuando se carga un mapa:

- se localiza SpawnPlayer;
- se coloca el Player;
- se hace visible;
- se reactiva su procesamiento físico;
- se reactiva su procesamiento de input.


Si el mapa no contiene SpawnPlayer:

- el Player permanece oculto;
- el Player permanece desactivado;
- se genera una advertencia.


==================================================
9. RESPONSABILIDAD DE GAME
==================================================

game.gd es el coordinador principal de la escena Game.

Actualmente es responsable de:

- cargar escenas;
- gestionar SceneContainer;
- mantener referencia al mapa actual;
- mantener referencia al Player persistente;
- colocar el Player en SpawnPlayer;
- controlar la visibilidad y activación del Player;
- controlar la UI global;
- controlar el HUD;
- actualizar nivel y XP en el HUD;
- controlar el panel de Estado;
- actualizar nivel y XP del panel de Estado;
- actualizar el inventario mostrado en Estado.


Game NO debe convertirse en un contenedor indiscriminado de
toda la lógica del juego.

Su responsabilidad principal es coordinar el estado global,
las escenas, el Player persistente y la UI global.


==================================================
10. RESPONSABILIDAD DE PLAYER
==================================================

Player es la fuente del estado relacionado directamente con el
jugador.

Entre otros datos:

- nivel;
- experiencia;
- estado propio del personaje.

Cuando la experiencia cambia, Player utiliza la señal:

xp_changed


Flujo:

Player cambia XP
    |
    v
xp_changed
    |
    v
Game
    |
    v
HUD actualizado


La UI no modifica directamente la XP.


==================================================
11. RESPONSABILIDAD DE DIALOGUEMANAGER
==================================================

DialogueManager es responsable de la lógica de los diálogos.

Actualmente participa en:

- gestión de conversaciones;
- opciones;
- selección de opciones;
- efectos asociados a diálogos;
- aplicación de efectos;
- inventario;
- carga y guardado del estado del jugador.


DialogueManager puede provocar cambios en el Player mediante
efectos de diálogo.

Ejemplo:

Diálogo
  |
  v
DialogueManager
  |
  v
efecto XP
  |
  v
Player
  |
  v
xp_changed
  |
  v
Game/HUD


DialogueManager no debe encargarse de dibujar o gestionar el
HUD global.


==================================================
12. RESPONSABILIDAD DE DIALOGUEUI
==================================================

DialogueUI gestiona exclusivamente la interfaz visual de los
diálogos.

Actualmente es un elemento común de Game.

No pertenece a un mapa concreto.

Estructura conceptual:

Game
|
+-- Dialogo
    |
    +-- PanelTexto
    |   |
    |   +-- NameLabel
    |   +-- DialogueText
    |
    +-- PanelOpciones
        |
        +-- OptionsContainer


DialogueUI es responsable de:

- registrar la UI en DialogueManager;
- mostrar y ocultar el diálogo;
- mostrar el nombre del interlocutor;
- mostrar el texto;
- crear y mostrar las opciones;
- ocultar las opciones;
- mostrar/ocultar las opciones mediante interacción;
- comunicar la selección de opciones a DialogueManager.


DialogueUI NO debe gestionar:

- nivel;
- experiencia;
- HUD global;
- inventario global;
- estado persistente del Player;
- mapa actual.


==================================================
13. DIALOGO COMO ELEMENTO GLOBAL
==================================================

El diálogo se considera una funcionalidad común a todos los
mapas.

Por ello, DialogueUI se encuentra dentro de Game.

Los mapas no deben contener una instancia propia de DialogueUI.

Los PNJ utilizan DialogueManager para iniciar diálogos y la
interfaz común de Game se encarga de mostrarlos.


Esto permite que:

- cualquier mapa pueda utilizar diálogos;
- cualquier PNJ pueda iniciar un diálogo;
- la UI de diálogo no dependa de un mapa concreto;
- no existan múltiples instancias innecesarias de DialogueUI.


==================================================
14. INTERFAZ DE DIALOGOS
==================================================

La interfaz de diálogo se separó en dos paneles independientes.

PanelTexto
  |
  +-- NameLabel
  +-- DialogueText


PanelOpciones
  |
  +-- OptionsContainer


El objetivo es separar visualmente:

- contenido del diálogo;
- opciones disponibles.


El panel de opciones puede mostrarse u ocultarse mediante una
interacción con la zona de texto.


==================================================
15. COMPORTAMIENTO DEL PANEL DE OPCIONES
==================================================

Cuando comienza un diálogo:

- PanelTexto se muestra;
- PanelOpciones comienza oculto.


Cuando el usuario interactúa con la zona de texto:

- si existen opciones, PanelOpciones cambia entre visible y
  oculto.


Si el nodo actual no tiene opciones:

- PanelOpciones permanece oculto.


Cuando termina completamente el diálogo:

- PanelTexto se oculta;
- PanelOpciones se oculta.


Esto garantiza que el siguiente diálogo siempre comienza con
las opciones ocultas.


==================================================
16. FINALIZACION DEL DIALOGO
==================================================

El diálogo termina cuando el Player deja de estar en contacto
con el área de interacción del PNJ.

El PNJ utiliza la variable:

player_nearby


Flujo conceptual:

Player entra en área del PNJ
    |
    v
player_nearby = true
    |
    v
se inicia diálogo


Player sale del área del PNJ
    |
    v
player_nearby = false
    |
    v
DialogueManager.end_dialogue()
    |
    v
DialogueUI.hide_dialogue()
    |
    +--> PanelTexto oculto
    |
    +--> PanelOpciones oculto


==================================================
17. RELACION PNJ - PLAYER
==================================================

Los PNJ ya no buscan el Player dentro del mapa.

Anteriormente la arquitectura utilizaba conceptualmente:

Game
  |
  +-- mapa_actual
      |
      +-- player


La arquitectura actual utiliza:

Game
  |
  +-- Player


Por tanto, los PNJ obtienen el Player directamente desde Game.


Esto permite que los PNJ funcionen correctamente con el Player
persistente.


==================================================
18. FLUJO DE CAMBIO DE MAPA
==================================================

El flujo actual es:

Game
  |
  v
cargar_escena()
  |
  v
desactivar Player
  |
  v
eliminar mapa anterior
  |
  v
cargar nuevo mapa
  |
  v
mapa_actual = nuevo mapa
  |
  v
buscar SpawnPlayer
  |
  v
colocar Player
  |
  v
hacer visible Player
  |
  v
activar Player
  |
  v
actualizar HUD


El Player NO se destruye durante el cambio de mapa.


==================================================
19. HUD
==================================================

El HUD es la representación permanente y resumida del estado
del jugador durante el juego de mapas.

Muestra:

- nivel;
- progreso de XP;
- barra de progreso de XP.


El HUD pertenece a Game y no a DialogueUI.


La actualización se realiza mediante eventos del Player.

No se utiliza polling continuo mediante _process() para
actualizar el HUD.


==================================================
20. ESTADO / INVENTARIO
==================================================

Game contiene un panel de Estado que se abre mediante el botón
INV.

El panel muestra:

- nivel;
- progreso;
- barra de XP;
- inventario.


El inventario se obtiene desde:

DialogueManager.inventory


El inventario continúa siendo:

Array[String]


No se ha introducido lógica de inventario en la UI.


==================================================
21. SCROLL DEL INVENTARIO
==================================================

Para evitar que una lista grande de objetos salga del área
visible del panel Estado se utiliza:

Panel
└── Scroll
    └── Inventario


Tipos:

Scroll      = ScrollContainer
Inventario  = Label


El ScrollContainer proporciona un área visual limitada y
permite desplazamiento vertical cuando el contenido supera el
espacio disponible.


La solución afecta únicamente a la presentación.

No modifica la estructura de datos del inventario.


==================================================
22. FLUJO DE XP
==================================================

El flujo actual es:

DialogueManager
    |
    | efecto de XP
    v
Player
    |
    | xp_changed
    v
Game
    |
    +--> HUD
    |
    +--> Estado


La UI no es responsable de modificar la XP.

Player es la fuente del estado.

Game es responsable de presentar ese estado en la UI global.


==================================================
23. NIVELES ACTUALES
==================================================

Actualmente existen los siguientes niveles:

A1
A2
B1
B2
C1


Límites actuales de XP:

A1 = 70
A2 = 120
B1 = 340
B2 = 410
C1 = 740


Estos valores no deben modificarse sin revisar previamente
cómo está implementada la progresión del jugador.


==================================================
24. DECISIONES ARQUITECTONICAS CONSOLIDADAS
==================================================

DECISION 1

Nivel y XP pertenecen al HUD global de Game.

MOTIVO:

Son información persistente del estado del jugador.


DECISION 2

DialogueUI no gestiona nivel ni XP.

MOTIVO:

Evitar mezclar presentación de diálogos con estado global.


DECISION 3

El HUD se actualiza mediante xp_changed.

MOTIVO:

Utilizar una arquitectura orientada a eventos.


DECISION 4

Player es la fuente del estado de XP.

MOTIVO:

La UI debe presentar el estado, no ser propietaria del mismo.


DECISION 5

Game coordina la presentación global.

MOTIVO:

Game es propietario de la UI global y del Player persistente.


DECISION 6

El panel Estado conserva su propia representación de nivel y XP.

MOTIVO:

HUD y Estado tienen funciones visuales diferentes.


DECISION 7

DialogueUI se mantiene independiente del Player.

MOTIVO:

Reducir acoplamiento y permitir reutilización del sistema de
diálogos.


DECISION 8

Player es una única instancia persistente propiedad de Game.

MOTIVO:

El personaje representa al mismo jugador durante toda la
partida y su estado debe mantenerse al cambiar de mapa.


DECISION 9

Los mapas no contienen una instancia del Player.

MOTIVO:

El mapa representa el entorno, no al personaje persistente.


DECISION 10

Los mapas utilizan SpawnPlayer como Marker2D.

MOTIVO:

Separar la posición de aparición de la entidad Player.


DECISION 11

SpawnPlayer no controla la apariencia del Player.

MOTIVO:

El sprite y la lógica pertenecen exclusivamente al Player.


DECISION 12

El Player solo es visible y está activo cuando existe un mapa
cargado.

MOTIVO:

Evitar que el personaje aparezca o procese lógica durante
escenas que no son mapas.


DECISION 13

DialogueUI pertenece a Game y es común a todos los mapas.

MOTIVO:

Los diálogos son una funcionalidad transversal del juego y no
pertenecen a un mapa específico.


DECISION 14

Texto y opciones de diálogo se presentan en paneles separados.

MOTIVO:

Permitir una interfaz más flexible y controlar
independientemente la visibilidad de las opciones.


DECISION 15

PanelOpciones comienza oculto en cada diálogo.

MOTIVO:

Las opciones deben mostrarse únicamente cuando corresponda.


DECISION 16

PanelOpciones se oculta al finalizar el diálogo.

MOTIVO:

Garantizar que el siguiente diálogo comience con una interfaz
limpia.


DECISION 17

Si un nodo no tiene opciones, PanelOpciones permanece oculto.

MOTIVO:

No mostrar un panel vacío.


==================================================
25. CAMBIO CONSOLIDADO EN v0.0.1
==================================================

Objetivo:

Separar la visualización global de nivel/XP del sistema de
diálogos.


Cambios:

- HUD global de Game utilizado para nivel y XP;
- actualización mediante xp_changed;
- DialogueUI liberado de la responsabilidad de nivel/XP;
- eliminación de elementos de XP de dialogo.tscn.


Resultado:

Funcionalidad probada correctamente.


==================================================
26. CAMBIO CONSOLIDADO EN v0.0.2
==================================================

Objetivo:

Mejorar la arquitectura del Player y la presentación del
inventario.


Cambios:

- Player convertido en instancia única persistente de Game;
- Player eliminado de los mapas;
- añadido SpawnPlayer como Marker2D en los mapas;
- Game coloca el Player en SpawnPlayer al cargar el mapa;
- Player oculto y desactivado cuando no existe un mapa;
- Player visible y activo únicamente durante los mapas;
- PNJ adaptados para localizar el Player persistente;
- inventario introducido dentro de ScrollContainer.


Resultado:

La arquitectura de Player persistente y SpawnPlayer fue
probada correctamente.

El inventario con múltiples elementos también fue probado
correctamente.


==================================================
27. CAMBIO CONSOLIDADO EN v0.0.3
==================================================

Objetivo:

Separar visualmente el texto y las opciones de los diálogos y
convertir DialogueUI en un elemento común a todos los mapas.


Cambios:

- DialogueUI trasladado conceptualmente a Game como elemento
  global;
- eliminado el concepto de DialogueUI perteneciente a un mapa;
- PanelTexto separado de PanelOpciones;
- PanelTexto contiene NameLabel y DialogueText;
- PanelOpciones contiene OptionsContainer;
- PanelOpciones comienza oculto;
- interacción sobre la zona de texto permite mostrar u ocultar
  las opciones;
- cuando el nodo no tiene opciones, PanelOpciones permanece
  oculto;
- al finalizar el diálogo, PanelOpciones se oculta;
- siguiente diálogo comienza con las opciones ocultas;
- PNJ continúan iniciando los diálogos mediante
  DialogueManager.


Resultado:

El nuevo diseño de diálogo fue probado correctamente y se
considera funcional.


==================================================
28. PRUEBAS REALIZADAS
==================================================

Se comprobó correctamente:

- arranque del proyecto;
- entrada al mapa;
- aparición del Player mediante SpawnPlayer;
- Player persistente entre cargas de escena;
- Player oculto cuando no existe un mapa;
- Player activo únicamente cuando existe un mapa;
- funcionamiento del HUD;
- visualización del nivel;
- visualización del progreso;
- funcionamiento de la barra XP;
- apertura del panel INV;
- cierre del panel INV;
- visualización del inventario;
- desplazamiento del inventario;
- funcionamiento de los diálogos;
- funcionamiento de las opciones;
- obtención de XP mediante diálogos;
- actualización del HUD después de obtener XP;
- interacción con PNJ;
- seguimiento de PNJ;
- finalización del diálogo al salir de la zona de interacción;
- ocultación del PanelOpciones al terminar el diálogo;
- ocultación del PanelOpciones cuando el nodo no tiene opciones;
- mostrar/ocultar opciones mediante interacción con PanelTexto;
- nuevo diálogo comenzando con PanelOpciones oculto.


==================================================
29. PROBLEMAS ENCONTRADOS Y RESUELTOS
==================================================

PROBLEMA 1:

El Player no aparecía al cargar el mapa después de convertirlo
en persistente.


CAUSA:

El Player necesitaba recibir la posición del nuevo
SpawnPlayer del mapa.


SOLUCION:

Game localiza SpawnPlayer y coloca allí el Player antes de
activarlo.


--------------------------------------------------


PROBLEMA 2:

Se produjo un error al intentar modificar la propiedad
visible de una referencia nula.


CAUSA:

La referencia al Player no estaba correctamente establecida
en la nueva arquitectura.


SOLUCION:

Game mantiene una referencia directa a:

Game/Player


--------------------------------------------------


PROBLEMA 3:

Los PNJ seguían buscando el Player dentro del mapa.


CAUSA:

El código anterior correspondía a la arquitectura en la que
cada mapa contenía su propio Player.


SOLUCION:

Los PNJ obtienen el Player directamente desde Game.


--------------------------------------------------


PROBLEMA 4:

Las opciones del diálogo no eran visibles.


CAUSA:

La posición del panel/contenedor de opciones era incorrecta.


SOLUCION:

La posición fue corregida visualmente en la escena.


--------------------------------------------------


PROBLEMA 5:

El panel de opciones podía permanecer visible al terminar
un diálogo.


SOLUCION:

DialogueUI oculta PanelOpciones al ejecutar
hide_dialogue().


--------------------------------------------------


PROBLEMA 6:

Los nodos sin opciones podían dejar un panel vacío visible.


SOLUCION:

show_options() mantiene PanelOpciones oculto cuando el array
de opciones está vacío.


==================================================
30. ESTADO ACTUAL
==================================================

v0.0.3 está considerada una versión funcional, probada y
consolidada.


Actualmente:

- Player único y persistente;
- Player propiedad de Game;
- Player separado de los mapas;
- SpawnPlayer funcionando;
- Player oculto cuando no hay mapa;
- Player activado únicamente cuando hay mapa;
- PNJ compatibles con Player persistente;
- HUD global funcionando;
- nivel funcionando;
- XP funcionando;
- barra XP funcionando;
- actualización mediante xp_changed funcionando;
- diálogos funcionando;
- DialogueUI común a todos los mapas;
- texto y opciones separados;
- opciones mostrables/ocultables;
- opciones ocultas cuando no existen;
- opciones ocultas al terminar el diálogo;
- inventario funcionando;
- ScrollContainer de inventario funcionando;
- panel Estado funcionando.


==================================================
31. ARCHIVOS RELEVANTES
==================================================

Escenas principales:

- escenas/game.tscn
- escenas/aldea.tscn
- escenas/dialogo.tscn
- escenas/player.tscn
- escenas/pnj.tscn
- bienvenida.tscn


Scripts principales:

- scripts/game.gd
- scripts/dialogue_ui.gd
- scripts/pnj.gd
- script del Player
- DialogueManager


Los nombres y rutas reales deben comprobarse en el repositorio
antes de modificar archivos.


==================================================
32. PRINCIPIO DE CONSERVACION
==================================================

No modificar sistemas que no sean necesarios para resolver el
objetivo actual.

Especialmente:

- no modificar Player sin necesidad;
- no modificar DialogueManager sin necesidad;
- no introducir lógica global innecesaria en DialogueUI;
- no duplicar sistemas de XP;
- no duplicar Player;
- no introducir DialogueUI dentro de mapas;
- no eliminar funcionalidades existentes sin comprobar sus
  referencias.


La arquitectura debe evolucionar de forma incremental.


==================================================
33. PRINCIPIO DE RESPONSABILIDADES
==================================================

PLAYER

Es el personaje real y mantiene su estado.


GAME

Coordina Player, mapas y UI global.


MAPA

Contiene el entorno y los elementos propios de la zona.


SPAWNPLAYER

Indica dónde aparece el Player.


PNJ

Interactúa con el Player y puede iniciar diálogos.


DIALOGUEMANAGER

Gestiona la lógica de conversaciones, efectos, inventario y
persistencia.


DIALOGUEUI

Muestra visualmente los diálogos y sus opciones.


HUD

Muestra información rápida y global del jugador.


ESTADO

Muestra información detallada del jugador.


==================================================
34. SIGUIENTE CONTINUACION
==================================================

El proyecto debe continuar desde el estado v0.0.3.

No se deben volver a implementar cambios ya consolidados.

Antes de comenzar el siguiente objetivo:

- revisar este documento;
- revisar el estado actual del repositorio;
- identificar exactamente qué se quiere modificar;
- estudiar los archivos afectados;
- mantener las decisiones arquitectónicas establecidas;
- realizar primero una propuesta si el cambio afecta a la
  arquitectura.


Todo nuevo cambio debe seguir:

PROPUESTA
    ↓
CAMBIO
    ↓
IMPLEMENTACION
    ↓
PRUEBA
    ↓
CONFIRMACION
    ↓
ACTUALIZACION DE content_context.md
    ↓
COMMIT


==================================================
FIN DE content_context.md
==================================================
