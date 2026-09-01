extends Node


const BIENVENIDA_SCENE := "res://escenas/bienvenida.tscn"
const SETTINGS_FILE := "user://settings.cfg"
const MAP_POSITIONS_SECTION := "map_positions"

const NIVELES_DATA := preload(
	"res://scripts/niveles.gd"
)


@onready var scene_container: Node = $SceneContainer
@onready var player_actual: Node = $Player

@onready var ui: CanvasLayer = $UI

# HUD general
@onready var hud_nivel: Label = $UI/HUD/lbl_Nivel
@onready var hud_progreso: Label = $UI/HUD/lbl_Progreso
@onready var hud_barra_xp: ProgressBar = $UI/HUD/bar_Progreso

# Navegación y estado
@onready var boton_mapas: Button = $EstadoUI/Estado/Panel/VolverMapas
@onready var boton_estado: Button = $UI/BotonEstado

# Panel de estado
@onready var estado_panel: Panel = $EstadoUI/Estado/Panel
@onready var boton_cerrar: Button = $EstadoUI/Estado/Panel/Cerrar

@onready var estado_titulo: Label = $EstadoUI/Estado/Panel/Titulo
@onready var estado_nivel: Label = $EstadoUI/Estado/Panel/Nivel
@onready var estado_progreso: Label = $EstadoUI/Estado/Panel/Progreso
@onready var estado_barra_xp: ProgressBar = $EstadoUI/Estado/Panel/BarraXP
@onready var estado_inventario: Label = $EstadoUI/Estado/Panel/Scroll/Inventario


var mapa_actual: Node = null


func _ready() -> void:

	estado_panel.visible = false

	player_actual.visible = false
	player_actual.set_physics_process(false)
	player_actual.set_process_unhandled_input(false)

	boton_mapas.pressed.connect(
		_volver_a_mapas
	)

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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_guardar_posicion_mapa_actual()

	elif what == NOTIFICATION_APPLICATION_PAUSED:
		_guardar_posicion_mapa_actual()



func cargar_escena(
	scene_path: String
) -> void:

	# Si venimos de un mapa, conservar la última posición del Player.
	_guardar_posicion_mapa_actual()

	# Desactivar Player y su cámara mientras no hay mapa cargado.
	player_actual.visible = false
	player_actual.set_physics_process(false)
	player_actual.set_process_unhandled_input(false)

	var camera: Camera2D = player_actual.get_node_or_null(
		"Camera2D"
	)

	if camera != null:
		camera.position = Vector2.ZERO
		camera.enabled = false

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
			ir_a_mapa
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

	var posicion_inicial: Vector2 = _obtener_posicion_mapa(
		spawn.global_position
	)

	player_actual.global_position = posicion_inicial

	# Player es persistente: al cambiarlo de posición también hay que
	# sincronizar su destino para que no intente volver al punto anterior.
	player_actual.destino = posicion_inicial

	player_actual.visible = true
	player_actual.set_physics_process(true)
	player_actual.set_process_unhandled_input(true)

	_configurar_camera()

	_actualizar_hud()



func _get_map_id(mapa: Node) -> String:
	if mapa == null:
		return ""

	var scene_path: String = mapa.scene_file_path

	if scene_path.is_empty():
		return ""

	return scene_path.get_file().get_basename().to_lower()



func _guardar_posicion_mapa_actual() -> void:
	if mapa_actual == null:
		return

	if player_actual == null or not player_actual.visible:
		return

	var map_id: String = _get_map_id(
		mapa_actual
	)

	if map_id.is_empty():
		return

	var config := ConfigFile.new()
	var error := config.load(
		SETTINGS_FILE
	)

	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning(
			"No se pudo leer settings.cfg para guardar la posición."
		)
		return

	config.set_value(
		MAP_POSITIONS_SECTION,
		map_id,
		player_actual.global_position
	)

	error = config.save(
		SETTINGS_FILE
	)

	if error != OK:
		push_warning(
			"No se pudo guardar la posición del mapa."
		)



func _obtener_posicion_mapa(
	fallback: Vector2
) -> Vector2:
	if mapa_actual == null:
		return fallback

	var map_id: String = _get_map_id(
		mapa_actual
	)

	if map_id.is_empty():
		return fallback

	var config := ConfigFile.new()
	var error := config.load(
		SETTINGS_FILE
	)

	if error != OK:
		return fallback

	var value: Variant = config.get_value(
		MAP_POSITIONS_SECTION,
		map_id,
		fallback
	)

	if value is Vector2:
		return value

	return fallback


func _configurar_camera() -> void:

	var camera: Camera2D = player_actual.get_node_or_null(
		"Camera2D"
	)

	if camera == null:

		push_warning(
			"No se encontró Camera2D en el Player."
		)

		return

	# Los mapas ilustrados pueden definir sus límites directamente con
	# un Sprite2D llamado Fondo. Su textura se usa a escala 1:1.
	if _configurar_limites_desde_fondo(camera):
		camera.enabled = true
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



func _configurar_limites_desde_fondo(camera: Camera2D) -> bool:
	var fondo_node := mapa_actual.get_node_or_null("Fondo")

	if not fondo_node is Sprite2D:
		return false

	var fondo := fondo_node as Sprite2D

	if fondo.texture == null:
		return false

	var local_rect := fondo.get_rect()
	var corners: Array[Vector2] = [
		fondo.to_global(local_rect.position),
		fondo.to_global(
			Vector2(local_rect.end.x, local_rect.position.y)
		),
		fondo.to_global(local_rect.end),
		fondo.to_global(
			Vector2(local_rect.position.x, local_rect.end.y)
		)
	]

	var min_x := corners[0].x
	var max_x := corners[0].x
	var min_y := corners[0].y
	var max_y := corners[0].y

	for point in corners:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)

	camera.limit_left = int(floor(min_x))
	camera.limit_right = int(ceil(max_x))
	camera.limit_top = int(floor(min_y))
	camera.limit_bottom = int(ceil(max_y))
	camera.position = Vector2.ZERO

	return true



func ir_a_mapa(mapa_path: String) -> void:

	cargar_escena(mapa_path)



func _volver_a_mapas() -> void:

	# El editor puede contener cambios sin guardar. El usuario debe
	# cerrarlo o guardarlo antes de abandonar el mapa.
	if DialogueManager.editor_active:
		return

	if DialogueManager.dialogue_active:
		DialogueManager.end_dialogue()

	estado_panel.visible = false

	cargar_escena(
		BIENVENIDA_SCENE
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

	if not NIVELES_DATA.tiene_nivel(nivel):

		hud_progreso.text = "XP: %d" % xp

		hud_barra_xp.min_value = 0
		hud_barra_xp.max_value = 1
		hud_barra_xp.value = 0

		return

	var limite_superior := (
		NIVELES_DATA.xp_limite_superior(
			nivel
		)
	)

	var limite_inferior := (
		NIVELES_DATA.xp_limite_inferior(
			nivel
		)
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

	if not NIVELES_DATA.tiene_nivel(nivel):

		estado_progreso.text = "XP: %d" % xp

		estado_barra_xp.min_value = 0
		estado_barra_xp.max_value = 1
		estado_barra_xp.value = 0

		return

	var limite_superior := (
		NIVELES_DATA.xp_limite_superior(
			nivel
		)
	)

	var limite_inferior := (
		NIVELES_DATA.xp_limite_inferior(
			nivel
		)
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
