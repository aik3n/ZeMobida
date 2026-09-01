extends Control


const CREDITOS_DATA := preload(
	"res://scripts/creditos_data.gd"
)


@onready var listado: VBoxContainer = $Panel/Scroll/Listado
@onready var boton_cerrar: Button = $Panel/Cerrar


func _ready() -> void:
	visible = false

	boton_cerrar.pressed.connect(
		cerrar
	)

	_construir_listado()


func abrir() -> void:
	visible = true


func cerrar() -> void:
	visible = false


func _construir_listado() -> void:
	for child in listado.get_children():
		child.queue_free()

	for credito in CREDITOS_DATA.CREDITOS:
		_agregar_credito(
			credito
		)


func _agregar_credito(
	credito: Dictionary
) -> void:
	var nombre: String = str(
		credito.get(
			"nombre",
			""
		)
	).strip_edges()

	var descripcion: String = str(
		credito.get(
			"descripcion",
			""
		)
	).strip_edges()

	var url: String = str(
		credito.get(
			"url",
			""
		)
	).strip_edges()

	if nombre.is_empty():
		return

	if not url.is_empty():
		var enlace := LinkButton.new()

		enlace.text = nombre
		enlace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		enlace.add_theme_font_size_override(
			"font_size",
			34
		)
		enlace.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND
		)

		enlace.pressed.connect(
			_abrir_enlace.bind(
				url
			)
		)

		listado.add_child(
			enlace
		)
	else:
		var titulo := Label.new()

		titulo.text = nombre
		titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		titulo.add_theme_font_size_override(
			"font_size",
			34
		)

		listado.add_child(
			titulo
		)

	if not descripcion.is_empty():
		var texto := Label.new()

		texto.text = descripcion
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.add_theme_font_size_override(
			"font_size",
			27
		)
		texto.add_theme_color_override(
			"font_color",
			Color(
				0.72,
				0.8,
				0.86,
				1.0
			)
		)

		listado.add_child(
			texto
		)

	var separador := HSeparator.new()

	separador.custom_minimum_size = Vector2(
		0,
		30
	)

	listado.add_child(
		separador
	)


func _abrir_enlace(
	url: String
) -> void:
	var error := OS.shell_open(
		url
	)

	if error != OK:
		push_warning(
			"No se pudo abrir el enlace: "
			+ url
		)
