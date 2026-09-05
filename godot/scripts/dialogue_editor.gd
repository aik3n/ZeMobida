extends CanvasLayer


const CUSTOM_DIALOGUE_FOLDER := "user://custom_dialogues/"
const PUBLISHER_URL := "https://zemobida-publish.sam-cdi110.workers.dev"
const SEND_TEXTURE := preload("res://art/ui/enviar.png")
const DISCARD_TEXTURE := preload("res://art/ui/papelera.png")

const ERROR_GUTTER_WIDTH := 34
const ERROR_MARKER := "●"
const ERROR_COLOR := Color("#ff4d5a")


@onready var title_label: Label = $Panel/Title
@onready var code_edit: CodeEdit = $Panel/CodeEdit
@onready var discard_button: Button = $Panel/DiscardButton
@onready var send_button: Button = $Panel/SendButton
@onready var close_button: Button = $Panel/CloseButton
@onready var confirmation_overlay: ColorRect = $ConfirmationOverlay
@onready var confirmation_icon: TextureRect = $ConfirmationOverlay/Icon
@onready var confirmation_cancel_button: Button = $ConfirmationOverlay/CancelButton
@onready var confirmation_ok_button: Button = $ConfirmationOverlay/ConfirmButton
@onready var feedback_icon: TextureRect = $FeedbackIcon


enum ConfirmationAction {
	NONE,
	DISCARD,
	SEND
}


var file_name := ""
var _base_text := ""
var _error_gutter := -1
var _submission_request: HTTPRequest
var _submission_busy := false
var _confirmation_action := ConfirmationAction.NONE
var _confirmation_source_button: Control


func _ready() -> void:
	_configure_highlighter()
	_configure_error_gutter()
	_configure_submission_request()

	code_edit.text_changed.connect(
		_refresh_line_error_markers
	)

	feedback_icon.pivot_offset = feedback_icon.size * 0.5


func setup(
	target_file_name: String,
	initial_text: String,
	base_text: String
) -> void:
	file_name = target_file_name
	_base_text = base_text
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


func _configure_submission_request() -> void:
	_submission_request = HTTPRequest.new()
	add_child(_submission_request)
	_submission_request.request_completed.connect(
		_on_submission_request_completed
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

	# La firma pública es una línea independiente.
	if line.begins_with("@"):
		return not line.substr(1).strip_edges().is_empty()

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

	# La etiqueta limpia es un único token y RANDOM está reservado.
	return (
		not label.contains(" ")
		and not label.contains("\t")
		and label.to_lower() != "random"
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

	return (
		not target.contains(" ")
		and not target.contains("\t")
	)


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

	for raw_effect in effects:
		var effect := str(
			raw_effect
		).strip_edges()

		if effect.is_empty():
			return false

		if (
			effect.begins_with("+")
			or effect.begins_with("-")
		):
			var item := effect.substr(
				1
			).strip_edges()

			if item.is_empty():
				return false

			if (
				item.contains(" ")
				or item.contains("\t")
			):
				return false

			if (
				effect.begins_with("-")
				and item.to_lower() == "_eoa_"
			):
				return false

			continue

		return false

	return true


func _save_current_text() -> bool:
	if file_name.is_empty():
		return false

	if not _ensure_custom_folder():
		print(
			"No se pudo crear la carpeta de guiones locales."
		)
		return false

	var file := FileAccess.open(
		CUSTOM_DIALOGUE_FOLDER + file_name,
		FileAccess.WRITE
	)

	if file == null:
		print(
			"No se pudo guardar el guion local: "
			+ file_name
		)
		return false

	file.store_string(code_edit.text)
	var write_error: Error = file.get_error()
	file.close()

	if write_error != OK:
		print(
			"No se pudo completar el guardado del guion local: "
			+ file_name
		)
		return false

	print(
		"Guion local guardado: ",
		file_name
	)

	return true


func _on_discard_pressed() -> void:
	if _submission_busy:
		return

	_show_confirmation(
		ConfirmationAction.DISCARD,
		DISCARD_TEXTURE,
		discard_button
	)


func _on_send_pressed() -> void:
	if _submission_busy:
		return

	_show_confirmation(
		ConfirmationAction.SEND,
		SEND_TEXTURE,
		send_button
	)


func _send_confirmed() -> void:
	# No se valida: propuestas es un buzón de trabajo.
	# Guardamos primero para que un fallo de red nunca pierda la edición.
	if not _persist_local_if_changed():
		return

	_submission_busy = true
	_set_editor_actions_enabled(false)

	var payload := JSON.stringify({
		"filename": file_name,
		"content": code_edit.text
	})

	var error := _submission_request.request(
		PUBLISHER_URL + "/proposal",
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		payload
	)

	if error != OK:
		_submission_busy = false
		print(
			"El guion se guardó, pero no se pudo iniciar el envío de la propuesta: ",
			error
		)
		await _show_send_result(false)
		_set_editor_actions_enabled(true)
		code_edit.grab_focus()


func _on_submission_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	_submission_busy = false

	var response_text := body.get_string_from_utf8()
	var response_data = JSON.parse_string(response_text)

	var success := (
		result == HTTPRequest.RESULT_SUCCESS
		and response_code >= 200
		and response_code < 300
		and response_data is Dictionary
		and bool(response_data.get("ok", false))
	)

	if success:
		var sent_name := str(
			response_data.get("filename", file_name)
		)

		print("Propuesta enviada: ", sent_name)

		if not _delete_local_copy():
			print(
				"La propuesta se envió, pero no se pudo borrar la copia local: ",
				file_name
			)
			await _show_send_result(false)
			_set_editor_actions_enabled(true)
			code_edit.grab_focus()
			return

		await _show_send_result(true)
		queue_free()
		return

	var message := "HTTP %s · resultado %s" % [
		response_code,
		result
	]

	if response_data is Dictionary:
		message = str(
			response_data.get("error", message)
		)

	print(
		"El guion quedó guardado localmente, pero falló el envío de la propuesta: ",
		message
	)

	await _show_send_result(false)
	_set_editor_actions_enabled(true)
	code_edit.grab_focus()


func _show_confirmation(
	action: ConfirmationAction,
	texture: Texture2D,
	source_button: Control
) -> void:
	_confirmation_action = action
	_confirmation_source_button = source_button
	confirmation_icon.texture = texture
	confirmation_overlay.visible = true

	await _animate_confirmation_in(source_button)

	confirmation_cancel_button.grab_focus()


func _confirmation_target_rect() -> Rect2:
	var side := clampf(
		min(
			confirmation_overlay.size.x,
			confirmation_overlay.size.y
		) * 0.34,
		180.0,
		320.0
	)

	var target_size := Vector2(side, side)
	var target_position := Vector2(
		(confirmation_overlay.size.x - side) * 0.5,
		(confirmation_overlay.size.y - side) * 0.5 - side * 0.08
	)

	return Rect2(
		target_position,
		target_size
	)


func _source_rect_in_overlay(
	source_button: Control
) -> Rect2:
	var source_rect := source_button.get_global_rect()
	var overlay_rect := confirmation_overlay.get_global_rect()

	return Rect2(
		source_rect.position - overlay_rect.position,
		source_rect.size
	)


func _layout_confirmation_buttons(
	target: Rect2
) -> void:
	confirmation_cancel_button.size = Vector2(64.0, 64.0)
	confirmation_cancel_button.position = Vector2(
		target.end.x - 34.0,
		target.position.y - 26.0
	)

	confirmation_ok_button.size = Vector2(124.0, 58.0)
	confirmation_ok_button.position = Vector2(
		target.position.x + (target.size.x - 124.0) * 0.5,
		target.end.y + 26.0
	)

	confirmation_cancel_button.pivot_offset = (
		confirmation_cancel_button.size * 0.5
	)
	confirmation_ok_button.pivot_offset = (
		confirmation_ok_button.size * 0.5
	)


func _reset_confirmation_visuals() -> void:
	confirmation_overlay.modulate = Color.WHITE
	confirmation_icon.modulate = Color.WHITE
	confirmation_cancel_button.modulate = Color.WHITE
	confirmation_ok_button.modulate = Color.WHITE

	confirmation_cancel_button.visible = true
	confirmation_ok_button.visible = true

	confirmation_icon.scale = Vector2.ONE
	confirmation_cancel_button.scale = Vector2.ONE
	confirmation_ok_button.scale = Vector2.ONE


func _set_confirmation_buttons_enabled(
	enabled: bool
) -> void:
	confirmation_cancel_button.disabled = not enabled
	confirmation_ok_button.disabled = not enabled


func _animate_confirmation_in(
	source_button: Control
) -> void:
	_reset_confirmation_visuals()
	_set_confirmation_buttons_enabled(false)

	var source := _source_rect_in_overlay(source_button)
	var target := _confirmation_target_rect()

	confirmation_overlay.modulate.a = 0.0

	confirmation_icon.position = source.position
	confirmation_icon.size = source.size
	confirmation_icon.pivot_offset = source.size * 0.5

	_layout_confirmation_buttons(target)

	confirmation_cancel_button.modulate.a = 0.0
	confirmation_ok_button.modulate.a = 0.0
	confirmation_cancel_button.scale = Vector2(0.72, 0.72)
	confirmation_ok_button.scale = Vector2(0.72, 0.72)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		confirmation_overlay,
		"modulate:a",
		1.0,
		0.14
	)

	tween.tween_property(
		confirmation_icon,
		"position",
		target.position,
		0.26
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		confirmation_icon,
		"size",
		target.size,
		0.26
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		confirmation_cancel_button,
		"modulate:a",
		1.0,
		0.10
	).set_delay(0.17)

	tween.tween_property(
		confirmation_cancel_button,
		"scale",
		Vector2.ONE,
		0.14
	).set_delay(0.17).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		confirmation_ok_button,
		"modulate:a",
		1.0,
		0.10
	).set_delay(0.20)

	tween.tween_property(
		confirmation_ok_button,
		"scale",
		Vector2.ONE,
		0.14
	).set_delay(0.20).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)

	await tween.finished

	confirmation_icon.pivot_offset = confirmation_icon.size * 0.5
	_set_confirmation_buttons_enabled(true)


func _animate_confirmation_cancel() -> void:
	_set_confirmation_buttons_enabled(false)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		confirmation_cancel_button,
		"modulate:a",
		0.0,
		0.08
	)
	tween.tween_property(
		confirmation_ok_button,
		"modulate:a",
		0.0,
		0.08
	)

	if (
		_confirmation_source_button != null
		and is_instance_valid(_confirmation_source_button)
	):
		var source := _source_rect_in_overlay(
			_confirmation_source_button
		)

		tween.tween_property(
			confirmation_icon,
			"position",
			source.position,
			0.20
		).set_trans(Tween.TRANS_QUART).set_ease(
			Tween.EASE_IN
		)

		tween.tween_property(
			confirmation_icon,
			"size",
			source.size,
			0.20
		).set_trans(Tween.TRANS_QUART).set_ease(
			Tween.EASE_IN
		)

	tween.tween_property(
		confirmation_overlay,
		"modulate:a",
		0.0,
		0.20
	)

	await tween.finished

	confirmation_overlay.visible = false
	_confirmation_source_button = null
	_reset_confirmation_visuals()
	_set_confirmation_buttons_enabled(true)


func _animate_confirmation_accept() -> void:
	_set_confirmation_buttons_enabled(false)

	var pop := create_tween()
	pop.set_parallel(true)

	pop.tween_property(
		confirmation_cancel_button,
		"modulate:a",
		0.0,
		0.07
	)

	pop.tween_property(
		confirmation_ok_button,
		"scale",
		Vector2(1.14, 1.14),
		0.10
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	pop.tween_property(
		confirmation_icon,
		"scale",
		Vector2(1.06, 1.06),
		0.10
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await pop.finished

	var fade := create_tween()
	fade.set_parallel(true)

	fade.tween_property(
		confirmation_overlay,
		"modulate:a",
		0.0,
		0.12
	)
	fade.tween_property(
		confirmation_ok_button,
		"modulate:a",
		0.0,
		0.10
	)

	await fade.finished

	confirmation_overlay.visible = false
	_confirmation_source_button = null
	_reset_confirmation_visuals()
	_set_confirmation_buttons_enabled(true)


func _prepare_confirmation_send_waiting() -> void:
	_set_confirmation_buttons_enabled(false)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		confirmation_cancel_button,
		"modulate:a",
		0.0,
		0.07
	)
	tween.tween_property(
		confirmation_ok_button,
		"modulate:a",
		0.0,
		0.07
	)
	tween.tween_property(
		confirmation_icon,
		"scale",
		Vector2(1.06, 1.06),
		0.10
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished

	confirmation_cancel_button.visible = false
	confirmation_ok_button.visible = false
	confirmation_icon.scale = Vector2.ONE


func _show_send_result(
	success: bool
) -> void:
	if success:
		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			confirmation_icon,
			"position",
			confirmation_icon.position + Vector2(0.0, -170.0),
			0.28
		).set_trans(Tween.TRANS_QUART).set_ease(
			Tween.EASE_OUT
		)

		tween.tween_property(
			confirmation_icon,
			"modulate:a",
			0.0,
			0.20
		).set_delay(0.08)

		tween.tween_property(
			confirmation_overlay,
			"modulate:a",
			0.0,
			0.22
		).set_delay(0.08)

		await tween.finished
	else:
		var origin := confirmation_icon.position
		var shake := create_tween()

		for offset in [-24.0, 24.0, -16.0, 16.0, -10.0, 10.0, 0.0]:
			shake.tween_property(
				confirmation_icon,
				"position",
				origin + Vector2(offset, 0.0),
				0.045
			)

		await shake.finished

		var fade := create_tween()
		fade.set_parallel(true)

		fade.tween_property(
			confirmation_icon,
			"modulate:a",
			0.0,
			0.12
		)
		fade.tween_property(
			confirmation_overlay,
			"modulate:a",
			0.0,
			0.14
		)

		await fade.finished

	confirmation_overlay.visible = false
	_confirmation_source_button = null
	_reset_confirmation_visuals()
	_set_confirmation_buttons_enabled(true)


func _on_confirmation_cancel_pressed() -> void:
	_confirmation_action = ConfirmationAction.NONE

	await _animate_confirmation_cancel()

	code_edit.grab_focus()


func _on_confirmation_ok_pressed() -> void:
	var action := _confirmation_action
	_confirmation_action = ConfirmationAction.NONE

	match action:
		ConfirmationAction.DISCARD:
			await _animate_confirmation_accept()
			_discard_confirmed()
		ConfirmationAction.SEND:
			await _prepare_confirmation_send_waiting()
			_send_confirmed()


func _discard_confirmed() -> void:
	if not _delete_local_copy():
		print(
			"No se pudo descartar la copia local: ",
			file_name
		)
		return

	queue_free()


func _persist_local_if_changed() -> bool:
	if code_edit.text == _base_text:
		return _delete_local_copy()

	return _save_current_text()


func _delete_local_copy() -> bool:
	var local_path := CUSTOM_DIALOGUE_FOLDER + file_name

	if not FileAccess.file_exists(local_path):
		return true

	var dir := DirAccess.open(CUSTOM_DIALOGUE_FOLDER)

	if dir == null:
		return false

	return dir.remove(file_name) == OK


func _set_editor_actions_enabled(
	enabled: bool
) -> void:
	discard_button.disabled = not enabled
	send_button.disabled = not enabled
	close_button.disabled = not enabled


func _show_send_feedback(
	success: bool
) -> void:
	feedback_icon.texture = SEND_TEXTURE
	feedback_icon.visible = true
	feedback_icon.modulate = Color.WHITE
	feedback_icon.scale = Vector2.ONE
	feedback_icon.pivot_offset = feedback_icon.size * 0.5

	if success:
		feedback_icon.scale = Vector2(0.72, 0.72)

		var tween := create_tween()
		tween.tween_property(
			feedback_icon,
			"scale",
			Vector2(1.14, 1.14),
			0.16
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(
			feedback_icon,
			"scale",
			Vector2.ONE,
			0.08
		)
		tween.tween_interval(0.35)
		tween.tween_property(
			feedback_icon,
			"modulate:a",
			0.0,
			0.18
		)
		await tween.finished
	else:
		var origin := feedback_icon.position
		var tween := create_tween()

		for offset in [-20.0, 20.0, -14.0, 14.0, 0.0]:
			tween.tween_property(
				feedback_icon,
				"position",
				origin + Vector2(offset, 0.0),
				0.055
			)

		tween.tween_interval(0.22)
		tween.tween_property(
			feedback_icon,
			"modulate:a",
			0.0,
			0.16
		)
		await tween.finished
		feedback_icon.position = origin

	feedback_icon.visible = false
	feedback_icon.modulate = Color.WHITE
	feedback_icon.scale = Vector2.ONE


func _ensure_custom_folder() -> bool:
	var dir := DirAccess.open("user://")

	if dir == null:
		return false

	if dir.dir_exists("custom_dialogues"):
		return true

	return dir.make_dir("custom_dialogues") == OK


func _on_close_pressed() -> void:
	if _submission_busy:
		return

	# Azul significa que existe una variante local realmente distinta.
	if _persist_local_if_changed():
		queue_free()
