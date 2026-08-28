#archivo: dialogue_ui.gd

extends CanvasLayer


@onready var name_label: Label = $Panel/NameLabel
@onready var dialogue_text: Label = $Panel/DialogueText
@onready var options_container: VBoxContainer = $Panel/OptionsContainer

@onready var level_label: Label = $Panel2/lbl_nivel
@onready var xp_bar: ProgressBar = $Panel2/bar_progreso


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
	DialogueManager.register_ui(self)

	var game = get_tree().current_scene
	var mapa_actual = game.get("mapa_actual")

	if mapa_actual != null:
		var player = mapa_actual.get_node_or_null("player")

		if player != null:
			player.xp_changed.connect(_actualizar_xp)

	_actualizar_xp()


func show_dialogue():
	$Panel.visible = true


func hide_dialogue():
	$Panel.visible = false


func show_text(speaker_name: String, text: String):
	name_label.text = speaker_name
	dialogue_text.text = text


func show_options(options: Array):
	for child in options_container.get_children():
		child.queue_free()

	for option in options:
		var button := Button.new()

		button.text = option["text"]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		options_container.add_child(button)

		button.pressed.connect(
			_on_option_pressed.bind(option)
		)


func _on_option_pressed(option: Dictionary):
	DialogueManager.select_option(option)


func _actualizar_xp():
	var game = get_tree().current_scene
	var mapa_actual = game.get("mapa_actual")

	if mapa_actual == null:
		return

	var player = mapa_actual.get_node_or_null("player")

	if player == null:
		return

	var nivel: String = player.nivel.to_lower()
	var xp: int = player.xp

	level_label.text = nivel.to_upper()

	var indice := ORDEN_NIVELES.find(nivel)

	if indice == -1:
		return

	var limite_superior: int = NIVELES[nivel]

	var limite_inferior := 0

	if indice > 0:
		var nivel_anterior: String = ORDEN_NIVELES[indice - 1]
		limite_inferior = NIVELES[nivel_anterior] + 1

	var rango := limite_superior - limite_inferior

	if rango <= 0:
		xp_bar.min_value = 0
		xp_bar.max_value = 1
		xp_bar.value = 1
		return

	var progreso := xp - limite_inferior

	xp_bar.min_value = 0
	xp_bar.max_value = rango
	xp_bar.value = clamp(progreso, 0, rango)

	xp_bar.tooltip_text = "%d / %d XP" % [
		progreso,
		rango
	]
