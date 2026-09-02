extends CanvasLayer


const OFFICIAL_DIALOGUE_FOLDER := "user://dialogues/"
const LOCAL_DIALOGUE_FOLDER := "user://custom_dialogues/"

const OFFICIAL_HALO_COLOR := Color("#45E07B")
const LOCAL_HALO_COLOR := Color("#4AA8FF")

# El color sólo matiza el fondo oscuro existente.
const DIALOGUE_TINT_STRENGTH := 0.20
const DIALOGUE_BORDER_STRENGTH := 0.75


@onready var panel_texto: Panel = $PanelTexto
@onready var panel_opciones: Panel = $PanelOpciones

@onready var name_label: Label = $PanelTexto/NameLabel
@onready var edit_button: Button = $PanelTexto/EditButton
@onready var dialogue_text: Label = $PanelTexto/ScrollTexto/DialogueText
@onready var options_indicator: Label = $PanelTexto/OptionsIndicator

@onready var options_container: VBoxContainer = (
	$PanelOpciones/ScrollOpciones/OptionsContainer
)


var _has_options := false
var _panel_text_style_base: StyleBoxFlat = null
var _panel_options_style_base: StyleBoxFlat = null


func _ready() -> void:

	DialogueManager.register_ui(self)

	_capture_panel_styles()

	panel_texto.visible = false
	panel_opciones.visible = false
	options_indicator.visible = false


func show_dialogue() -> void:

	var starting_dialogue := not panel_texto.visible

	_update_dialogue_halo()
	panel_texto.visible = true

	# El panel de opciones sólo se fuerza a oculto cuando empieza
	# realmente un diálogo, no en cada cambio de nodo.
	if starting_dialogue:
		panel_opciones.visible = false


func _capture_panel_styles() -> void:

	var text_style := panel_texto.get_theme_stylebox("panel")
	if text_style is StyleBoxFlat:
		_panel_text_style_base = (
			text_style.duplicate() as StyleBoxFlat
		)

	var options_style := panel_opciones.get_theme_stylebox("panel")
	if options_style is StyleBoxFlat:
		_panel_options_style_base = (
			options_style.duplicate() as StyleBoxFlat
		)


func _update_dialogue_halo() -> void:

	var halo_color := OFFICIAL_HALO_COLOR
	var file_path: String = DialogueManager.current_dialogue_file

	if file_path.begins_with(LOCAL_DIALOGUE_FOLDER):
		halo_color = LOCAL_HALO_COLOR

	_apply_panel_halo(
		panel_texto,
		_panel_text_style_base,
		halo_color
	)
	_apply_panel_halo(
		panel_opciones,
		_panel_options_style_base,
		halo_color
	)


func _apply_panel_halo(
	panel: Panel,
	base_style: StyleBoxFlat,
	halo_color: Color
) -> void:

	if base_style == null:
		return

	var style := base_style.duplicate() as StyleBoxFlat

	# Mantiene el panel oscuro y añade sólo un matiz de procedencia.
	style.bg_color = base_style.bg_color.lerp(
		halo_color,
		DIALOGUE_TINT_STRENGTH
	)

	style.border_color = base_style.border_color.lerp(
		halo_color,
		DIALOGUE_BORDER_STRENGTH
	)

	# Sin resplandor exterior: el estado permanece visible en el fondo.
	style.shadow_size = 0

	panel.add_theme_stylebox_override(
		"panel",
		style
	)


func hide_dialogue() -> void:

	panel_texto.visible = false
	panel_opciones.visible = false
	options_indicator.visible = false
	_has_options = false


func show_text(
	speaker_name: String,
	text: String
) -> void:

	name_label.text = speaker_name.replace(
		"_",
		" "
	)
	dialogue_text.text = text

	# Cada nodo nuevo comienza mostrando el inicio del texto.
	var scroll_texto: ScrollContainer = $PanelTexto/ScrollTexto
	scroll_texto.scroll_vertical = 0


func show_options(options: Array) -> void:

	for child in options_container.get_children():
		# Se retira inmediatamente del contenedor para que las opciones
		# antiguas no convivan un frame con las del nuevo nodo.
		options_container.remove_child(child)
		child.queue_free()

	_has_options = not options.is_empty()
	options_indicator.visible = _has_options

	if not _has_options:
		panel_opciones.visible = false
		return

	var shuffled_options: Array = options.duplicate()
	shuffled_options.shuffle()

	for option in shuffled_options:

		var button := Button.new()

		button.text = option["text"]
		button.custom_minimum_size = Vector2(0, 88)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 32)

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


func _on_edit_button_pressed() -> void:

	DialogueManager.open_current_dialogue_editor()


func _on_panel_texto_gui_input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				toggle_options()
