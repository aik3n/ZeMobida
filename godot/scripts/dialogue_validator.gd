#archivo: dialogue_validator.gd
class_name DialogueValidator
extends RefCounted

var errors: Array[String] = []


func validate(
	dialogue: Dictionary,
	parser_errors: Array[String] = []
) -> bool:
	errors.clear()

	for error in parser_errors:
		errors.append(error)

	if dialogue.is_empty():
		errors.append("El guion está vacío.")
		return false

	for node_name in dialogue.keys():
		var node: Dictionary = dialogue[node_name]

		_validate_node_structure(node_name, node)
		_validate_conditions(node_name, node, dialogue)
		_validate_jump(node_name, node, dialogue)
		_validate_options(node_name, node, dialogue)

	return errors.is_empty()


func _validate_node_structure(node_name: String, node: Dictionary) -> void:
	if not node.has("text"):
		_error(node_name, "falta 'text'")

	if not node.has("effects"):
		_error(node_name, "faltan 'effects'")

	if not node.has("conditions"):
		_error(node_name, "faltan 'conditions'")

	if not node.has("options"):
		_error(node_name, "faltan 'options'")

	if not node.has("jump"):
		_error(node_name, "falta 'jump'")


func _validate_conditions(
	node_name: String,
	node: Dictionary,
	dialogue: Dictionary
) -> void:
	if not node.has("conditions"):
		return

	for condition in node["conditions"]:
		var next: String = condition["next"]

		if not dialogue.has(next):
			_error(
				node_name,
				"destino de condición inexistente: %s" % next
			)


func _validate_jump(
	node_name: String,
	node: Dictionary,
	dialogue: Dictionary
) -> void:
	if not node.has("jump"):
		return

	var jump: String = node["jump"]

	if jump.is_empty() or jump == "random":
		return

	if not dialogue.has(jump):
		_error(
			node_name,
			"destino de salto inexistente: %s" % jump
		)


func _validate_options(
	node_name: String,
	node: Dictionary,
	dialogue: Dictionary
) -> void:
	if not node.has("options"):
		return

	for option in node["options"]:
		var next: String = option["next"]

		# Por especificación, una opción sin salto es válida.
		if next.is_empty():
			continue

		if not dialogue.has(next):
			_error(
				node_name,
				"destino de opción inexistente: %s" % next
			)


func _error(node_name: String, message: String) -> void:
	errors.append("#%s: %s" % [node_name, message])
