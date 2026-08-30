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
const CAMERA_RECENTER_TIME := 0.38

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
		var touch := event as InputEventScreenTouch

		if touch.pressed:
			_pointer_source = PointerSource.TOUCH
			_begin_pointer(touch.position)
		elif _pointer_source == PointerSource.TOUCH:
			_end_pointer(touch.position)
			_pointer_source = PointerSource.NONE

		return

	if event is InputEventScreenDrag:
		if _pointer_source == PointerSource.TOUCH:
			var drag := event as InputEventScreenDrag
			_update_pointer(drag.position)

		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton

		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		# En dispositivos táctiles Godot puede generar también eventos
		# de ratón. Si ya estamos procesando el toque, se ignoran.
		if mouse_button.pressed:
			if _pointer_source != PointerSource.TOUCH:
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

	if camera.position.is_zero_approx():
		camera.position = Vector2.ZERO
		return

	# Tween nativo de Godot: el arrastre sigue respondiendo 1:1 al dedo,
	# pero al ordenar movimiento la cámara recupera al jugador sin salto.
	_camera_recenter_tween = create_tween()
	_camera_recenter_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_recenter_tween.set_ease(Tween.EASE_OUT)
	_camera_recenter_tween.tween_property(
		camera,
		"position",
		Vector2.ZERO,
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
		# Teclado/mandos vuelven inmediatamente al seguimiento normal.
		camera.position = Vector2.ZERO
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
