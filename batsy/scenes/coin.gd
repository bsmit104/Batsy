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













#extends Area2D
#
#signal collected(coin)
#
#func _ready():
	#if not body_entered.is_connected(_on_body_entered):
		#body_entered.connect(_on_body_entered)
#
#func _on_body_entered(body):
	#if body.name == "Bat":
		#emit_signal("collected", self)  # Pass 'self' so the main script knows which coin was collected
		#queue_free()
#
extends Area2D

signal collected(coin)

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# ✅ Self-connect to prevent unused warning
	if not collected.is_connected(_on_collected_debug):
		collected.connect(_on_collected_debug)

func _on_body_entered(body):
	if body.name == "Bat":
		emit_signal("collected", self)  # Emit the collected signal
		queue_free()

# ✅ Dummy function to ensure the signal is explicitly used
func _on_collected_debug(_coin):
	pass



#extends Area2D
#
#signal collected
#
#func _ready():
	## Connect only if not already connected
	#if not body_entered.is_connected(_on_body_entered):
		#body_entered.connect(_on_body_entered)
#
#func _on_body_entered(body):
	#if body.name == "Bat":  # Ensure the player collects the coin
		#emit_signal("collected")
		#queue_free()  # Remove the coin after collection
