extends Control

#var coins = 200
var owned_characters = ["default"]
var character_data = []


func _ready():
	load_data()
	load_character_data()
	update_shop_coins()
	update_coins_label()  # ✅ Update coins display when shop opens
	update_shop()

func load_character_data():
	var file = FileAccess.open("res://characters.json", FileAccess.READ)
	character_data = JSON.parse_string(file.get_as_text())

#adding
#func update_shop_coins():
	#$CoinsLabel.text = "Coins: " + str(coins)
##
func update_shop_coins():
	# Set the label to reflect the global coin total
	$CoinsLabel.text = "Coins: " + str(Global.totalcoins)

func update_shop():
	var container = $CharacterScroll/CharacterList
	for child in container.get_children():
		child.queue_free()

	for character in character_data:
		var item = create_shop_item(character)
		container.add_child(item)

func create_shop_item(character):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)  # Adds space between elements

	# Character Image (Increase size)
	var image = TextureRect.new()
	image.texture = load(character["image"])
	image.custom_minimum_size = Vector2(128, 128)  # Increase from 64x64 to 128x128
	hbox.add_child(image)

	# Character Name and Price (Increase text size)
	var label = Label.new()
	label.text = character["name"] + " - " + str(character["price"]) + " Coins"
	label.add_theme_font_size_override("font_size", 32)  # Increase text size
	hbox.add_child(label)

	# Buy Button (Increase size and text)
	var button = Button.new()
	button.text = "Buy"
	button.add_theme_font_size_override("font_size", 32)  # Make button text bigger
	button.custom_minimum_size = Vector2(200, 75)  # Make button bigger
	button.connect("pressed", Callable(self, "_on_buy_character").bind(character))
	hbox.add_child(button)

	# If already owned, disable the button
	if character["id"] in owned_characters:
		button.text = "Owned"
		button.disabled = true

	return hbox


func _on_buy_character(character):
	if character["id"] in owned_characters:
		return

	if Global.totalcoins >= character["price"]:
		Global.totalcoins -= character["price"]
		owned_characters.append(character["id"])
		update_shop()
		update_coins_label()
		update_shop_coins()  # Update the coin count after purchase
		#FIX ME SAVE FUNCTIONS INTERFERING WITH EACH OTHER PREVENTS COINS COLLECTED FROM BEING ADDED AFTER PURCHASE
		save_data()  # Save data to ensure coins are saved
		Global.save_data()

func update_coins_label():
	$CoinsLabel.text = "Coins: " + str(Global.totalcoins)


func save_data():
	var file = FileAccess.open("user://shop_save.json", FileAccess.WRITE)
	#var data = {"coins": coins, "owned_characters": owned_characters}
	var data = {"coins": Global.totalcoins, "owned_characters": owned_characters}
	file.store_string(JSON.stringify(data))

	# Save owned characters to Global
	Global.owned_characters = owned_characters

func load_data():
	if FileAccess.file_exists("user://shop_save.json"):
		var file = FileAccess.open("user://shop_save.json", FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		
		# Check if the parsed data is valid
		if data is Dictionary:
			#coins = data.get("coins", 200)  # Default to 200 if missing
			Global.totalcoins = data.get("coins", 200)  # Default to 200 if missing
			owned_characters = data.get("owned_characters", ["default"])  # Default to just "default"
		else:
			print("Warning: Failed to load shop data, resetting to default.")
			reset_shop_data()  # Call function to reset

# Function to reset shop data when file is missing/corrupted
func reset_shop_data():
	#coins = 200
	Global.totalcoins = 200
	owned_characters = ["default"]
	save_data()  # Save default values so the game doesn't break again


# Called when the 'Back' button is pressed
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")



#extends Control
#
#var coins = 200
#var owned_characters = ["default"]
#var character_data = []
#
#
#func _ready():
	#load_data()
	#load_character_data()
	#update_coins_label()  # ✅ Update coins display when shop opens
	#update_shop()
#
#func load_character_data():
	#var file = FileAccess.open("res://characters.json", FileAccess.READ)
	#character_data = JSON.parse_string(file.get_as_text())
#
##adding
#func update_shop_coins():
	#$CoinsLabel.text = "Coins: " + str(coins)
##
#
#func update_shop():
	#var container = $CharacterScroll/CharacterList
	#for child in container.get_children():
		#child.queue_free()
#
	#for character in character_data:
		#var item = create_shop_item(character)
		#container.add_child(item)
#
#func create_shop_item(character):
	#var hbox = HBoxContainer.new()
	#hbox.add_theme_constant_override("separation", 20)  # Adds space between elements
#
	## Character Image (Increase size)
	#var image = TextureRect.new()
	#image.texture = load(character["image"])
	#image.custom_minimum_size = Vector2(128, 128)  # Increase from 64x64 to 128x128
	#hbox.add_child(image)
#
	## Character Name and Price (Increase text size)
	#var label = Label.new()
	#label.text = character["name"] + " - " + str(character["price"]) + " Coins"
	#label.add_theme_font_size_override("font_size", 32)  # Increase text size
	#hbox.add_child(label)
#
	## Buy Button (Increase size and text)
	#var button = Button.new()
	#button.text = "Buy"
	#button.add_theme_font_size_override("font_size", 32)  # Make button text bigger
	#button.custom_minimum_size = Vector2(200, 75)  # Make button bigger
	#button.connect("pressed", Callable(self, "_on_buy_character").bind(character))
	#hbox.add_child(button)
#
	## If already owned, disable the button
	#if character["id"] in owned_characters:
		#button.text = "Owned"
		#button.disabled = true
#
	#return hbox
#
#func _on_buy_character(character):
	#if character["id"] in owned_characters:
		#return
#
	#if coins >= character["price"]:
		#coins -= character["price"]
		#owned_characters.append(character["id"])
		#update_shop()
		#update_coins_label()
		#save_data()  # ✅ Ensure coins are saved
#
#
#func update_coins_label():
	#$CoinsLabel.text = "Coins: " + str(coins)
#
#func save_data():
	#var file = FileAccess.open("user://shop_save.json", FileAccess.WRITE)
	#var data = {"coins": coins, "owned_characters": owned_characters}
	#file.store_string(JSON.stringify(data))
#
	## Save owned characters to Global
	#Global.owned_characters = owned_characters
#
#func load_data():
	#if FileAccess.file_exists("user://shop_save.json"):
		#var file = FileAccess.open("user://shop_save.json", FileAccess.READ)
		#var data = JSON.parse_string(file.get_as_text())
		#
		## Check if the parsed data is valid
		#if data is Dictionary:
			#coins = data.get("coins", 200)  # Default to 200 if missing
			#owned_characters = data.get("owned_characters", ["default"])  # Default to just "default"
		#else:
			#print("Warning: Failed to load shop data, resetting to default.")
			#reset_shop_data()  # Call function to reset
#
## Function to reset shop data when file is missing/corrupted
#func reset_shop_data():
	#coins = 200
	#owned_characters = ["default"]
	#save_data()  # Save default values so the game doesn't break again
#
#
## Called when the 'Back' button is pressed
#func _on_back_pressed() -> void:
	#get_tree().change_scene_to_file("res://scenes/main.tscn")
#



















#func save_data():
	#var file = FileAccess.open("user://shop_save.json", FileAccess.WRITE)
	#var data = {"coins": coins, "owned_characters": owned_characters}
	#file.store_string(JSON.stringify(data))

#func load_data():
	#if FileAccess.file_exists("user://shop_save.json"):
		#var file = FileAccess.open("user://shop_save.json", FileAccess.READ)
		#var data = JSON.parse_string(file.get_as_text())
		#coins = data["coins"]
		#owned_characters = data["owned_characters"]
