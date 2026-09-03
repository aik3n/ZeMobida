@tool
extends CharacterBody2D


enum TipoSeguimiento {
	NUNCA_SEGUIR,
	SEGUIR_Y_QUEDARSE,
	SEGUIR_Y_VOLVER
}


@export var sprite: Texture2D:
	set(value):
		sprite = value
		_actualizar_sprite_visual()

@export var tipo_seguimiento: TipoSeguimiento = TipoSeguimiento.SEGUIR_Y_VOLVER


var player_nearby := false

var player: CharacterBody2D = null
var player_depth_collision: CollisionShape2D = null

@onready var depth_collision: CollisionShape2D = $Collision
@onready var name_label: Label = $NameLabel

var posicion_seguimiento: Vector2
var posicion_seguimiento_guardada := false

var siguiendo := false


const VELOCIDAD_SEGUIR := 100.0
const DISTANCIA_REANUDAR := 120.0
const DISTANCIA_LLEGADA := 5.0

# Profundidad visual respecto al Player.
# Fondo permanece en -10 y los frontales fijos en +10.
const PROFUNDIDAD_Z_DETRAS_PLAYER := 1
const PROFUNDIDAD_Z_DELANTE_PLAYER := 3

# Estado editorial del guion disponible para el nivel actual.
const NAME_COLOR_NONE := Color("#D0D0D0")
const NAME_COLOR_OFFICIAL_EXACT := Color("#45E07B")
const NAME_COLOR_LOCAL_EXACT := Color("#4AA8FF")
const NAME_COLOR_OFFICIAL_GENERIC := Color("#FFD166")


func _actualizar_sprite_visual() -> void:
	var nodo_sprite := get_node_or_null("Sprite2D") as Sprite2D

	if nodo_sprite != null:
		nodo_sprite.texture = sprite


func get_nombre_tecnico() -> String:
	return str(name).to_lower()


func _actualizar_estado_nombre_dialogo() -> void:
	if Engine.is_editor_hint():
		return

	if name_label == null or player == null:
		return

	name_label.text = str(name).replace("_", " ").capitalize()

	var map_name := get_map_name()

	if map_name.is_empty():
		name_label.modulate = NAME_COLOR_NONE
		return

	var state := DialogueManager.get_dialogue_assignment_state(
		map_name,
		get_nombre_tecnico(),
		str(player.nivel)
	)

	match state:
		"local_exact":
			name_label.modulate = NAME_COLOR_LOCAL_EXACT
		"official_exact":
			name_label.modulate = NAME_COLOR_OFFICIAL_EXACT
		"official_generic":
			name_label.modulate = NAME_COLOR_OFFICIAL_GENERIC
		_:
			name_label.modulate = NAME_COLOR_NONE


func _ready() -> void:
	_actualizar_sprite_visual()

	# @tool permite reflejar el sprite dentro del editor. Toda la lógica
	# de gameplay sigue ejecutándose exclusivamente durante el juego.
	if Engine.is_editor_hint():
		return

	var game := get_tree().current_scene

	if game != null:
		player = game.get_node_or_null("Player")

		if player != null:
			player_depth_collision = (
				player.get_node_or_null("CollisionShape2D") as CollisionShape2D
			)

			if player.has_signal("xp_changed"):
				player.xp_changed.connect(
					_actualizar_estado_nombre_dialogo
				)

	DialogueManager.dialogue_sources_changed.connect(
		_actualizar_estado_nombre_dialogo
	)

	_actualizar_estado_nombre_dialogo()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if player == null:
		return

	_actualizar_profundidad_visual()
	_actualizar_seguimiento()

	match tipo_seguimiento:

		TipoSeguimiento.NUNCA_SEGUIR:

			velocity = Vector2.ZERO


		TipoSeguimiento.SEGUIR_Y_QUEDARSE:

			if siguiendo:

				_seguir_player()

			else:

				velocity = Vector2.ZERO


		TipoSeguimiento.SEGUIR_Y_VOLVER:

			if siguiendo:

				_seguir_player()

			elif posicion_seguimiento_guardada:

				volver_posicion_seguimiento()

			else:

				velocity = Vector2.ZERO


func _actualizar_profundidad_visual() -> void:
	if depth_collision == null or player_depth_collision == null:
		return

	var pnj_depth_y := depth_collision.global_position.y
	var player_depth_y := player_depth_collision.global_position.y

	# La posicion Y de las colisiones de los pies actua como referencia
	# de profundidad visual.
	if pnj_depth_y <= player_depth_y:
		z_index = PROFUNDIDAD_Z_DETRAS_PLAYER
	else:
		z_index = PROFUNDIDAD_Z_DELANTE_PLAYER


func _actualizar_seguimiento() -> void:

	var nuevo_estado: bool = bool(DialogueManager.has_item(
		get_nombre_tecnico()
	))

	# El seguimiento acaba de comenzar.
	if nuevo_estado and not siguiendo:

		posicion_seguimiento = global_position
		posicion_seguimiento_guardada = true

	# El seguimiento acaba de terminar.
	if not nuevo_estado and siguiendo:

		pass

	siguiendo = nuevo_estado


func _seguir_player() -> void:

	var distancia := global_position.distance_to(
		player.global_position
	)

	# Si el PNJ ya está dentro de la distancia
	# de reanudación, no se mueve.
	if distancia <= DISTANCIA_REANUDAR:

		velocity = Vector2.ZERO
		return

	var direccion := global_position.direction_to(
		player.global_position
	)

	velocity = direccion * VELOCIDAD_SEGUIR

	move_and_slide()


func volver_posicion_seguimiento() -> void:

	var distancia := global_position.distance_to(
		posicion_seguimiento
	)

	if distancia <= DISTANCIA_LLEGADA:

		velocity = Vector2.ZERO
		return

	var direccion := global_position.direction_to(
		posicion_seguimiento
	)

	velocity = direccion * VELOCIDAD_SEGUIR

	move_and_slide()


func get_map_name() -> String:

	var game := get_tree().current_scene

	if game == null:

		push_error(
			"No se encontró Game."
		)

		return ""

	var mapa_actual = game.get("mapa_actual")

	if mapa_actual == null:

		push_error(
			"No se encontró el mapa actual."
		)

		return ""

	var scene_path: String = mapa_actual.scene_file_path

	return scene_path.get_file().get_basename().to_lower()


func get_dialogue_path() -> String:

	var map_name := get_map_name()

	if map_name.is_empty():

		return ""

	var game := get_tree().current_scene

	if game == null:

		push_error(
			"No se encontró Game."
		)

		return ""

	var player_node: Node = game.get_node_or_null(
		"Player"
	)

	if player_node == null:

		push_error(
			"No se encontró el Player."
		)

		return ""

	var nombre_tecnico := get_nombre_tecnico()

	var dialogue_path: String = str(DialogueManager.resolve_dialogue_path(
		map_name,
		nombre_tecnico,
		str(player_node.nivel)
	))

	if dialogue_path.is_empty():

		push_error(
			"No existe diálogo para: %s_%s"
			% [map_name, nombre_tecnico]
		)

	return dialogue_path


func _on_interaction_area_body_entered(body: Node) -> void:
	if Engine.is_editor_hint():
		return

	if body.name != "Player":

		return

	player_nearby = true

	if (
		not DialogueManager.dialogue_active
		and not DialogueManager.editor_active
	):

		var dialogue_path := get_dialogue_path()

		if dialogue_path.is_empty():

			return

		DialogueManager.start_dialogue(
			dialogue_path,
			get_nombre_tecnico()
		)


func _on_interaction_area_body_exited(body: Node) -> void:
	if Engine.is_editor_hint():
		return

	if body.name != "Player":

		return

	player_nearby = false

	if DialogueManager.dialogue_active:

		DialogueManager.end_dialogue()


func _on_interaction_area_area_exited(_area: Area2D) -> void:

	pass
