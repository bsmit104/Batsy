#extends Control
#
#var owned_characters = ["default"]
#var selected_character = "default"
#var character_data = []
#
#func _ready():
	#load_character_data()
	#update_character_list()
#
#func load_character_data():
	#var file = FileAccess.open("res://characters.json", FileAccess.READ)
	#character_data = JSON.parse_string(file.get_as_text())
#
#func update_character_list():
	#var container = $ScrollContainer/CharacterList
	#for child in container.get_children():
		#child.queue_free()  # Clear old buttons
#
	#for character in character_data:
		#if character["id"] in owned_characters:
			#var button = Button.new()
			#button.text = character["name"]
			#button.connect("pressed", Callable(self, "_on_character_selected").bind(character))
			#container.add_child(button)
#
#func _on_character_selected(character):
	#Global.selected_character = character["id"]
	#Global.save_data()
	#$SelectionLabel.text = "Selected: " + character["name"]
#
## Called when the 'Back' button is pressed
#func _on_back_pressed() -> void:
	#get_tree().change_scene_to_file("res://scenes/main.tscn")


extends Control

var owned_characters = ["default"]
var selected_character = "default"
var character_data = []

func _ready():
	# Load owned characters from save file
	load_data()
	load_character_data()
	update_character_list()

func load_character_data():
	var file = FileAccess.open("res://characters.json", FileAccess.READ)
	character_data = JSON.parse_string(file.get_as_text())

func update_character_list():
	var container = $ScrollContainer/CharacterList
	for child in container.get_children():
		child.queue_free()  # Clear old buttons

	for character in character_data:
		if character["id"] in owned_characters:
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 20)

			# Character Image (added image for character)
			var image = TextureRect.new()
			image.texture = load(character["image"])
			image.custom_minimum_size = Vector2(128, 128)  # Adjust size of image
			hbox.add_child(image)

			# Character Name Label
			var label = Label.new()
			label.text = character["name"]
			label.add_theme_font_size_override("font_size", 32)
			hbox.add_child(label)

			# Equip Button
			var button = Button.new()
			button.text = "Equip"
			button.add_theme_font_size_override("font_size", 28)
			button.custom_minimum_size = Vector2(200, 75)
			button.connect("pressed", Callable(self, "_on_character_selected").bind(character))
			hbox.add_child(button)

			# Check if this character is selected
			if character["id"] == selected_character:
				button.text = "Equipped"
				button.disabled = true

			container.add_child(hbox)

func _on_character_selected(character):
	selected_character = character["id"]
	Global.selected_character = selected_character  # Save globally
	save_selected_character()
	update_character_list()  # Refresh UI

func save_selected_character():
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	var data = {"selected_character": selected_character}
	file.store_string(JSON.stringify(data))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func load_data():
	if FileAccess.file_exists("user://shop_save.json"):
		var file = FileAccess.open("user://shop_save.json", FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		owned_characters = data["owned_characters"]

	# Load selected character from savegame.json
	if FileAccess.file_exists("user://savegame.json"):
		var file = FileAccess.open("user://savegame.json", FileAccess.READ)
		var saved_data = JSON.parse_string(file.get_as_text())
		if saved_data is Dictionary and "selected_character" in saved_data:
			selected_character = saved_data["selected_character"]


#extends Control
#
#var owned_characters = ["default"]
#var selected_character = "default"
#var character_data = []
#
#func _ready():
	## Load owned characters from save file
	#load_data()
	#load_character_data()
	#update_character_list()
#
#func load_character_data():
	#var file = FileAccess.open("res://characters.json", FileAccess.READ)
	#character_data = JSON.parse_string(file.get_as_text())
#
#func update_character_list():
	#var container = $ScrollContainer/CharacterList
	#for child in container.get_children():
		#child.queue_free()  # Clear old buttons
#
	#for character in character_data:
		#if character["id"] in owned_characters:
			#var hbox = HBoxContainer.new()
			#hbox.add_theme_constant_override("separation", 20)
#
			## Character Name Label
			#var label = Label.new()
			#label.text = character["name"]
			#label.add_theme_font_size_override("font_size", 32)
			#hbox.add_child(label)
#
			## Equip Button
			#var button = Button.new()
			#button.text = "Equip"
			#button.add_theme_font_size_override("font_size", 28)
			#button.custom_minimum_size = Vector2(200, 75)
			#button.connect("pressed", Callable(self, "_on_character_selected").bind(character))
			#hbox.add_child(button)
#
			## Check if this character is selected
			#if character["id"] == selected_character:
				#button.text = "Equipped"
				#button.disabled = true
#
			#container.add_child(hbox)
#
##
	### Save selection globally (optional)
	##Global.selected_character = selected_character
#func _on_character_selected(character):
	#selected_character = character["id"]
	#Global.selected_character = selected_character  # Save globally
	#save_selected_character()
	#update_character_list()  # Refresh UI
#
#
#func save_selected_character():
	#var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	#var data = {"selected_character": selected_character}
	#file.store_string(JSON.stringify(data))
#
#func _on_back_pressed() -> void:
	#get_tree().change_scene_to_file("res://scenes/main.tscn")
#
#func load_data():
	#if FileAccess.file_exists("user://shop_save.json"):
		#var file = FileAccess.open("user://shop_save.json", FileAccess.READ)
		#var data = JSON.parse_string(file.get_as_text())
		#owned_characters = data["owned_characters"]
#
	## Load selected character from savegame.json
	#if FileAccess.file_exists("user://savegame.json"):
		#var file = FileAccess.open("user://savegame.json", FileAccess.READ)
		#var saved_data = JSON.parse_string(file.get_as_text())
		#if saved_data is Dictionary and "selected_character" in saved_data:
			#selected_character = saved_data["selected_character"]
