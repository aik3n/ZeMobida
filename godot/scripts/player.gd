#archivo: player.gd

extends CharacterBody2D

signal xp_changed

@export_enum("a1", "a2", "b1", "b2", "c1")
var nivel: String = "a1"

@export var xp: int = 0

var vel := 400.0
var destino: Vector2


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


func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			destino = get_global_mouse_position()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			destino = get_global_mouse_position()


func _physics_process(_delta):
	var input_direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if input_direction != Vector2.ZERO:
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
