extends Node


var current_node := ""
var dialogue_active := false
var dialogue_ui = null
var dialogue_editor = null
var editor_active := false
var current_dialogue_file := ""
var current_dialogue_level := ""
var current_speaker := ""

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
const PLAYER_KEY_XP := "xp"
const PLAYER_KEY_INVENTORY := "inventory"
const MAX_AUTOMATIC_TRANSITIONS := 100


func _ready() -> void:
	pass


func register_ui(ui):
	dialogue_ui = ui


func get_dialogue_path(file_name: String) -> String:
	return DIALOGUE_FOLDER + file_name


func get_level_dialogue_file_name(
	map_name: String,
	speaker_name: String,
	level: String
) -> String:
	return "%s_%s_%s.txt" % [
		map_name,
		speaker_name,
		level
	]


func resolve_dialogue_path(
	map_name: String,
	speaker_name: String,
	level: String
) -> String:
	var level_file := get_level_dialogue_file_name(
		map_name,
		speaker_name,
		level
	)

	var local_level_path := (
		CUSTOM_DIALOGUE_FOLDER
		+ level_file
	)

	if FileAccess.file_exists(local_level_path):
		return local_level_path

	var official_level_path := (
		DIALOGUE_FOLDER
		+ level_file
	)

	if FileAccess.file_exists(official_level_path):
		return official_level_path

	var generic_file := "%s_%s.txt" % [
		map_name,
		speaker_name
	]

	var official_generic_path := (
		DIALOGUE_FOLDER
		+ generic_file
	)

	if FileAccess.file_exists(official_generic_path):
		return official_generic_path

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
		push_warning(
			"No se encontró Game para abrir el editor."
		)
		return

	var mapa_actual = game.get("mapa_actual")

	if mapa_actual == null:
		push_warning(
			"No se encontró el mapa actual para editar."
		)
		return

	var player = game.get("player_actual")

	if player == null:
		player = game.get_node_or_null("Player")

	if player == null:
		push_warning(
			"No se encontró el Player para editar."
		)
		return

	var scene_path: String = mapa_actual.scene_file_path
	var map_name := scene_path.get_file().get_basename().to_lower()

	var speaker_name := current_speaker

	if (
		map_name.is_empty()
		or speaker_name.is_empty()
		or current_dialogue_level.is_empty()
	):
		return

	var file_name := get_level_dialogue_file_name(
		map_name,
		speaker_name,
		current_dialogue_level
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


func start_dialogue(
	file_path: String,
	speaker_name: String
):
	if dialogue_active or editor_active:
		return

	dialogue_active = true
	current_dialogue_file = file_path
	current_dialogue_level = ""
	current_speaker = speaker_name

	var game = get_tree().current_scene

	if game != null:
		var player = game.get("player_actual")

		if player == null:
			player = game.get_node_or_null("Player")

		if player != null:
			current_dialogue_level = str(player.nivel)

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
	var next_node := node_name
	var automatic_transitions := 0

	while true:
		if not dialogue_data.has(next_node):
			push_warning(
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
					push_warning(
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

				var xp_anterior: int = player.xp

				player.add_xp(
					int(effect["value"])
				)

				if player.xp != xp_anterior:
					state_changed = true

	if state_changed:
		_save_player_status()


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
	_save_player_status()

	return true


func end_dialogue():
	if not dialogue_active:
		return

	dialogue_active = false
	current_node = ""
	current_dialogue_file = ""
	current_dialogue_level = ""
	current_speaker = ""

	dialogue_data.clear()

	if dialogue_ui != null:
		dialogue_ui.hide_dialogue()


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
