# ZeMobida — content_context.md

PROYECTO: ZeMobida
REPOSITORIO: https://github.com/aik3n/ZeMobida
VERSION: v0.0.2
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

Su objetivo es permitir que un chat nuevo pueda continuar el desarrollo comprendiendo:

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

El código real se encuentra en el repositorio y debe estudiarse directamente cuando sea necesario.

Este documento registra contexto, arquitectura, decisiones, estado y metodología de trabajo.


==================================================
2. OBJETIVO GENERAL DEL PROYECTO
==================================================

ZeMobida es un proyecto de videojuego desarrollado en Godot.

El juego se estructura alrededor de mapas explorables, un Player, PNJ, conversaciones, decisiones, efectos de diálogo, experiencia, niveles e inventario.

La arquitectura busca mantener separadas las responsabilidades para evitar que sistemas diferentes acumulen lógica que no les corresponde.

Principio general:

- Player mantiene el estado del jugador.
- DialogueManager gestiona la lógica de diálogos y sus efectos.
- DialogueUI muestra e interactúa con los diálogos.
- Game coordina escenas y UI global.
- HUD muestra información global y persistente del jugador.


==================================================
3. VERSION ACTUAL
==================================================

VERSION: v0.0.2

Esta versión representa un avance arquitectónico y funcional
consolidado sobre la versión anterior.

Objetivos principales de v0.0.2:

- mantener el HUD global de nivel y XP;
- mantener el inventario dentro de un área desplazable;
- convertir al Player en una única entidad persistente
  propiedad de Game;
- permitir que cada mapa defina su propio punto de aparición
  mediante SpawnPlayer.

Resultado:

- Nivel y XP pertenecen a la UI global de Game.
- DialogueUI deja de gestionar nivel y XP.
- El inventario dispone de ScrollContainer.
- Existe una única instancia persistente del Player durante
  la partida.
- Los mapas ya no contienen una instancia propia del Player.
- Cada mapa utiliza SpawnPlayer como punto de aparición.
- El Player se recoloca al cargar un nuevo mapa.
- El Player solamente permanece visible cuando existe un mapa
  de juego cargado.


==================================================
4. ARQUITECTURA GENERAL
==================================================

La arquitectura actual separa las responsabilidades principales:

GAME
  Coordinación global del juego, Player persistente,
  mapas y UI global.

PLAYER
  Estado y lógica propia del jugador.

DIALOGUEMANAGER
  Lógica del sistema de conversaciones, opciones, efectos,
  inventario y persistencia del estado.

DIALOGUEUI
  Presentación visual e interacción de los diálogos.

MAPA
  Entorno del juego, PNJ, objetos, escenario y SpawnPlayer.

La relación conceptual es:

Game
  |
  +-- Player
  |
  +-- SceneContainer
  |     |
  |     +-- mapa_actual
  |           |
  |           +-- SpawnPlayer
  |           +-- PNJ
  |           +-- objetos
  |           +-- escenario
  |
  +-- UI


DialogueManager
  |
  v
DialogueUI


DialogueManager
  |
  | efectos
  v
Player


==================================================
5. RESPONSABILIDAD DE GAME
==================================================

game.gd es el coordinador principal de la escena Game.

Actualmente es responsable de:

- cargar escenas;
- gestionar SceneContainer;
- mantener referencia al mapa actual;
- mantener referencia al Player persistente;
- colocar el Player en el SpawnPlayer del mapa;
- controlar la visibilidad del Player según exista un mapa;
- controlar la UI global;
- controlar el HUD;
- actualizar nivel y XP en el HUD;
- controlar el panel de Estado;
- actualizar nivel y XP del panel de Estado;
- actualizar el inventario mostrado en Estado.

Game NO debe convertirse en un contenedor indiscriminado de toda
la lógica del juego.

Su responsabilidad principal es coordinar el estado global,
el Player persistente, el mapa actual y la UI global.


==================================================
6. RESPONSABILIDAD DE PLAYER
==================================================

Player es la única instancia real del personaje durante la
partida.

Player pertenece a Game y no a un mapa concreto.

Entre otros datos conserva:

- nivel;
- experiencia;
- inventario o referencias relacionadas si corresponden;
- estado propio del personaje;
- posición actual;
- cualquier otra información persistente del jugador.

Cuando la experiencia cambia, Player utiliza la señal:

xp_changed

El HUD no modifica directamente la XP.

El flujo correcto es:

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


==================================================
7. PLAYER PERSISTENTE
==================================================

A partir de v0.0.2 existe una única instancia del Player
durante la partida.

El Player es hijo directo de Game.

Estructura conceptual:

Game
|
+-- Player
|
+-- SceneContainer
|
+-- UI


Los mapas NO contienen una instancia real del Player.

Antes:

Game
|
+-- SceneContainer
|    |
|    +-- Aldea
|         |
|         +-- player
|
+-- UI


Ahora:

Game
|
+-- Player
|
+-- SceneContainer
|    |
|    +-- Aldea
|         |
|         +-- SpawnPlayer
|
+-- UI


El mismo Player se conserva cuando se descarga un mapa y se
carga otro.

Esto permite conservar el estado del personaje durante las
transiciones.


==================================================
8. RESPONSABILIDAD DE SPAWNPLAYER
==================================================

Cada mapa proporciona un nodo:

SpawnPlayer

Tipo:

Marker2D


SpawnPlayer solamente representa una posición de aparición.

No contiene lógica de Player.

No contiene una segunda instancia del personaje.

No cambia el sprite del Player.

El flujo es:

Game carga mapa
    |
    v
Game localiza SpawnPlayer
    |
    v
Game obtiene su posición
    |
    v
Game coloca Player persistente
    |
    v
Player aparece en el mapa


Ejemplo:

Aldea
|
+-- SpawnPlayer
+-- PNJ
+-- objetos
+-- escenario


==================================================
9. VISIBILIDAD DEL PLAYER
==================================================

El Player pertenece permanentemente a Game, pero no debe ser
visible cuando no existe un mapa de juego cargado.

Por tanto:

- en bienvenida.tscn el Player permanece oculto;
- al cargar un mapa el Player se hace visible;
- al cambiar de mapa el mismo Player continúa utilizándose;
- la posición del Player se actualiza utilizando SpawnPlayer.

Esto permite mantener una instancia persistente sin mostrarla
fuera del contexto de juego.


==================================================
10. RESPONSABILIDAD DEL MAPA
==================================================

El mapa representa exclusivamente el entorno donde se encuentra
el Player.

El mapa contiene elementos propios como:

- escenario;
- PNJ;
- objetos;
- elementos interactivos;
- puntos de entrada/salida;
- SpawnPlayer;
- otros elementos específicos de la zona.

El mapa NO es propietario del Player.

Esto permite intercambiar mapas sin reconstruir el personaje.


==================================================
11. CAMBIO DE MAPA
==================================================

El flujo actual conceptual es:

1. Game conserva el Player.
2. Game elimina el mapa anterior.
3. Game carga el nuevo mapa.
4. Game añade el nuevo mapa a SceneContainer.
5. Game localiza SpawnPlayer.
6. Game coloca el Player en la posición de SpawnPlayer.
7. Game hace visible el Player.
8. El Player continúa siendo la misma instancia.

Ejemplo:

Aldea
  |
  | cambio de mapa
  v
Bosque

Durante todo el proceso:

Player
  = misma instancia.


==================================================
12. ENTRADAS MULTIPLES
==================================================

Se contempla como posibilidad futura que un mapa tenga varios
puntos de entrada.

Ejemplo:

Aldea
|
+-- EntradaInicial
+-- EntradaDesdeBosque
+-- EntradaDesdeCiudad


Esta funcionalidad todavía NO está implementada.

La arquitectura actual utiliza un único:

SpawnPlayer

por mapa.

En el futuro podría evolucionar hacia un sistema de puntos
de entrada identificados según el mapa de procedencia.

No debe considerarse una funcionalidad consolidada hasta que
sea propuesta, implementada, probada y confirmada.


==================================================
13. RESPONSABILIDAD DE DIALOGUEMANAGER
==================================================

DialogueManager es responsable de la lógica de los diálogos.

Actualmente participa en:

- gestión de conversaciones;
- opciones;
- selección de opciones;
- efectos asociados a diálogos;
- aplicación de efectos;
- inventario;
- guardado del estado del jugador;
- carga del estado del jugador.

DialogueManager puede provocar cambios en el Player mediante
efectos de diálogo.

Ejemplo conceptual:

Diálogo
  |
  v
DialogueManager
  |
  v
efecto de XP
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
14. RESPONSABILIDAD DE DIALOGUEUI
==================================================

dialogue_ui.gd gestiona exclusivamente la interfaz visual de
los diálogos.

Responsabilidades:

- registrar la UI en DialogueManager;
- mostrar y ocultar la ventana de diálogo;
- mostrar nombre del interlocutor;
- mostrar texto;
- crear y mostrar opciones;
- recibir la selección de una opción;
- comunicar la selección a DialogueManager.

DialogueUI NO debe gestionar:

- nivel;
- experiencia;
- ProgressBar de XP;
- HUD global;
- inventario global;
- estado del Player;
- mapa actual.

Esta separación se considera una decisión arquitectónica
consolidada.


==================================================
15. UI GLOBAL DE GAME
==================================================

La escena Game contiene una UI global mediante CanvasLayer.

Estructura conceptual actual:

Game
|
+-- Player
|
+-- SceneContainer
|
+-- UI
    |
    +-- BotonEstado
    |
    +-- HUD
    |   |
    |   +-- lbl_Nivel
    |   +-- lbl_Progreso
    |   +-- bar_Progreso
    |
    +-- Estado
        |
        +-- Panel
            |
            +-- Titulo
            +-- Nivel
            +-- Progreso
            +-- BarraXP
            +-- Scroll
            |   |
            |   +-- Inventario
            |
            +-- Cerrar


==================================================
16. HUD
==================================================

El HUD es la representación permanente y resumida del estado
del jugador durante el juego de mapas.

Muestra:

- nivel;
- progreso de XP;
- barra de progreso de XP.

El HUD pertenece a Game y no a DialogueUI.

Debe permanecer visible mientras el jugador está dentro de
las escenas de juego/mapa.

La actualización del HUD se realiza mediante eventos del
Player, evitando polling continuo mediante _process().


==================================================
17. ESTADO / INVENTARIO
==================================================

Game contiene un panel de Estado que se abre mediante el botón
INV.

Actualmente muestra:

- nivel;
- progreso;
- barra de XP;
- inventario.

El inventario se obtiene desde:

DialogueManager.inventory

El inventario continúa almacenándose como:

Array[String]


La representación visual utiliza:

Panel
└── Scroll
    └── Inventario


Tipos:

Scroll      = ScrollContainer
Inventario  = Label


El ScrollContainer limita el área visible y permite desplazarse
verticalmente cuando el contenido supera el espacio disponible.

No se modifica la estructura de datos del inventario para
resolver este problema.


==================================================
18. DIALOGO.TSCN
==================================================

La escena de diálogo anteriormente contenía elementos propios
de nivel y XP.

Se consideró incorrecto porque nivel y XP son información global
del jugador y no información específica de una conversación.

En v0.0.1 fueron eliminados:

- Panel2
- lbl_nivel
- bar_progreso

La escena de diálogo queda conceptualmente dedicada a:

- NameLabel;
- DialogueText;
- OptionsContainer.

No deben volver a introducirse elementos de nivel o XP en
dialogo.tscn sin una decisión arquitectónica nueva y explícita.


==================================================
19. FLUJO DE XP
==================================================

El flujo actual y deseado es:

DialogueUI
    |
    v
DialogueManager
    |
    | efecto de diálogo
    v
Player
    |
    | cambia XP
    v
xp_changed
    |
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
20. NIVELES ACTUALES
==================================================

Actualmente existen los siguientes niveles:

A1
A2
B1
B2
C1

Los límites actuales de XP son:

A1 = 70
A2 = 120
B1 = 340
B2 = 410
C1 = 740

El sistema utiliza un orden explícito de niveles.

Estos valores no deben modificarse sin revisar previamente cómo
está implementada la progresión del jugador.


==================================================
21. CARGA DE ESCENAS
==================================================

Game utiliza SceneContainer para cargar las escenas del juego.

Actualmente existen como referencias principales:

- bienvenida.tscn
- aldea.tscn

Flujo conceptual:

Game
  |
  v
bienvenida
  |
  | Jugar
  v
aldea
  |
  v
SpawnPlayer
  |
  v
Player persistente


Cuando se carga una escena de juego:

- se limpia la escena anterior;
- se actualiza mapa_actual;
- se instancia el nuevo mapa;
- se carga el estado persistente del jugador;
- se localiza SpawnPlayer;
- se coloca el Player;
- se hace visible el Player;
- se actualiza el HUD.


==================================================
22. DECISIONES ARQUITECTONICAS CONSOLIDADAS
==================================================

DECISION 1
Nivel y XP pertenecen al HUD global de Game.

MOTIVO:
Son información persistente del estado del jugador.


DECISION 2
DialogueUI no gestiona nivel ni XP.

MOTIVO:
Evitar mezclar presentación de diálogos con estado global del
jugador.


DECISION 3
El HUD se actualiza mediante xp_changed.

MOTIVO:
Usar una arquitectura orientada a eventos y evitar
actualizaciones continuas innecesarias.


DECISION 4
Player es la fuente del estado de XP.

MOTIVO:
La UI debe presentar el estado, no convertirse en propietaria
del mismo.


DECISION 5
Game coordina la presentación global.

MOTIVO:
Game es propietario de la UI global y coordina el Player y el
mapa actual.


DECISION 6
El panel Estado conserva su propia representación de nivel y XP.

MOTIVO:
El HUD y Estado tienen funciones visuales diferentes.


DECISION 7
DialogueUI se mantiene independiente del Player.

MOTIVO:
Reducir acoplamiento y permitir que el sistema de diálogos sea
reutilizable.


DECISION 8
Player es una única entidad persistente propiedad de Game.

MOTIVO:
El personaje representa al mismo jugador durante toda la
partida y su estado debe conservarse al cambiar de mapa.


DECISION 9
Los mapas no contienen una instancia real del Player.

MOTIVO:
Evitar duplicación del personaje y separar al jugador del
entorno.


DECISION 10
Cada mapa utiliza SpawnPlayer como Marker2D.

MOTIVO:
Separar la posición de aparición de la entidad Player.


DECISION 11
El Player permanece oculto cuando no existe un mapa de juego.

MOTIVO:
Player pertenece a Game y persiste durante la partida, pero
solo debe ser visible dentro del contexto de un mapa.


DECISION 12
SpawnPlayer no modifica el sprite ni la apariencia del Player.

MOTIVO:
El sprite pertenece exclusivamente al Player persistente y
no es responsabilidad del punto de aparición.


==================================================
23. CAMBIO REALIZADO EN v0.0.1
==================================================

Objetivo:

Separar la visualización global de nivel/XP del sistema de
diálogos.

Cambios:

- HUD global de Game utilizado para nivel y XP.
- actualización mediante xp_changed;
- DialogueUI liberado de la responsabilidad de nivel/XP;
- eliminado Panel2 de dialogo.tscn;
- eliminado lbl_nivel de dialogo.tscn;
- eliminado bar_progreso de dialogo.tscn.

Resultado:

Funcionalidad probada correctamente.


==================================================
24. MEJORA DE UI DEL INVENTARIO
==================================================

OBJETIVO:

Evitar que un inventario con muchos objetos haga crecer
verticalmente el Label de inventario hasta salir del área
visible del panel Estado.


PROBLEMA:

DialogueManager.inventory se almacena como Array[String].

Game mostraba todos los elementos concatenados en un único
Label directamente dentro de Panel.

Cuando había suficientes elementos, el Label podía crecer
verticalmente y salir de los límites visibles del panel.


SOLUCION:

Se mantiene intacta la estructura de datos:

DialogueManager.inventory
    = Array[String]

La representación visual utiliza:

Panel
└── Scroll
    └── Inventario


Tipos:

Scroll      = ScrollContainer
Inventario  = Label


El ScrollContainer proporciona un área visual limitada y
permite desplazarse verticalmente cuando el contenido supera
el espacio disponible.


DECISION ARQUITECTONICA:

La solución se limita a la presentación.

No se introduce lógica de inventario en el ScrollContainer.

No se modifica DialogueManager.inventory.

Game continúa siendo responsable de presentar el inventario
en el panel Estado.


ARCHIVOS AFECTADOS:

- escenas/Game.tscn
- scripts/game.gd


PRUEBAS:

Se comprobó:

- visualización normal del inventario;
- inventario con múltiples elementos;
- aparición del desplazamiento vertical;
- acceso a los elementos inferiores;
- lectura del último elemento;
- mantenimiento de los límites del panel;
- funcionamiento con pocos elementos;
- funcionamiento del botón de cierre del panel Estado.

RESULTADO:

La mejora queda confirmada y se considera funcional.


==================================================
25. PLAYER PERSISTENTE Y SPAWN POR MAPA
==================================================

OBJETIVO:

Convertir al Player en una única entidad persistente propiedad
de Game y eliminar la dependencia de que cada mapa contenga su
propia instancia del personaje.


PROBLEMA ANTERIOR:

Cada mapa podía contener su propia instancia del Player.

Conceptualmente:

Game
|
+-- SceneContainer
|    |
|    +-- Aldea
|         |
|         +-- player
|
+-- UI

Esto implicaba crear una instancia diferente del personaje al
cambiar de mapa, aunque conceptualmente se trata del mismo
jugador.


SOLUCION IMPLEMENTADA:

El Player pasó a ser una instancia persistente hija directa de
Game.

Los mapas dejaron de contener una instancia real del Player.

Arquitectura actual:

Game
|
+-- Player
|
+-- SceneContainer
|    |
|    +-- mapa_actual
|         |
|         +-- SpawnPlayer
|         +-- PNJ
|         +-- escenario
|         +-- objetos
|
+-- UI


SpawnPlayer es un Marker2D.

Su única responsabilidad es indicar dónde debe colocarse el
Player al cargar el mapa.


COMPORTAMIENTO:

Al cargar un mapa:

1. Game conserva el Player existente.
2. Game descarga el mapa anterior.
3. Game carga el nuevo mapa.
4. Game localiza SpawnPlayer.
5. Game obtiene su posición.
6. Game coloca el Player persistente en dicha posición.
7. Game hace visible el Player.


Al cargar una escena que no representa un mapa de juego, como
bienvenida.tscn:

- el Player permanece oculto.


ESTADO DEL PLAYER:

No se crea un nuevo Player al cambiar de mapa.

El mismo Player conserva su estado entre mapas.

Entre otros datos:

- nivel;
- XP;
- estado propio;
- posición;
- demás información persistente que corresponda.


SPRITE:

El sprite real pertenece al Player.

SpawnPlayer no tiene sprite de personaje y no modifica la
apariencia del Player.


ARCHIVOS AFECTADOS:

- escenas/game.tscn
- scripts/game.gd
- escenas/aldea.tscn
- scripts relacionados con Player/PJ según referencias existentes


DEPENDENCIAS REVISADAS:

Se revisaron las dependencias relacionadas con:

- Player;
- Game;
- mapas;
- PNJ;
- DialogueManager;
- HUD;
- diálogos;
- XP;
- carga del estado del jugador;
- visibilidad del Player;
- SpawnPlayer.


AJUSTES REALIZADOS:

Las referencias que anteriormente buscaban el Player dentro
del mapa fueron adaptadas al nuevo modelo en los sistemas
necesarios.

Game mantiene una referencia directa al Player persistente.

Los sistemas que necesitan acceder al Player deben utilizar la
instancia persistente correspondiente y no asumir que el Player
es hijo del mapa.


PROBLEMA ENCONTRADO:

Durante la implementación apareció un error relacionado con
la visibilidad de un nodo nulo:

"Invalid assignment of property or key 'visible' with value of
type 'bool' on a base object of type 'null instance'."


La causa estaba relacionada con la referencia al Player antes
de que existiera correctamente en la nueva estructura.


También se comprobó inicialmente que el Player no aparecía al
cargar el mapa.

La causa fue la ausencia/configuración incorrecta del punto
SpawnPlayer necesario para posicionar al Player persistente.


SOLUCION:

Se incorporó SpawnPlayer como Marker2D en el mapa y Game utiliza
su posición para colocar el Player al cargarlo.

También se controla correctamente la visibilidad del Player
según exista un mapa de juego cargado.


PRUEBAS:

El cambio fue probado correctamente.

Se comprobó:

- carga de bienvenida;
- Player oculto fuera del mapa;
- entrada al mapa;
- aparición correcta del Player;
- posición inicial mediante SpawnPlayer;
- funcionamiento del movimiento;
- funcionamiento del mapa;
- persistencia de la misma instancia del Player;
- funcionamiento del HUD;
- funcionamiento de XP;
- funcionamiento de diálogos;
- funcionamiento de PNJ;
- funcionamiento del inventario;
- funcionamiento del panel Estado.


RESULTADO:

El Player persistente y el sistema SpawnPlayer funcionan
correctamente.

El cambio queda CONFIRMADO y consolidado en v0.0.2.


==================================================
26. ESTADO ACTUAL
==================================================

v0.0.2 está considerada una versión funcional y probada.

Actualmente:

- HUD global funcionando;
- nivel funcionando;
- XP funcionando;
- barra XP funcionando;
- actualización mediante xp_changed funcionando;
- diálogos funcionando;
- opciones de diálogo funcionando;
- inventario funcionando;
- inventario con ScrollContainer funcionando;
- panel Estado funcionando;
- Player persistente funcionando;
- Player propiedad de Game;
- Player oculto cuando no hay mapa;
- Player visible cuando hay mapa;
- SpawnPlayer funcionando;
- posición del Player determinada por SpawnPlayer;
- mapas sin instancia propia del Player;
- separación Game / DialogueUI establecida;
- restos de XP eliminados de dialogo.tscn.


==================================================
27. ARCHIVOS RELEVANTES PARA ESTE SISTEMA
==================================================

Escenas:

- escenas/game.tscn
- escenas/aldea.tscn
- bienvenida.tscn
- escena de diálogo correspondiente a dialogo.tscn

Scripts:

- scripts/game.gd
- scripts/dialogue_ui.gd
- script del Player
- pnj.gd
- DialogueManager


Los nombres y rutas reales deben comprobarse en el repositorio
antes de modificar archivos.


==================================================
28. METODOLOGIA DE TRABAJO
==================================================

Antes de modificar código:

1. Estudiar el archivo real.
2. Estudiar las escenas relacionadas.
3. Identificar dependencias.
4. Determinar qué sistema debe ser responsable de la
   funcionalidad.
5. Evitar duplicar responsabilidades.
6. Hacer el cambio mínimo necesario.
7. Probar la funcionalidad.
8. Comprobar que no se ha roto ninguna funcionalidad existente.
9. Registrar el avance en content_context.md.
10. Solo después considerar cerrada la versión o avance.

No reconstruir scripts completos basándose en suposiciones cuando
el archivo real puede ser consultado.

Cuando se solicite un script completo, debe generarse a partir
de la versión real del archivo.


==================================================
29. PRINCIPIO DE CONSERVACION
==================================================

No modificar sistemas que no sean necesarios para resolver el
objetivo actual.

Especialmente:

- no modificar Player sin necesidad;
- no modificar DialogueManager sin necesidad;
- no introducir lógica global en DialogueUI;
- no duplicar sistemas de XP;
- no eliminar funcionalidades existentes sin comprobar sus
  referencias;
- no crear Players adicionales dentro de los mapas;
- no convertir SpawnPlayer en un segundo Player.

La arquitectura debe evolucionar de forma incremental.


==================================================
30. REGISTRO DE VERSIONES
==================================================

v0.0.1

Objetivo:
Separar la visualización global de nivel/XP del sistema de
diálogos.

Cambios:

- HUD global de Game utilizado para nivel y XP;
- actualización mediante xp_changed;
- DialogueUI liberado de la responsabilidad de nivel/XP;
- eliminado Panel2 de dialogo.tscn;
- eliminado lbl_nivel de dialogo.tscn;
- eliminado bar_progreso de dialogo.tscn.

Resultado:

Funcionalidad probada correctamente.


v0.0.2

Objetivo:

Mejorar la arquitectura del Player y la presentación del
inventario.

Cambios:

- inventario contenido en ScrollContainer;
- Player convertido en entidad única y persistente;
- Player trasladado a Game;
- mapas liberados de su instancia propia del Player;
- añadido SpawnPlayer como Marker2D;
- Player colocado según SpawnPlayer;
- Player oculto cuando no existe un mapa;
- Player visible al cargar un mapa;
- referencias dependientes del Player adaptadas al nuevo modelo.

Resultado:

Cambios implementados, probados y confirmados correctamente.


==================================================
31. SIGUIENTE CONTINUACION
==================================================

El proyecto debe continuar desde el estado v0.0.2.

No se debe volver a implementar:

- la separación del HUD/XP;
- el ScrollContainer del inventario;
- el Player persistente;
- SpawnPlayer básico.

Antes de comenzar el siguiente objetivo:

- revisar este documento;
- revisar el estado actual del repositorio;
- identificar exactamente qué se quiere modificar;
- estudiar los archivos afectados;
- mantener las decisiones arquitectónicas establecidas.

Cualquier nueva modificación deberá seguir el flujo:

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
