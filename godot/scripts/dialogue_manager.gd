extends Node


var current_node := ""
var dialogue_active := false
var dialogue_ui = null
var current_dialogue_file := ""
var current_speaker := ""

var dialogue_data: Dictionary = {}
var inventory: Array[String] = []

var _parser := DialogueParser.new()
var _validator := DialogueValidator.new()


const DIALOGUE_FOLDER := "user://dialogues/"
const DIALOGUE_ERROR_FILE := "user://dialogues/fallo.txt"

const SETTINGS_FILE := "user://settings.cfg"
const PLAYER_SECTION := "player"
const PLAYER_KEY_XP := "xp"
const PLAYER_KEY_INVENTORY := "inventory"


func _ready() -> void:
	pass


func register_ui(ui):
	dialogue_ui = ui


func get_dialogue_path(file_name: String) -> String:
	return DIALOGUE_FOLDER + file_name


func start_dialogue(
	file_path: String,
	speaker_name: String
):
	if dialogue_active:
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
		push_warning(
			"No se pudo abrir el diálogo: " + file_path
		)

		_load_error_dialogue()
		return

	dialogue_data = _parser.parse(
		file.get_as_text()
	)

	if not _validator.validate(
		dialogue_data,
		_parser.errors
	):
		push_warning(
			"El guion contiene errores: "
			+ file_path
		)

		for error in _validator.errors:
			push_warning(
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
		push_warning(
			"No existe el archivo: "
			+ DIALOGUE_ERROR_FILE
		)

		end_dialogue()
		return

	current_dialogue_file = DIALOGUE_ERROR_FILE

	dialogue_data = _parser.parse(
		file.get_as_text()
	)

	if not _validator.validate(
		dialogue_data,
		_parser.errors
	):
		push_warning(
			"fallo.txt también contiene errores."
		)

		for error in _validator.errors:
			push_warning(
				"  " + error
			)

		end_dialogue()
		return

	show_node(
		dialogue_data.keys()[0]
	)


func show_node(node_name: String):
	if not dialogue_data.has(node_name):
		push_warning(
			"Nodo inexistente: " + node_name
		)

		end_dialogue()
		return

	current_node = node_name

	var node: Dictionary = dialogue_data[node_name]

	for condition in node["conditions"]:
		if _has_all_items(condition["items"]):
			show_node(
				condition["next"]
			)

			return

	var jump: String = node["jump"]

	if not jump.is_empty():
		if jump == "random":
			var random_node := _get_random_node()

			if random_node.is_empty():
				push_warning(
					"No hay nodos disponibles para RANDOM."
				)

				end_dialogue()
				return

			show_node(random_node)
			return

		show_node(jump)
		return

	if dialogue_ui != null:
		dialogue_ui.show_dialogue()

		dialogue_ui.show_text(
			current_speaker,
			node["text"]
		)

		dialogue_ui.show_options(
			node["options"]
		)


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
	for effect in effects:
		match effect["type"]:
			"add_item":
				add_item(
					effect["item"]
				)

			"remove_item":
				remove_item(
					effect["item"]
				)

			"xp":
				var game = get_tree().current_scene

				if game == null:
					push_warning(
						"No se encontró Game para aplicar XP."
					)

					continue

				var player = game.get("player_actual")

				if player == null:
					push_warning(
						"No se encontró el Player para aplicar XP."
					)

					continue

				player.add_xp(
					int(effect["value"])
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


func add_item(item: String) -> void:
	item = item.to_lower()

	if not inventory.has(item):
		inventory.append(item)

		print(
			"Inventario:",
			inventory
		)


func remove_item(item: String) -> void:
	inventory.erase(
		item.to_lower()
	)


func end_dialogue():
	if not dialogue_active:
		return

	dialogue_active = false
	current_node = ""
	current_dialogue_file = ""
	current_speaker = ""

	dialogue_data.clear()

	if dialogue_ui != null:
		dialogue_ui.hide_dialogue()

	_save_player_status()


func load_player_status() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_FILE)

	if error == ERR_FILE_NOT_FOUND:
		print(
			"No existe estado guardado. "
			+ "Se utilizarán los valores iniciales."
		)
		return

	if error != OK:
		push_warning(
			"No se pudo cargar el estado del jugador."
		)
		return


	var game = get_tree().current_scene

	if game == null:
		push_warning(
			"No se encontró Game para cargar el estado."
		)
		return

	var player = game.get("player_actual")

	if player == null:
		push_warning(
			"No se encontró el Player para cargar el estado."
		)
		return

	if config.has_section_key(PLAYER_SECTION, PLAYER_KEY_XP):
		var saved_xp: int = int(
			config.get_value(
				PLAYER_SECTION,
				PLAYER_KEY_XP,
				0
			)
		)

		player.xp = clamp(
			saved_xp,
			0,
			player._xp_maximo()
		)

		player._actualizar_nivel()
		player.xp_changed.emit()

	inventory.clear()

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
		"Estado cargado. XP:",
		player.xp,
		" Inventario:",
		inventory
	)


func _save_player_status() -> void:
	var game = get_tree().current_scene

	if game == null:
		push_warning(
			"No se encontró Game para guardar el estado."
		)
		return

	var player = game.get("player_actual")

	if player == null:
		push_warning(
			"No se encontró el Player para guardar el estado."
		)
		return

	var config := ConfigFile.new()
	var load_error := config.load(SETTINGS_FILE)

	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_error(
			"No se pudo cargar la configuración para guardar el estado."
		)
		return

	config.set_value(
		PLAYER_SECTION,
		PLAYER_KEY_XP,
		player.xp
	)

	config.set_value(
		PLAYER_SECTION,
		PLAYER_KEY_INVENTORY,
		PackedStringArray(inventory)
	)

	var error := config.save(SETTINGS_FILE)

	if error != OK:
		push_error(
			"No se pudo guardar el estado del jugador."
		)
		return

	print(
		"Estado guardado. XP:",
		player.xp,
		" Inventario:",
		inventory
	)
