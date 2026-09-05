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
@onready var visual_sprite: Sprite2D = $Sprite2D

var posicion_seguimiento: Vector2
var posicion_seguimiento_guardada := false

var siguiendo := false

var _idle_tween: Tween
var _idle_base_position := Vector2.ZERO
var _idle_base_scale := Vector2.ONE

# Pista blanda: condiciones de diálogo que dependen del inventario.
# No se guarda ningún estado nuevo; sólo detectamos false -> true.
var _conditional_item_sets: Array = []
var _conditional_available := false
var _conditional_hint_pending := false


const VELOCIDAD_SEGUIR := 100.0
const DISTANCIA_REANUDAR := 120.0
const DISTANCIA_LLEGADA := 5.0

# Idle visual muy sutil. Sólo se anima el Sprite2D:
# el CharacterBody2D, las colisiones y el nombre permanecen quietos.
const IDLE_BOB_DISTANCE := 6.0
const IDLE_SCALE := 1.03
const IDLE_MOVE_TIME := 0.6
const IDLE_INITIAL_DELAY_MAX := 1.5
const IDLE_REST_MIN := 1.0
const IDLE_REST_MAX := 2.5

# Pista condicional breve. No es un marcador permanente:
# dos pulsos dorados y desaparece.
const HINT_AURA_COLOR := Color(1.0, 0.84, 0.25, 0.48)
const HINT_AURA_SCALE_START := 1.04
const HINT_AURA_SCALE_END := 1.26
const HINT_AURA_FADE_IN := 0.10
const HINT_AURA_EXPAND_TIME := 0.58
const HINT_AURA_SECOND_DELAY := 0.16

# Profundidad visual respecto al Player.
# Fondo permanece en -10 y los frontales fijos en +10.
const PROFUNDIDAD_Z_DETRAS_PLAYER := 1
const PROFUNDIDAD_Z_DELANTE_PLAYER := 3

# Estado editorial del guion asignado al PNJ.
const NAME_COLOR_NONE := Color("#D0D0D0")
const NAME_COLOR_OFFICIAL := Color("#45E07B")
const NAME_COLOR_LOCAL := Color("#4AA8FF")


func _actualizar_sprite_visual() -> void:
	var nodo_sprite := get_node_or_null("Sprite2D") as Sprite2D

	if nodo_sprite != null:
		nodo_sprite.texture = sprite


func get_nombre_tecnico() -> String:
	return str(name).to_lower()


func _actualizar_estado_nombre_dialogo() -> void:
	if Engine.is_editor_hint():
		return

	if name_label == null:
		return

	name_label.text = str(name).replace("_", " ").capitalize()

	var map_name := get_map_name()

	if map_name.is_empty():
		name_label.modulate = NAME_COLOR_NONE
		return

	var state := DialogueManager.get_dialogue_assignment_state(
		map_name,
		get_nombre_tecnico()
	)

	match state:
		"local":
			name_label.modulate = NAME_COLOR_LOCAL
		"official":
			name_label.modulate = NAME_COLOR_OFFICIAL
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

	DialogueManager.dialogue_sources_changed.connect(
		_actualizar_estado_nombre_dialogo
	)
	DialogueManager.dialogue_sources_changed.connect(
		_actualizar_condiciones_de_pista
	)

	_actualizar_estado_nombre_dialogo()
	_actualizar_condiciones_de_pista()

	_idle_base_position = visual_sprite.position
	_idle_base_scale = visual_sprite.scale
	_start_idle_cycle(
		randf_range(0.0, IDLE_INITIAL_DELAY_MAX)
	)


func _start_idle_cycle(delay: float = -1.0) -> void:
	if Engine.is_editor_hint() or visual_sprite == null:
		return

	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()

	var rest := delay
	if rest < 0.0:
		rest = randf_range(IDLE_REST_MIN, IDLE_REST_MAX)

	_idle_tween = create_tween()
	_idle_tween.tween_interval(rest)

	var up_position := _idle_tween.tween_property(
		visual_sprite,
		"position",
		_idle_base_position + Vector2(0.0, -IDLE_BOB_DISTANCE),
		IDLE_MOVE_TIME
	)
	up_position.set_trans(Tween.TRANS_SINE)
	up_position.set_ease(Tween.EASE_IN_OUT)

	var up_scale := _idle_tween.parallel().tween_property(
		visual_sprite,
		"scale",
		_idle_base_scale * IDLE_SCALE,
		IDLE_MOVE_TIME
	)
	up_scale.set_trans(Tween.TRANS_SINE)
	up_scale.set_ease(Tween.EASE_IN_OUT)

	var down_position := _idle_tween.tween_property(
		visual_sprite,
		"position",
		_idle_base_position,
		IDLE_MOVE_TIME
	)
	down_position.set_trans(Tween.TRANS_SINE)
	down_position.set_ease(Tween.EASE_IN_OUT)

	var down_scale := _idle_tween.parallel().tween_property(
		visual_sprite,
		"scale",
		_idle_base_scale,
		IDLE_MOVE_TIME
	)
	down_scale.set_trans(Tween.TRANS_SINE)
	down_scale.set_ease(Tween.EASE_IN_OUT)

	_idle_tween.tween_callback(
		Callable(self, "_start_idle_cycle")
	)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if player == null:
		return

	_actualizar_profundidad_visual()
	_actualizar_seguimiento()
	_actualizar_pista_condicional()

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


func _actualizar_condiciones_de_pista() -> void:
	_conditional_item_sets.clear()
	_conditional_available = false
	_conditional_hint_pending = false

	var map_name := get_map_name()
	if map_name.is_empty():
		return

	var dialogue_path := str(DialogueManager.resolve_dialogue_path(
		map_name,
		get_nombre_tecnico()
	))

	if dialogue_path.is_empty():
		return

	if not FileAccess.file_exists(dialogue_path):
		return

	var parser := DialogueParser.new()
	var dialogue := parser.parse(
		FileAccess.get_file_as_string(dialogue_path)
	)

	# Una pista nunca debe intentar "arreglar" un guion inválido.
	if not parser.errors.is_empty():
		return

	for node in dialogue.values():
		for condition in node.get("conditions", []):
			var items = condition.get("items", [])

			if not items.is_empty():
				_conditional_item_sets.append(items.duplicate())


func _actualizar_pista_condicional() -> void:
	if _conditional_item_sets.is_empty():
		return

	var available := _tiene_condicion_de_dialogo_disponible()

	if available and not _conditional_available:
		_conditional_hint_pending = true

	_conditional_available = available

	# Si el objeto se obtiene durante una conversación, esperamos a que
	# termine: así el pulso se ve en el mapa y no detrás del diálogo.
	if (
		_conditional_hint_pending
		and not DialogueManager.dialogue_active
		and not DialogueManager.editor_active
	):
		_conditional_hint_pending = false
		_mostrar_pista_condicional()


func _tiene_condicion_de_dialogo_disponible() -> bool:
	for items in _conditional_item_sets:
		var all_present := true

		for item in items:
			if not DialogueManager.has_item(str(item)):
				all_present = false
				break

		if all_present:
			return true

	return false


func _mostrar_pista_condicional() -> void:
	if visual_sprite == null or visual_sprite.texture == null:
		return

	_crear_pulso_aura(0.0)
	_crear_pulso_aura(HINT_AURA_SECOND_DELAY)


func _crear_pulso_aura(delay: float) -> void:
	var aura := Sprite2D.new()

	# Copiamos sólo las propiedades visuales necesarias. El aura no tiene
	# colisión, interacción ni lógica: es una silueta temporal del sprite.
	aura.texture = visual_sprite.texture
	aura.centered = visual_sprite.centered
	aura.offset = visual_sprite.offset
	aura.flip_h = visual_sprite.flip_h
	aura.flip_v = visual_sprite.flip_v
	aura.hframes = visual_sprite.hframes
	aura.vframes = visual_sprite.vframes
	aura.frame = visual_sprite.frame
	aura.region_enabled = visual_sprite.region_enabled
	aura.region_rect = visual_sprite.region_rect

	aura.position = visual_sprite.position
	aura.rotation = visual_sprite.rotation
	aura.scale = visual_sprite.scale * HINT_AURA_SCALE_START
	aura.z_index = visual_sprite.z_index - 1
	aura.modulate = HINT_AURA_COLOR
	aura.modulate.a = 0.0

	add_child(aura)

	var tween := create_tween()

	if delay > 0.0:
		tween.tween_interval(delay)

	tween.tween_property(
		aura,
		"modulate:a",
		HINT_AURA_COLOR.a,
		HINT_AURA_FADE_IN
	)

	var expand := tween.tween_property(
		aura,
		"scale",
		visual_sprite.scale * HINT_AURA_SCALE_END,
		HINT_AURA_EXPAND_TIME
	)
	expand.set_trans(Tween.TRANS_CUBIC)
	expand.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		aura,
		"modulate:a",
		0.0,
		HINT_AURA_EXPAND_TIME
	)

	tween.tween_callback(aura.queue_free)


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
	var map_id := scene_path.get_file().get_basename().to_lower()

	return DialogueManager.get_dialogue_map_name(map_id)


func get_dialogue_path() -> String:

	var map_name := get_map_name()

	if map_name.is_empty():
		return ""

	var nombre_tecnico := get_nombre_tecnico()

	var dialogue_path: String = str(DialogueManager.resolve_dialogue_path(
		map_name,
		nombre_tecnico
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
