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
const SCROLL_SPEED : int = 5
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
	scroll_speed = BASE_SPEED  # Reset scroll speed
	$ScoreLabel.text = "SCORE: " + str(score)
	$CoinLabel.text = "Coins: " + str(coins)
	$CoinEarnedLabel.text = " "
	$Menu.hide()

	# Reset object pools
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

#func new_game():
	#game_running = false
	#game_over = false
	#score = 0
	#scroll = 0
	#coins = 0  
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
	#$Bat.selected_character = Global.selected_character
	#$Bat.load_character_animation()
	#$Bat.reset()
	#
	## Clear existing coins
	#for coin in get_tree().get_nodes_in_group("coins"):
		#pool_coin(coin)  # Pool instead of freeing


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


const BASE_SPEED = 600  # Pixels per second
var scroll_speed = BASE_SPEED  

func _process(delta):
	if game_running:
			
		if not spawn_enabled and scroll >= 1500:
			spawn_enabled = true  

		# Adjust scroll speed based on delta
		var adjusted_speed = scroll_speed * delta  

		# Move ground
		$Ground1.position.x -= adjusted_speed
		$Ground2.position.x -= adjusted_speed
		scroll += adjusted_speed

		# Reset ground
		if $Ground1.position.x <= -ground_width:
			$Ground1.position.x = $Ground2.position.x + ground_width
		if $Ground2.position.x <= -ground_width:
			$Ground2.position.x = $Ground1.position.x + ground_width

		# Move rocks
		for rock in rocks:
			rock.position.x -= adjusted_speed

		# Move and pool coins
		for coin in get_tree().get_nodes_in_group("coins"):
			coin.position.x -= adjusted_speed
			if coin.position.x < -100:  # Off-screen left
				pool_coin(coin)  

#func _process(_delta):
	#if game_running:
		#if not spawn_enabled and scroll >= 1500:
			#spawn_enabled = true  
#
		 ##Move ground
		#$Ground1.position.x -= SCROLL_SPEED
		#$Ground2.position.x -= SCROLL_SPEED
		#scroll += SCROLL_SPEED
		##var adjusted_speed = SCROLL_SPEED * delta
		##$Ground1.position.x -= adjusted_speed
		##$Ground2.position.x -= adjusted_speed
		##scroll += adjusted_speed
#
		## Reset ground
		#if $Ground1.position.x <= -ground_width:
			#$Ground1.position.x = $Ground2.position.x + ground_width
		#if $Ground2.position.x <= -ground_width:
			#$Ground2.position.x = $Ground1.position.x + ground_width
#
		## Move rocks
		#for rock in rocks:
			#rock.position.x -= SCROLL_SPEED
#
		## Move and pool coins
		#for coin in get_tree().get_nodes_in_group("coins"):
			#coin.position.x -= SCROLL_SPEED
			#if coin.position.x < -100:  # Off-screen left
				#pool_coin(coin)  

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

const MIN_ROCK_DISTANCE = 300
const MAX_ROCK_DISTANCE = 500

func generate_rocks():
	if rock_scenes.is_empty():
		return

	if coin_count < MAX_COINS_PER_CYCLE and randi_range(1, TOTAL_SPAWNS_PER_CYCLE) <= int(MAX_COINS_PER_CYCLE * 0.5):
		spawn_coin(last_rock_x)  
		coin_count += 1  
	else:
		var rock = get_pooled_rock()
		rock.show()
		rock.set_process(true)

		# Ensure rocks have a consistent spacing range
		var min_x = last_rock_x + MIN_ROCK_DISTANCE
		var max_x = last_rock_x + MAX_ROCK_DISTANCE
		rock.position.x = max(screen_size.x + 300, randi_range(min_x, max_x))
		rock.position.y = int((screen_size.y - ground_height) * 0.5) + randi_range(-ROCK_RANGE, ROCK_RANGE)

		if not rock.hit.is_connected(bat_hit):
			rock.hit.connect(bat_hit)
		if not rock.scored.is_connected(scored):
			rock.scored.connect(scored)

		rocks.append(rock)
		last_rock_x = rock.position.x  

	if coin_count >= MAX_COINS_PER_CYCLE:
		coin_count = 0  








#func generate_rocks():
	#if rock_scenes.is_empty():
		#return
#
	##if coin_count < MAX_COINS_PER_CYCLE and randi_range(1, TOTAL_SPAWNS_PER_CYCLE) <= MAX_COINS_PER_CYCLE:
	#if coin_count < MAX_COINS_PER_CYCLE and randi_range(1, TOTAL_SPAWNS_PER_CYCLE) <= int(MAX_COINS_PER_CYCLE * 0.5):
		#spawn_coin(last_rock_x)  
		#coin_count += 1  
	#else:
		#var rock = get_pooled_rock()
		#rock.show()
		#rock.set_process(true)
##
		##var min_x = last_rock_x + ROCK_SPACING_X
		#var min_x = last_rock_x + ROCK_SPACING_X + 100  # Extra buffer
#
		#rock.position.x = max(screen_size.x + 300, min_x)
		#rock.position.y = int((screen_size.y - ground_height) * 0.5) + randi_range(-ROCK_RANGE, ROCK_RANGE)
#
#
		##var rock_tween = create_tween()
		##rock.modulate.a = 0  
		##rock_tween.tween_property(rock, "modulate:a", 1, 0.5)  
#
		#if not rock.hit.is_connected(bat_hit):
			#rock.hit.connect(bat_hit)
		#if not rock.scored.is_connected(scored):
			#rock.scored.connect(scored)
#
		#rocks.append(rock)
		#last_rock_x = rock.position.x  
#
	#if coin_count >= MAX_COINS_PER_CYCLE:
		#coin_count = 0  

var last_coin_y = -1  

func get_pooled_coin():
	for coin in coin_pool:
		if is_instance_valid(coin) and not coin.visible:
			coin.position = Vector2(-1000, -1000)  # Reset position before reuse
			return coin

	#for coin in coin_pool:
		## Ensure the coin is a valid instance and is not visible
		#if is_instance_valid(coin) and not coin.visible:
			#return coin
	
	var new_coin = coin_scene.instantiate()
	add_child(new_coin)
	coin_pool.append(new_coin)
	return new_coin



func spawn_coin(x_position):
	var min_x_position = x_position + ROCK_SPACING_X
	var new_coin = get_pooled_coin()
	new_coin.show()
	new_coin.set_process(true)
	new_coin.add_to_group("coins")


	new_coin.position.x = min_x_position + 300

	#var vertical_buffer = 50
	var vertical_buffer = 400
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

	#var coin_tween = create_tween()
	#new_coin.modulate.a = 0
	#coin_tween.tween_property(new_coin, "modulate:a", 1, 0.5)

	# Prevent duplicate signal connections
	if not new_coin.collected.is_connected(_on_coin_collected):
		new_coin.collected.connect(_on_coin_collected)


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
