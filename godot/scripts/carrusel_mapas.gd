extends Control

signal jugar(mapa_path: String)

const INTERNAL_MAPS_FOLDER := "res://mapas/"
const ZIP_MAPS_NAMESPACE := "res://maps/"
const SETTINGS_FILE := "user://settings.cfg"
const SETTINGS_SECTION := "maps"
const SETTINGS_KEY_LAST_MAP := "last_map"

@onready var btn_anterior: Button = $Contenedor/BtnAnterior
@onready var btn_siguiente: Button = $Contenedor/BtnSiguiente
@onready var lbl_nombre: Label = $Contenedor/Centro/Nombre
@onready var preview: TextureRect = $Contenedor/Centro/Preview
@onready var btn_jugar: Button = $Contenedor/Centro/Jugar
@onready var indicadores: Label = $Contenedor/Centro/Indicadores

var mapas: Array[String] = []
var indice_actual: int = 0
var _drag_start: Vector2 = Vector2.ZERO
var _dragging := false
const SWIPE_THRESHOLD := 60.0


func _ready() -> void:
	_discover_maps()
	_select_last_map()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_left"):
		_previous()
	elif event.is_action_pressed("ui_right"):
		_next()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_drag_start = mouse_event.position
				_dragging = true
			elif _dragging:
				_dragging = false
				var distance := mouse_event.position.x - _drag_start.x
				if abs(distance) >= SWIPE_THRESHOLD:
					if distance < 0:
						_next()
					else:
						_previous()


func _discover_maps() -> void:
	mapas.clear()

	var map_ids: Dictionary = {}

	_discover_internal_maps(map_ids)
	_discover_zip_maps(map_ids)

	mapas.sort_custom(_sort_map_paths)


func _discover_internal_maps(map_ids: Dictionary) -> void:
	# ResourceLoader conserva los nombres originales de los recursos
	# también en builds exportadas.
	var entries := ResourceLoader.list_directory(
		INTERNAL_MAPS_FOLDER
	)

	for file_name in entries:
		if file_name.ends_with("/"):
			continue

		if not file_name.to_lower().ends_with(".tscn"):
			continue

		var map_id: String = file_name.get_basename()
		map_ids[map_id] = true
		mapas.append(INTERNAL_MAPS_FOLDER + file_name)


func _discover_zip_maps(map_ids: Dictionary) -> void:
	var folder: String = _get_external_maps_folder()
	var dir := DirAccess.open(folder)

	# La carpeta externa es opcional. Si no existe, simplemente
	# seguimos mostrando los mapas incluidos en el proyecto.
	if dir == null:
		return

	for file_name in dir.get_files():
		if not file_name.to_lower().ends_with(".zip"):
			continue

		var map_id: String = file_name.get_basename()

		if map_id.is_empty():
			continue

		if map_ids.has(map_id):
			push_warning(
				"Mapa duplicado '%s': se conserva el mapa interno."
				% map_id
			)
			continue

		var map_folder: String = (
			ZIP_MAPS_NAMESPACE
			+ map_id
			+ "/"
		)

		# Si el ZIP ya quedó montado al volver al selector, podemos
		# reutilizar directamente su escena.
		var scene_path: String = _find_first_map_scene(
			map_folder
		)

		if scene_path.is_empty():
			var zip_path: String = folder.path_join(file_name)

			# false impide que un ZIP externo sustituya recursos
			# ya existentes en el proyecto principal.
			if not ProjectSettings.load_resource_pack(
				zip_path,
				false
			):
				push_warning(
					"No se pudo cargar el mapa ZIP: " + file_name
				)
				continue

			scene_path = _find_first_map_scene(
				map_folder
			)

		if scene_path.is_empty():
			push_warning(
				"El ZIP '%s' no contiene un .tscn directo en %s"
				% [file_name, map_folder]
			)
			continue

		map_ids[map_id] = true
		mapas.append(scene_path)

		print(
			"Mapa ZIP cargado: ",
			file_name,
			" -> ",
			scene_path
		)


func _find_first_map_scene(map_folder: String) -> String:
	# Contrato deliberadamente mínimo: se usa el primer .tscn
	# situado directamente en res://maps/<id>/. No hay recursión.
	for entry in ResourceLoader.list_directory(map_folder):
		if entry.ends_with("/"):
			continue

		if entry.to_lower().ends_with(".tscn"):
			return map_folder + entry

	return ""


func _get_external_maps_folder() -> String:
	# Desde Godot, res:// es ZeMobida/godot/. Los ZIP externos viven
	# en ZeMobida/mapas_zip/, separados de res://mapas/.
	if OS.has_feature("editor"):
		var project_dir: String = ProjectSettings.globalize_path(
			"res://"
		).trim_suffix("/")
		return project_dir.get_base_dir().path_join(
			"mapas_zip"
		)

	# En Android se usa el mismo nombre dentro del almacenamiento
	# de usuario de la aplicación.
	if OS.has_feature("android"):
		return ProjectSettings.globalize_path(
			"user://mapas_zip"
		)

	# Export de escritorio: mapas_zip/ junto al ejecutable.
	return OS.get_executable_path().get_base_dir().path_join(
		"mapas_zip"
	)


func _sort_map_paths(a: String, b: String) -> bool:
	return a.naturalnocasecmp_to(b) < 0


func _select_last_map() -> void:
	if mapas.is_empty():
		indice_actual = 0
		return

	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		var last_map := str(
			config.get_value(
				SETTINGS_SECTION,
				SETTINGS_KEY_LAST_MAP,
				""
			)
		)
		var found := mapas.find(last_map)
		if found >= 0:
			indice_actual = found
			return

	indice_actual = 0


func _refresh() -> void:
	var hay_mapas := not mapas.is_empty()

	btn_anterior.disabled = not hay_mapas
	btn_siguiente.disabled = not hay_mapas
	btn_jugar.disabled = not hay_mapas

	if not hay_mapas:
		lbl_nombre.text = "No hay mapas disponibles"
		preview.texture = null
		preview.visible = false
		indicadores.text = ""
		return

	var mapa_path := mapas[indice_actual]
	var nombre: String = _get_map_id_from_path(
		mapa_path
	).replace("_", " ")

	lbl_nombre.text = nombre
	indicadores.text = "%d / %d" % [indice_actual + 1, mapas.size()]

	_load_preview(mapa_path)


func _get_map_id_from_path(mapa_path: String) -> String:
	if mapa_path.begins_with(ZIP_MAPS_NAMESPACE):
		var relative: String = mapa_path.trim_prefix(
			ZIP_MAPS_NAMESPACE
		)
		var separator: int = relative.find("/")

		if separator > 0:
			return relative.substr(0, separator)

	return mapa_path.get_file().get_basename()


func _load_preview(mapa_path: String) -> void:
	preview.texture = null
	preview.visible = false

	var packed_scene := ResourceLoader.load(mapa_path) as PackedScene
	if packed_scene == null:
		return

	var instance := packed_scene.instantiate()
	var preview_node := instance.get_node_or_null("Preview")

	if preview_node is Sprite2D:
		preview.texture = (preview_node as Sprite2D).texture
	elif preview_node is TextureRect:
		preview.texture = (preview_node as TextureRect).texture

	preview.visible = preview.texture != null
	instance.free()


func _previous() -> void:
	if mapas.is_empty():
		return

	indice_actual = posmod(indice_actual - 1, mapas.size())
	_refresh()


func _next() -> void:
	if mapas.is_empty():
		return

	indice_actual = posmod(indice_actual + 1, mapas.size())
	_refresh()


func _on_btn_anterior_pressed() -> void:
	_previous()


func _on_btn_siguiente_pressed() -> void:
	_next()


func _on_jugar_pressed() -> void:
	if mapas.is_empty():
		return

	var mapa_path := mapas[indice_actual]
	_save_last_map(mapa_path)
	jugar.emit(mapa_path)


func _save_last_map(mapa_path: String) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_FILE)
	config.set_value(
		SETTINGS_SECTION,
		SETTINGS_KEY_LAST_MAP,
		mapa_path
	)

	var error := config.save(SETTINGS_FILE)
	if error != OK:
		push_warning("No se pudo guardar el último mapa seleccionado.")
