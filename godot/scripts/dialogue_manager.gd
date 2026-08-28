# archivo: dialogue_manager.gd
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

const SAVE_FOLDER := "user://save/"
const SAVE_FILE := "user://save/status.txt"


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
		if jump == "RANDOM":
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

			show_node(
				candidate["next"]
			)

			return


func _get_random_node() -> String:
	var available: Array[String] = []

	for node_name in dialogue_data.keys():
		if node_name == current_node:
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
				var mapa_actual = game.get("mapa_actual")

				if mapa_actual == null:
					push_warning(
						"No se encontró el mapa actual para aplicar XP."
					)

					continue

				var player = mapa_actual.get_node_or_null(
					"player"
				)

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
	var file := FileAccess.open(
		SAVE_FILE,
		FileAccess.READ
	)

	if file == null:
		print(
			"No existe partida guardada. "
			+ "Se utilizarán los valores iniciales."
		)

		return

	var status: Dictionary = {}

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		if line.is_empty():
			continue

		if line.begins_with("#"):
			continue

		var separator: int = line.find("=")

		if separator == -1:
			continue

		var key: String = line.substr(
			0,
			separator
		).strip_edges()

		var value: String = line.substr(
			separator + 1
		).strip_edges()

		status[key] = value

	file.close()

	var game = get_tree().current_scene
	var mapa_actual = game.get("mapa_actual")

	if mapa_actual == null:
		push_warning(
			"No se encontró el mapa actual para cargar el estado."
		)

		return

	var player = mapa_actual.get_node_or_null(
		"player"
	)

	if player == null:
		push_warning(
			"No se encontró el Player para cargar el estado."
		)

		return

	if status.has("xp"):
		var saved_xp: int = int(status["xp"])

		player.xp = clamp(
			saved_xp,
			0,
			player._xp_maximo()
		)

		player._actualizar_nivel()
		player.xp_changed.emit()

	inventory.clear()

	if status.has("inventory"):
		var saved_items: PackedStringArray = str(
			status["inventory"]
		).split(
			",",
			false
		)

		for item in saved_items:
			var clean_item: String = item.strip_edges().to_lower()

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
	var mapa_actual = game.get("mapa_actual")

	if mapa_actual == null:
		push_warning(
			"No se encontró el mapa actual para guardar el estado."
		)

		return

	var player = mapa_actual.get_node_or_null(
		"player"
	)

	if player == null:
		push_warning(
			"No se encontró el Player para guardar el estado."
		)

		return

	var dir := DirAccess.open(
		"user://"
	)

	if dir == null:
		push_error(
			"No se puede acceder a user://"
		)

		return

	if not dir.dir_exists("save"):
		var error := dir.make_dir("save")

		if error != OK:
			push_error(
				"No se pudo crear la carpeta de guardado."
			)

			return

	var file := FileAccess.open(
		SAVE_FILE,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"No se pudo abrir el archivo de guardado."
		)

		return

	file.store_line(
		"# Estado de la partida"
	)

	file.store_line(
		"xp=" + str(player.xp)
	)

	file.store_line(
		"inventory=" + ",".join(inventory)
	)

	file.close()

	print(
		"Estado guardado. XP:",
		player.xp,
		" Inventario:",
		inventory
	)
