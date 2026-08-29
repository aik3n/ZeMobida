extends CanvasLayer


@onready var panel_texto: Panel = $PanelTexto
@onready var panel_opciones: Panel = $PanelOpciones

@onready var name_label: Label = $PanelTexto/NameLabel
@onready var dialogue_text: Label = $PanelTexto/DialogueText
@onready var options_indicator: Label = $PanelTexto/OptionsIndicator

@onready var options_container: VBoxContainer = (
	$PanelOpciones/OptionsContainer
)


var _has_options := false


func _ready() -> void:

	DialogueManager.register_ui(self)

	panel_texto.visible = false
	panel_opciones.visible = false
	options_indicator.visible = false


func show_dialogue() -> void:

	panel_texto.visible = true
	panel_opciones.visible = false


func hide_dialogue() -> void:

	panel_texto.visible = false
	panel_opciones.visible = false
	options_indicator.visible = false


func show_text(
	speaker_name: String,
	text: String
) -> void:

	name_label.text = speaker_name
	dialogue_text.text = text


func show_options(options: Array) -> void:

	# Al mostrar un nodo nuevo, el panel de opciones empieza oculto.
	panel_opciones.visible = false

	for child in options_container.get_children():
		child.queue_free()

	_has_options = not options.is_empty()
	options_indicator.visible = _has_options

	if not _has_options:
		return

	var shuffled_options: Array = options.duplicate()
	shuffled_options.shuffle()

	for option in shuffled_options:

		var button := Button.new()

		button.text = option["text"]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		options_container.add_child(button)

		button.pressed.connect(
			_on_option_pressed.bind(option)
		)


func toggle_options() -> void:

	if not _has_options:
		panel_opciones.visible = false
		return

	panel_opciones.visible = not panel_opciones.visible


func _on_option_pressed(option: Dictionary) -> void:

	DialogueManager.select_option(option)


func _on_panel_texto_gui_input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				toggle_options()
