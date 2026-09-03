extends SyntaxHighlighter


const COLOR_DEFAULT := Color("#e6edf5")
const COLOR_COMMENT := Color("#7bd88f")
const COLOR_SIGNATURE := Color("#a6accd")
const COLOR_NODE := Color("#c792ea")
const COLOR_OPTION := Color("#82aaff")
const COLOR_CONDITION := Color("#ffcb6b")
const COLOR_JUMP := Color("#89ddff")
const COLOR_EFFECT := Color("#f78c6c")


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var result := {}

	var text_edit := get_text_edit()

	if text_edit == null:
		return result

	var line_text: String = text_edit.get_line(line)

	if line_text.is_empty():
		return result

	var comment_index := line_text.find("'")
	var code_part := line_text

	if comment_index >= 0:
		code_part = line_text.substr(0, comment_index)

	var first_index := _find_first_non_space(code_part)

	if first_index == -1:
		if comment_index >= 0:
			_set_color(result, comment_index, COLOR_COMMENT)
		return result

	match code_part[first_index]:
		"@":
			_set_color(result, first_index, COLOR_SIGNATURE)
		"#":
			_highlight_node_line(result, code_part, first_index)
		"=":
			_highlight_option_line(result, code_part, first_index)
		"?":
			_highlight_condition_line(result, code_part, first_index)
		">":
			_highlight_jump_line(result, code_part, first_index)
		_:
			pass

	_highlight_effects(result, code_part)

	if comment_index >= 0:
		_set_color(result, comment_index, COLOR_COMMENT)

	return result


func _highlight_node_line(
	result: Dictionary,
	_line_text: String,
	start: int
) -> void:
	_set_color(result, start, COLOR_NODE)


func _highlight_option_line(
	result: Dictionary,
	line_text: String,
	start: int
) -> void:
	_set_color(result, start, COLOR_OPTION)

	var jump_index := line_text.find(">", start + 1)

	if jump_index >= 0:
		_set_color(result, jump_index, COLOR_JUMP)


func _highlight_condition_line(
	result: Dictionary,
	line_text: String,
	start: int
) -> void:
	_set_color(result, start, COLOR_CONDITION)

	var jump_index := line_text.find(">", start + 1)

	if jump_index >= 0:
		_set_color(result, jump_index, COLOR_JUMP)


func _highlight_jump_line(
	result: Dictionary,
	_line_text: String,
	start: int
) -> void:
	_set_color(result, start, COLOR_JUMP)


func _highlight_effects(
	result: Dictionary,
	line_text: String
) -> void:
	var search_from := 0

	while true:
		var start := line_text.find("[", search_from)

		if start < 0:
			break

		var finish := line_text.find("]", start + 1)

		if finish < 0:
			_set_color(result, start, COLOR_EFFECT)
			break

		_set_color(result, start, COLOR_EFFECT)
		_set_color(result, finish + 1, COLOR_DEFAULT)

		search_from = finish + 1


func _find_first_non_space(text: String) -> int:
	for i in text.length():
		var c := text[i]

		if c != " " and c != "\t":
			return i

	return -1


func _set_color(
	result: Dictionary,
	column: int,
	color: Color
) -> void:
	if column < 0:
		return

	result[column] = {"color": color}
