extends Control

signal jugar

@onready var panel_carga_escenas: Panel = $PanelCargaEscenas
@onready var btn_aldea: Button = $PanelCargaEscenas/btn_Aldea


func _ready() -> void:

	panel_carga_escenas.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)

	DialogueUpdater.guiones_disponibles_changed.connect(
		_on_guiones_disponibles_changed
	)

	if DialogueUpdater.guiones_disponibles:
		_habilitar_carga_escenas()

	btn_aldea.pressed.connect(
		_on_btn_aldea_pressed
	)



func _on_guiones_disponibles_changed() -> void:

	_habilitar_carga_escenas()



func _habilitar_carga_escenas() -> void:

	panel_carga_escenas.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)



func _on_btn_aldea_pressed() -> void:

	jugar.emit()
