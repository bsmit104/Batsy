extends Node

#@export var rock_scene : PackedScene
@export var rock_scenes : Array[PackedScene]
@export var coin_scene: PackedScene  # Assign the coin scene in the editor

const COIN_SPACING_X = 400
const COIN_SPACING_RANGE = 200  # Random offset between 400-600 pixels
var last_coin_x = 0  # Track last coin position
var coins = 0  # Player coin count

var game_running : bool
var game_over : bool
var scroll
var score
const SCROLL_SPEED : int = 10
var screen_size : Vector2i
var rocks : Array
const ROCK_DELAY : int = 50
const ROCK_RANGE : int = 200
var ground_width : int
var ground_height : int
var last_rock_x = 0  # Tracks the last rock's x position
const ROCK_SPACING_X = 400  # Set a fixed spacing between rocks 

var rock_pool : Array = []

func _ready():
	screen_size = get_window().size
	ground_width = $Ground1.get_child(0).texture.get_width()  # Assuming the TextureRect is the first child of Ground1
	$Ground2.position.x = $Ground1.position.x + ground_width  # Position the second ground next to the first
	ground_height = $Ground1.get_node("Sprite2D").texture.get_height()
	$CoinLabel.text = "Coins: " + str(coins)
	#new_game()
	# Start in game-over state (as if the player had already lost)
	game_running = false
	game_over = true  # Set game_over so the player can't interact yet
	$Menu.show()  # Show the death menu at the start
	
func new_game():
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	coins = 0  # Reset the coins for the new game
	$ScoreLabel.text = "SCORE: " + str(score)
	$CoinLabel.text = "Coins: " + str(coins)
	$CoinEarnedLabel.text = " "
	$Menu.hide()

	# Reset object pool
	for rock in rock_pool:
		rock.queue_free()
	rock_pool.clear()
	rocks.clear()

	# Reset last rock position for proper spacing
	last_rock_x = 0

	generate_rocks()

	# Reload the selected character in case the player changed it
	$Bat.selected_character = Global.selected_character
	$Bat.load_character_animation()
	$Bat.reset()

	
func _input(event):
	if game_over == false:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if game_running == false:
					start_game()
				else:
					if $Bat.flying:
						$Bat.flap()
						check_top()

func start_game():
	game_running = true
	$Bat.flying = true
	$Bat.flap()
	$RockTimer.start()

func _process(delta):
	if game_running:
		# Move both ground sprites
		$Ground1.position.x -= SCROLL_SPEED
		$Ground2.position.x -= SCROLL_SPEED

		# Reset position when a ground sprite moves fully off-screen
		if $Ground1.position.x <= -ground_width:
			$Ground1.position.x = $Ground2.position.x + ground_width
		if $Ground2.position.x <= -ground_width:
			$Ground2.position.x = $Ground1.position.x + ground_width

		for rock in rocks:
			rock.position.x -= SCROLL_SPEED

		# Move coins
		for coin in get_tree().get_nodes_in_group("coins"):
			coin.position.x -= SCROLL_SPEED



func _on_rock_timer_timeout() -> void:
	generate_rocks()

func get_pooled_rock():
	# Reuse an existing rock if available
	for rock in rock_pool:
		if not rock.visible:
			return rock
	
	# If none are available, create a new one
	var rock_scene = rock_scenes[randi() % rock_scenes.size()]
	var new_rock = rock_scene.instantiate()
	add_child(new_rock)
	rock_pool.append(new_rock)
	return new_rock

func generate_rocks():
	if rock_scenes.is_empty():
		return  # Prevent errors if no rock scenes are assigned

	# Get a rock from the pool (existing or new)
	var rock = get_pooled_rock()
	rock.show()
	rock.set_process(true)

	# Ensure consistent spacing between rocks
	var min_x = last_rock_x + ROCK_SPACING_X
	rock.position.x = max(screen_size.x + ROCK_DELAY, min_x)
	rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)

	# Connect signals
	if not rock.hit.is_connected(bat_hit):
		rock.hit.connect(bat_hit)
	if not rock.scored.is_connected(scored):
		rock.scored.connect(scored)

	rocks.append(rock)
	last_rock_x = rock.position.x  # Track rock position

	# Try to spawn a coin
	spawn_coin(last_rock_x)


func spawn_coin(x_position):
	# Ensure coins are spaced apart
	if x_position - last_coin_x < COIN_SPACING_X + randi_range(0, COIN_SPACING_RANGE):
		return

	var new_coin = coin_scene.instantiate()
	add_child(new_coin)

	# Add the coin to a group so we can move it later
	new_coin.add_to_group("coins")  # <--- Add this line

	# Set initial coin position with more vertical variation
	new_coin.position.x = x_position + randi_range(50, 400)  # Random slight offset
	new_coin.position.y = randi_range(400, 1600)

	# Ensure the coin doesn't spawn inside rocks
	var tries = 0
	while is_coin_overlapping_rocks(new_coin) and tries < 5:
		# Reassign coin y-position if overlapping
		new_coin.position.y = randi_range(400, 1600)
		tries += 1

	# Connect coin collection signal
	new_coin.collected.connect(_on_coin_collected)

	# Update last coin position
	last_coin_x = new_coin.position.x


# Helper function to check if the coin is overlapping with any rocks
func is_coin_overlapping_rocks(coin: Node2D) -> bool:
	for rock in rocks:
		var collision_polygons = []  # Empty array to store all collision polygons

		# Check for multiple collision polygons (e.g., CollisionPolygon2D, CollisionPolygon2D2, etc.)
		for i in range(rock.get_child_count()):
			var child = rock.get_child(i)
			if child is CollisionPolygon2D:
				collision_polygons.append(child)

		# Check each collision polygon
		for collision_polygon in collision_polygons:
			var polygon = collision_polygon.polygon
			if polygon.size() > 0:
				# Compute the bounding box of the polygon
				var min_bounds = Vector2.INF
				var max_bounds = -Vector2.INF
				for point in polygon:
					min_bounds = min_bounds.min(point)
					max_bounds = max_bounds.max(point)

				var rock_size = max_bounds - min_bounds
				var rock_rect = Rect2(rock.position + min_bounds, rock_size)
				var coin_rect = Rect2(coin.position - Vector2(16, 16), Vector2(32, 32))  # Assuming a 32x32 coin

				if rock_rect.intersects(coin_rect):
					return true  # Coin overlaps with a rock
	return false



func _on_coin_collected():
	coins += 1  # Increase coin count
	Global.totalcoins += 1  # Save it globally for the shop
	$CoinLabel.text = "Coins: " + str(coins)  # Update UI

func scored():
	score += 1
	$ScoreLabel.text = "SCORE: " + str(score)

func check_top():
	if $Bat.position.y < 0:
		$Bat.falling = true
		stop_game()

func stop_game():
	$RockTimer.stop()
	$Menu.show()
	$Bat.flying = false
	game_running = false
	game_over = true
	# Update total coins after the game ends
	#Global.totalcoins += coins  # Add the session's coins to the global total
	Global.save_data()  # Save the updated total coins
	$CoinEarnedLabel.text = "Coins Earned: " + str(coins)  # Display coins earned in this session

func bat_hit():
	$Bat.falling = true
	stop_game()

func _on_ground_1_hit() -> void:
	$Bat.falling = true
	stop_game()

func _on_ground_2_hit() -> void:
	$Bat.falling = true
	stop_game()

func _on_menu_restart() -> void:
	new_game()

#extends Node
#
##@export var rock_scene : PackedScene
#@export var rock_scenes : Array[PackedScene]
#@export var coin_scene: PackedScene  # Assign the coin scene in the editor
#
#const COIN_SPACING_X = 400
#const COIN_SPACING_RANGE = 200  # Random offset between 400-600 pixels
#var last_coin_x = 0  # Track last coin position
#var coins = 0  # Player coin count
#
#var game_running : bool
#var game_over : bool
#var scroll
#var score
#const SCROLL_SPEED : int = 10
#var screen_size : Vector2i
#var rocks : Array
#const ROCK_DELAY : int = 50
#const ROCK_RANGE : int = 200
#var ground_width : int
#var ground_height : int
#var last_rock_x = 0  # Tracks the last rock's x position
#const ROCK_SPACING_X = 400  # Set a fixed spacing between rocks 
#
#var rock_pool : Array = []
#
#func _ready():
	#screen_size = get_window().size
	#ground_width = $Ground1.get_child(0).texture.get_width()  # Assuming the TextureRect is the first child of Ground1
	#$Ground2.position.x = $Ground1.position.x + ground_width  # Position the second ground next to the first
	#ground_height = $Ground1.get_node("Sprite2D").texture.get_height()
	#$CoinLabel.text = "Coins: " + str(coins)
	##new_game()
	## Start in game-over state (as if the player had already lost)
	#game_running = false
	#game_over = true  # Set game_over so the player can't interact yet
	#$Menu.show()  # Show the death menu at the start
	#
#func new_game():
	#game_running = false
	#game_over = false
	#score = 0
	#scroll = 0
	#$ScoreLabel.text = "SCORE: " + str(score)
	#$Menu.hide()
#
	## Reset object pool
	#for rock in rock_pool:
		#rock.queue_free()
	#rock_pool.clear()
	#rocks.clear()
#
	## Reset last rock position for proper spacing
	#last_rock_x = 0
#
	#generate_rocks()
#
	## Reload the selected character in case the player changed it
	#$Bat.selected_character = Global.selected_character
	#$Bat.load_character_animation()
	#$Bat.reset()
#
	#
#func _input(event):
	#if game_over == false:
		#if event is InputEventMouseButton:
			#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#if game_running == false:
					#start_game()
				#else:
					#if $Bat.flying:
						#$Bat.flap()
						#check_top()
#
#func start_game():
	#game_running = true
	#$Bat.flying = true
	#$Bat.flap()
	#$RockTimer.start()
#
#func _process(delta):
	#if game_running:
		## Move both ground sprites
		#$Ground1.position.x -= SCROLL_SPEED
		#$Ground2.position.x -= SCROLL_SPEED
#
		## Reset position when a ground sprite moves fully off-screen
		#if $Ground1.position.x <= -ground_width:
			#$Ground1.position.x = $Ground2.position.x + ground_width
		#if $Ground2.position.x <= -ground_width:
			#$Ground2.position.x = $Ground1.position.x + ground_width
#
		#for rock in rocks:
			#rock.position.x -= SCROLL_SPEED
#
		## Move coins
		#for coin in get_tree().get_nodes_in_group("coins"):
			#coin.position.x -= SCROLL_SPEED
#
#
#
#func _on_rock_timer_timeout() -> void:
	#generate_rocks()
#
#func get_pooled_rock():
	## Reuse an existing rock if available
	#for rock in rock_pool:
		#if not rock.visible:
			#return rock
	#
	## If none are available, create a new one
	#var rock_scene = rock_scenes[randi() % rock_scenes.size()]
	#var new_rock = rock_scene.instantiate()
	#add_child(new_rock)
	#rock_pool.append(new_rock)
	#return new_rock
#
#func generate_rocks():
	#if rock_scenes.is_empty():
		#return  # Prevent errors if no rock scenes are assigned
#
	## Get a rock from the pool (existing or new)
	#var rock = get_pooled_rock()
	#rock.show()
	#rock.set_process(true)
#
	## Ensure consistent spacing between rocks
	#var min_x = last_rock_x + ROCK_SPACING_X
	#rock.position.x = max(screen_size.x + ROCK_DELAY, min_x)
	#rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)
#
	## Connect signals
	#if not rock.hit.is_connected(bat_hit):
		#rock.hit.connect(bat_hit)
	#if not rock.scored.is_connected(scored):
		#rock.scored.connect(scored)
#
	#rocks.append(rock)
	#last_rock_x = rock.position.x  # Track rock position
#
	## Try to spawn a coin
	#spawn_coin(last_rock_x)
#
#
#func spawn_coin(x_position):
	## Ensure coins are spaced apart
	#if x_position - last_coin_x < COIN_SPACING_X + randi_range(0, COIN_SPACING_RANGE):
		#return
#
	#var new_coin = coin_scene.instantiate()
	#add_child(new_coin)
#
	## Add the coin to a group so we can move it later
	#new_coin.add_to_group("coins")  # <--- Add this line
#
	## Set initial coin position with more vertical variation
	#new_coin.position.x = x_position + randi_range(50, 400)  # Random slight offset
	#new_coin.position.y = randi_range(400, 1600)
#
	## Ensure the coin doesn't spawn inside rocks
	#var tries = 0
	#while is_coin_overlapping_rocks(new_coin) and tries < 5:
		## Reassign coin y-position if overlapping
		#new_coin.position.y = randi_range(400, 1600)
		#tries += 1
#
	## Connect coin collection signal
	#new_coin.collected.connect(_on_coin_collected)
#
	## Update last coin position
	#last_coin_x = new_coin.position.x
#
#
## Helper function to check if the coin is overlapping with any rocks
#func is_coin_overlapping_rocks(coin: Node2D) -> bool:
	#for rock in rocks:
		#var collision_polygons = []  # Empty array to store all collision polygons
#
		## Check for multiple collision polygons (e.g., CollisionPolygon2D, CollisionPolygon2D2, etc.)
		#for i in range(rock.get_child_count()):
			#var child = rock.get_child(i)
			#if child is CollisionPolygon2D:
				#collision_polygons.append(child)
#
		## Check each collision polygon
		#for collision_polygon in collision_polygons:
			#var polygon = collision_polygon.polygon
			#if polygon.size() > 0:
				## Compute the bounding box of the polygon
				#var min_bounds = Vector2.INF
				#var max_bounds = -Vector2.INF
				#for point in polygon:
					#min_bounds = min_bounds.min(point)
					#max_bounds = max_bounds.max(point)
#
				#var rock_size = max_bounds - min_bounds
				#var rock_rect = Rect2(rock.position + min_bounds, rock_size)
				#var coin_rect = Rect2(coin.position - Vector2(16, 16), Vector2(32, 32))  # Assuming a 32x32 coin
#
				#if rock_rect.intersects(coin_rect):
					#return true  # Coin overlaps with a rock
	#return false
#
#
#
#func _on_coin_collected():
	#coins += 1  # Increase coin count
	#Global.coins += 1  # Save it globally for the shop
	#$CoinLabel.text = "Coins: " + str(coins)  # Update UI
#
#func scored():
	#score += 1
	#$ScoreLabel.text = "SCORE: " + str(score)
#
#func check_top():
	#if $Bat.position.y < 0:
		#$Bat.falling = true
		#stop_game()
#
#func stop_game():
	#$RockTimer.stop()
	#$Menu.show()
	#$Bat.flying = false
	#game_running = false
	#game_over = true
#
#func bat_hit():
	#$Bat.falling = true
	#stop_game()
#
#func _on_ground_1_hit() -> void:
	#$Bat.falling = true
	#stop_game()
#
#func _on_ground_2_hit() -> void:
	#$Bat.falling = true
	#stop_game()
#
#func _on_menu_restart() -> void:
	#new_game()

















#
#extends Node
#
##@export var rock_scene : PackedScene
#@export var rock_scenes : Array[PackedScene]
#
#var game_running : bool
#var game_over : bool
#var scroll
#var score
#const SCROLL_SPEED : int = 20
#var screen_size : Vector2i
#var rocks : Array
#const ROCK_DELAY : int = 50
#const ROCK_RANGE : int = 200
#var ground_width : int
#var ground_height : int
#var last_rock_x = 0  # Tracks the last rock's x position
#const ROCK_SPACING_X = 400  # Set a fixed spacing between rocks 
#
#var rock_pool : Array = []
#
#func _ready():
	#screen_size = get_window().size
	#ground_width = $Ground1.get_child(0).texture.get_width()  # Assuming the TextureRect is the first child of Ground1
	#$Ground2.position.x = $Ground1.position.x + ground_width  # Position the second ground next to the first
	#ground_height = $Ground1.get_node("Sprite2D").texture.get_height()
	##new_game()
	## Start in game-over state (as if the player had already lost)
	#game_running = false
	#game_over = true  # Set game_over so the player can't interact yet
	#$Menu.show()  # Show the death menu at the start
	#
#func new_game():
	#game_running = false
	#game_over = false
	#score = 0
	#scroll = 0
	#$ScoreLabel.text = "SCORE: " + str(score)
	#$Menu.hide()
#
	## Reset object pool
	#for rock in rock_pool:
		#rock.queue_free()
	#rock_pool.clear()
	#rocks.clear()
#
	## Reset last rock position for proper spacing
	#last_rock_x = 0
#
	#generate_rocks()
#
	## Reload the selected character in case the player changed it
	#$Bat.selected_character = Global.selected_character
	#$Bat.load_character_animation()
	#$Bat.reset()
#
	#
#func _input(event):
	#if game_over == false:
		#if event is InputEventMouseButton:
			#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#if game_running == false:
					#start_game()
				#else:
					#if $Bat.flying:
						#$Bat.flap()
						#check_top()
#
#func start_game():
	#game_running = true
	#$Bat.flying = true
	#$Bat.flap()
	#$RockTimer.start()
#
#func _process(delta):
	#if game_running:
		## Move both ground sprites
		#$Ground1.position.x -= SCROLL_SPEED
		#$Ground2.position.x -= SCROLL_SPEED
#
		## Reset position when a ground sprite moves fully off-screen
		#if $Ground1.position.x <= -ground_width:
			#$Ground1.position.x = $Ground2.position.x + ground_width
		#if $Ground2.position.x <= -ground_width:
			#$Ground2.position.x = $Ground1.position.x + ground_width
#
		#for rock in rocks:
			#rock.position.x -= SCROLL_SPEED
#
#
#
#func _on_rock_timer_timeout() -> void:
	#generate_rocks()
#
#func get_pooled_rock():
	## Reuse an existing rock if available
	#for rock in rock_pool:
		#if not rock.visible:
			#return rock
	#
	## If none are available, create a new one
	#var rock_scene = rock_scenes[randi() % rock_scenes.size()]
	#var new_rock = rock_scene.instantiate()
	#add_child(new_rock)
	#rock_pool.append(new_rock)
	#return new_rock
#
#func generate_rocks():
	#if rock_scenes.is_empty():
		#return  # Prevent errors if no rock scenes are assigned
#
	## Get a rock from the pool (existing or new)
	#var rock = get_pooled_rock()
	#rock.show()  # Make sure the rock is visible
	#rock.set_process(true)
#
	## Ensure consistent spacing between rocks
	#var min_x = last_rock_x + ROCK_SPACING_X
	#rock.position.x = max(screen_size.x + ROCK_DELAY, min_x)
	#
	#rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)
#
	## Connect signals only if not already connected
	#if not rock.hit.is_connected(bat_hit):
		#rock.hit.connect(bat_hit)
	#if not rock.scored.is_connected(scored):
		#rock.scored.connect(scored)
#
	## **Do not re-add the rock as a child if it was pooled**
	#if rock.get_parent() == null:
		#add_child(rock)  # Only add if it's a new instance
#
	#rocks.append(rock)
#
	## Update last rock position
	#last_rock_x = rock.position.x
#
#func scored():
	#score += 1
	#$ScoreLabel.text = "SCORE: " + str(score)
#
#func check_top():
	#if $Bat.position.y < 0:
		#$Bat.falling = true
		#stop_game()
#
#func stop_game():
	#$RockTimer.stop()
	#$Menu.show()
	#$Bat.flying = false
	#game_running = false
	#game_over = true
#
#func bat_hit():
	#$Bat.falling = true
	#stop_game()
#
#func _on_ground_1_hit() -> void:
	#$Bat.falling = true
	#stop_game()
#
#func _on_ground_2_hit() -> void:
	#$Bat.falling = true
	#stop_game()
#
#func _on_menu_restart() -> void:
	#new_game()
#
#










#func new_game():
	#game_running = false
	#game_over = false
	#score = 0
	#scroll = 0
	#$ScoreLabel.text = "SCORE: " + str(score)
	#$Menu.hide()
	#
	## Reset object pool
	#for rock in rock_pool:
		#rock.queue_free()
	#rock_pool.clear()
	#rocks.clear()
	#
	## **Reset last_rock_x to ensure proper spawning**
	#last_rock_x = 0  # Reset to the leftmost screen edge
	#
	##rocks.clear()
	#generate_rocks()
	#$Bat.reset()

#func generate_rocks():
	#if rock_scenes.is_empty():
		#return  # Prevent errors if no rock scenes are assigned
#
	## Pick a random rock formation from the list
	#var rock_scene = rock_scenes[randi() % rock_scenes.size()]
	##var rock = rock_scene.instantiate()
	#var rock = get_pooled_rock()
	#rock.show()
	#rock.set_process(true)
	#
	## Ensure consistent spacing between rocks
	#var min_x = last_rock_x + ROCK_SPACING_X
	#rock.position.x = max(screen_size.x + ROCK_DELAY, min_x)
	#
	#rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)
	#rock.hit.connect(bat_hit)
	#rock.scored.connect(scored)
	#
	#add_child(rock)
	#rocks.append(rock)
#
	## Update last rock position
	#last_rock_x = rock.position.x
