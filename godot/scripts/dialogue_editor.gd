extends CanvasLayer


const CUSTOM_DIALOGUE_FOLDER := "user://custom_dialogues/"
const SUBMISSION_EMAIL := "zemobida@gmail.com"

const ERROR_GUTTER_WIDTH := 34
const ERROR_MARKER := "●"
const ERROR_COLOR := Color("#ff4d5a")


@onready var title_label: Label = $Panel/Title
@onready var code_edit: CodeEdit = $Panel/CodeEdit


var file_name := ""
var _error_gutter := -1


func _ready() -> void:
	_configure_highlighter()
	_configure_error_gutter()

	code_edit.text_changed.connect(
		_refresh_line_error_markers
	)


func setup(
	target_file_name: String,
	initial_text: String
) -> void:
	file_name = target_file_name
	title_label.text = target_file_name
	code_edit.text = initial_text

	_refresh_line_error_markers()
	code_edit.grab_focus()


func _configure_highlighter() -> void:
	var highlighter := preload(
		"res://scripts/dialogue_syntax_highlighter.gd"
	).new()

	code_edit.syntax_highlighter = highlighter


func _configure_error_gutter() -> void:
	code_edit.add_gutter(0)

	_error_gutter = 0

	code_edit.set_gutter_name(
		_error_gutter,
		"syntax_error"
	)

	code_edit.set_gutter_type(
		_error_gutter,
		TextEdit.GUTTER_TYPE_STRING
	)

	code_edit.set_gutter_width(
		_error_gutter,
		ERROR_GUTTER_WIDTH
	)

	code_edit.set_gutter_draw(
		_error_gutter,
		true
	)


func _refresh_line_error_markers() -> void:
	if _error_gutter < 0:
		return

	for line_index in code_edit.get_line_count():
		var line_text := code_edit.get_line(
			line_index
		)

		var has_error := not _is_line_locally_valid(
			line_text
		)

		code_edit.set_line_gutter_text(
			line_index,
			_error_gutter,
			ERROR_MARKER if has_error else ""
		)

		code_edit.set_line_gutter_item_color(
			line_index,
			_error_gutter,
			ERROR_COLOR
		)


func _is_line_locally_valid(
	raw_line: String
) -> bool:
	var line := _remove_comment(
		raw_line
	).strip_edges()

	if line.is_empty():
		return true

	if _has_invalid_brackets(line):
		return false

	if _has_repeated_leading_marker(line):
		return false

	# '#' sólo puede existir en una declaración de nodo.
	# El comentario ya se retiró antes de llegar aquí.
	if line.contains("#") and not line.begins_with("#"):
		return false

	match line[0]:
		"#":
			return _is_node_line_valid(
				line
			)

		"=":
			return _is_option_line_valid(
				line
			)

		"?":
			return _is_condition_line_valid(
				line
			)

		">":
			return _is_jump_line_valid(
				line
			)

		"[":
			# Los efectos no son una línea independiente.
			return false

		_:
			return _is_text_line_valid(
				line
			)


func _is_node_line_valid(
	line: String
) -> bool:
	if line.count("#") != 1:
		return false

	# Una línea de nodo sólo admite:
	# # ETIQUETA
	# El comentario ya fue eliminado por _remove_comment().
	for marker in ["=", "?", ">", "[", "]"]:
		if line.contains(marker):
			return false

	var label := line.substr(
		1
	).strip_edges()

	if label.is_empty():
		return false

	# La etiqueta limpia es un único token.
	return (
		not label.contains(" ")
		and not label.contains("\t")
	)


func _is_jump_line_valid(
	line: String
) -> bool:
	if line.count(">") != 1:
		return false

	var target := line.substr(
		1
	).strip_edges()

	return _is_clean_target(
		target
	)


func _is_clean_target(
	target: String
) -> bool:
	if target.is_empty():
		return false

	for marker in ["#", "=", "?", ">", "[", "]"]:
		if target.contains(marker):
			return false

	return true


func _has_invalid_brackets(line: String) -> bool:
	var open_count := line.count("[")
	var close_count := line.count("]")

	if open_count > 1 or close_count > 1:
		return true

	return open_count != close_count


func _has_repeated_leading_marker(
	line: String
) -> bool:
	if line.length() < 2:
		return false

	var marker := line[0]

	if marker not in ["#", "=", "?", ">"]:
		return false

	return line[1] == marker


func _has_more_than_one_jump(
	line: String
) -> bool:
	return line.count(">") > 1


func _has_extra_option_marker(
	line: String
) -> bool:
	if not line.begins_with("="):
		return false

	return line.count("=") > 1


func _has_extra_node_marker(
	line: String
) -> bool:
	if not line.begins_with("#"):
		return false

	return line.count("#") > 1


func _remove_comment(line: String) -> String:
	var comment_index := line.find("'")

	if comment_index < 0:
		return line

	return line.substr(
		0,
		comment_index
	)


func _is_option_line_valid(
	line: String
) -> bool:
	if _has_extra_option_marker(line):
		return false

	if _has_more_than_one_jump(line):
		return false

	var content := line.substr(
		1
	).strip_edges()

	if content.is_empty():
		return false

	var bracket := content.find("[")

	if bracket >= 0:
		if not content.ends_with("]"):
			return false

		var effect_text := content.substr(
			bracket + 1,
			content.length() - bracket - 2
		)

		if (
			effect_text.contains("[")
			or effect_text.contains("]")
		):
			return false

		if not _are_effects_locally_valid(
			effect_text
		):
			return false

		content = content.substr(
			0,
			bracket
		).strip_edges()

	elif content.contains("]"):
		return false

	if content.is_empty():
		return false

	var jump_index := content.find(">")

	if jump_index < 0:
		return true

	var option_text := content.substr(
		0,
		jump_index
	).strip_edges()

	var target := content.substr(
		jump_index + 1
	).strip_edges()

	return (
		not option_text.is_empty()
		and _is_clean_target(target)
	)


func _is_condition_line_valid(
	line: String
) -> bool:
	if _has_more_than_one_jump(line):
		return false

	if (
		line.contains("[")
		or line.contains("]")
	):
		return false

	var jump_index := line.find(">")

	if jump_index < 0:
		return false

	var condition_text := line.substr(
		0,
		jump_index
	).strip_edges()

	var target := line.substr(
		jump_index + 1
	).strip_edges()

	if not _is_clean_target(target):
		return false

	var normalized_conditions := condition_text.replace(
		"\t",
		" "
	)

	var tokens := normalized_conditions.split(
		" ",
		false
	)

	if tokens.is_empty():
		return false

	for token in tokens:
		var condition := str(token)

		if not condition.begins_with("?"):
			return false

		if condition.count("?") != 1:
			return false

		if condition.substr(
			1
		).strip_edges().is_empty():
			return false

	return true


func _is_text_line_valid(
	line: String
) -> bool:
	# '>' está reservado al salto estructural.
	if line.contains(">"):
		return false

	var bracket := line.rfind("[")

	if bracket < 0:
		return not line.contains("]")

	if not line.ends_with("]"):
		return false

	var text_part := line.substr(
		0,
		bracket
	).strip_edges()

	if text_part.is_empty():
		return false

	var effect_text := line.substr(
		bracket + 1,
		line.length() - bracket - 2
	)

	if (
		effect_text.contains("[")
		or effect_text.contains("]")
	):
		return false

	return _are_effects_locally_valid(
		effect_text
	)


func _are_effects_locally_valid(
	effect_text: String
) -> bool:
	var effects := effect_text.split(
		",",
		true
	)

	if effects.is_empty():
		return false

	var xp_count := 0

	for raw_effect in effects:
		var effect := str(
			raw_effect
		).strip_edges()

		if effect.is_empty():
			return false

		var lower_effect := effect.to_lower()

		if lower_effect.begins_with("xp"):
			xp_count += 1

			if xp_count > 1:
				return false

			var value_text := effect.substr(
				2
			).strip_edges()

			if value_text.length() < 2:
				return false

			if not (
				value_text.begins_with("+")
				or value_text.begins_with("-")
			):
				return false

			var number_text := value_text.substr(1)

			if (
				number_text.is_empty()
				or not number_text.is_valid_int()
			):
				return false

			continue

		if (
			effect.begins_with("+")
			or effect.begins_with("-")
		):
			if effect.substr(
				1
			).strip_edges().is_empty():
				return false

			continue

		return false

	return true


func _save_current_text() -> bool:
	if file_name.is_empty():
		return false

	if not _ensure_custom_folder():
		push_warning(
			"No se pudo crear la carpeta de guiones locales."
		)
		return false

	var file := FileAccess.open(
		CUSTOM_DIALOGUE_FOLDER + file_name,
		FileAccess.WRITE
	)

	if file == null:
		push_warning(
			"No se pudo guardar el guion local: "
			+ file_name
		)
		return false

	file.store_string(code_edit.text)
	var write_error: Error = file.get_error()
	file.close()

	if write_error != OK:
		push_warning(
			"No se pudo completar el guardado del guion local: "
			+ file_name
		)
		return false

	print(
		"Guion local guardado: ",
		file_name
	)

	return true


func _on_save_pressed() -> void:
	if not _save_current_text():
		return

	# Guardar confirma la edición y vuelve inmediatamente al juego.
	queue_free()


func _on_send_pressed() -> void:
	# Nunca se abre el correo con una versión que no se haya guardado.
	if not _save_current_text():
		return

	var subject: String = (
		"ZeMobida - " + file_name
	).uri_encode()

	var body: String = (
		"Archivo: "
		+ file_name
		+ "\n\n"
		+ code_edit.text
	).uri_encode()

	var mailto_uri: String = (
		"mailto:"
		+ SUBMISSION_EMAIL
		+ "?subject="
		+ subject
		+ "&body="
		+ body
	)

	var error: Error = OS.shell_open(
		mailto_uri
	)

	if error != OK:
		push_warning(
			"El guion se guardó, pero no se pudo abrir la aplicación de correo."
		)


func _ensure_custom_folder() -> bool:
	var dir := DirAccess.open("user://")

	if dir == null:
		return false

	if dir.dir_exists("custom_dialogues"):
		return true

	return dir.make_dir("custom_dialogues") == OK


func _on_close_pressed() -> void:
	queue_free()
