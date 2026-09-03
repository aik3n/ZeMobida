extends CanvasLayer


const OFFICIAL_DIALOGUE_FOLDER := "user://dialogues/"
const LOCAL_DIALOGUE_FOLDER := "user://custom_dialogues/"

const OFFICIAL_HALO_COLOR := Color("#45E07B")
const LOCAL_HALO_COLOR := Color("#4AA8FF")

# El color sólo matiza el fondo oscuro existente.
const DIALOGUE_TINT_STRENGTH := 0.20
const DIALOGUE_BORDER_STRENGTH := 0.75

# Altura automática de los paneles de diálogo.
# El texto está anclado arriba y las opciones abajo.
const TEXT_PANEL_MIN_HEIGHT := 260.0
const TEXT_PANEL_VISIBLE_LINES := 5.5
const TEXT_PANEL_EXTRA_HEIGHT := 140.0

const OPTIONS_PANEL_MIN_HEIGHT := 160.0
const OPTIONS_VISIBLE_BUTTONS := 4
const OPTION_BUTTON_MIN_HEIGHT := 88.0
const OPTIONS_PANEL_PADDING := 56.0


@onready var panel_texto: Panel = $PanelTexto
@onready var panel_opciones: Panel = $PanelOpciones

@onready var name_label: Label = $PanelTexto/NameLabel
@onready var signature_label: Label = $PanelTexto/SignatureLabel
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

	_set_panel_height_from_top(
		panel_texto,
		TEXT_PANEL_MIN_HEIGHT
	)
	_set_panel_height_from_bottom(
		panel_opciones,
		OPTIONS_PANEL_MIN_HEIGHT
	)

	panel_texto.visible = false
	panel_opciones.visible = false
	options_indicator.visible = false
	signature_label.visible = false


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
	signature_label.visible = false
	_has_options = false


func show_text(
	speaker_name: String,
	text: String
) -> void:

	name_label.text = speaker_name.replace(
		"_",
		" "
	)

	signature_label.text = DialogueManager.current_dialogue_signature
	signature_label.visible = not signature_label.text.is_empty()

	dialogue_text.text = text
	call_deferred("_update_text_panel_height")

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

		# El botón conserva los clics, pero deja pasar la rueda al
		# ScrollContainer de opciones. Éste consume el scroll y evita
		# que termine llegando al zoom del mapa.
		button.mouse_filter = Control.MOUSE_FILTER_PASS

		button.custom_minimum_size = Vector2(0, 88)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 32)

		options_container.add_child(button)

		button.pressed.connect(
			_on_option_pressed.bind(option)
		)

	call_deferred("_update_options_panel_height")


func _update_text_panel_height() -> void:

	var line_count := maxi(
		dialogue_text.get_line_count(),
		1
	)

	var font_size := dialogue_text.get_theme_font_size(
		"font_size"
	)
	var line_spacing := dialogue_text.get_theme_constant(
		"line_spacing"
	)
	var font := dialogue_text.get_theme_font("font")

	var line_height := (
		font.get_height(font_size)
		+ float(line_spacing)
	)

	var target_height := (
		TEXT_PANEL_EXTRA_HEIGHT
		+ line_height * float(line_count)
	)

	var max_height := (
		TEXT_PANEL_EXTRA_HEIGHT
		+ line_height * TEXT_PANEL_VISIBLE_LINES
	)

	_set_panel_height_from_top(
		panel_texto,
		clampf(
			target_height,
			TEXT_PANEL_MIN_HEIGHT,
			max_height
		)
	)


func _update_options_panel_height() -> void:

	var target_height := (
		options_container.get_combined_minimum_size().y
		+ OPTIONS_PANEL_PADDING
	)

	var separation := float(
		options_container.get_theme_constant("separation")
	)

	var max_height := (
		OPTION_BUTTON_MIN_HEIGHT * float(OPTIONS_VISIBLE_BUTTONS)
		+ separation * float(OPTIONS_VISIBLE_BUTTONS - 1)
		+ OPTIONS_PANEL_PADDING
	)

	_set_panel_height_from_bottom(
		panel_opciones,
		clampf(
			target_height,
			OPTIONS_PANEL_MIN_HEIGHT,
			max_height
		)
	)


func _set_panel_height_from_top(
	panel: Control,
	height: float
) -> void:

	panel.anchor_bottom = panel.anchor_top
	panel.offset_top = 0.0
	panel.offset_bottom = height


func _set_panel_height_from_bottom(
	panel: Control,
	height: float
) -> void:

	panel.anchor_top = panel.anchor_bottom
	panel.offset_top = -height
	panel.offset_bottom = 0.0


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
