extends CanvasLayer


const CUSTOM_DIALOGUE_FOLDER := "user://custom_dialogues/"


@onready var title_label: Label = $Panel/Title
@onready var code_edit: CodeEdit = $Panel/CodeEdit


var file_name := ""


func _ready() -> void:
	_configure_highlighter()


func setup(
	target_file_name: String,
	initial_text: String
) -> void:
	file_name = target_file_name
	title_label.text = target_file_name
	code_edit.text = initial_text

	code_edit.grab_focus()


func _configure_highlighter() -> void:
	var highlighter := preload(
		"res://scripts/dialogue_syntax_highlighter.gd"
	).new()

	code_edit.syntax_highlighter = highlighter


func _on_save_pressed() -> void:
	if file_name.is_empty():
		return

	if not _ensure_custom_folder():
		push_warning(
			"No se pudo crear la carpeta de guiones locales."
		)
		return

	var file := FileAccess.open(
		CUSTOM_DIALOGUE_FOLDER + file_name,
		FileAccess.WRITE
	)

	if file == null:
		push_warning(
			"No se pudo guardar el guion local: "
			+ file_name
		)
		return

	file.store_string(code_edit.text)
	file.close()

	print(
		"Guion local guardado: ",
		file_name
	)

	# Guardar confirma la edición y vuelve inmediatamente al juego.
	queue_free()


func _ensure_custom_folder() -> bool:
	var dir := DirAccess.open("user://")

	if dir == null:
		return false

	if dir.dir_exists("custom_dialogues"):
		return true

	return dir.make_dir("custom_dialogues") == OK


func _on_close_pressed() -> void:
	queue_free()
