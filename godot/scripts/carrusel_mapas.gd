extends Control

signal jugar(mapa_path: String)

const MAPS_FOLDER := "res://mapas/"
const SETTINGS_FILE := "user://settings.cfg"
const SETTINGS_SECTION := "maps"
const SETTINGS_KEY_LAST_MAP := "last_map"
const DEFAULT_PREVIEW := preload(
	"res://art/ui/preview_default.png"
)

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

	# ResourceLoader conserva los nombres originales de los recursos
	# también en builds exportadas. DirAccess sobre res:// puede no
	# devolver los .tscn porque Godot remapea recursos dentro del PCK.
	var entries := ResourceLoader.list_directory(MAPS_FOLDER)

	for file_name in entries:
		if file_name.ends_with("/"):
			continue

		if file_name.to_lower().ends_with(".tscn"):
			mapas.append(MAPS_FOLDER + file_name)

	mapas.sort_custom(_sort_map_paths)


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
	var file_name := mapa_path.get_file()
	var nombre := file_name.get_basename().replace("_", " ")

	lbl_nombre.text = nombre
	indicadores.text = "%d / %d" % [indice_actual + 1, mapas.size()]

	_load_preview(mapa_path)


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

	if preview.texture == null:
		var fondo_node := instance.get_node_or_null("Fondo")

		if fondo_node is Sprite2D:
			preview.texture = (fondo_node as Sprite2D).texture

	if preview.texture == null:
		preview.texture = DEFAULT_PREVIEW

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
		print("No se pudo guardar el último mapa seleccionado.")
