#extends Area2D
#
#signal collected
#
#func _ready():
	#set_process(true)
#
#func _on_body_entered(body):
	#if body.name == "Bat":  # Assuming your bat is named "Bat"
		#emit_signal("collected")

extends Area2D

signal collected

func _ready():
	# Connect only if not already connected
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Bat":  # Ensure the player collects the coin
		emit_signal("collected")
		queue_free()  # Remove the coin after collection
