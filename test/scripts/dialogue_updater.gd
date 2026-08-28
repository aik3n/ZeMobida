extends Node


const LOCAL_FOLDER: String = "user://dialogues/"
const TEMP_FOLDER: String = "user://dialogues_temp/"


# CONFIGURACIÓN GITHUB
const GITHUB_USER: String = "aik3n"
const GITHUB_REPO: String = "ZeMobida"
const GITHUB_BRANCH: String = "main"
const GITHUB_FOLDER: String = "guiones"


signal guiones_disponibles_changed

var pending_downloads: int = 0
var github_files: Array[Dictionary] = []
var github_file_names: Array[String] = []

var sync_failed: bool = false
var guiones_disponibles: bool = false


func _ready() -> void:

	initialize_dialogues()



func initialize_dialogues() -> void:

	guiones_disponibles = false

	_create_local_folder()

	_download_from_github()



func _create_local_folder() -> void:

	var dir: DirAccess = DirAccess.open(
		"user://"
	)

	if dir == null:

		push_error(
			"No se puede acceder a user://"
		)

		return

	if not dir.dir_exists("dialogues"):

		var error := dir.make_dir("dialogues")

		if error != OK:

			push_error(
				"No se pudo crear user://dialogues/"
			)



func _download_from_github() -> void:

	github_files.clear()
	github_file_names.clear()

	pending_downloads = 0
	sync_failed = false

	_prepare_temp_folder()

	if sync_failed:

		_finish_synchronization()

		return

	var url: String = (
		"https://api.github.com/repos/"
		+ GITHUB_USER
		+ "/"
		+ GITHUB_REPO
		+ "/contents/"
		+ GITHUB_FOLDER
		+ "?ref="
		+ GITHUB_BRANCH
	)

	var http: HTTPRequest = HTTPRequest.new()

	add_child(http)

	http.request_completed.connect(
		_on_github_list_received.bind(http)
	)

	var error: Error = http.request(url)

	if error != OK:

		sync_failed = true

		push_warning(
			"No se pudo iniciar la conexión con GitHub. "
			+ "Se mantendrán los guiones locales."
		)

		http.queue_free()

		_delete_temp_folder()

		_finish_synchronization()



func _prepare_temp_folder() -> void:

	_delete_temp_folder()

	var dir: DirAccess = DirAccess.open(
		"user://"
	)

	if dir == null:

		sync_failed = true

		push_error(
			"No se puede acceder a user://"
		)

		return

	var error := dir.make_dir("dialogues_temp")

	if error != OK:

		sync_failed = true

		push_error(
			"No se pudo crear la carpeta temporal."
		)



func _on_github_list_received(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest
) -> void:

	http.queue_free()

	if response_code != 200:

		sync_failed = true

		push_warning(
			"GitHub no disponible. "
			+ "Se mantendrán los guiones locales."
		)

		_delete_temp_folder()

		_finish_synchronization()

		return

	var data: Variant = JSON.parse_string(
		body.get_string_from_utf8()
	)

	if data == null or not data is Array:

		sync_failed = true

		push_warning(
			"Respuesta incorrecta de GitHub. "
			+ "Se mantendrán los guiones locales."
		)

		_delete_temp_folder()

		_finish_synchronization()

		return

	for file_data: Variant in data:

		if not file_data is Dictionary:
			continue

		var file: Dictionary = file_data

		if not file.has("name"):
			continue

		if not file.has("download_url"):
			continue

		var file_name: String = str(
			file["name"]
		)

		if not file_name.ends_with(".txt"):
			continue

		github_files.append(file)
		github_file_names.append(file_name)

	pending_downloads = github_files.size()

	if pending_downloads == 0:

		_finish_synchronization()

		return

	for file: Dictionary in github_files:

		_download_file(file)



func _download_file(
	file: Dictionary
) -> void:

	var http: HTTPRequest = HTTPRequest.new()

	add_child(http)

	http.request_completed.connect(
		_on_file_downloaded.bind(
			http,
			file["name"]
		)
	)

	var error: Error = http.request(
		file["download_url"]
	)

	if error != OK:

		sync_failed = true

		push_warning(
			"No se pudo iniciar la descarga de: "
			+ file["name"]
		)

		http.queue_free()

		pending_downloads -= 1

		if pending_downloads == 0:

			_finish_synchronization()



func _on_file_downloaded(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest,
	file_name: String
) -> void:

	http.queue_free()

	if response_code == 200:

		var path: String = (
			TEMP_FOLDER
			+ file_name
		)

		var save: FileAccess = FileAccess.open(
			path,
			FileAccess.WRITE
		)

		if save != null:

			save.store_buffer(body)
			save.close()

			print(
				"Descargado temporalmente: ",
				file_name
			)

		else:

			sync_failed = true

			push_warning(
				"No se pudo guardar temporalmente: "
				+ file_name
			)

	else:

		sync_failed = true

		push_warning(
			"Error descargando: "
			+ file_name
		)

	pending_downloads -= 1

	if pending_downloads == 0:

		_finish_synchronization()



func _finish_synchronization() -> void:

	if sync_failed:

		push_warning(
			"Sincronización incompleta. "
			+ "Se conserva la carpeta local."
		)

		_delete_temp_folder()

		_marcar_guiones_disponibles()

		return

	if not _replace_local_folder():

		sync_failed = true

		push_warning(
			"No se pudo actualizar la carpeta local. "
			+ "Se conserva el estado anterior."
		)

		_delete_temp_folder()

		_marcar_guiones_disponibles()

		return

	print(
		"Sincronización de guiones completada."
	)

	_marcar_guiones_disponibles()



func _marcar_guiones_disponibles() -> void:

	guiones_disponibles = true

	guiones_disponibles_changed.emit()



func _replace_local_folder() -> bool:

	var backup_path := "user://dialogues_backup/"

	_delete_folder(
		backup_path
	)

	var local_dir := DirAccess.open(
		"user://"
	)

	if local_dir == null:
		return false

	var error := local_dir.rename(
		"dialogues",
		"dialogues_backup"
	)

	if error != OK:
		return false

	error = local_dir.rename(
		"dialogues_temp",
		"dialogues"
	)

	if error != OK:

		local_dir.rename(
			"dialogues_backup",
			"dialogues"
		)

		return false

	_delete_folder(
		backup_path
	)

	return true



func _delete_temp_folder() -> void:

	_delete_folder(
		TEMP_FOLDER
	)



func _delete_folder(
	folder_path: String
) -> void:

	var dir := DirAccess.open(
		folder_path
	)

	if dir == null:
		return

	for file_name in dir.get_files():

		var file_path := folder_path + file_name

		DirAccess.remove_absolute(
			file_path
		)

	DirAccess.remove_absolute(
		folder_path
	)
