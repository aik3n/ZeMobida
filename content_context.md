Correcto. El content_context.me no debe convertirse en una copia de los scripts. Su función es conservar contexto, decisiones, arquitectura, estado, objetivos y metodología de trabajo. El código debe permanecer en los archivos del repositorio.

Te dejo una versión más adecuada y limpia para usar como documento maestro:

# ZeMobida — content_context.me

PROYECTO: ZeMobida
REPOSITORIO: https://github.com/aik3n/ZeMobida
VERSION: v0.0.1
ESTADO: avance funcional probado y consolidado

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

VERSION: v0.0.1

Esta versión representa un primer avance arquitectónico y funcional consolidado.

Objetivo principal de v0.0.1:

Mover la información de nivel y progreso de experiencia desde la interfaz de diálogo hacia el HUD global de Game.

Resultado:

- Nivel y XP pertenecen ahora a la UI global de Game.
- DialogueUI deja de gestionar nivel y XP.
- dialogo.tscn deja de contener elementos visuales de nivel y XP.
- El HUD se actualiza mediante la señal de XP del Player.
- El sistema de diálogos continúa funcionando.
- El inventario continúa funcionando.
- El panel de Estado continúa funcionando.


==================================================
4. ARQUITECTURA GENERAL
==================================================

La arquitectura actual separa cuatro responsabilidades principales:

GAME
  Coordinación global del juego y de la UI.

PLAYER
  Estado y lógica propia del jugador.

DIALOGUEMANAGER
  Lógica del sistema de conversaciones, opciones, efectos e inventario.

DIALOGUEUI
  Presentación visual e interacción de los diálogos.

La relación conceptual es:

Player
  |
  | estado del jugador
  v
Game
  |
  +--> HUD global
  |
  +--> Estado / Inventario


DialogueManager
  |
  v
DialogueUI


DialogueManager
  |
  | efectos de diálogo
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
- localizar el Player del mapa actual;
- mantener referencia al Player actual;
- controlar la UI global;
- controlar el HUD;
- actualizar nivel y XP en el HUD;
- controlar el panel de Estado;
- actualizar nivel y XP del panel de Estado;
- actualizar el inventario mostrado en Estado.

Game NO debe convertirse en un contenedor indiscriminado de toda la lógica del juego.

Su responsabilidad principal es coordinar el estado global y la UI global.


==================================================
6. RESPONSABILIDAD DE PLAYER
==================================================

Player es la fuente del estado relacionado directamente con el jugador.

Entre otros datos:

- nivel;
- experiencia.

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
7. RESPONSABILIDAD DE DIALOGUEMANAGER
==================================================

DialogueManager es responsable de la lógica de los diálogos.

Actualmente participa en:

- gestión de conversaciones;
- opciones;
- selección de opciones;
- efectos asociados a diálogos;
- aplicación de efectos;
- inventario;
- carga del estado del jugador.

DialogueManager puede provocar cambios en el Player mediante efectos de diálogo.

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

DialogueManager no debe encargarse de dibujar o gestionar el HUD global.


==================================================
8. RESPONSABILIDAD DE DIALOGUEUI
==================================================

dialogue_ui.gd gestiona exclusivamente la interfaz visual de los diálogos.

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

Esta separación se considera una decisión arquitectónica consolidada en v0.0.1.


==================================================
9. UI GLOBAL DE GAME
==================================================

La escena Game contiene una UI global mediante CanvasLayer.

Estructura conceptual actual:

Game
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
            +-- Inventario
            +-- Cerrar


==================================================
10. HUD
==================================================

El HUD es la representación permanente y resumida del estado del jugador durante el juego de mapas.

Muestra:

- nivel;
- progreso de XP;
- barra de progreso de XP.

El HUD pertenece a Game y no a DialogueUI.

Debe permanecer visible mientras el jugador está dentro de las escenas de juego/mapa.

La actualización del HUD se realiza mediante eventos del Player, evitando polling continuo mediante _process().


==================================================
11. ESTADO / INVENTARIO
==================================================

Game también contiene un panel de Estado que se abre mediante el botón INV.

El panel proporciona información más detallada que el HUD.

Actualmente muestra:

- nivel;
- progreso;
- barra de XP;
- inventario.

El inventario se obtiene desde DialogueManager.

El panel se muestra bajo demanda.

La existencia simultánea de:

- HUD permanente;
- Estado bajo demanda

es intencionada.

No representan dos sistemas diferentes de XP.

Representan dos vistas del mismo estado:

HUD
  = información rápida y permanente.

Estado
  = información detallada bajo demanda.


==================================================
12. DIALOGO.TSCN
==================================================

La escena de diálogo anteriormente contenía elementos propios de nivel y XP.

Se consideró incorrecto porque nivel y XP son información global del jugador y no información específica de una conversación.

En v0.0.1 fueron eliminados de dialogo.tscn:

- Panel2
- lbl_nivel
- bar_progreso

La escena de diálogo queda conceptualmente dedicada a:

- NameLabel;
- DialogueText;
- OptionsContainer.

No deben volver a introducirse elementos de nivel o XP en dialogo.tscn sin una decisión arquitectónica nueva y explícita.


==================================================
13. FLUJO DE XP
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
14. NIVELES ACTUALES
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

Estos valores no deben modificarse sin revisar previamente cómo está implementada la progresión del jugador.


==================================================
15. CARGA DE ESCENAS
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
Player


Cuando se carga una escena de juego:

- se limpia la escena anterior;
- se actualiza mapa_actual;
- se instancia el nuevo mapa;
- se carga el estado persistente del jugador;
- se localiza el Player;
- se conecta su señal xp_changed;
- se actualiza inmediatamente el HUD.


==================================================
16. DECISIONES ARQUITECTONICAS CONSOLIDADAS
==================================================

DECISION 1
Nivel y XP pertenecen al HUD global de Game.

MOTIVO:
Son información persistente del estado del jugador.


DECISION 2
DialogueUI no gestiona nivel ni XP.

MOTIVO:
Evitar mezclar presentación de diálogos con estado global del jugador.


DECISION 3
El HUD se actualiza mediante xp_changed.

MOTIVO:
Usar una arquitectura orientada a eventos y evitar actualizaciones continuas innecesarias.


DECISION 4
Player es la fuente del estado de XP.

MOTIVO:
La UI debe presentar el estado, no convertirse en propietaria del mismo.


DECISION 5
Game coordina la presentación global.

MOTIVO:
Game es propietario de la UI global y conoce el mapa y Player actuales.


DECISION 6
El panel Estado conserva su propia representación de nivel y XP.

MOTIVO:
El HUD y Estado tienen funciones visuales diferentes.


DECISION 7
DialogueUI se mantiene independiente del Player.

MOTIVO:
Reducir acoplamiento y permitir que el sistema de diálogos sea reutilizable.


==================================================
17. CAMBIO REALIZADO EN v0.0.1
==================================================

Antes:

dialogo.tscn
  |
  +-- diálogo
  |
  +-- nivel
  |
  +-- XP


Después:

Game
  |
  +-- HUD
  |    |
  |    +-- nivel
  |    +-- XP
  |
  +-- Estado
       |
       +-- nivel
       +-- XP
       +-- inventario


DialogueUI
  |
  +-- solamente diálogo


El cambio fue probado correctamente.


==================================================
18. PRUEBAS REALIZADAS
==================================================

Se comprobó correctamente:

- arranque del proyecto;
- entrada al mapa;
- aparición del HUD;
- visualización del nivel;
- visualización del progreso;
- funcionamiento de la barra XP;
- apertura del panel INV;
- cierre del panel INV;
- visualización del inventario;
- funcionamiento del diálogo;
- funcionamiento de las opciones;
- obtención de XP durante un diálogo;
- actualización del HUD después de obtener XP;
- eliminación de Panel2 de dialogo.tscn;
- eliminación de lbl_nivel de dialogo.tscn;
- eliminación de bar_progreso de dialogo.tscn.

El sistema continúa funcionando después de eliminar los elementos de XP de la escena de diálogo.


==================================================
19. PROBLEMA ENCONTRADO Y RESUELTO
==================================================

Durante la prueba posterior al cambio se observó inicialmente que el botón INV parecía no funcionar.

La causa no era el código.

El nodo Estado había quedado oculto en la escena durante la comprobación.

Se corrigió la prueba dejando la configuración correspondiente y se confirmó que el sistema de inventario funcionaba correctamente.

Conclusión:

No existe actualmente un problema conocido con el botón INV.


==================================================
20. ESTADO ACTUAL
==================================================

v0.0.1 está considerada una versión funcional y probada.

La reorganización de nivel/XP está terminada.

Actualmente:

- HUD global funcionando;
- nivel funcionando;
- XP funcionando;
- barra XP funcionando;
- actualización mediante xp_changed funcionando;
- diálogos funcionando;
- opciones de diálogo funcionando;
- inventario funcionando;
- panel Estado funcionando;
- separación Game / DialogueUI establecida;
- restos de XP eliminados de dialogo.tscn.


==================================================
21. ARCHIVOS RELEVANTES PARA ESTE SISTEMA
==================================================

Escenas:

- escenas/game.tscn
- escena de diálogo correspondiente a dialogo.tscn
- escenas de mapas, especialmente aldea.tscn
- bienvenida.tscn

Scripts:

- scripts/game.gd
- scripts/dialogue_ui.gd
- script del Player
- DialogueManager

Los nombres y rutas reales deben comprobarse en el repositorio antes de modificar archivos.


==================================================
22. METODOLOGIA DE TRABAJO
==================================================

Antes de modificar código:

1. Estudiar el archivo real.
2. Estudiar las escenas relacionadas.
3. Identificar dependencias.
4. Determinar qué sistema debe ser responsable de la funcionalidad.
5. Evitar duplicar responsabilidades.
6. Hacer el cambio mínimo necesario.
7. Probar la funcionalidad.
8. Comprobar que no se ha roto ninguna funcionalidad existente.
9. Registrar el avance en content_context.me.
10. Solo después considerar cerrada la versión o avance.

No reconstruir scripts completos basándose en suposiciones cuando el archivo real puede ser consultado.

Cuando se solicite un script completo, debe generarse a partir de la versión real del archivo.


==================================================
23. PRINCIPIO DE CONSERVACION
==================================================

No modificar sistemas que no sean necesarios para resolver el objetivo actual.

Especialmente:

- no modificar Player sin necesidad;
- no modificar DialogueManager sin necesidad;
- no introducir lógica global en DialogueUI;
- no duplicar sistemas de XP;
- no eliminar funcionalidades existentes sin comprobar sus referencias.

La arquitectura debe evolucionar de forma incremental.


==================================================
24. REGISTRO DE VERSIONES
==================================================

v0.0.1

Objetivo:
Separar la visualización global de nivel/XP del sistema de diálogos.

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
25. SIGUIENTE CONTINUACION
==================================================

El proyecto debe continuar desde el estado v0.0.1.

No se debe volver a implementar el cambio de HUD/XP ya realizado.

Antes de comenzar el siguiente objetivo:

- revisar este documento;
- revisar el estado actual del repositorio;
- identificar exactamente qué se quiere modificar;
- estudiar los archivos afectados;
- mantener las decisiones arquitectónicas establecidas.

El siguiente avance funcional deberá registrarse aquí cuando haya sido implementado y probado correctamente.


==================================================
FIN DE content_context.me
==================================================