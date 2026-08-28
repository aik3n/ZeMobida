#archivo: dialogue_ui.gd

extends CanvasLayer


@onready var name_label: Label = $Panel/NameLabel
@onready var dialogue_text: Label = $Panel/DialogueText
@onready var options_container: VBoxContainer = $Panel/OptionsContainer


func _ready():
	DialogueManager.register_ui(self)


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
