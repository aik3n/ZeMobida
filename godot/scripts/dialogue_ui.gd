extends CanvasLayer


@onready var panel_texto: Panel = $PanelTexto
@onready var panel_opciones: Panel = $PanelOpciones

@onready var name_label: Label = $PanelTexto/NameLabel
@onready var dialogue_text: Label = $PanelTexto/DialogueText

@onready var options_container: VBoxContainer = (
	$PanelOpciones/OptionsContainer
)


func _ready() -> void:

	DialogueManager.register_ui(self)

	panel_texto.visible = false
	panel_opciones.visible = false


func show_dialogue() -> void:

	panel_texto.visible = true


func hide_dialogue() -> void:

	panel_texto.visible = false
	panel_opciones.visible = false


func show_text(
	speaker_name: String,
	text: String
) -> void:

	name_label.text = speaker_name
	dialogue_text.text = text


func show_options(options: Array) -> void:

	for child in options_container.get_children():

		child.queue_free()

	if options.is_empty():

		panel_opciones.visible = false
		return

	for option in options:

		var button := Button.new()

		button.text = option["text"]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		options_container.add_child(button)

		button.pressed.connect(
			_on_option_pressed.bind(option)
		)


func toggle_options() -> void:

	if options_container.get_child_count() == 0:

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
