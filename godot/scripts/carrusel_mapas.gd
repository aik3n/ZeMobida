extends Control

signal jugar(mapa_path: String)

const MAPS_FOLDER := "res://mapas/"
const SETTINGS_FILE := "user://settings.cfg"
const SETTINGS_SECTION := "maps"
const SETTINGS_KEY_LAST_MAP := "last_map"
const DEFAULT_PREVIEW := preload(
	"res://art/ui/preview_default.png"
)

@onready var btn_anterior: Button = $Contenedor/Centro/Navegacion/BtnAnterior
@onready var btn_siguiente: Button = $Contenedor/Centro/Navegacion/BtnSiguiente
@onready var lbl_nombre: Label = $Contenedor/Centro/Nombre
@onready var preview: TextureRect = $Contenedor/Centro/Preview
@onready var sello: TextureRect = $Contenedor/Centro/Preview/Sello
@onready var lbl_texto: Label = $Contenedor/Centro/Texto
@onready var indicadores: Label = $Contenedor/Centro/Indicadores

var mapas: Array[String] = []
var indice_actual: int = 0
var _drag_start: Vector2 = Vector2.ZERO
var _dragging := false
var _transitioning := false
const SWIPE_THRESHOLD := 60.0
const MAP_TRANSITION_TIME := 0.42


func _ready() -> void:
	_discover_maps()
	_select_last_map()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _transitioning:
		return

	if event.is_action_pressed("ui_left"):
		_previous()
	elif event.is_action_pressed("ui_right"):
		_next()


func _input(event: InputEvent) -> void:
	if not visible or _transitioning:
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
				elif _preview_was_clicked(
					_drag_start,
					mouse_event.position
				):
					_play_current_map()


func _preview_was_clicked(
	press_position: Vector2,
	release_position: Vector2
) -> bool:
	if mapas.is_empty() or not preview.visible:
		return false

	var preview_rect := preview.get_global_rect()

	return (
		preview_rect.has_point(press_position)
		and preview_rect.has_point(release_position)
	)


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

	if not hay_mapas:
		lbl_nombre.text = "No hay mapas disponibles"
		lbl_texto.text = ""
		preview.texture = null
		preview.visible = false
		sello.visible = false
		indicadores.text = ""
		return

	var mapa_path := mapas[indice_actual]
	var file_name := mapa_path.get_file()
	var nombre := file_name.get_basename().replace("_", " ")

	lbl_nombre.text = nombre
	indicadores.text = "%d / %d" % [indice_actual + 1, mapas.size()]

	_load_map_info(mapa_path)


func _load_map_info(mapa_path: String) -> void:
	preview.texture = null
	preview.visible = false
	lbl_texto.text = ""
	sello.visible = false

	var packed_scene := ResourceLoader.load(mapa_path) as PackedScene
	if packed_scene == null:
		return

	var instance := packed_scene.instantiate()
	var completado := _is_map_completed(mapa_path)

	var texto_node: Node = null

	if completado:
		texto_node = instance.get_node_or_null("final")
	else:
		texto_node = instance.get_node_or_null("descripcion")

	if texto_node is Label:
		lbl_texto.text = (texto_node as Label).text

	sello.visible = completado

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


func _is_map_completed(mapa_path: String) -> bool:
	var map_id := mapa_path.get_file().get_basename().to_lower()

	if map_id.is_empty():
		return false

	var config := ConfigFile.new()

	if config.load(SETTINGS_FILE) != OK:
		return false

	var saved_inventory = config.get_value(
		DialogueManager.MAP_INVENTORIES_SECTION,
		map_id,
		PackedStringArray()
	)

	if saved_inventory is Array or saved_inventory is PackedStringArray:
		for item in saved_inventory:
			if (
				str(item).strip_edges().to_lower()
				== DialogueManager.MAP_COMPLETED_ITEM
			):
				return true

	return false


func _previous() -> void:
	_change_map_with_transition(-1)


func _next() -> void:
	_change_map_with_transition(1)


func _change_map_with_transition(step: int) -> void:
	if _transitioning or mapas.is_empty() or step == 0:
		return

	_transitioning = true

	var direction := 1 if step > 0 else -1
	var bounds := _transition_content_bounds()
	var host := _create_transition_host(bounds)
	var outgoing := _snapshot_transition_content(
		host,
		bounds
	)

	indice_actual = posmod(
		indice_actual + direction,
		mapas.size()
	)
	_refresh()

	# Texto y TextureRect pueden provocar un nuevo layout del Container.
	# Esperamos un frame antes de copiar la tarjeta que entra.
	await get_tree().process_frame

	if not is_instance_valid(host):
		_transitioning = false
		return

	var incoming := _snapshot_transition_content(
		host,
		bounds
	)

	_set_transition_content_visible(false)

	var travel := maxf(host.size.x * 1.12, 1.0)

	outgoing.position = Vector2.ZERO
	incoming.position = Vector2(
		float(direction) * travel,
		0.0
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)

	tween.tween_property(
		outgoing,
		"position",
		Vector2(-float(direction) * travel, 0.0),
		MAP_TRANSITION_TIME
	)

	tween.tween_property(
		incoming,
		"position",
		Vector2.ZERO,
		MAP_TRANSITION_TIME
	)

	await tween.finished

	if is_instance_valid(host):
		host.queue_free()

	_set_transition_content_visible(true)
	_transitioning = false


func _transition_sources() -> Array[Control]:
	return [
		lbl_nombre,
		preview,
		lbl_texto,
		indicadores
	]


func _transition_content_bounds() -> Rect2:
	var sources := _transition_sources()
	var bounds := sources[0].get_global_rect()

	for index in range(1, sources.size()):
		bounds = bounds.merge(
			sources[index].get_global_rect()
		)

	return bounds


func _create_transition_host(bounds: Rect2) -> Control:
	var host := Control.new()
	host.name = "MapTransition"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.clip_contents = true
	add_child(host)

	var root_rect := get_global_rect()
	host.position = bounds.position - root_rect.position
	host.size = bounds.size

	return host


func _snapshot_transition_content(
	host: Control,
	bounds: Rect2
) -> Control:
	var group := Control.new()
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.position = Vector2.ZERO
	group.size = host.size
	host.add_child(group)

	for source in _transition_sources():
		var copy := source.duplicate() as Control

		if copy == null:
			continue

		group.add_child(copy)

		copy.anchor_left = 0.0
		copy.anchor_top = 0.0
		copy.anchor_right = 0.0
		copy.anchor_bottom = 0.0
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var rect := source.get_global_rect()
		copy.position = rect.position - bounds.position
		copy.size = rect.size

	return group


func _set_transition_content_visible(value: bool) -> void:
	lbl_nombre.visible = value
	lbl_texto.visible = value
	indicadores.visible = value

	if value:
		preview.visible = preview.texture != null
	else:
		preview.visible = false


func _on_btn_anterior_pressed() -> void:
	_previous()


func _on_btn_siguiente_pressed() -> void:
	_next()


func _play_current_map() -> void:
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
