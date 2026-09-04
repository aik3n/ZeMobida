#archivo: dialogue_parser.gd
class_name DialogueParser
extends RefCounted

var errors: Array[String] = []
var signature := ""


const END_OF_ADVENTURE_ITEM := "_eoa_"
const RESERVED_RANDOM_LABEL := "random"


func parse(text: String) -> Dictionary:
	var dialogue: Dictionary = {}
	var label := ""
	var entry: Dictionary = {}

	errors.clear()
	signature = ""

	for raw_line in text.split("\n"):
		var line := _clean_line(raw_line)

		if line.is_empty():
			continue

		var marker := line[0]

		# Firma pública del archivo. Se conserva para la UI,
		# pero no forma parte de ningún nodo del diálogo.
		if marker == "@":
			if line.substr(1).strip_edges().is_empty():
				errors.append("Firma vacía.")
			else:
				signature = line
			continue

		if marker == "#":
			if not label.is_empty():
				dialogue[label] = entry

			var raw_label := line.substr(1).strip_edges()
			label = _normalize_label(raw_label)

			if label.is_empty():
				errors.append("Etiqueta vacía.")
			elif not _is_identifier(raw_label):
				errors.append(
					"Etiqueta inválida: usa un identificador sin espacios: #%s"
					% raw_label
				)
			elif label == RESERVED_RANDOM_LABEL:
				errors.append("Etiqueta reservada: #RANDOM.")
			elif dialogue.has(label):
				errors.append("Etiqueta duplicada: #%s" % label)

			entry = {
				"text": "",
				"effects": [],
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
				errors.append(
					"Efectos sin texto u opción en #%s: %s"
					% [label, line]
				)
			_:
				_parse_text_line(entry, line)

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


func _is_identifier(value: String) -> bool:
	var clean := value.strip_edges()

	return (
		not clean.is_empty()
		and not clean.contains(" ")
		and not clean.contains("\t")
	)


func _parse_condition(line: String, entry: Dictionary) -> void:
	var parts := line.split(">", false, 1)

	if parts.size() != 2:
		errors.append("Condición sin destino: %s" % line)
		return

	var items := _parse_conditions(parts[0])
	var raw_next := parts[1].strip_edges()
	var next := _normalize_label(raw_next)

	if items.is_empty() or next.is_empty():
		return

	if not _is_identifier(raw_next):
		errors.append(
			"Destino de condición inválido: %s" % raw_next
		)
		return

	if next == RESERVED_RANDOM_LABEL:
		errors.append(
			"RANDOM sólo es válido en un salto directo."
		)
		return

	entry["conditions"].append({
		"items": items,
		"next": next
	})


func _parse_conditions(text: String) -> Array:
	var result: Array = []
	var normalized := text.replace("\t", " ")

	for raw_token in normalized.strip_edges().split(" ", false):
		var token := str(raw_token)

		if not token.begins_with("?") or token.count("?") != 1:
			errors.append("Condición inválida: %s" % token)
			continue

		var item := token.substr(1).strip_edges()

		if item.is_empty():
			errors.append("Objeto vacío en condición: %s" % token)
			continue

		if not _is_identifier(item):
			errors.append(
				"Objeto inválido en condición: %s" % item
			)
			continue

		result.append(item.to_lower())

	return result


func _parse_jump(line: String, entry: Dictionary) -> void:
	var raw_jump := line.substr(1).strip_edges()
	var jump := _normalize_label(raw_jump)

	if jump.is_empty():
		errors.append("Salto sin destino: %s" % line)
		return

	if not _is_identifier(raw_jump):
		errors.append("Destino de salto inválido: %s" % raw_jump)
		return

	if not entry["jump"].is_empty():
		errors.append("Más de un salto directo en el mismo nodo.")
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

		var raw_next := parts[1].strip_edges()
		next = _normalize_label(raw_next)

		if not _is_identifier(raw_next):
			errors.append(
				"Opción: destino inválido: %s" % raw_next
			)
		elif next == RESERVED_RANDOM_LABEL:
			errors.append(
				"RANDOM sólo es válido en un salto directo."
			)
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

		if not (
			effect.begins_with("+")
			or effect.begins_with("-")
		):
			errors.append("Efecto desconocido: %s" % effect)
			continue

		var item := effect.substr(1).strip_edges()

		if item.is_empty():
			errors.append("Objeto vacío en efecto: %s" % effect)
			continue

		if not _is_identifier(item):
			errors.append(
				"Objeto inválido en efecto: %s" % item
			)
			continue

		var normalized_item := item.to_lower()

		if (
			effect.begins_with("-")
			and normalized_item == END_OF_ADVENTURE_ITEM
		):
			errors.append(
				"_EOA_ sólo puede añadirse con '+'."
			)
			continue

		result.append({
			"type": (
				"add_item"
				if effect.begins_with("+")
				else "remove_item"
			),
			"item": normalized_item
		})

	return result


func _parse_text_line(entry: Dictionary, line: String) -> void:
	var text := line
	var bracket := line.rfind("[")

	if bracket >= 0:
		if not line.ends_with("]"):
			errors.append("Texto: efecto sin ']': %s" % line)
			return

		var effect_text := line.substr(
			bracket + 1,
			line.length() - bracket - 2
		)

		var effects := _parse_effects(effect_text)
		entry["effects"].append_array(effects)
		text = line.substr(0, bracket).strip_edges()

	if text.is_empty():
		errors.append("Línea de texto sin texto: %s" % line)
		return

	_add_text(entry, text)


func _add_text(entry: Dictionary, line: String) -> void:
	if entry["text"].is_empty():
		entry["text"] = line
	else:
		entry["text"] += "\n" + line
