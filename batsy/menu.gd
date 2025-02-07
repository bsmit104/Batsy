extends CanvasLayer

signal restart



func _on_play_pressed() -> void:
	restart.emit()
