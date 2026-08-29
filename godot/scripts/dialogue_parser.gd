#archivo: dialogue_parser.gd
class_name DialogueParser
extends RefCounted

var errors: Array[String] = []


func parse(text: String) -> Dictionary:
	var dialogue: Dictionary = {}
	var label := ""
	var entry: Dictionary = {}

	errors.clear()

	for raw_line in text.split("\n"):
		var line := _clean_line(raw_line)

		if line.is_empty():
			continue

		var marker := line[0]

		if marker == "#":
			if not label.is_empty():
				dialogue[label] = entry

			label = _normalize_label(line.substr(1))

			if label.is_empty():
				errors.append("Etiqueta vacía.")
			elif dialogue.has(label):
				errors.append("Etiqueta duplicada: #%s" % label)

			entry = {
				"text": "",
				"conditions": [],
				"options": [],
				"jump": ""
			}
			continue

		if label.is_empty():
			errors.append("Línea fuera de cualquier etiqueta: %s" % line)
			continue

		match marker:
			"?":
				_parse_condition(line, entry)
			">":
				_parse_jump(line, entry)
			"=":
				entry["options"].append(_parse_option(line))
			"[":
				errors.append("Efectos sin opción en #%s: %s" % [label, line])
			_:
				_add_text(entry, line)

	if not label.is_empty():
		dialogue[label] = entry

	return dialogue


func _clean_line(raw_line: String) -> String:
	var line := raw_line.strip_edges()
	var comment := line.find("'")

	if comment >= 0:
		line = line.substr(0, comment)

	return line.strip_edges()


func _normalize_label(value: String) -> String:
	return value.strip_edges().to_lower()


func _parse_condition(line: String, entry: Dictionary) -> void:
	var parts := line.split(">", false, 1)

	# Por especificación, una condición sin salto se ignora.
	if parts.size() != 2:
		return

	var items := _parse_conditions(parts[0])
	var next := _normalize_label(parts[1])

	if items.is_empty() or next.is_empty():
		return

	entry["conditions"].append({
		"items": items,
		"next": next
	})


func _parse_conditions(text: String) -> Array:
	var result: Array = []

	for token in text.strip_edges().split(" ", false):
		if token.begins_with("?"):
			var item := token.substr(1).strip_edges()

			if not item.is_empty():
				result.append(item.to_lower())

	return result


func _parse_jump(line: String, entry: Dictionary) -> void:
	var jump := _normalize_label(line.substr(1))

	if jump.is_empty():
		errors.append("Salto sin destino: %s" % line)
		return

	entry["jump"] = jump


func _parse_option(line: String) -> Dictionary:
	var content := line.substr(1).strip_edges()
	var next := ""
	var effects: Array = []

	var bracket := content.find("[")

	if bracket >= 0:
		if not content.ends_with("]"):
			errors.append("Opción: efecto sin ']': %s" % line)
		else:
			var effect_text := content.substr(
				bracket + 1,
				content.length() - bracket - 2
			)

			effects = _parse_effects(effect_text)
			content = content.substr(0, bracket).strip_edges()

	var option_text := content
	var parts := content.split(">", false, 1)

	if parts.size() == 2:
		option_text = parts[0].strip_edges()
		next = _normalize_label(parts[1])
	else:
		option_text = content.strip_edges()

	if option_text.is_empty():
		errors.append("Opción sin texto: %s" % line)

	return {
		"text": option_text,
		"next": next,
		"effects": effects
	}


func _parse_effects(text: String) -> Array:
	var result: Array = []

	for raw_effect in text.split(","):
		var effect := raw_effect.strip_edges()

		if effect.is_empty():
			errors.append("Efecto vacío.")
			continue

		if effect.to_lower().begins_with("xp"):
			var value_text := effect.substr(2).strip_edges()

			if value_text.is_empty():
				errors.append("XP sin valor: %s" % effect)
				continue

			if not (
				value_text.begins_with("+")
				or value_text.begins_with("-")
			):
				errors.append("XP necesita + o -: %s" % effect)
				continue

			var number_text := value_text.substr(1)

			if number_text.is_empty() or not number_text.is_valid_int():
				errors.append("Cantidad de XP inválida: %s" % effect)
				continue

			result.append({
				"type": "xp",
				"value": int(value_text)
			})

		elif effect.begins_with("+"):
			var item := effect.substr(1).strip_edges()

			if item.is_empty():
				errors.append("Objeto vacío en efecto: %s" % effect)
				continue

			result.append({
				"type": "add_item",
				"item": item.to_lower()
			})

		elif effect.begins_with("-"):
			var item := effect.substr(1).strip_edges()

			if item.is_empty():
				errors.append("Objeto vacío en efecto: %s" % effect)
				continue

			result.append({
				"type": "remove_item",
				"item": item.to_lower()
			})

		else:
			errors.append("Efecto desconocido: %s" % effect)

	return result


func _add_text(entry: Dictionary, line: String) -> void:
	if entry["text"].is_empty():
		entry["text"] = line
	else:
		entry["text"] += "\n" + line
