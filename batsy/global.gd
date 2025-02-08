extends Node

# Store the currently selected character
var selected_character : String = "default"  # Default value, can be changed later
var owned_characters : Array = ["default"]  # Add this line

# File path for storing data
const SAVE_FILE_PATH = "user://savegame.json"

# Called when the game starts
func _ready():
	# Load any existing saved data when the game starts
	load_data()

# Save the game data (in this case, the selected character)
func save_data():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)  # Open file in write mode
	if file:
		var data = {"selected_character": selected_character}  # Data to save
		var json = JSON.new()  # Create an instance of JSON
		var json_string = json.stringify(data)  # Convert the dictionary to a JSON string
		file.store_string(json_string)  # Save the JSON string to the file
		file.close()  # Close the file

# Load the game data (in this case, the selected character)
func load_data():
	if FileAccess.file_exists(SAVE_FILE_PATH):  # Check if the save file exists
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)  # Open file in read mode
		if file:
			var json_data = file.get_as_text()  # Read the file's contents as a text string
			file.close()  # Close the file
			var json = JSON.new()  # Create an instance of JSON
			var data = json.parse(json_data)  # Parse the JSON string into a dictionary
			if data is Dictionary:
				selected_character = data["selected_character"]  # Set the selected character
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
	
	# Force reload to apply reset
	get_tree().reload_current_scene()


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and event.shift_pressed:  # Shift + R
			reset_save()
