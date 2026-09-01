extends Control

signal jugar(mapa_path: String)

@onready var panel_carga_escenas: Panel = $PanelCargaEscenas
@onready var chk_actualizar: Button = $PanelCargaEscenas/chk_ActualizarGuiones
@onready var lbl_estado_guiones: Label = $PanelCargaEscenas/lbl_EstadoGuiones
@onready var boton_creditos: Button = $BotonCreditos
@onready var creditos: Control = $Creditos


func _ready() -> void:

	panel_carga_escenas.process_mode = Node.PROCESS_MODE_DISABLED

	chk_actualizar.button_pressed = DialogueUpdater.actualizar_guiones_al_iniciar
	_actualizar_texto_check()

	chk_actualizar.toggled.connect(
		_on_actualizar_guiones_toggled
	)

	DialogueUpdater.guiones_disponibles_changed.connect(
		_on_guiones_disponibles_changed
	)

	DialogueUpdater.sincronizacion_completada.connect(
		_on_sincronizacion_completada
	)

	$PanelCargaEscenas/CarruselMapas.jugar.connect(
		_on_carrusel_jugar
	)

	boton_creditos.pressed.connect(
		_abrir_creditos
	)

	_actualizar_estado_inicial()


func _actualizar_estado_inicial() -> void:

	if DialogueUpdater.sincronizando:
		lbl_estado_guiones.text = "Comprobando guiones..."
		return

	if DialogueUpdater.guiones_disponibles:
		_habilitar_carga_escenas()
		lbl_estado_guiones.text = "Guiones disponibles."
	else:
		lbl_estado_guiones.text = "No hay guiones disponibles."


func _on_actualizar_guiones_toggled(enabled: bool) -> void:
	DialogueUpdater.set_actualizar_guiones_al_iniciar(enabled)
	_actualizar_texto_check()


func _actualizar_texto_check() -> void:

	if chk_actualizar.button_pressed:
		chk_actualizar.text = "Actualizar guiones al iniciar  ☑"
	else:
		chk_actualizar.text = "Actualizar guiones al iniciar  ☐"


func _on_guiones_disponibles_changed() -> void:

	if DialogueUpdater.guiones_disponibles:
		_habilitar_carga_escenas()
		lbl_estado_guiones.text = "Guiones disponibles."
	else:
		panel_carga_escenas.process_mode = Node.PROCESS_MODE_DISABLED
		lbl_estado_guiones.text = "No hay guiones disponibles."


func _on_sincronizacion_completada() -> void:

	if DialogueUpdater.guiones_disponibles:
		lbl_estado_guiones.text = "Guiones disponibles."
	else:
		lbl_estado_guiones.text = "No hay guiones disponibles."


func _habilitar_carga_escenas() -> void:

	panel_carga_escenas.process_mode = Node.PROCESS_MODE_INHERIT


func _on_carrusel_jugar(mapa_path: String) -> void:
	jugar.emit(mapa_path)


func _abrir_creditos() -> void:
	creditos.abrir()
