extends Node


signal dialogue_sources_changed

var current_node := ""
var dialogue_active := false
var dialogue_ui = null
var dialogue_editor = null
var editor_active := false
var current_dialogue_file := ""
var current_speaker := ""
var current_dialogue_signature := ""

var dialogue_data: Dictionary = {}
var inventory: Array[String] = []

var _parser := DialogueParser.new()
var _validator := DialogueValidator.new()


const DIALOGUE_FOLDER := "user://dialogues/"
const CUSTOM_DIALOGUE_FOLDER := "user://custom_dialogues/"
const DIALOGUE_ERROR_FILE := "user://dialogues/fallo.txt"

const DIALOGUE_EDITOR_SCENE: PackedScene = preload(
	"res://escenas/dialogue_editor.tscn"
)

const DIALOGUE_TEMPLATE := (
	"# INICIO\n"
	+ "Escribe aquí tu diálogo.\n\n"
	+ "= Salir > FINAL\n\n"
	+ "# FINAL\n"
	+ "Adiós.\n"
)

const SETTINGS_FILE := "user://settings.cfg"
const PLAYER_SECTION := "player"
const PLAYER_KEY_INVENTORY := "inventory"
const DIALOGUE_MAP_LEVEL_MARKERS := [
	"_a1",
	"_a2",
	"_b1",
	"_b2",
	"_c1",
	"_c2"
]
const MAX_AUTOMATIC_TRANSITIONS := 100


func _ready() -> void:
	load_inventory()


func register_ui(ui):
	dialogue_ui = ui


func get_dialogue_path(file_name: String) -> String:
	return DIALOGUE_FOLDER + file_name


func get_dialogue_map_name(map_id: String) -> String:
	var normalized := map_id.to_lower()

	for marker in DIALOGUE_MAP_LEVEL_MARKERS:
		var marker_index := normalized.find(marker)

		if marker_index >= 0:
			return normalized.substr(0, marker_index)

	return normalized


func get_dialogue_file_name(
	map_name: String,
	speaker_name: String
) -> String:
	return "%s_%s.txt" % [
		map_name,
		speaker_name
	]


func get_dialogue_assignment_state(
	map_name: String,
	speaker_name: String
) -> String:
	var file_name := get_dialogue_file_name(
		map_name,
		speaker_name
	)

	if FileAccess.file_exists(
		CUSTOM_DIALOGUE_FOLDER + file_name
	):
		return "local"

	if FileAccess.file_exists(
		DIALOGUE_FOLDER + file_name
	):
		return "official"

	# generico.txt es fallback técnico y no se considera
	# un guion asignado específicamente a este PNJ.
	return "none"


func resolve_dialogue_path(
	map_name: String,
	speaker_name: String
) -> String:
	var file_name := get_dialogue_file_name(
		map_name,
		speaker_name
	)

	var local_path := (
		CUSTOM_DIALOGUE_FOLDER
		+ file_name
	)

	if FileAccess.file_exists(local_path):
		return local_path

	var official_path := (
		DIALOGUE_FOLDER
		+ file_name
	)

	if FileAccess.file_exists(official_path):
		return official_path

	if FileAccess.file_exists(
		DIALOGUE_FOLDER + "generico.txt"
	):
		return DIALOGUE_FOLDER + "generico.txt"

	return ""


func open_current_dialogue_editor() -> void:
	if editor_active or not dialogue_active:
		return

	var game = get_tree().current_scene

	if game == null:
		print(
			"No se encontró Game para abrir el editor."
		)
		return

	var mapa_actual = game.get("mapa_actual")

	if mapa_actual == null:
		print(
			"No se encontró el mapa actual para editar."
		)
		return

	var scene_path: String = mapa_actual.scene_file_path
	var map_id := scene_path.get_file().get_basename().to_lower()
	var map_name := get_dialogue_map_name(map_id)
	var speaker_name := current_speaker

	if map_name.is_empty() or speaker_name.is_empty():
		return

	var file_name := get_dialogue_file_name(
		map_name,
		speaker_name
	)

	var initial_text := _get_editable_dialogue_source(
		file_name
	)

	editor_active = true

	# El editor sustituye temporalmente al diálogo.
	# Al cerrar, el jugador vuelve al mapa y puede interactuar
	# otra vez con el PNJ para probar el archivo guardado.
	end_dialogue()

	dialogue_editor = DIALOGUE_EDITOR_SCENE.instantiate()
	game.add_child(dialogue_editor)

	dialogue_editor.tree_exited.connect(
		_on_dialogue_editor_closed,
		CONNECT_ONE_SHOT
	)

	dialogue_editor.setup(
		file_name,
		initial_text
	)


func _get_editable_dialogue_source(
	file_name: String
) -> String:
	var local_path := (
		CUSTOM_DIALOGUE_FOLDER
		+ file_name
	)

	if FileAccess.file_exists(local_path):
		return _read_dialogue_text(local_path)

	var official_path := (
		DIALOGUE_FOLDER
		+ file_name
	)

	if FileAccess.file_exists(official_path):
		return _read_dialogue_text(official_path)

	return DIALOGUE_TEMPLATE


func _read_dialogue_text(file_path: String) -> String:
	var file := FileAccess.open(
		file_path,
		FileAccess.READ
	)

	if file == null:
		return DIALOGUE_TEMPLATE

	var content := file.get_as_text()
	file.close()

	return content


func _on_dialogue_editor_closed() -> void:
	editor_active = false
	dialogue_editor = null
	dialogue_sources_changed.emit()


func start_dialogue(
	file_path: String,
	speaker_name: String
):
	if dialogue_active or editor_active:
		return

	dialogue_active = true
	current_dialogue_file = file_path
	current_speaker = speaker_name

	load_dialogue(file_path)


func load_dialogue(file_path: String):
	var file := FileAccess.open(
		file_path,
		FileAccess.READ
	)

	if file == null:
		print(
			"No se pudo abrir el diálogo: " + file_path
		)

		_load_error_dialogue()
		return

	dialogue_data = _parser.parse(
		file.get_as_text()
	)
	current_dialogue_signature = _parser.signature

	if not _validator.validate(
		dialogue_data,
		_parser.errors
	):
		print(
			"El guion contiene errores: "
			+ file_path
		)

		for error in _validator.errors:
			print(
				"  " + error
			)

		_load_error_dialogue()
		return

	show_node(
		dialogue_data.keys()[0]
	)


func _load_error_dialogue() -> void:
	var file := FileAccess.open(
		DIALOGUE_ERROR_FILE,
		FileAccess.READ
	)

	if file == null:
		print(
			"No existe el archivo: "
			+ DIALOGUE_ERROR_FILE
		)

		end_dialogue()
		return

	current_dialogue_file = DIALOGUE_ERROR_FILE

	dialogue_data = _parser.parse(
		file.get_as_text()
	)
	current_dialogue_signature = _parser.signature

	if not _validator.validate(
		dialogue_data,
		_parser.errors
	):
		print(
			"fallo.txt también contiene errores."
		)

		for error in _validator.errors:
			print(
				"  " + error
			)

		end_dialogue()
		return

	show_node(
		dialogue_data.keys()[0]
	)


func show_node(node_name: String):
	var next_node := node_name
	var automatic_transitions := 0

	while true:
		if not dialogue_data.has(next_node):
			print(
				"Nodo inexistente: " + next_node
			)

			end_dialogue()
			return

		current_node = next_node

		var node: Dictionary = dialogue_data[current_node]
		var automatic_next := ""

		for condition in node["conditions"]:
			if _has_all_items(condition["items"]):
				automatic_next = condition["next"]
				break

		if not automatic_next.is_empty():
			automatic_transitions += 1

			if automatic_transitions > MAX_AUTOMATIC_TRANSITIONS:
				print(
					"[DialogueManager] Diálogo detenido por superar ",
					MAX_AUTOMATIC_TRANSITIONS,
					" transiciones automáticas consecutivas. Archivo: ",
					current_dialogue_file,
					" Nodo: ",
					current_node
				)

				if dialogue_ui != null:
					dialogue_ui.show_dialogue()
					dialogue_ui.show_text(
						current_speaker,
						""
					)
					dialogue_ui.show_options([])

				return

			next_node = automatic_next
			continue

		var jump: String = node["jump"]

		if not jump.is_empty():
			if jump == "random":
				automatic_next = _get_random_node()

				if automatic_next.is_empty():
					print(
						"No hay nodos disponibles para RANDOM."
					)

					end_dialogue()
					return
			else:
				automatic_next = jump

			automatic_transitions += 1

			if automatic_transitions > MAX_AUTOMATIC_TRANSITIONS:
				print(
					"[DialogueManager] Diálogo detenido por superar ",
					MAX_AUTOMATIC_TRANSITIONS,
					" transiciones automáticas consecutivas. Archivo: ",
					current_dialogue_file,
					" Nodo: ",
					current_node
				)

				if dialogue_ui != null:
					dialogue_ui.show_dialogue()
					dialogue_ui.show_text(
						current_speaker,
						""
					)
					dialogue_ui.show_options([])

				return

			next_node = automatic_next
			continue

		if dialogue_ui != null:
			_apply_effects(
				node["effects"]
			)

			dialogue_ui.show_dialogue()

			dialogue_ui.show_text(
				current_speaker,
				node["text"]
			)

			dialogue_ui.show_options(
				node["options"]
			)

		return


func select_option(option: Dictionary):
	if not dialogue_active:
		return

	if not dialogue_data.has(current_node):
		return

	var node: Dictionary = dialogue_data[current_node]

	for candidate in node["options"]:
		if candidate == option:
			_apply_effects(
				candidate["effects"]
			)

			var next: String = candidate["next"]

			if next.is_empty():
				return

			show_node(next)
			return


func _get_random_node() -> String:
	var available: Array[String] = []

	for node_name in dialogue_data.keys():
		if node_name.to_lower() == current_node.to_lower():
			continue

		available.append(node_name)

	if available.is_empty():
		return ""

	return available.pick_random()


func _apply_effects(effects: Array):
	var state_changed := false

	for effect in effects:
		match effect["type"]:
			"add_item":
				if add_item(
					effect["item"]
				):
					state_changed = true

			"remove_item":
				if remove_item(
					effect["item"]
				):
					state_changed = true

	if state_changed:
		_save_inventory()


func _mostrar_feedback_objeto(
	texto: String,
	positivo: bool
) -> void:
	var game = get_tree().current_scene

	if game == null:
		return

	var player = game.get("player_actual")

	if player == null:
		return

	if player.has_method("mostrar_feedback"):
		player.mostrar_feedback(
			texto,
			positivo
		)


func _has_all_items(items: Array) -> bool:
	for item in items:
		if not inventory.has(item):
			return false

	return true


func has_item(item: String) -> bool:
	return inventory.has(
		item.to_lower()
	)


func add_item(item: String) -> bool:
	item = item.to_lower()

	if inventory.has(item):
		return false

	inventory.append(item)

	print(
		"Inventario:",
		inventory
	)

	_mostrar_feedback_objeto(
		"+ " + item.capitalize(),
		true
	)

	return true


func remove_item(item: String) -> bool:
	item = item.to_lower()

	if not inventory.has(item):
		return false

	inventory.erase(item)

	_mostrar_feedback_objeto(
		"- " + item.capitalize(),
		false
	)

	return true


func clear_inventory() -> bool:
	if inventory.is_empty():
		return false

	inventory.clear()
	_save_inventory()

	return true


func end_dialogue():
	if not dialogue_active:
		return

	dialogue_active = false
	current_node = ""
	current_dialogue_file = ""
	current_speaker = ""
	current_dialogue_signature = ""

	dialogue_data.clear()

	if dialogue_ui != null:
		dialogue_ui.hide_dialogue()


func load_inventory() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_FILE)

	inventory.clear()

	if error == ERR_FILE_NOT_FOUND:
		return

	if error != OK:
		print(
			"No se pudo cargar el inventario."
		)
		return

	var saved_inventory = config.get_value(
		PLAYER_SECTION,
		PLAYER_KEY_INVENTORY,
		PackedStringArray()
	)

	if saved_inventory is Array or saved_inventory is PackedStringArray:
		for item in saved_inventory:
			var clean_item: String = str(item).strip_edges().to_lower()

			if clean_item.is_empty():
				continue

			if not inventory.has(clean_item):
				inventory.append(clean_item)

	print(
		"Inventario cargado:",
		inventory
	)


func _save_inventory() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(SETTINGS_FILE)

	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		print(
			"No se pudo cargar la configuración para guardar el inventario."
		)
		return

	config.set_value(
		PLAYER_SECTION,
		PLAYER_KEY_INVENTORY,
		PackedStringArray(inventory)
	)

	var error := config.save(SETTINGS_FILE)

	if error != OK:
		print(
			"No se pudo guardar el inventario."
		)
		return

	print(
		"Inventario guardado:",
		inventory
	)
