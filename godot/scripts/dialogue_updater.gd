extends Node


const LOCAL_FOLDER: String = "user://dialogues/"
const TEMP_FOLDER: String = "user://dialogues_temp/"
const MANIFEST_FILE: String = "user://dialogues_manifest.json"
const SETTINGS_FILE: String = "user://settings.cfg"
const SETTINGS_SECTION: String = "dialogues"
const SETTINGS_KEY_UPDATE_ON_START: String = "update_on_start"

# CONFIGURACIÓN GITHUB
const GITHUB_USER: String = "aik3n"
const GITHUB_REPO: String = "ZeMobida_guiones"
const GITHUB_BRANCH: String = "main"

# Tiempo máximo de sincronización al iniciar.
const SYNC_TIMEOUT_SECONDS: float = 30.0

signal guiones_disponibles_changed
signal sincronizacion_completada

var pending_downloads: int = 0
var github_files: Array[Dictionary] = []
var github_file_names: Array[String] = []
var local_manifest: Dictionary = {}
var downloaded_files: Dictionary = {}
var active_requests: Array[HTTPRequest] = []

var sync_failed: bool = false
var cache_needs_replace: bool = false
var guiones_disponibles: bool = false
var sincronizando: bool = false
var actualizar_guiones_al_iniciar: bool = true

var _sync_timer: Timer = null
var _sync_finished: bool = false


func _ready() -> void:

	_load_settings()
	initialize_dialogues()


func initialize_dialogues() -> void:

	guiones_disponibles = false
	sincronizando = false
	_sync_finished = false

	_create_local_folder()

	if not _local_dialogues_are_available():
		guiones_disponibles = false
	else:
		# La caché local es utilizable desde el principio, pero no se permite
		# entrar al mapa hasta terminar la comprobación configurada.
		guiones_disponibles = true

	if not actualizar_guiones_al_iniciar:
		_finish_synchronization(false)
		return

	_download_from_github()


func set_actualizar_guiones_al_iniciar(enabled: bool) -> void:

	actualizar_guiones_al_iniciar = enabled
	_save_settings()


func _load_settings() -> void:

	var config := ConfigFile.new()
	var error := config.load(SETTINGS_FILE)

	if error != OK:
		actualizar_guiones_al_iniciar = true
		return

	actualizar_guiones_al_iniciar = config.get_value(
		SETTINGS_SECTION,
		SETTINGS_KEY_UPDATE_ON_START,
		true
	)


func _save_settings() -> void:

	var config := ConfigFile.new()
	var error := config.load(SETTINGS_FILE)

	if error != OK and error != ERR_FILE_NOT_FOUND:
		print("No se pudieron cargar las preferencias de guiones.")

	config.set_value(
		SETTINGS_SECTION,
		SETTINGS_KEY_UPDATE_ON_START,
		actualizar_guiones_al_iniciar
	)

	error = config.save(SETTINGS_FILE)

	if error != OK:
		print("No se pudieron guardar las preferencias de guiones.")


func _create_local_folder() -> void:

	var dir: DirAccess = DirAccess.open("user://")

	if dir == null:
		push_error("No se puede acceder a user://")
		return

	if not dir.dir_exists("dialogues"):
		var error := dir.make_dir("dialogues")

		if error != OK:
			push_error("No se pudo crear user://dialogues/")


func _local_dialogues_are_available() -> bool:

	var dir := DirAccess.open(LOCAL_FOLDER)

	if dir == null:
		return false

	var files := dir.get_files()

	for file_name in files:
		if file_name.ends_with(".txt"):
			return true

	return false


func _download_from_github() -> void:

	github_files.clear()
	github_file_names.clear()
	local_manifest = _load_manifest()
	downloaded_files.clear()
	pending_downloads = 0
	sync_failed = false
	cache_needs_replace = false
	sincronizando = true
	_sync_finished = false

	_prepare_temp_folder()

	if sync_failed:
		_finish_synchronization(true)
		return

	_start_sync_timeout()

	var url: String = (
		"https://api.github.com/repos/"
		+ GITHUB_USER
		+ "/"
		+ GITHUB_REPO
		+ "/contents/"
		+ "?ref="
		+ GITHUB_BRANCH
	)

	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	active_requests.append(http)

	http.request_completed.connect(
		_on_github_list_received.bind(http)
	)

	var error: Error = http.request(url)

	if error != OK:
		sync_failed = true
		print(
			"No se pudo iniciar la conexión con GitHub. "
			+ "Se mantendrán los guiones locales."
		)
		http.queue_free()
		active_requests.erase(http)
		_delete_temp_folder()
		_finish_synchronization(true)


func _prepare_temp_folder() -> void:

	_delete_temp_folder()

	var dir: DirAccess = DirAccess.open("user://")

	if dir == null:
		sync_failed = true
		push_error("No se puede acceder a user://")
		return

	var error := dir.make_dir("dialogues_temp")

	if error != OK:
		sync_failed = true
		push_error("No se pudo crear la carpeta temporal.")


func _start_sync_timeout() -> void:

	if _sync_timer != null:
		_sync_timer.queue_free()

	_sync_timer = Timer.new()
	_sync_timer.one_shot = true
	_sync_timer.wait_time = SYNC_TIMEOUT_SECONDS
	add_child(_sync_timer)
	_sync_timer.timeout.connect(_on_sync_timeout)
	_sync_timer.start()


func _stop_sync_timeout() -> void:

	if _sync_timer == null:
		return

	_sync_timer.stop()
	_sync_timer.queue_free()
	_sync_timer = null


func _on_sync_timeout() -> void:

	if _sync_finished:
		return

	sync_failed = true
	print(
		"Tiempo de sincronización agotado. "
		+ "Se mantendrán los guiones locales."
	)

	_cancel_active_requests()
	_delete_temp_folder()
	_finish_synchronization(true)


func _cancel_active_requests() -> void:

	for http in active_requests:
		if is_instance_valid(http):
			http.queue_free()

	active_requests.clear()


func _on_github_list_received(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest
) -> void:

	if _sync_finished:
		return

	active_requests.erase(http)
	if is_instance_valid(http):
		http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		sync_failed = true
		print(
			"GitHub no disponible. "
			+ "Se mantendrán los guiones locales."
		)
		_delete_temp_folder()
		_finish_synchronization(true)
		return

	var data: Variant = JSON.parse_string(body.get_string_from_utf8())

	if data == null or not data is Array:
		sync_failed = true
		print(
			"Respuesta incorrecta de GitHub. "
			+ "Se mantendrán los guiones locales."
		)
		_delete_temp_folder()
		_finish_synchronization(true)
		return

	for file_data: Variant in data:
		if not file_data is Dictionary:
			continue

		var file: Dictionary = file_data

		if not file.has("name") or not file.has("download_url") or not file.has("sha"):
			continue

		var file_name: String = str(file["name"])

		if not file_name.ends_with(".txt"):
			continue

		github_files.append(file)
		github_file_names.append(file_name)

	if github_files.is_empty():
		sync_failed = true
		print(
			"GitHub no contiene archivos .txt. "
			+ "Se mantendrán los guiones locales."
		)
		_delete_temp_folder()
		_finish_synchronization(true)
		return

	var changed_files: Array[Dictionary] = []

	for file in github_files:
		var file_name: String = str(file["name"])
		var remote_sha: String = str(file["sha"])
		var local_sha: String = str(local_manifest.get(file_name, ""))

		if local_sha == remote_sha and FileAccess.file_exists(LOCAL_FOLDER + file_name):
			if not _copy_file_to_temp(file_name):
				sync_failed = true
				break
		else:
			changed_files.append(file)

	if sync_failed:
		_delete_temp_folder()
		_finish_synchronization(true)
		return

	cache_needs_replace = (
		not changed_files.is_empty()
		or _local_file_set_differs_from_remote()
	)

	pending_downloads = changed_files.size()

	if pending_downloads == 0:
		_finish_synchronization(false)
		return

	for file in changed_files:
		_download_file(file)


func _copy_file_to_temp(file_name: String) -> bool:

	var source_path := LOCAL_FOLDER + file_name
	var target_path := TEMP_FOLDER + file_name

	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return false

	var data := source.get_buffer(source.get_length())
	source.close()

	var target := FileAccess.open(target_path, FileAccess.WRITE)
	if target == null:
		return false

	target.store_buffer(data)
	target.close()
	return true


func _download_file(file: Dictionary) -> void:

	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	active_requests.append(http)

	http.request_completed.connect(
		_on_file_downloaded.bind(
			http,
			file["name"]
		)
	)

	var error: Error = http.request(file["download_url"])

	if error != OK:
		active_requests.erase(http)
		if is_instance_valid(http):
			http.queue_free()
		sync_failed = true
		pending_downloads -= 1
		print(
			"No se pudo iniciar la descarga de: "
			+ file["name"]
		)

		if pending_downloads == 0:
			_delete_temp_folder()
			_finish_synchronization(true)


func _on_file_downloaded(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest,
	file_name: String
) -> void:

	if _sync_finished:
		return

	active_requests.erase(http)
	if is_instance_valid(http):
		http.queue_free()

	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var path: String = TEMP_FOLDER + file_name
		var save: FileAccess = FileAccess.open(path, FileAccess.WRITE)

		if save != null:
			save.store_buffer(body)
			save.close()
			downloaded_files[file_name] = true
			print("Descargado temporalmente: ", file_name)
		else:
			sync_failed = true
			print(
				"No se pudo guardar temporalmente: "
				+ file_name
			)
	else:
		sync_failed = true
		print("Error descargando: " + file_name)

	pending_downloads -= 1

	if pending_downloads == 0:
		if sync_failed:
			_delete_temp_folder()
			_finish_synchronization(true)
		else:
			_finish_synchronization(false)


func _finish_synchronization(failed: bool) -> void:

	if _sync_finished:
		return

	_sync_finished = true
	sincronizando = false
	_stop_sync_timeout()

	if failed or sync_failed:
		if sync_failed:
			print(
				"Sincronización incompleta. "
				+ "Se conserva la carpeta local."
			)

		_delete_temp_folder()
		_marcar_guiones_disponibles()
		sincronizacion_completada.emit()
		return

	if cache_needs_replace:
		# El updater valida la integridad de la sincronización:
		# el temporal debe contener exactamente los .txt publicados.
		# No interpreta ni valida la sintaxis de los guiones.
		if not _temp_file_set_matches_remote():
			sync_failed = true
			print(
				"El conjunto descargado está incompleto. "
				+ "Se conserva la carpeta local."
			)
			_delete_temp_folder()
			_marcar_guiones_disponibles()
			sincronizacion_completada.emit()
			return

		if not _replace_local_folder():
			sync_failed = true
			print(
				"No se pudo actualizar la carpeta local. "
				+ "Se conserva el estado anterior."
			)
			_delete_temp_folder()
			_marcar_guiones_disponibles()
			sincronizacion_completada.emit()
			return

		_marcar_guiones_disponibles()
		sincronizacion_completada.emit()
		return

	# Sin cambios de contenido ni de conjunto de archivos.
	_delete_temp_folder()
	_marcar_guiones_disponibles()
	sincronizacion_completada.emit()


func _local_file_set_differs_from_remote() -> bool:

	var dir := DirAccess.open(LOCAL_FOLDER)

	if dir == null:
		return true

	var local_files: Array[String] = []

	for file_name in dir.get_files():
		if file_name.ends_with(".txt"):
			local_files.append(file_name)

	var remote_files: Array[String] = []

	for file_name in github_file_names:
		remote_files.append(file_name)

	local_files.sort()
	remote_files.sort()

	return local_files != remote_files


func _temp_file_set_matches_remote() -> bool:

	var dir := DirAccess.open(TEMP_FOLDER)

	if dir == null:
		return false

	var temp_files: Array[String] = []

	for file_name in dir.get_files():
		if file_name.ends_with(".txt"):
			temp_files.append(file_name)

	var remote_files: Array[String] = []

	for file_name in github_file_names:
		remote_files.append(file_name)

	temp_files.sort()
	remote_files.sort()

	return temp_files == remote_files


func _marcar_guiones_disponibles() -> void:

	var available := _local_dialogues_are_available()
	guiones_disponibles = available
	guiones_disponibles_changed.emit()


func _load_manifest() -> Dictionary:

	var file := FileAccess.open(MANIFEST_FILE, FileAccess.READ)
	if file == null:
		return {}

	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if data is Dictionary and data.has("files") and data["files"] is Dictionary:
		return data["files"]

	return {}


func _save_manifest() -> bool:

	var files := {}

	for file in github_files:
		files[str(file["name"])] = str(file["sha"])

	var file := FileAccess.open(MANIFEST_FILE, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify({"files": files}, "  "))
	file.close()
	return true


func _replace_local_folder() -> bool:

	var backup_path := "user://dialogues_backup/"
	_delete_folder(backup_path)

	var local_dir := DirAccess.open("user://")
	if local_dir == null:
		return false

	var error := local_dir.rename("dialogues", "dialogues_backup")
	if error != OK:
		return false

	error = local_dir.rename("dialogues_temp", "dialogues")
	if error != OK:
		local_dir.rename("dialogues_backup", "dialogues")
		return false

	_delete_folder(backup_path)

	if not _save_manifest():
		print("No se pudo guardar el manifest de guiones.")

	return true


func _delete_temp_folder() -> void:
	_delete_folder(TEMP_FOLDER)


func _delete_folder(folder_path: String) -> void:

	var dir := DirAccess.open(folder_path)
	if dir == null:
		return

	for file_name in dir.get_files():
		dir.remove(file_name)

	dir = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder_path))
