#archivo: dialogue_parser.gd
class_name DialogueParser
extends RefCounted


var errors: Array[String] = []


func parse(text: String) -> Dictionary:
	var dialogue := {}
	var label := ""
	var entry := {}

	errors.clear()

	for raw_line in text.split("\n"):
		var line := _clean_line(raw_line)

		if line.is_empty():
			continue

		if line.begins_with("#"):
			if not label.is_empty():
				dialogue[label] = entry

			label = line.substr(1).strip_edges()

			if label.is_empty():
				errors.append("Etiqueta vacía.")

			elif dialogue.has(label):
				errors.append(
					"Etiqueta duplicada: #%s" % label
				)

			entry = {
				"text": "",
				"conditions": [],
				"options": [],
				"jump": ""
			}

			continue

		if label.is_empty():
			errors.append(
				"Línea fuera de cualquier etiqueta: %s"
				% line
			)
			continue

		if line.begins_with("?"):
			_parse_condition(line, entry)
			continue

		if line.begins_with(">"):
			_parse_jump(line, entry)
			continue

		if line[0].is_valid_int():
			var option := _parse_option(line)

			if option["number"] == 0:
				errors.append(
					"Opción inválida en #%s: %s"
					% [label, line]
				)
			else:
				entry["options"].append(option)

			continue

		_add_text(entry, line)

	if not label.is_empty():
		dialogue[label] = entry

	return dialogue


func _clean_line(raw_line: String) -> String:
	var line := raw_line.strip_edges()

	var comment := line.find("--")

	if comment >= 0:
		line = line.substr(0, comment)

	return line.strip_edges()


func _parse_condition(
	line: String,
	entry: Dictionary
) -> void:

	var parts := line.split(">", false, 1)

	if parts.size() != 2:
		errors.append(
			"Condición sin destino: %s" % line
		)
		return

	var items := _parse_conditions(parts[0])

	if items.is_empty():
		errors.append(
			"Condición sin objetos: %s" % line
		)
		return

	var next := parts[1].strip_edges()

	if next.is_empty():
		errors.append(
			"Condición sin destino: %s" % line
		)
		return

	entry["conditions"].append({
		"items": items,
		"next": next
	})


func _parse_conditions(text: String) -> Array:
	var result := []

	for token in text.split(" ", false):
		if token.begins_with("?"):

			var item := token.substr(1).strip_edges()

			if not item.is_empty():
				result.append(
					item.to_lower()
				)

	return result


func _parse_jump(
	line: String,
	entry: Dictionary
) -> void:

	var jump := line.substr(1).strip_edges()

	if jump.is_empty():
		errors.append(
			"Salto sin destino: %s" % line
		)
		return

	entry["jump"] = jump


func _parse_option(line: String) -> Dictionary:
	var parts := line.split(">", false, 1)

	if parts.size() != 2:
		return {
			"number": 0,
			"text": "",
			"next": "",
			"effects": []
		}

	var left := parts[0].strip_edges()
	var right := parts[1].strip_edges()

	var i := 0

	while i < left.length() and left[i].is_valid_int():
		i += 1

	if i == 0:
		return {
			"number": 0,
			"text": "",
			"next": "",
			"effects": []
		}

	var number := int(
		left.substr(0, i)
	)

	var option_text := left.substr(i).strip_edges()

	if option_text.is_empty():
		errors.append(
			"Opción %d sin texto." % number
		)

	var next := right
	var effects := []

	var bracket := right.find("[")

	if bracket >= 0:

		if not right.ends_with("]"):
			errors.append(
				"Opción %d: acción sin ']'."
				% number
			)

			return {
				"number": number,
				"text": option_text,
				"next": "",
				"effects": []
			}

		next = right.substr(
			0,
			bracket
		).strip_edges()

		var actions := right.substr(
			bracket + 1,
			right.length() - bracket - 2
		)

		effects = _parse_effects(actions)

	if next.is_empty():
		errors.append(
			"Opción %d sin destino." % number
		)

	return {
		"number": number,
		"text": option_text,
		"next": next,
		"effects": effects
	}


func _parse_effects(text: String) -> Array:
	var result := []

	for raw_effect in text.split(","):
		var effect := raw_effect.strip_edges()

		if effect.is_empty():
			errors.append(
				"Acción vacía."
			)
			continue

		if effect.begins_with("xp"):

			var value_text := effect.substr(2).strip_edges()

			if value_text.is_empty():
				errors.append(
					"XP sin valor: %s" % effect
				)
				continue

			if not (
				value_text.begins_with("+")
				or value_text.begins_with("-")
			):
				errors.append(
					"XP necesita + o -: %s"
					% effect
				)
				continue

			var number_text := value_text.substr(1)

			if number_text.is_empty():
				errors.append(
					"XP sin cantidad: %s"
					% effect
				)
				continue

			var cantidad_valida := true

			for character in number_text:
				if not character.is_valid_int():
					cantidad_valida = false
					break

			if not cantidad_valida:
				errors.append(
					"Cantidad de XP inválida: %s"
					% effect
				)
				continue

			result.append({
				"type": "xp",
				"value": int(value_text)
			})

		elif effect.begins_with("+"):

			var item := effect.substr(1).strip_edges()

			if item.is_empty():
				errors.append(
					"Objeto vacío en acción: %s"
					% effect
				)
				continue

			result.append({
				"type": "add_item",
				"item": item.to_lower()
			})

		elif effect.begins_with("-"):

			var item := effect.substr(1).strip_edges()

			if item.is_empty():
				errors.append(
					"Objeto vacío en acción: %s"
					% effect
				)
				continue

			result.append({
				"type": "remove_item",
				"item": item.to_lower()
			})

		else:
			errors.append(
				"Acción desconocida: %s"
				% effect
			)

	return result


func _add_text(
	entry: Dictionary,
	line: String
) -> void:

	if entry["text"].is_empty():
		entry["text"] = line
	else:
		entry["text"] += "\n" + line
