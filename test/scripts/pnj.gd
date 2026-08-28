#archivo: pnj.gd

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
var a_distancia_segura := false

const VELOCIDAD_SEGUIR := 100.0
const DISTANCIA_PARAR := 80.0
const DISTANCIA_REANUDAR := 120.0
const DISTANCIA_LLEGADA := 5.0


@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready():

	sprite_2d.texture = sprite

	var mapa_actual = get_tree().current_scene.get("mapa_actual")

	if mapa_actual != null:
		player = mapa_actual.get_node_or_null(
			"player"
		)


func _physics_process(_delta):

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



func _actualizar_seguimiento():

	var nuevo_estado := DialogueManager.has_item(
		nombre.to_lower()
	)


	# El seguimiento acaba de comenzar.
	if nuevo_estado and not siguiendo:

		posicion_seguimiento = global_position
		posicion_seguimiento_guardada = true
		a_distancia_segura = false


	# El seguimiento acaba de terminar.
	if not nuevo_estado and siguiendo:

		a_distancia_segura = false


	siguiendo = nuevo_estado



func _seguir_player():

	var distancia := global_position.distance_to(
		player.global_position
	)


	# El PNJ está dentro de la distancia segura.
	# Permanece quieto hasta que el Player se aleja.
	if a_distancia_segura:

		if distancia > DISTANCIA_REANUDAR:

			a_distancia_segura = false

		else:

			velocity = Vector2.ZERO
			move_and_slide()

			return


	# El PNJ ha alcanzado la distancia mínima de seguimiento.
	if distancia <= DISTANCIA_PARAR:

		a_distancia_segura = true

		velocity = Vector2.ZERO
		move_and_slide()

		return


	var direccion := global_position.direction_to(
		player.global_position
	)

	velocity = direccion * VELOCIDAD_SEGUIR

	move_and_slide()



func volver_posicion_seguimiento():

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

	var mapa_actual = get_tree().current_scene.get("mapa_actual")

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


	var player_node = get_tree().current_scene.get("mapa_actual")

	if player_node != null:

		player_node = player_node.get_node_or_null(
			"player"
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



func _on_interaction_area_body_entered(body):

	if body.name != "player":

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



func _on_interaction_area_body_exited(body):

	if body.name != "player":

		return


	player_nearby = false


	if DialogueManager.dialogue_active:

		DialogueManager.end_dialogue()



func _on_interaction_area_area_exited(area):

	pass
