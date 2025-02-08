extends Area2D

signal collected

func _ready():
	set_process(true)

func _on_body_entered(body):
	if body.name == "Bat":  # Assuming your bat is named "Bat"
		emit_signal("collected")
