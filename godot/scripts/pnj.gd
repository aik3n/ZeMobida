extends CharacterBody2D


@export var nombre: String = "PNJ"
@export var sprite: Texture2D


enum TipoSeguimiento {
	NUNCA_SEGUIR,
	SEGUIR_Y_QUEDARSE,
	SEGUIR_Y_VOLVER
}


@export var tipo_seguimiento: TipoSeguimiento = TipoSeguimiento.SEGUIR_Y_VOLVER


var player_nearby := false

var player: CharacterBody2D = null

var posicion_seguimiento: Vector2
var posicion_seguimiento_guardada := false

var siguiendo := false


const VELOCIDAD_SEGUIR := 100.0
const DISTANCIA_REANUDAR := 120.0
const DISTANCIA_LLEGADA := 5.0


@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:

	sprite_2d.texture = sprite

	var game := get_tree().current_scene

	if game != null:
		player = game.get_node_or_null("Player")


func _physics_process(_delta: float) -> void:

	if player == null:
		return

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


func _actualizar_seguimiento() -> void:

	var nuevo_estado := DialogueManager.has_item(
		nombre.to_lower()
	)

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

	return scene_path.get_file().get_basename()


func get_dialogue_file() -> String:

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

	var base_name := "%s_%s" % [
		map_name,
		nombre
	]

	# Primero busca el diálogo específico del nivel.
	var level_file := "%s_%s.txt" % [
		base_name,
		player_node.nivel
	]

	if FileAccess.file_exists(
		"user://dialogues/" + level_file
	):

		return level_file

	# Después busca el diálogo específico del NPC.
	var generic_file := "%s.txt" % base_name

	if FileAccess.file_exists(
		"user://dialogues/" + generic_file
	):

		return generic_file

	# Finalmente busca el diálogo genérico.
	if FileAccess.file_exists(
		"user://dialogues/generico.txt"
	):

		return "generico.txt"

	push_error(
		"No existe diálogo para: "
		+ base_name
	)

	return ""


func _on_interaction_area_body_entered(body: Node) -> void:

	if body.name != "Player":

		return

	player_nearby = true

	if not DialogueManager.dialogue_active:

		var dialogue_file := get_dialogue_file()

		if dialogue_file.is_empty():

			return

		DialogueManager.start_dialogue(
			"user://dialogues/" + dialogue_file,
			nombre
		)


func _on_interaction_area_body_exited(body: Node) -> void:

	if body.name != "Player":

		return

	player_nearby = false

	if DialogueManager.dialogue_active:

		DialogueManager.end_dialogue()


func _on_interaction_area_area_exited(_area: Area2D) -> void:

	pass
