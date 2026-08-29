extends Node


const BIENVENIDA_SCENE := "res://escenas/bienvenida.tscn"
const ALDEA_SCENE := "res://escenas/aldea.tscn"


@onready var scene_container: Node = $SceneContainer
@onready var player_actual: Node = $Player

@onready var ui: CanvasLayer = $UI

# HUD general
@onready var hud_nivel: Label = $UI/HUD/lbl_Nivel
@onready var hud_progreso: Label = $UI/HUD/lbl_Progreso
@onready var hud_barra_xp: ProgressBar = $UI/HUD/bar_Progreso

# Panel de estado
@onready var estado_panel: Panel = $UI/Estado/Panel
@onready var boton_estado: Button = $UI/BotonEstado
@onready var boton_cerrar: Button = $UI/Estado/Panel/Cerrar

@onready var estado_titulo: Label = $UI/Estado/Panel/Titulo
@onready var estado_nivel: Label = $UI/Estado/Panel/Nivel
@onready var estado_progreso: Label = $UI/Estado/Panel/Progreso
@onready var estado_barra_xp: ProgressBar = $UI/Estado/Panel/BarraXP
@onready var estado_inventario: Label = $UI/Estado/Panel/Scroll/Inventario


var mapa_actual: Node = null


const NIVELES := {
	"a1": 70,
	"a2": 120,
	"b1": 340,
	"b2": 410,
	"c1": 740
}


const ORDEN_NIVELES := [
	"a1",
	"a2",
	"b1",
	"b2",
	"c1"
]


func _ready() -> void:

	estado_panel.visible = false

	player_actual.visible = false
	player_actual.set_physics_process(false)
	player_actual.set_process_unhandled_input(false)

	boton_estado.pressed.connect(
		_abrir_estado
	)

	boton_cerrar.pressed.connect(
		_cerrar_estado
	)

	if player_actual.has_signal("xp_changed"):

		player_actual.xp_changed.connect(
			_actualizar_hud
		)

	cargar_escena(
		BIENVENIDA_SCENE
	)



func cargar_escena(
	scene_path: String
) -> void:

	# Desactivar Player mientras no hay mapa cargado.
	player_actual.visible = false
	player_actual.set_physics_process(false)
	player_actual.set_process_unhandled_input(false)

	for child in scene_container.get_children():
		child.queue_free()

	mapa_actual = null

	ui.visible = scene_path != BIENVENIDA_SCENE

	var scene: PackedScene = load(
		scene_path
	)

	if scene == null:

		push_error(
			"No se pudo cargar la escena: "
			+ scene_path
		)

		return

	var instance: Node = scene.instantiate()

	if scene_path != BIENVENIDA_SCENE:

		mapa_actual = instance

	scene_container.add_child(
		instance
	)

	if mapa_actual != null:

		_configurar_player()

		DialogueManager.load_player_status()

	if instance.has_signal("jugar"):

		instance.jugar.connect(
			ir_a_aldea
		)



func _configurar_player() -> void:

	if mapa_actual == null:

		player_actual.visible = false
		player_actual.set_physics_process(false)
		player_actual.set_process_unhandled_input(false)

		return

	var spawn := mapa_actual.get_node_or_null(
		"SpawnPlayer"
	)

	if spawn == null:

		push_warning(
			"No se encontró SpawnPlayer en el mapa."
		)

		player_actual.visible = false
		player_actual.set_physics_process(false)
		player_actual.set_process_unhandled_input(false)

		return

	player_actual.global_position = (
		spawn.global_position
	)

	player_actual.visible = true
	player_actual.set_physics_process(true)
	player_actual.set_process_unhandled_input(true)

	_configurar_camera()

	_actualizar_hud()



func _configurar_camera() -> void:

	var camera: Camera2D = player_actual.get_node_or_null(
		"Camera2D"
	)

	if camera == null:

		push_warning(
			"No se encontró Camera2D en el Player."
		)

		return

	var camera_bounds: Area2D = mapa_actual.get_node_or_null(
		"CameraBounds"
	)

	if camera_bounds == null:

		push_warning(
			"No se encontró CameraBounds en el mapa."
		)

		return

	var collision_shape: CollisionShape2D = (
		camera_bounds.get_node_or_null(
			"CollisionShape2D"
		)
	)

	if collision_shape == null:

		push_warning(
			"No se encontró CollisionShape2D dentro de CameraBounds."
		)

		return

	if collision_shape.shape == null:

		push_warning(
			"CameraBounds no tiene un Shape definido."
		)

		return

	if not collision_shape.shape is RectangleShape2D:

		push_warning(
			"CameraBounds debe utilizar RectangleShape2D."
		)

		return

	var rectangle: RectangleShape2D = (
		collision_shape.shape as RectangleShape2D
	)

	var size: Vector2 = rectangle.size
	var center: Vector2 = collision_shape.global_position

	camera.limit_left = int(
		center.x - size.x / 2.0
	)

	camera.limit_right = int(
		center.x + size.x / 2.0
	)

	camera.limit_top = int(
		center.y - size.y / 2.0
	)

	camera.limit_bottom = int(
		center.y + size.y / 2.0
	)

	camera.enabled = true



func ir_a_aldea() -> void:

	cargar_escena(
		ALDEA_SCENE
	)



func _actualizar_hud() -> void:

	if player_actual == null:
		return

	if not player_actual.visible:
		return

	var nivel: String = str(
		player_actual.nivel
	).to_lower()

	var xp: int = int(
		player_actual.xp
	)

	hud_nivel.text = nivel.to_upper()

	if not NIVELES.has(nivel):

		hud_progreso.text = "XP: %d" % xp

		hud_barra_xp.min_value = 0
		hud_barra_xp.max_value = 1
		hud_barra_xp.value = 0

		return

	var indice := ORDEN_NIVELES.find(
		nivel
	)

	if indice == -1:
		return

	var limite_superior: int = NIVELES[nivel]

	var limite_inferior := 0

	if indice > 0:

		var nivel_anterior: String = (
			ORDEN_NIVELES[indice - 1]
		)

		limite_inferior = (
			NIVELES[nivel_anterior] + 1
		)

	var rango := (
		limite_superior
		- limite_inferior
	)

	if rango <= 0:

		hud_progreso.text = (
			"XP: %d / %d"
			% [xp, limite_superior]
		)

		hud_barra_xp.min_value = 0
		hud_barra_xp.max_value = 1
		hud_barra_xp.value = 1

		return

	var progreso := (
		xp - limite_inferior
	)

	progreso = clamp(
		progreso,
		0,
		rango
	)

	hud_progreso.text = (
		"XP: %d / %d"
		% [xp, limite_superior]
	)

	hud_barra_xp.min_value = 0
	hud_barra_xp.max_value = rango
	hud_barra_xp.value = progreso

	hud_barra_xp.tooltip_text = (
		"%d / %d XP"
		% [progreso, rango]
	)



func _abrir_estado() -> void:

	_actualizar_estado()

	estado_panel.visible = true



func _cerrar_estado() -> void:

	estado_panel.visible = false



func _actualizar_estado() -> void:

	if mapa_actual == null:
		return

	if player_actual == null:
		return

	_actualizar_nivel(
		player_actual
	)

	_actualizar_experiencia(
		player_actual
	)

	_actualizar_inventario()



func _actualizar_nivel(
	player: Node
) -> void:

	var nivel: String = str(
		player.nivel
	).to_lower()

	estado_nivel.text = nivel.to_upper()



func _actualizar_experiencia(
	player: Node
) -> void:

	var nivel: String = str(
		player.nivel
	).to_lower()

	var xp: int = int(
		player.xp
	)

	if not NIVELES.has(nivel):

		estado_progreso.text = "XP: %d" % xp

		estado_barra_xp.min_value = 0
		estado_barra_xp.max_value = 1
		estado_barra_xp.value = 0

		return

	var indice := ORDEN_NIVELES.find(
		nivel
	)

	if indice == -1:
		return

	var limite_superior: int = NIVELES[nivel]

	var limite_inferior := 0

	if indice > 0:

		var nivel_anterior: String = (
			ORDEN_NIVELES[indice - 1]
		)

		limite_inferior = (
			NIVELES[nivel_anterior] + 1
		)

	var rango := (
		limite_superior
		- limite_inferior
	)

	if rango <= 0:

		estado_progreso.text = (
			"XP: %d / %d"
			% [xp, limite_superior]
		)

		estado_barra_xp.min_value = 0
		estado_barra_xp.max_value = 1
		estado_barra_xp.value = 1

		return

	var progreso := (
		xp - limite_inferior
	)

	progreso = clamp(
		progreso,
		0,
		rango
	)

	estado_progreso.text = (
		"XP: %d / %d"
		% [xp, limite_superior]
	)

	estado_barra_xp.min_value = 0
	estado_barra_xp.max_value = rango
	estado_barra_xp.value = progreso

	estado_barra_xp.tooltip_text = (
		"%d / %d XP"
		% [progreso, rango]
	)



func _actualizar_inventario() -> void:

	var inventario: Array[String] = (
		DialogueManager.inventory
	)

	if inventario.is_empty():

		estado_inventario.text = (
			"Inventario vacío"
		)

		return

	var texto := ""

	for item in inventario:

		if not texto.is_empty():

			texto += "\n"

		texto += "- " + item

	estado_inventario.text = texto
