extends CanvasLayer

signal restart

# Reference to the Shop and Character Select scenes (Control nodes)
@export var shop_scene_path : String = "res://scenes/shop.tscn"
@export var character_select_scene_path : String = "res://scenes/characterSelect.tscn"

# Called when the 'Play' button is pressed
func _on_play_pressed() -> void:
	restart.emit()

# Called when the 'Shop' button is pressed
func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file(shop_scene_path)  # Change to the Shop scene

# Called when the 'Character Select' button is pressed
func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file(character_select_scene_path)  # Change to the Character Select scene

#extends CanvasLayer
#
#signal restart
#
#
#
#func _on_play_pressed() -> void:
	#restart.emit()
