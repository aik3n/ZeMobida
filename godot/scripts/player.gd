#archivo: player.gd

extends CharacterBody2D

var vel := 400.0
var destino: Vector2

const MOVEMENT_ACCELERATION := 1800.0
const MOVEMENT_DECELERATION := 1200.0
const ARRIVAL_DISTANCE := 5.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var feedback_layer: CanvasLayer = $FeedbackLayer
@onready var feedback_label: Label = $FeedbackLayer/FeedbackLabel
@onready var positive_feedback_timer: Timer = $PositiveFeedbackTimer
@onready var negative_feedback_timer: Timer = $NegativeFeedbackTimer

const DRAG_THRESHOLD := 28.0
const CAMERA_RECENTER_TIME := 0.8
const CAMERA_FOLLOW_SMOOTHING_SPEED := 6.0

const DESTINATION_FEEDBACK_DURATION := 0.7
const DESTINATION_FEEDBACK_RADIUS := 34.0
const DESTINATION_FEEDBACK_START_SCALE := 0.55

const ZOOM_MIN := 0.5
const ZOOM_MAX := 1.8
const ZOOM_WHEEL_STEP := 0.1

const FEEDBACK_POSITIVE_COLOR := Color("#5CFF79")
const FEEDBACK_NEGATIVE_COLOR := Color("#FF5F6D")

const FEEDBACK_POSITIVE_BASE_POSITION := Vector2(-300.0, -185.0)
const FEEDBACK_NEGATIVE_BASE_POSITION := Vector2(-300.0, -125.0)

const FEEDBACK_POSITIVE_DISTANCE := 125.0
const FEEDBACK_NEGATIVE_DISTANCE := 105.0
const FEEDBACK_DURATION := 1.20
const FEEDBACK_INTERVAL := 0.25
const FEEDBACK_FADE_DELAY := 0.68
const FEEDBACK_FADE_TIME := 0.42
const FEEDBACK_ROTATION_DEGREES := 4.0
const FEEDBACK_HIGHLIGHT_SCALE := 1.4

enum PointerSource {
	NONE,
	TOUCH,
	MOUSE
}

var _pointer_source := PointerSource.NONE
var _pointer_start := Vector2.ZERO
var _pointer_last := Vector2.ZERO
var _pointer_dragging := false
var _camera_recenter_tween: Tween
var _camera_manual_active := false
var _camera_manual_world_center := Vector2.ZERO

# Toques activos por índice de dedo.
var _touch_points: Dictionary = {}
var _pinch_active := false
var _pinch_last_distance := 0.0

# Tras terminar un pinch se ignora el dedo que pueda quedar apoyado
# hasta que todos los dedos se hayan soltado. Así no se genera un tap
# accidental al finalizar el gesto de zoom.
var _touch_block_until_release := false

var _positive_feedback_queue: Array[Dictionary] = []
var _negative_feedback_queue: Array[Dictionary] = []

var _positive_feedback_launcher_busy := false
var _negative_feedback_launcher_busy := false


func _ready():
	destino = global_position

	camera.position_smoothing_speed = CAMERA_FOLLOW_SMOOTHING_SPEED
	_enable_camera_follow_smoothing()

	feedback_label.pivot_offset = feedback_label.size * 0.5
	feedback_label.visible = false

	positive_feedback_timer.timeout.connect(
		_on_positive_feedback_timer_timeout
	)

	negative_feedback_timer.timeout.connect(
		_on_negative_feedback_timer_timeout
	)

	_actualizar_posicion_feedback()


func _process(_delta: float) -> void:
	_actualizar_posicion_feedback()


func _actualizar_posicion_feedback() -> void:
	# FeedbackLayer está en CanvasLayer 15 para dibujarse por encima del
	# diálogo (10), pero su origen sigue la posición visual del Player.
	feedback_layer.offset = (
		get_viewport().get_canvas_transform()
		* global_position
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
		return

	if event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton

		# Zoom de escritorio con rueda.
		if mouse_button.pressed:
			if (
				mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP
				or mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN
			):
				if _mouse_over_dialogue_scroll():
					return

			if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
				_set_zoom(camera.zoom.x + ZOOM_WHEEL_STEP * mouse_button.factor)
				return

			if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_set_zoom(camera.zoom.x - ZOOM_WHEEL_STEP * mouse_button.factor)
				return

		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		# En dispositivos táctiles Godot puede generar también eventos
		# de ratón. Si ya estamos procesando el toque, se ignoran.
		if mouse_button.pressed:
			if _pointer_source != PointerSource.TOUCH and not _pinch_active:
				_pointer_source = PointerSource.MOUSE
				_begin_pointer(mouse_button.position)
		elif _pointer_source == PointerSource.MOUSE:
			_end_pointer(mouse_button.position)
			_pointer_source = PointerSource.NONE

		return

	if event is InputEventMouseMotion:
		if _pointer_source == PointerSource.MOUSE:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var motion := event as InputEventMouseMotion
				_update_pointer(motion.position)



func _mouse_over_dialogue_scroll() -> bool:

	var hovered := get_viewport().gui_get_hovered_control()

	while hovered != null:
		if (
			hovered.name == "ScrollTexto"
			or hovered.name == "ScrollOpciones"
		):
			return true

		hovered = hovered.get_parent() as Control

	return false


func _handle_screen_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		_touch_points[touch.index] = touch.position

		if _touch_block_until_release:
			return

		if _touch_points.size() == 1:
			_pointer_source = PointerSource.TOUCH
			_begin_pointer(touch.position)
			return

		if _touch_points.size() >= 2:
			_start_pinch()
			return

	# Release.
	if not _touch_points.has(touch.index):
		return

	if _pinch_active:
		_touch_points.erase(touch.index)

		if _touch_points.size() < 2:
			_end_pinch()
		return

	if _touch_block_until_release:
		_touch_points.erase(touch.index)

		if _touch_points.is_empty():
			_touch_block_until_release = false

		return

	if _pointer_source == PointerSource.TOUCH:
		_end_pointer(touch.position)
		_pointer_source = PointerSource.NONE

	_touch_points.erase(touch.index)


func _handle_screen_drag(drag: InputEventScreenDrag) -> void:
	if not _touch_points.has(drag.index):
		return

	_touch_points[drag.index] = drag.position

	if _pinch_active:
		_update_pinch()
		return

	if _touch_block_until_release:
		return

	if _pointer_source == PointerSource.TOUCH:
		_update_pointer(drag.position)


func _start_pinch() -> void:
	_stop_camera_recenter()
	_begin_camera_manual_mode()

	# Dos dedos significan exclusivamente exploración/zoom.
	# El Player conserva el destino y continúa caminando.

	_pointer_source = PointerSource.NONE
	_pointer_dragging = false

	_pinch_active = true
	_pinch_last_distance = _current_pinch_distance()


func _update_pinch() -> void:
	if _touch_points.size() < 2:
		return

	var new_distance := _current_pinch_distance()

	if _pinch_last_distance <= 0.0:
		_pinch_last_distance = new_distance
		return

	if new_distance <= 0.0:
		return

	var ratio := new_distance / _pinch_last_distance
	_set_zoom(camera.zoom.x * ratio)

	_pinch_last_distance = new_distance


func _end_pinch() -> void:
	_pinch_active = false
	_pinch_last_distance = 0.0
	_pointer_source = PointerSource.NONE
	_pointer_dragging = false

	# Si todavía queda un dedo apoyado se ignora hasta soltarlo.
	_touch_block_until_release = not _touch_points.is_empty()


func _current_pinch_distance() -> float:
	var indices: Array = _touch_points.keys()
	indices.sort()

	if indices.size() < 2:
		return 0.0

	var a: Vector2 = _touch_points[indices[0]]
	var b: Vector2 = _touch_points[indices[1]]

	return a.distance_to(b)


func _set_zoom(value: float) -> void:
	var clamped_zoom := clampf(value, ZOOM_MIN, ZOOM_MAX)

	camera.zoom = Vector2(
		clamped_zoom,
		clamped_zoom
	)

	_clamp_camera_to_limits()

	if _camera_manual_active:
		_camera_manual_world_center = global_position + camera.position


func _begin_pointer(screen_position: Vector2) -> void:
	_stop_camera_recenter()

	_pointer_start = screen_position
	_pointer_last = screen_position
	_pointer_dragging = false

	# Mientras se decide si el gesto es tap o arrastre, el Player
	# conserva su destino y continúa caminando.


func _update_pointer(screen_position: Vector2) -> void:
	var total_delta := screen_position - _pointer_start

	if not _pointer_dragging:
		if total_delta.length() < DRAG_THRESHOLD:
			_pointer_last = screen_position
			return

		_pointer_dragging = true
		_begin_camera_manual_mode()

		# Al superar el umbral se aplica todo lo recorrido hasta ahora,
		# para que el mapa alcance la posición del dedo sin salto raro.
		_pan_camera(total_delta)
	else:
		_pan_camera(screen_position - _pointer_last)

	_pointer_last = screen_position


func _end_pointer(screen_position: Vector2) -> void:
	if _pointer_dragging:
		# Un arrastre sólo explora el mapa. Al soltar, la cámara se queda
		# donde la dejó el jugador y no se inicia ningún desplazamiento.
		_pointer_dragging = false
		return

	# El destino se calcula antes de recentrar la cámara para que un tap
	# sobre un mapa desplazado apunte al lugar que realmente se tocó.
	var world_position := _screen_to_world(screen_position)
	destino = world_position
	_show_destination_feedback(world_position)
	_start_camera_recenter()


func _start_camera_recenter() -> void:
	_stop_camera_recenter()
	_end_camera_manual_mode()

	var position_is_normal := camera.position.is_zero_approx()
	var zoom_is_normal := camera.zoom.is_equal_approx(Vector2.ONE)

	if position_is_normal and zoom_is_normal:
		camera.position = Vector2.ZERO
		camera.zoom = Vector2.ONE

		if not camera.position_smoothing_enabled:
			_enable_camera_follow_smoothing()

		return

	_disable_camera_follow_smoothing()

	# Volver al Player significa restaurar la cámara estándar completa:
	# posición centrada y zoom 1.0. Ambos cambios ocurren en paralelo para
	# que la transición se perciba como un único movimiento suave.
	_camera_recenter_tween = create_tween()
	_camera_recenter_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_recenter_tween.set_ease(Tween.EASE_OUT)
	_camera_recenter_tween.set_parallel(true)

	_camera_recenter_tween.tween_property(
		camera,
		"position",
		Vector2.ZERO,
		CAMERA_RECENTER_TIME
	)

	_camera_recenter_tween.tween_property(
		camera,
		"zoom",
		Vector2.ONE,
		CAMERA_RECENTER_TIME
	)

	_camera_recenter_tween.finished.connect(
		_on_camera_recenter_finished,
		CONNECT_ONE_SHOT
	)


func _on_camera_recenter_finished() -> void:
	_camera_recenter_tween = null
	_enable_camera_follow_smoothing()


func _enable_camera_follow_smoothing() -> void:
	camera.position_smoothing_speed = CAMERA_FOLLOW_SMOOTHING_SPEED

	if camera.position_smoothing_enabled:
		return

	camera.position_smoothing_enabled = true
	camera.reset_smoothing()


func _disable_camera_follow_smoothing() -> void:
	if not camera.position_smoothing_enabled:
		return

	# Conservar el centro que el jugador está viendo evita un salto al
	# pasar del seguimiento suavizado al control manual de la cámara.
	var visual_center := camera.get_screen_center_position()

	camera.position_smoothing_enabled = false
	camera.position = visual_center - global_position

	_clamp_camera_to_limits()


func _begin_camera_manual_mode() -> void:
	if _camera_manual_active:
		return

	_disable_camera_follow_smoothing()

	_camera_manual_active = true
	_camera_manual_world_center = global_position + camera.position


func _end_camera_manual_mode() -> void:
	_camera_manual_active = false


func _update_camera_manual_position() -> void:
	if not _camera_manual_active:
		return

	# La cámara permanece en el punto del mundo que está explorando el
	# jugador aunque el Player siga caminando por debajo.
	camera.position = _camera_manual_world_center - global_position
	_clamp_camera_to_limits()

	_camera_manual_world_center = global_position + camera.position


func _stop_camera_recenter() -> void:
	if _camera_recenter_tween != null:
		if _camera_recenter_tween.is_valid():
			_camera_recenter_tween.kill()

		_camera_recenter_tween = null


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return (
		get_viewport().get_canvas_transform().affine_inverse()
		* screen_position
	)


func _pan_camera(screen_delta: Vector2) -> void:
	var world_delta := Vector2(
		screen_delta.x / camera.zoom.x,
		screen_delta.y / camera.zoom.y
	)

	# El mapa sigue el movimiento del dedo: arrastrar a la derecha
	# desplaza el contenido visual a la derecha, por lo que la cámara
	# se mueve en sentido contrario.
	if _camera_manual_active:
		_camera_manual_world_center -= world_delta
		_update_camera_manual_position()
	else:
		camera.position -= world_delta
		_clamp_camera_to_limits()


func _clamp_camera_to_limits() -> void:
	var viewport_size := get_viewport_rect().size
	var half_view := Vector2(
		viewport_size.x / (2.0 * camera.zoom.x),
		viewport_size.y / (2.0 * camera.zoom.y)
	)

	var camera_center := global_position + camera.position

	camera_center.x = _clamp_camera_axis(
		camera_center.x,
		camera.limit_left,
		camera.limit_right,
		half_view.x
	)
	camera_center.y = _clamp_camera_axis(
		camera_center.y,
		camera.limit_top,
		camera.limit_bottom,
		half_view.y
	)

	camera.position = camera_center - global_position


func _clamp_camera_axis(
	value: float,
	limit_min: int,
	limit_max: int,
	half_view: float
) -> float:
	var min_center := float(limit_min) + half_view
	var max_center := float(limit_max) - half_view

	if min_center > max_center:
		return (float(limit_min) + float(limit_max)) * 0.5

	return clampf(value, min_center, max_center)


func _show_destination_feedback(world_position: Vector2) -> void:
	var marker := Line2D.new()

	marker.width = 6.0
	marker.default_color = Color.WHITE
	marker.antialiased = true
	marker.closed = true
	marker.z_index = 100

	var point_count := 24

	for i in range(point_count):
		var angle := TAU * float(i) / float(point_count)

		marker.add_point(
			Vector2.RIGHT.rotated(angle)
			* DESTINATION_FEEDBACK_RADIUS
		)

	get_tree().current_scene.add_child(marker)

	marker.global_position = world_position
	marker.scale = (
		Vector2.ONE
		* DESTINATION_FEEDBACK_START_SCALE
	)
	marker.modulate = Color(1.0, 1.0, 1.0, 0.9)

	var tween := create_tween()

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		marker,
		"scale",
		Vector2.ONE,
		DESTINATION_FEEDBACK_DURATION
	)

	tween.tween_property(
		marker,
		"modulate:a",
		0.0,
		DESTINATION_FEEDBACK_DURATION
	)

	tween.finished.connect(
		marker.queue_free,
		CONNECT_ONE_SHOT
	)


func mostrar_feedback(
	texto: String,
	positivo: bool,
	destacado := false
) -> void:
	if texto.is_empty():
		return

	var data := {
		"texto": texto,
		"positivo": positivo,
		"destacado": destacado
	}

	if positivo:
		_positive_feedback_queue.append(data)

		if not _positive_feedback_launcher_busy:
			_positive_feedback_launcher_busy = true
			_lanzar_siguiente_feedback_positivo()
	else:
		_negative_feedback_queue.append(data)

		if not _negative_feedback_launcher_busy:
			_negative_feedback_launcher_busy = true
			_lanzar_siguiente_feedback_negativo()


func _on_positive_feedback_timer_timeout() -> void:
	if _positive_feedback_queue.is_empty():
		_positive_feedback_launcher_busy = false
		return

	_lanzar_siguiente_feedback_positivo()


func _on_negative_feedback_timer_timeout() -> void:
	if _negative_feedback_queue.is_empty():
		_negative_feedback_launcher_busy = false
		return

	_lanzar_siguiente_feedback_negativo()


func _lanzar_siguiente_feedback_positivo() -> void:
	if _positive_feedback_queue.is_empty():
		_positive_feedback_launcher_busy = false
		return

	var data: Dictionary = _positive_feedback_queue.pop_front()

	_crear_feedback(
		str(data["texto"]),
		true,
		bool(data.get("destacado", false))
	)

	positive_feedback_timer.start(
		FEEDBACK_INTERVAL
	)


func _lanzar_siguiente_feedback_negativo() -> void:
	if _negative_feedback_queue.is_empty():
		_negative_feedback_launcher_busy = false
		return

	var data: Dictionary = _negative_feedback_queue.pop_front()

	_crear_feedback(
		str(data["texto"]),
		false,
		bool(data.get("destacado", false))
	)

	negative_feedback_timer.start(
		FEEDBACK_INTERVAL
	)


func _crear_feedback(
	texto: String,
	positivo: bool,
	destacado := false
) -> void:
	var label := feedback_label.duplicate() as Label

	if label == null:
		return

	feedback_layer.add_child(label)

	var base_position := (
		FEEDBACK_POSITIVE_BASE_POSITION
		if positivo
		else FEEDBACK_NEGATIVE_BASE_POSITION
	)

	label.text = texto
	label.position = base_position
	label.modulate = Color.WHITE
	label.visible = true
	label.pivot_offset = label.size * 0.5

	label.rotation = deg_to_rad(
		-FEEDBACK_ROTATION_DEGREES
		if positivo
		else FEEDBACK_ROTATION_DEGREES
	)

	label.add_theme_color_override(
		"font_color",
		FEEDBACK_POSITIVE_COLOR
		if positivo
		else FEEDBACK_NEGATIVE_COLOR
	)

	var escala := (
		FEEDBACK_HIGHLIGHT_SCALE
		if destacado
		else 1.0
	)

	if positivo:
		label.scale = Vector2.ONE * 0.72 * escala
	else:
		label.scale = Vector2.ONE * 1.24 * escala

	var target_position := base_position

	if positivo:
		target_position.y -= FEEDBACK_POSITIVE_DISTANCE
	else:
		target_position.y += FEEDBACK_NEGATIVE_DISTANCE

	var tween := create_tween()

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		label,
		"position",
		target_position,
		FEEDBACK_DURATION
	)

	tween.tween_property(
		label,
		"rotation",
		0.0,
		0.42
	)

	tween.tween_property(
		label,
		"modulate:a",
		0.0,
		FEEDBACK_FADE_TIME
	).set_delay(
		FEEDBACK_FADE_DELAY
	)

	if positivo:
		tween.tween_property(
			label,
			"scale",
			Vector2.ONE * 1.18 * escala,
			0.17
		)

		tween.tween_property(
			label,
			"scale",
			Vector2.ONE * escala,
			0.30
		).set_delay(
			0.17
		)
	else:
		tween.tween_property(
			label,
			"scale",
			Vector2.ONE * 0.86 * escala,
			0.68
		)

	tween.finished.connect(
		label.queue_free,
		CONNECT_ONE_SHOT
	)


func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if input_direction != Vector2.ZERO:
		# Teclado/mandos vuelven inmediatamente a la cámara estándar.
		_stop_camera_recenter()
		_end_camera_manual_mode()
		camera.position = Vector2.ZERO
		camera.zoom = Vector2.ONE
		_enable_camera_follow_smoothing()
		velocity = input_direction * vel
		_actualizar_orientacion_sprite()
		move_and_slide()
		return

	var distance_to_target := global_position.distance_to(destino)

	if distance_to_target <= ARRIVAL_DISTANCE:
		velocity = Vector2.ZERO
	else:
		# La velocidad máxima permitida baja al acercarse al destino.
		# Así el Player puede frenar con MOVEMENT_DECELERATION sin
		# necesitar un radio de frenado independiente.
		var braking_distance := maxf(
			distance_to_target - ARRIVAL_DISTANCE,
			0.0
		)

		var target_speed := minf(
			vel,
			sqrt(
				2.0
				* MOVEMENT_DECELERATION
				* braking_distance
			)
		)

		var target_velocity := (
			global_position.direction_to(destino)
			* target_speed
		)

		var change_rate := MOVEMENT_ACCELERATION

		if target_speed < velocity.length():
			change_rate = MOVEMENT_DECELERATION

		velocity = velocity.move_toward(
			target_velocity,
			change_rate * delta
		)

	_actualizar_orientacion_sprite()
	move_and_slide()
	_update_camera_manual_position()


func _actualizar_orientacion_sprite() -> void:
	if absf(velocity.x) < 1.0:
		return

	sprite.flip_h = velocity.x < 0.0
