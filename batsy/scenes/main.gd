#extends Node
#
##@export var rock_scene : PackedScene
#@export var rock_scenes : Array[PackedScene]
#@export var coin_scene : PackedScene  # Your coin scene
#var coins_collected : int = 0  # Track collected coins
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
##func generate_rocks():
	##if rock_scenes.is_empty():
		##return  # Prevent errors if no rock scenes are assigned
##
	### Get a rock from the pool (existing or new)
	##var rock = get_pooled_rock()
	##rock.show()  # Make sure the rock is visible
	##rock.set_process(true)
##
	### Ensure consistent spacing between rocks
	##var min_x = last_rock_x + ROCK_SPACING_X
	##rock.position.x = max(screen_size.x + ROCK_DELAY, min_x)
	##
	##rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)
##
	### Connect signals only if not already connected
	##if not rock.hit.is_connected(bat_hit):
		##rock.hit.connect(bat_hit)
	##if not rock.scored.is_connected(scored):
		##rock.scored.connect(scored)
##
	### **Do not re-add the rock as a child if it was pooled**
	##if rock.get_parent() == null:
		##add_child(rock)  # Only add if it's a new instance
##
	##rocks.append(rock)
##
	### Update last rock position
	##last_rock_x = rock.position.x
#
## In your generate_rocks() function
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
	## Spawn coins around the rock
	#spawn_coins(rock)
#
	## Update last rock position
	#last_rock_x = rock.position.x
#
## Function to spawn coins in the coin zones around the rock
#func spawn_coins(rock):
	## Assuming rock has a "CoinZone" child (CollisionShape2D or Area)
	#var coin_zones = rock.get_children()
	#
	#for zone in coin_zones:
		#if zone is Area2D or CollisionShape2D:
			## Randomly decide if a coin should spawn in this zone
			#if randi() % 2 == 0:  # 50% chance to spawn a coin
				#var coin = coin_scene.instantiate()
				#var zone_pos = zone.position
				#coin.position = zone_pos + Vector2(randi_range(-50, 50), randi_range(-50, 50))  # Add some randomness to position within the zone
				#add_child(coin)
				#
				## Use a lambda to pass the coin argument in the connect call
				#coin.connect("body_entered", Callable(self, "_on_coin_collected").bind(coin))  # Pass coin as argument using .bind()
#
## Coin collection signal handler
#func _on_coin_collected(coin):
	#coins_collected += 1
	#print("Coins collected: ", coins_collected)
	#coin.queue_free()  # Remove coin after collection
	#update_shop_coins()  # Update coin count in the shop
#
## Update the coin count in the shop
#func update_shop_coins():
	#var shop = get_node("/root/Shop")  # Adjust the path to your Shop node
	#shop.coins = coins_collected
	#shop.update_coins_label()
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


extends Node

#@export var rock_scene : PackedScene
@export var rock_scenes : Array[PackedScene]

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
	$ScoreLabel.text = "SCORE: " + str(score)
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
	rock.show()  # Make sure the rock is visible
	rock.set_process(true)

	# Ensure consistent spacing between rocks
	var min_x = last_rock_x + ROCK_SPACING_X
	rock.position.x = max(screen_size.x + ROCK_DELAY, min_x)
	
	rock.position.y = (screen_size.y - ground_height) / 2 + randi_range(-ROCK_RANGE, ROCK_RANGE)

	# Connect signals only if not already connected
	if not rock.hit.is_connected(bat_hit):
		rock.hit.connect(bat_hit)
	if not rock.scored.is_connected(scored):
		rock.scored.connect(scored)

	# **Do not re-add the rock as a child if it was pooled**
	if rock.get_parent() == null:
		add_child(rock)  # Only add if it's a new instance

	rocks.append(rock)

	# Update last rock position
	last_rock_x = rock.position.x

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
