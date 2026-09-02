extends Control

signal jugar(mapa_path: String)

const NIVELES_DATA := preload(
	"res://scripts/niveles.gd"
)

@onready var panel_carga_escenas: Panel = $PanelCargaEscenas
@onready var chk_actualizar: Button = $PanelCargaEscenas/chk_ActualizarGuiones
@onready var lbl_estado_guiones: Label = $PanelCargaEscenas/lbl_EstadoGuiones
@onready var boton_creditos: Button = $BotonCreditos
@onready var creditos: Control = $Creditos

# DEV TEMPORAL: editor de XP en bienvenida.
# Retirar antes de una versión de distribución.
@onready var dev_xp: SpinBox = $PanelCargaEscenas/DevXP


func _ready() -> void:

	# DEV TEMPORAL: cargar la XP guardada antes de mostrar el control.
	DialogueManager.load_player_status()
	_configurar_dev_xp()

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


func _configurar_dev_xp() -> void:
	dev_xp.min_value = 0
	dev_xp.max_value = NIVELES_DATA.xp_maximo()
	dev_xp.step = 1

	var player := _get_player()

	if player != null:
		dev_xp.set_value_no_signal(
			float(player.xp)
		)

	dev_xp.value_changed.connect(
		_on_dev_xp_changed
	)


func _get_player() -> Node:
	var game := get_tree().current_scene

	if game == null:
		return null

	return game.get("player_actual")


# DEV TEMPORAL: cambio directo de XP desde bienvenida.
func _on_dev_xp_changed(value: float) -> void:
	var player := _get_player()

	if player == null:
		return

	if not player.has_method("set_xp_dev"):
		return

	player.set_xp_dev(
		int(value)
	)

	DialogueManager._save_player_status()


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
