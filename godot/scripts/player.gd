#archivo: player.gd

extends CharacterBody2D

signal xp_changed

@export_enum("a1", "a2", "b1", "b2", "c1")
var nivel: String = "a1"

@export var xp: int = 0

var vel := 400.0
var destino: Vector2

@onready var camera: Camera2D = $Camera2D

const DRAG_THRESHOLD := 28.0
const CAMERA_RECENTER_TIME := 0.8

const ZOOM_MIN := 0.7
const ZOOM_MAX := 1.4
const ZOOM_WHEEL_STEP := 0.1

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

# Toques activos por índice de dedo.
var _touch_points: Dictionary = {}
var _pinch_active := false
var _pinch_last_distance := 0.0

# Tras terminar un pinch se ignora el dedo que pueda quedar apoyado
# hasta que todos los dedos se hayan soltado. Así no se genera un tap
# accidental al finalizar el gesto de zoom.
var _touch_block_until_release := false


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


func _ready():
	xp = clamp(xp, 0, _xp_maximo())
	_actualizar_nivel()
	destino = global_position


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

	# Dos dedos significan exclusivamente exploración/zoom.
	destino = global_position
	velocity = Vector2.ZERO

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


func _begin_pointer(screen_position: Vector2) -> void:
	_stop_camera_recenter()

	_pointer_start = screen_position
	_pointer_last = screen_position
	_pointer_dragging = false

	# El movimiento por tap empieza al soltar. Mientras se decide si
	# el gesto es tap o arrastre, el personaje permanece quieto.
	destino = global_position
	velocity = Vector2.ZERO


func _update_pointer(screen_position: Vector2) -> void:
	var total_delta := screen_position - _pointer_start

	if not _pointer_dragging:
		if total_delta.length() < DRAG_THRESHOLD:
			_pointer_last = screen_position
			return

		_pointer_dragging = true

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
	_start_camera_recenter()


func _start_camera_recenter() -> void:
	_stop_camera_recenter()

	var position_is_normal := camera.position.is_zero_approx()
	var zoom_is_normal := camera.zoom.is_equal_approx(Vector2.ONE)

	if position_is_normal and zoom_is_normal:
		camera.position = Vector2.ZERO
		camera.zoom = Vector2.ONE
		return

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


func _physics_process(_delta):
	var input_direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if input_direction != Vector2.ZERO:
		# Teclado/mandos vuelven inmediatamente a la cámara estándar.
		_stop_camera_recenter()
		camera.position = Vector2.ZERO
		camera.zoom = Vector2.ONE
		velocity = input_direction * vel
		move_and_slide()
		return

	if global_position.distance_to(destino) > 5.0:
		velocity = global_position.direction_to(destino) * vel
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func add_xp(amount: int) -> void:
	var nueva_xp: int = clamp(
		xp + amount,
		0,
		_xp_maximo()
	)

	if nueva_xp == xp:
		return

	xp = nueva_xp
	_actualizar_nivel()
	xp_changed.emit()


func _actualizar_nivel() -> void:
	var nuevo_nivel := ORDEN_NIVELES[0]

	for nivel_nombre in ORDEN_NIVELES:
		if xp <= NIVELES[nivel_nombre]:
			nuevo_nivel = nivel_nombre
			break

	if nuevo_nivel != nivel:
		print(
			"Nivel cambiado: %s → %s"
			% [nivel, nuevo_nivel]
		)

		nivel = nuevo_nivel


func _xp_maximo() -> int:
	return NIVELES[ORDEN_NIVELES[-1]]
