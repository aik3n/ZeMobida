extends CanvasLayer


const DIPLOMA_FOLDER := "res://art/diplomas/"
const ANIMATION_DURATION := 0.7
const INITIAL_SCALE := Vector2(0.02, 0.02)
const INITIAL_ROTATION_DEGREES := 35.0


@onready var overlay: Control = $Overlay
@onready var diploma: TextureRect = $Overlay/Diploma


var _dialogue_was_active := false
var _dialogue_start_level := ""
var _can_close := false
var _tween: Tween = null


func _ready() -> void:
	overlay.visible = false


func _process(_delta: float) -> void:
	if DialogueManager.dialogue_active:
		if not _dialogue_was_active:
			_dialogue_was_active = true
			_dialogue_start_level = (
				DialogueManager.current_dialogue_level
			)

		return

	if not _dialogue_was_active:
		return

	_dialogue_was_active = false

	var start_level := _dialogue_start_level.to_lower()
	_dialogue_start_level = ""

	# Abrir el editor también cierra temporalmente el diálogo.
	# Ese cierre no debe presentar un diploma encima del editor.
	if DialogueManager.editor_active:
		return

	var player := _get_player()

	# Al abandonar el mapa, Game oculta el Player antes del siguiente
	# frame. Así ese cierre forzado tampoco deja un diploma en bienvenida.
	if player == null or not player.visible:
		return

	var final_level := str(
		player.get("nivel")
	).to_lower()

	if (
		start_level.is_empty()
		or final_level.is_empty()
		or final_level == start_level
	):
		return

	_show_level(final_level)


func _get_player() -> CharacterBody2D:
	var game := get_tree().current_scene

	if game == null:
		return null

	var player = game.get("player_actual")

	if player is CharacterBody2D:
		return player

	var fallback := game.get_node_or_null("Player")

	if fallback is CharacterBody2D:
		return fallback

	return null


func _show_level(level: String) -> void:
	var image_path := (
		DIPLOMA_FOLDER
		+ level
		+ ".png"
	)

	if not ResourceLoader.exists(image_path):
		print(
			"No existe el diploma de nivel: "
			+ image_path
		)
		return

	var texture := load(image_path) as Texture2D

	if texture == null:
		print(
			"No se pudo cargar el diploma de nivel: "
			+ image_path
		)
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	diploma.texture = texture
	diploma.pivot_offset = diploma.size * 0.5
	diploma.scale = INITIAL_SCALE
	diploma.rotation_degrees = INITIAL_ROTATION_DEGREES

	_can_close = false
	overlay.visible = true

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)

	_tween.tween_property(
		diploma,
		"scale",
		Vector2.ONE,
		ANIMATION_DURATION
	)

	_tween.tween_property(
		diploma,
		"rotation_degrees",
		0.0,
		ANIMATION_DURATION
	)

	_tween.finished.connect(
		_on_animation_finished,
		CONNECT_ONE_SHOT
	)


func _on_animation_finished() -> void:
	_tween = null
	_can_close = true


func _input(event: InputEvent) -> void:
	if not overlay.visible:
		return

	if (
		event is InputEventScreenTouch
		or event is InputEventScreenDrag
		or event is InputEventMouseButton
		or event is InputEventMouseMotion
	):
		get_viewport().set_input_as_handled()

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch

		if touch.pressed:
			_try_close()

		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton

		if mouse_button.pressed:
			_try_close()


func _try_close() -> void:
	if not _can_close:
		return

	_can_close = false

	# Se difiere el ocultado para absorber también posibles eventos de
	# ratón emulados por el mismo toque en dispositivos móviles.
	call_deferred(
		"_hide_diploma"
	)


func _hide_diploma() -> void:
	overlay.visible = false
	diploma.texture = null
