extends Node


const BIENVENIDA_SCENE := "res://escenas/bienvenida.tscn"
const SETTINGS_FILE := "user://settings.cfg"
const MAP_POSITIONS_SECTION := "map_positions"

# PROFUNDIDAD_AUTOMATICA_STATICBODY
const PROFUNDIDAD_Z_DETRAS_PLAYER := 1
const PROFUNDIDAD_Z_DELANTE_PLAYER := 3


@onready var scene_container: Node = $SceneContainer
@onready var player_actual: Node = $Player
@onready var player_depth_collision: CollisionShape2D = (
	$Player/CollisionShape2D
)

@onready var ui: CanvasLayer = $UI

# Navegación y estado
@onready var boton_mapas: Button = $EstadoUI/Estado/Panel/VolverMapas
@onready var boton_estado: Button = $UI/BotonEstado

# Panel de estado
@onready var estado_panel: Panel = $EstadoUI/Estado/Panel
@onready var boton_cerrar: Button = $EstadoUI/Estado/Panel/Cerrar
@onready var boton_vaciar_inventario: Button = (
	$EstadoUI/Estado/Panel/VaciarInventario
)
@onready var confirmar_vaciar_inventario: Control = (
	$EstadoUI/Estado/ConfirmarVaciarInventario
)
@onready var confirmar_vaciar_ok: Button = (
	$EstadoUI/Estado/ConfirmarVaciarInventario/Panel/Ok
)
@onready var confirmar_vaciar_cancel: Button = (
	$EstadoUI/Estado/ConfirmarVaciarInventario/Panel/Cancel
)

@onready var estado_titulo: Label = $EstadoUI/Estado/Panel/Titulo
@onready var estado_inventario: Label = $EstadoUI/Estado/Panel/Scroll/Inventario


var mapa_actual: Node = null
var objetos_profundidad: Array[Dictionary] = []


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

	boton_vaciar_inventario.pressed.connect(
		_pedir_vaciar_inventario
	)

	confirmar_vaciar_ok.pressed.connect(
		_vaciar_inventario
	)

	confirmar_vaciar_cancel.pressed.connect(
		_cancelar_vaciado_inventario
	)

	cargar_escena(
		BIENVENIDA_SCENE
	)


func _process(_delta: float) -> void:
	if objetos_profundidad.is_empty():
		return

	if not player_actual.visible:
		return

	_actualizar_profundidad_visual()


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
	objetos_profundidad.clear()

	# Fuera de un mapa no existe inventario activo.
	DialogueManager.load_map_inventory("")

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

		# El inventario pertenece a la aventura concreta, usando el
		# mismo ID completo que la persistencia de posición.
		DialogueManager.load_map_inventory(
			scene_path.get_file().get_basename().to_lower()
		)

	scene_container.add_child(
		instance
	)

	if mapa_actual != null:

		_configurar_player()
		_registrar_objetos_profundidad(mapa_actual)
		_actualizar_profundidad_visual()

	if instance.has_signal("jugar"):

		instance.jugar.connect(
			ir_a_mapa
		)



func _registrar_objetos_profundidad(root: Node) -> void:
	objetos_profundidad.clear()
	_buscar_objetos_profundidad(root)


func _buscar_objetos_profundidad(node: Node) -> void:
	if node is StaticBody2D:
		var body := node as StaticBody2D
		var depth_collision: CollisionShape2D = null
		var collision_count := 0
		var sprite_count := 0

		for child in body.get_children():
			if child is CollisionShape2D:
				collision_count += 1
				depth_collision = child as CollisionShape2D
			elif child is Sprite2D:
				sprite_count += 1

		# Convencion automatica:
		# StaticBody2D + exactamente una CollisionShape2D
		# + uno o mas Sprite2D directos.
		if (
			collision_count == 1
			and sprite_count >= 1
			and depth_collision != null
		):
			objetos_profundidad.append({
				"body": body,
				"collision": depth_collision
			})

	for child in node.get_children():
		_buscar_objetos_profundidad(child)


func _actualizar_profundidad_visual() -> void:
	if player_depth_collision == null:
		return

	var player_depth_y := player_depth_collision.global_position.y

	for item in objetos_profundidad:
		var body := item.get("body") as StaticBody2D
		var collision := item.get("collision") as CollisionShape2D

		if not is_instance_valid(body):
			continue

		if not is_instance_valid(collision):
			continue

		# La CollisionShape2D situada en la base del objeto
		# representa su profundidad visual respecto a los pies del Player.
		if collision.global_position.y <= player_depth_y:
			body.z_index = PROFUNDIDAD_Z_DETRAS_PLAYER
		else:
			body.z_index = PROFUNDIDAD_Z_DELANTE_PLAYER


func _configurar_player() -> void:

	if mapa_actual == null:

		player_actual.visible = false
		player_actual.set_physics_process(false)
		player_actual.set_process_unhandled_input(false)

		return

	var spawn := mapa_actual.get_node_or_null(
		"SpawnPlayer"
	) as Node2D

	var posicion_fallback := Vector2.ZERO

	if spawn != null:
		posicion_fallback = spawn.global_position

	var posicion_inicial: Vector2 = _obtener_posicion_mapa(
		posicion_fallback
	)

	player_actual.global_position = posicion_inicial

	# Player es persistente: al cambiarlo de posición también hay que
	# sincronizar su destino para que no intente volver al punto anterior.
	player_actual.destino = posicion_inicial

	player_actual.visible = true
	player_actual.set_physics_process(true)
	player_actual.set_process_unhandled_input(true)

	_configurar_camera()



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
		print(
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
		print(
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

		print(
			"No se encontró Camera2D en el Player."
		)

		return

	# Los mapas ilustrados definen sus límites directamente con
	# un Sprite2D llamado Fondo. Su textura se usa a escala 1:1.
	if _configurar_limites_desde_fondo(camera):
		camera.enabled = true
		return

	# Sin Fondo el mapa se considera un prototipo. Se usan límites
	# conservadores alrededor del origen para que siga siendo jugable.
	camera.limit_left = -1000
	camera.limit_right = 1000
	camera.limit_top = -1000
	camera.limit_bottom = 1000
	camera.position = Vector2.ZERO
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

	confirmar_vaciar_inventario.visible = false
	estado_panel.visible = false

	cargar_escena(
		BIENVENIDA_SCENE
	)



func _abrir_estado() -> void:

	confirmar_vaciar_inventario.visible = false
	_actualizar_estado()

	estado_panel.visible = true



func _cerrar_estado() -> void:

	confirmar_vaciar_inventario.visible = false
	estado_panel.visible = false



func _pedir_vaciar_inventario() -> void:
	if DialogueManager.inventory.is_empty():
		return

	confirmar_vaciar_inventario.visible = true



func _vaciar_inventario() -> void:
	confirmar_vaciar_inventario.visible = false

	if DialogueManager.clear_inventory():
		_actualizar_inventario()



func _cancelar_vaciado_inventario() -> void:
	confirmar_vaciar_inventario.visible = false



func _actualizar_estado() -> void:

	if mapa_actual == null:
		return

	_actualizar_inventario()



func _actualizar_inventario() -> void:

	var inventario: Array[String] = (
		DialogueManager.inventory
	)

	boton_vaciar_inventario.disabled = inventario.is_empty()

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
