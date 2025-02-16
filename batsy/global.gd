extends Node

# Store the currently selected character
var selected_character : String = "default"  # Default value, can be changed later
var owned_characters : Array = ["default"]  # Add this line
var totalcoins: int = 200

# File path for storing data
const SAVE_FILE_PATH = "user://savegame.json"

# Called when the game starts
func _ready():
	# Load any existing saved data when the game starts
	load_data()
	
	SilentWolf.configure({
	"api_key": "MKwEFV6PW156lqubyg5do5qE2MmXc0JkaY4Gi3u2",
	"game_id": "batsy",
	"log_level": 1
	})

	SilentWolf.configure_scores({
	"open_scene_on_close": "res://scenes/MainPage.tscn"
	})


func save_data():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"selected_character": selected_character,
			"totalcoins": totalcoins,
			"owned_characters": owned_characters  # Ensure this is saved too
		}
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()

func load_data():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			file.close()
			var data = JSON.parse_string(json_data)
			if data is Dictionary:
				selected_character = data.get("selected_character", "default")
				totalcoins = data.get("totalcoins", 200)
				owned_characters = data.get("owned_characters", ["default"])  # Load owned characters
			else:
				print("Failed to parse JSON data")


func reset_save():
	# List of save files to delete
	var save_files = ["user://savegame.json", "user://shop_save.json"]
	
	for save_file in save_files:
		if FileAccess.file_exists(save_file):
			DirAccess.remove_absolute(save_file)
			print("Deleted:", save_file)
		else:
			print("No save file found:", save_file)
	
	# Reset in-memory values
	selected_character = "default"
	totalcoins = 200
	owned_characters = ["default"]
	
	# Force reload to apply reset
	get_tree().reload_current_scene()


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and event.shift_pressed:  # Shift + R
			reset_save()




#extends Node
#
## Store the currently selected character
#var selected_character : String = "default"  # Default value, can be changed later
#var owned_characters : Array = ["default"]  # Add this line
#var totalcoins: int = 200
#
## File path for storing data
#const SAVE_FILE_PATH = "user://savegame.json"
#
## Called when the game starts
#func _ready():
	## Load any existing saved data when the game starts
	#load_data()
#
#
#func save_data():
	#var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	#if file:
		#var data = {
			#"selected_character": selected_character,
			#"totalcoins": totalcoins,
			#"owned_characters": owned_characters  # Ensure this is saved too
		#}
		#var json_string = JSON.stringify(data)
		#file.store_string(json_string)
		#file.close()
#
#func load_data():
	#if FileAccess.file_exists(SAVE_FILE_PATH):
		#var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		#if file:
			#var json_data = file.get_as_text()
			#file.close()
			#var data = JSON.parse_string(json_data)
			#if data is Dictionary:
				#selected_character = data.get("selected_character", "default")
				#totalcoins = data.get("totalcoins", 200)
				#owned_characters = data.get("owned_characters", ["default"])  # Load owned characters
			#else:
				#print("Failed to parse JSON data")
#
#
#func reset_save():
	## List of save files to delete
	#var save_files = ["user://savegame.json", "user://shop_save.json"]
	#
	#for save_file in save_files:
		#if FileAccess.file_exists(save_file):
			#DirAccess.remove_absolute(save_file)
			#print("Deleted:", save_file)
		#else:
			#print("No save file found:", save_file)
	#
	## Reset in-memory values
	#selected_character = "default"
	#totalcoins = 200
	#owned_characters = ["default"]
	#
	## Force reload to apply reset
	#get_tree().reload_current_scene()
#
#
#func _input(event):
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_R and event.shift_pressed:  # Shift + R
			#reset_save()
#
#
