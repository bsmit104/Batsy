extends Node

@export var rock_scenes : Array[PackedScene]
@export var coin_scene: PackedScene  # Assign the coin scene in the editor

const COIN_SPACING_X = 600
const COIN_SPACING_RANGE = 300  # Random offset between 400-600 pixels
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

var spawn_enabled = false

var rock_pool : Array = []
var coin_pool : Array = []  # Pool for coin reuse

func _ready():
	screen_size = get_window().size
	ground_width = $Ground1.get_child(0).texture.get_width()
	$Ground2.position.x = $Ground1.position.x + ground_width  
	ground_height = $Ground1.get_node("Sprite2D").texture.get_height()
	$CoinLabel.text = "Coins: " + str(coins)
	game_running = false
	game_over = true  
	$Menu.show()  

func new_game():
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	coins = 0  
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

	$Bat.selected_character = Global.selected_character
	$Bat.load_character_animation()
	$Bat.reset()
	
	# Clear existing coins
	for coin in get_tree().get_nodes_in_group("coins"):
		pool_coin(coin)  # Pool instead of freeing

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
		if not spawn_enabled and scroll >= 1500:
			spawn_enabled = true  

		# Move ground
		$Ground1.position.x -= SCROLL_SPEED
		$Ground2.position.x -= SCROLL_SPEED
		scroll += SCROLL_SPEED

		# Reset ground
		if $Ground1.position.x <= -ground_width:
			$Ground1.position.x = $Ground2.position.x + ground_width
		if $Ground2.position.x <= -ground_width:
			$Ground2.position.x = $Ground1.position.x + ground_width

		# Move rocks
		for rock in rocks:
			rock.position.x -= SCROLL_SPEED

		# Move and pool coins
		for coin in get_tree().get_nodes_in_group("coins"):
			coin.position.x -= SCROLL_SPEED
			if coin.position.x < -100:  # Off-screen left
				pool_coin(coin)  

func _on_rock_timer_timeout() -> void:
	generate_rocks()

func get_pooled_rock():
	for rock in rock_pool:
		if not rock.visible:
			return rock
	
	var rock_scene = rock_scenes[randi() % rock_scenes.size()]
	var new_rock = rock_scene.instantiate()
	add_child(new_rock)
	rock_pool.append(new_rock)
	return new_rock

var coin_count = 0  
const MAX_COINS_PER_CYCLE = 5  
const TOTAL_SPAWNS_PER_CYCLE = 15  

func generate_rocks():
	if rock_scenes.is_empty():
		return

	if coin_count < MAX_COINS_PER_CYCLE and randi_range(1, TOTAL_SPAWNS_PER_CYCLE) <= MAX_COINS_PER_CYCLE:
		spawn_coin(last_rock_x)  
		coin_count += 1  
	else:
		var rock = get_pooled_rock()
		rock.show()
		rock.set_process(true)

		var min_x = last_rock_x + ROCK_SPACING_X
		rock.position.x = max(screen_size.x + 300, min_x)
		rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)

		var rock_tween = create_tween()
		rock.modulate.a = 0  
		rock_tween.tween_property(rock, "modulate:a", 1, 0.5)  

		if not rock.hit.is_connected(bat_hit):
			rock.hit.connect(bat_hit)
		if not rock.scored.is_connected(scored):
			rock.scored.connect(scored)

		rocks.append(rock)
		last_rock_x = rock.position.x  

	if coin_count >= MAX_COINS_PER_CYCLE:
		coin_count = 0  

var last_coin_y = -1  

#func get_pooled_coin():
	#for coin in coin_pool:
		#if not coin.visible:
			#return coin
	#
	#var new_coin = coin_scene.instantiate()
	#add_child(new_coin)
	#coin_pool.append(new_coin)
	#return new_coin
func get_pooled_coin():
	for coin in coin_pool:
		# Ensure the coin is a valid instance and is not visible
		if is_instance_valid(coin) and not coin.visible:
			return coin
	
	var new_coin = coin_scene.instantiate()
	add_child(new_coin)
	coin_pool.append(new_coin)
	return new_coin



func spawn_coin(x_position):
	var min_x_position = x_position + ROCK_SPACING_X
	#var new_coin = coin_scene.instantiate()
	#add_child(new_coin)
	#new_coin.add_to_group("coins")
	var new_coin = get_pooled_coin()
	new_coin.show()
	new_coin.set_process(true)
	new_coin.add_to_group("coins")


	new_coin.position.x = min_x_position + 300

	var vertical_buffer = 50
	var min_y = vertical_buffer
	var max_y = 1600
	var random_y_position = randi_range(min_y, max_y) + 300
	random_y_position = clamp(random_y_position, min_y, max_y)

	var vertical_spacing = 200
	while abs(random_y_position - last_coin_y) < vertical_spacing:
		random_y_position = randi_range(min_y, max_y) + 300
		random_y_position = clamp(random_y_position, min_y, max_y)

	new_coin.position.y = random_y_position
	last_coin_y = new_coin.position.y
	last_coin_x = new_coin.position.x

	var coin_tween = create_tween()
	new_coin.modulate.a = 0
	coin_tween.tween_property(new_coin, "modulate:a", 1, 0.5)

	# Prevent duplicate signal connections
	if not new_coin.collected.is_connected(_on_coin_collected):
		new_coin.collected.connect(_on_coin_collected)


#func _on_coin_collected(coin):
	#coins += 1  
	#Global.totalcoins += 1  
	#$CoinLabel.text = "Coins: " + str(coins)
	#pool_coin(coin)  
func _on_coin_collected(coin):  
	coins += 1
	Global.totalcoins += 1
	$CoinLabel.text = "Coins: " + str(coins)
	pool_coin(coin)  # Return coin to pool


func pool_coin(coin):
	coin.hide()
	coin.set_process(false)
	coin.position = Vector2(-1000, -1000)  

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
	Global.save_data()
	$CoinEarnedLabel.text = "Coins Earned: " + str(coins)  

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
#@export var rock_scenes : Array[PackedScene]
#@export var coin_scene: PackedScene  # Assign the coin scene in the editor
#
#const COIN_SPACING_X = 600
#const COIN_SPACING_RANGE = 300  # Random offset between 400-600 pixels
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
#var spawn_enabled = false
#
#var rock_pool : Array = []
#
#func _ready():
	#screen_size = get_window().size
	#ground_width = $Ground1.get_child(0).texture.get_width()  # Assuming the TextureRect is the first child of Ground1
	#$Ground2.position.x = $Ground1.position.x + ground_width  # Position the second ground next to the first
	#ground_height = $Ground1.get_node("Sprite2D").texture.get_height()
	#$CoinLabel.text = "Coins: " + str(coins)
	#game_running = false
	#game_over = true  # Set game_over so the player can't interact yet
	#$Menu.show()  # Show the death menu at the start
	#
#func new_game():
	#game_running = false
	#game_over = false
	#score = 0
	#scroll = 0
	#coins = 0  # Reset the coins for the new game
	#$ScoreLabel.text = "SCORE: " + str(score)
	#$CoinLabel.text = "Coins: " + str(coins)
	#$CoinEarnedLabel.text = " "
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
	## Clear existing coins in the scene
	#for coin in get_tree().get_nodes_in_group("coins"):
		#coin.queue_free()  # Remove the coin from the scene
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
		#if not spawn_enabled and scroll >= 1500:
			#spawn_enabled = true  # Enable rock and coin spawning
#
		## Move both ground sprites
		#$Ground1.position.x -= SCROLL_SPEED
		#$Ground2.position.x -= SCROLL_SPEED
		#scroll += SCROLL_SPEED
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
#var coin_count = 0  # Track how many coins have spawned in this cycle
#const MAX_COINS_PER_CYCLE = 5  # Maximum coins per 15 spawns
#const TOTAL_SPAWNS_PER_CYCLE = 15  # Total spawns (coins + rocks)
#
#func generate_rocks():
	#if rock_scenes.is_empty():
		#return
#
	## Check if we've reached the maximum number of coins (5 per 15 spawns)
	#if coin_count < MAX_COINS_PER_CYCLE and randi_range(1, TOTAL_SPAWNS_PER_CYCLE) <= MAX_COINS_PER_CYCLE:
		#spawn_coin(last_rock_x)  # Spawn a coin
		#coin_count += 1  # Increment coin count
	#else:
		#var rock = get_pooled_rock()
		#rock.show()
		#rock.set_process(true)
#
		## Ensure proper spacing between rocks and spawn closer to the screen
		#var min_x = last_rock_x + ROCK_SPACING_X
		#rock.position.x = max(screen_size.x + 300, min_x)  # Reduce off-screen distance for better visibility
		#rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)
#
		## Fade-in effect for the rock
		#var rock_tween = create_tween()
		#rock.modulate.a = 0  # Start fully transparent
		#rock_tween.tween_property(rock, "modulate:a", 1, 0.5)  # Fade in over 0.5 seconds
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
	## Reset after 15 spawns (5 coins and 10 rocks)
	#if coin_count >= MAX_COINS_PER_CYCLE:
		#coin_count = 0  # Reset coin count after 5 coins
#
#var last_coin_y = -1  # Track the last coin's vertical position to prevent overlap
#
#func spawn_coin(x_position):
	## Debug prints to check values
	##print("Screen height: ", screen_size.y)
	##print("Ground height: ", ground_height)
#
	## Ensure the coin is spaced at least 400 units from the previous rock (same as rocks)
	#var min_x_position = x_position + ROCK_SPACING_X  # 400 units spacing from the last rock position
	#var new_coin = coin_scene.instantiate()
	#add_child(new_coin)
	#new_coin.add_to_group("coins")
#
	## Set the fixed horizontal position, with 300 units of buffer from the screen's edge
	#new_coin.position.x = min_x_position + 300  # Fixed horizontal position after last rock + buffer
#
	## Define the vertical range for coin spawning
	#var vertical_buffer = 50  # Reduced buffer to avoid restricting spawn area
	#var min_y = vertical_buffer  # Minimum Y position (top buffer)
	#var max_y = 1600
	##screen_size.y - ground_height - vertical_buffer  # Maximum Y position (bottom buffer, accounting for ground height)
#
	### Debug prints for Y range
	##print("Min Y: ", min_y)
	##print("Max Y: ", max_y)
#
	## Randomize the Y position within the defined range
	#var random_y_position = randi_range(min_y, max_y)
#
	## Shift the entire range downwards by 300 pixels
	#random_y_position += 300
#
	## Clamp the Y position to ensure it stays within the screen bounds
	#random_y_position = clamp(random_y_position, min_y, max_y)
#
	## Debug print for final Y position
	##print("Random Y position: ", random_y_position)
#
	## Avoid spawning the coin too close to the previous one
	#var vertical_spacing = 200  # Minimum vertical space between coins
	#while abs(random_y_position - last_coin_y) < vertical_spacing:
		## Recalculate the Y position with the shift and clamp
		#random_y_position = randi_range(min_y, max_y) + 300  # Shift downwards again
		#random_y_position = clamp(random_y_position, min_y, max_y)
#
	## Set the coin's Y position
	#new_coin.position.y = random_y_position
#
	## Update the last coin's Y position to prevent overlap with the next coin
	#last_coin_y = new_coin.position.y
#
	## Apply fade-in tween for the coin
	#var coin_tween = create_tween()
	#new_coin.modulate.a = 0  # Start fully transparent
	#coin_tween.tween_property(new_coin, "modulate:a", 1, 0.5)  # Fade in over 0.5 seconds
#
	## Update the last coin x position
	#last_coin_x = new_coin.position.x
#
	## Connect the coin's collected signal
	#new_coin.collected.connect(_on_coin_collected)
#
#
#
#func _on_coin_collected():
	#coins += 1  # Increase coin count
	#Global.totalcoins += 1  # Save it globally for the shop
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
	## Update total coins after the game ends
	#Global.save_data()  # Save the updated total coins
	#$CoinEarnedLabel.text = "Coins Earned: " + str(coins)  # Display coins earned in this session
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
#@export var coin_scene: PackedScene  # Assign the coin scene in the editor
#
#const COIN_SPACING_X = 600
#const COIN_SPACING_RANGE = 300  # Random offset between 400-600 pixels
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
#var spawn_enabled = false
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
	#coins = 0  # Reset the coins for the new game
	#$ScoreLabel.text = "SCORE: " + str(score)
	#$CoinLabel.text = "Coins: " + str(coins)
	#$CoinEarnedLabel.text = " "
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
	## Clear existing coins in the scene
	#for coin in get_tree().get_nodes_in_group("coins"):
		#coin.queue_free()  # Remove the coin from the scene
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
		#if not spawn_enabled and scroll >= 1500:
			#spawn_enabled = true  # Enable rock and coin spawning
#
		## Move both ground sprites
		#$Ground1.position.x -= SCROLL_SPEED
		#$Ground2.position.x -= SCROLL_SPEED
		#scroll += SCROLL_SPEED
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
		#return
#
	#var rock = get_pooled_rock()
	#rock.show()
	#rock.set_process(true)
#
	## Ensure proper spacing between rocks and spawn closer to the screen
	#var min_x = last_rock_x + ROCK_SPACING_X
	#rock.position.x = max(screen_size.x + 300, min_x)  # Reduce off-screen distance for better visibility
	#rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)
#
	## Fade-in effect for the rock
	#var rock_tween = create_tween()
	#rock.modulate.a = 0  # Start fully transparent
	#rock_tween.tween_property(rock, "modulate:a", 1, 0.5)  # Fade in over 0.5 seconds
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
	## Spawn a coin after rock generation
	#spawn_coin(last_rock_x)
#
##func spawn_coin(x_position):
	##var tries = 0
	##var valid_position = false
	##var new_coin: Node2D
	##
	##while not valid_position and tries < 100:  # Limit attempts to avoid infinite loops
		### Instantiate and add the coin
		##new_coin = coin_scene.instantiate()
		##add_child(new_coin)
		##new_coin.add_to_group("coins")
		##
		### Set initial coin position with offset
		##new_coin.position.x = x_position + randi_range(50, 400)
		##new_coin.position.y = randi_range(400, 1600)
##
		### Ensure it's not too close to rocks
		##if not is_coin_too_close_to_rocks(new_coin):
			##valid_position = true
		##else:
			##tries += 1
			##new_coin.queue_free()  # Remove invalid coin
##
	### Apply fade-in tween if valid position is found
	##if valid_position:
		##if is_instance_valid(new_coin):  # Check if coin is still valid
			##var coin_tween = create_tween()
			##new_coin.modulate.a = 0
			##coin_tween.tween_property(new_coin, "modulate:a", 1, 0.5)
			##last_coin_x = new_coin.position.x
			##new_coin.collected.connect(_on_coin_collected)
		##else:
			##print("Coin was freed before tween could be applied.")
	##else:
		##print("Failed to find a valid position for coin after 100 tries.")
#
#func spawn_coin(x_position):
	#var tries = 0
	#var valid_position = false
	#var new_coin: Node2D
	#
	#while not valid_position and tries < 100:  # Limit attempts to avoid infinite loops
		## Instantiate and add the coin
		#new_coin = coin_scene.instantiate()
		#add_child(new_coin)
		#new_coin.add_to_group("coins")
		#
		## Set initial coin position with offset
		#new_coin.position.x = x_position + randi_range(50, 400)
		#new_coin.position.y = randi_range(400, 1600)
#
		## Ensure it's not too close to rocks
		#if not is_coin_too_close_to_rocks(new_coin):
			#valid_position = true
		#else:
			#tries += 1
			#new_coin.queue_free()  # Remove invalid coin
#
	## Apply fade-in tween if valid position is found
	#if valid_position:
		#if is_instance_valid(new_coin):  # Check if coin is still valid
			#var coin_tween = create_tween()
			#new_coin.modulate.a = 0
			#coin_tween.tween_property(new_coin, "modulate:a", 1, 0.5)
			#last_coin_x = new_coin.position.x
			#new_coin.collected.connect(_on_coin_collected)
		#else:
			#print("Coin was freed before tween could be applied.")
	#else:
		#print("Failed to find a valid position for coin after 100 tries.")
#
## Helper function to check if the coin is too close to any rock's CollisionPolygon2D
#func is_coin_too_close_to_rocks(coin: Node2D) -> bool:
	## A buffer to ensure coins are not too close to rocks
	#var buffer = 300  
	#for rock in rocks:
		## Iterate through all CollisionPolygon2D nodes in the rock
		#for collision_polygon in rock.get_children():
			#if collision_polygon is CollisionPolygon2D:
				## Get the polygon of the CollisionPolygon2D
				#var polygon = collision_polygon.polygon
#
				## Calculate the bounding box of the polygon by expanding it manually
				#var min_x = polygon[0].x
				#var max_x = polygon[0].x
				#var min_y = polygon[0].y
				#var max_y = polygon[0].y
#
				## Find the min and max x and y values from the polygon points
				#for point in polygon:
					#min_x = min(min_x, point.x)
					#max_x = max(max_x, point.x)
					#min_y = min(min_y, point.y)
					#max_y = max(max_y, point.y)
#
				## Create a bounding box from the min and max values
				#var bounding_box = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
#
				## Add a 100px buffer to the bounding box
				#bounding_box.position -= Vector2(buffer, buffer)  # Expand the position
				#bounding_box.size += Vector2(buffer * 2, buffer * 2)  # Expand the size
#
				## Check if the coin's bounding box intersects with the rock's bounding box
				#var coin_rect = Rect2(coin.position - Vector2(16, 16), Vector2(32, 32))  # Assuming the coin is 32x32
				#if bounding_box.intersects(coin_rect):
					#return true  # Coin is too close to the rock
	#return false
#
#
#
## Function to check if a point is inside a polygon
#func is_point_in_polygon(point: Vector2, polygon: Array) -> bool:
	#var inside = false
	#var j = polygon.size() - 1
	#for i in range(polygon.size()):
		#var v0 = polygon[i]
		#var v1 = polygon[j]
		#if ((v0.y > point.y) != (v1.y > point.y)) and (point.x < (v1.x - v0.x) * (point.y - v0.y) / (v1.y - v0.y) + v0.x):
			#inside = !inside
		#j = i
	#return inside
#
#func is_coin_overlapping_rocks(coin: Node2D) -> bool:
	#for rock in rocks:
		## Assuming each rock has a CollisionPolygon2D
		#var collision_polygon = rock.get_node("CollisionPolygon2D")
		#if collision_polygon:
			## Get the polygon of the rock's CollisionPolygon2D
			#var polygon = collision_polygon.polygon
#
			## Convert the polygon points to global space
			#var global_polygon = []
			#for point in polygon:
				#global_polygon.append(rock.to_global(point))
#
			## Check the corners of the coin against the rock's polygon
			#var coin_rect = Rect2(coin.position - Vector2(16, 16), Vector2(32, 32))  # Coin size
			#var coin_corners = [
				#coin_rect.position,
				#coin_rect.position + Vector2(coin_rect.size.x, 0),
				#coin_rect.position + coin_rect.size,
				#coin_rect.position + Vector2(0, coin_rect.size.y)
			#]
#
			## Check each corner of the coin to see if it is inside the rock's polygon
			#for corner in coin_corners:
				#if is_point_in_polygon(rock.to_global(corner), global_polygon):
					#return true  # Coin is overlapping with a rock
	#return false
#
### Helper function to check if the coin is too close to rocks
##func is_coin_too_close_to_rocks(coin: Node2D) -> bool:
	##for rock in rocks:
		### Assuming each rock has a CollisionPolygon2D
		##var collision_polygon = rock.get_node("CollisionPolygon2D")
		##if collision_polygon:
			### Get the polygon of the rock's CollisionPolygon2D
			##var polygon = collision_polygon.polygon
##
			### Calculate the bounding box of the polygon by expanding it manually
			##var min_x = polygon[0].x
			##var max_x = polygon[0].x
			##var min_y = polygon[0].y
			##var max_y = polygon[0].y
##
			### Find the min and max x and y values from the polygon points
			##for point in polygon:
				##min_x = min(min_x, point.x)
				##max_x = max(max_x, point.x)
				##min_y = min(min_y, point.y)
				##max_y = max(max_y, point.y)
##
			### Create a bounding box from the min and max values
			##var bounding_box = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
##
			### Add a 100px buffer to the bounding box
			##bounding_box.position -= Vector2(100, 100)  # Expand the position
			##bounding_box.size += Vector2(200, 200)  # Expand the size
##
			### Check if the coin's bounding box intersects with the rock's bounding box
			##var coin_rect = Rect2(coin.position - Vector2(16, 16), Vector2(32, 32))  # Assuming the coin is 32x32
			##if bounding_box.intersects(coin_rect):
				##return true  # Coin is too close to the rock
	##return false
#
#
#
#func _on_coin_collected():
	#coins += 1  # Increase coin count
	#Global.totalcoins += 1  # Save it globally for the shop
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
	## Update total coins after the game ends
	##Global.totalcoins += coins  # Add the session's coins to the global total
	#Global.save_data()  # Save the updated total coins
	#$CoinEarnedLabel.text = "Coins Earned: " + str(coins)  # Display coins earned in this session
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

















#great code

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
	#coins = 0  # Reset the coins for the new game
	#$ScoreLabel.text = "SCORE: " + str(score)
	#$CoinLabel.text = "Coins: " + str(coins)
	#$CoinEarnedLabel.text = " "
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
#func spawn_coin(x_position):
	## Ensure coins are spaced apart
	#if x_position - last_coin_x < COIN_SPACING_X + randi_range(0, COIN_SPACING_RANGE):
		#return
#
	#var new_coin = coin_scene.instantiate()
	#add_child(new_coin)
#
	## Add the coin to a group so we can move it later
	#new_coin.add_to_group("coins")
#
	## Set initial coin position
	#new_coin.position.x = x_position + randi_range(50, 400)
	#new_coin.position.y = randi_range(400, 1600)
#
	## Ensure the coin doesn't spawn too close to rocks
	#var tries = 0
	#while is_coin_too_close_to_rocks(new_coin) and tries < 5:
		#new_coin.position.y = randi_range(400, 1600)  # Adjust Y position
		#tries += 1
#
	## Connect coin collection signal
	#new_coin.collected.connect(_on_coin_collected)
#
	## Update last coin position
	#last_coin_x = new_coin.position.x
#
#
#
## Helper function to check if the coin is too close to rocks
#func is_coin_too_close_to_rocks(coin: Node2D) -> bool:
	#for rock in rocks:
		#var rock_rect = Rect2(rock.position - Vector2(200, 200), Vector2(200, 200))  # 100px buffer around the rock
		#var coin_rect = Rect2(coin.position - Vector2(16, 16), Vector2(32, 32))  # Assuming a 32x32 coin
#
		#if rock_rect.intersects(coin_rect):
			#return true  # Coin is too close to a rock
	#return false
#
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
	#Global.totalcoins += 1  # Save it globally for the shop
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
	## Update total coins after the game ends
	##Global.totalcoins += coins  # Add the session's coins to the global total
	#Global.save_data()  # Save the updated total coins
	#$CoinEarnedLabel.text = "Coins Earned: " + str(coins)  # Display coins earned in this session
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
