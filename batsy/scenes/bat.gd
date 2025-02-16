



extends CharacterBody2D

const GRAVITY : int = 1000
const MAX_VEL : int = 600
const FLAP_SPEED : int = -550
var flying : bool = false
var falling : bool = false
const START_POS = Vector2(100, 700)

var selected_character = "default"  # Default character (global or hardcoded)

func _ready():
	# Load saved character selection
	if Global.selected_character != "":
		selected_character = Global.selected_character  # Ensure this exists and has a value
	load_character_animation()
	reset()

func reset():
	falling = false
	flying = false
	position = START_POS
	set_rotation(0)  # Ensure the rotation is reset to 0

func _physics_process(delta):
	if flying or falling:
		velocity.y += GRAVITY * delta
		if velocity.y > MAX_VEL:
			velocity.y = MAX_VEL

		# Set rotation to 0 for a level bat when flying and falling, no tilting
		if flying:
			set_rotation(0)  # Prevent tilting when flying
			get_node("AnimatedSprite2D").play()  # Play flying animation
		elif falling:
			set_rotation(PI / 2)  # Optional: rotation for falling (upside down)
			get_node("AnimatedSprite2D").stop()  # Stop flying animation
		move_and_collide(velocity * delta)
	else:
		get_node("AnimatedSprite2D").stop()

func flap():
	velocity.y = FLAP_SPEED

func load_character_animation():
	var sprite = get_node("AnimatedSprite2D")  # Get the AnimatedSprite2D node

	# Create a new SpriteFrames resource
	var frames = SpriteFrames.new()

	# **Create the 'flying' animation before adding frames**
	frames.add_animation("flying")
	frames.set_animation_loop("flying", true)  # Ensure the animation loops

	# Define paths to the flying animation frames
	var flying_frames = [
		"res://characters/" + selected_character + "/bat1.png",
		"res://characters/" + selected_character + "/bat2.png",
		"res://characters/" + selected_character + "/bat3.png"
	]

	# Add frames to the 'flying' animation
	for frame in flying_frames:
		if FileAccess.file_exists(frame):
			frames.add_frame("flying", load(frame))
		else:
			print("Missing frame: " + frame)

	# Assign the frames to the AnimatedSprite2D node
	sprite.frames = frames

	# Set the animation and play it
	sprite.animation = "flying"
	sprite.play()


#


















#extends CharacterBody2D
#
#const GRAVITY : int = 1000
#const MAX_VEL : int = 600
#const FLAP_SPEED : int = -550
#var flying : bool = false
#var falling : bool = false
#const START_POS = Vector2(100, 700)
#
#var selected_character = "default"  # Default character (global or hardcoded)
#
#func _ready():
	## Load saved character selection
	#if Global.selected_character != "":
		#selected_character = Global.selected_character  # Ensure this exists and has a value
	#load_character_animation()
	#reset()
	#
	##var light = $PointLight2D  # Assuming PointLight2D is a child node of Bat
	##light.rotation = 0  # Set the rotation to 0, so it doesn't follow the bat's rotation
#
#func reset():
	#falling = false
	#flying = false
	#position = START_POS
	#set_rotation(0)
#
#func _physics_process(delta):
	#if flying or falling:
		#velocity.y += GRAVITY * delta
		#if velocity.y > MAX_VEL:
			#velocity.y = MAX_VEL
		#if flying:
			#set_rotation(deg_to_rad(velocity.y * 0.05))
			#get_node("AnimatedSprite2D").play()  # Use get_node() to reference the AnimatedSprite2D node
		#elif falling:
			#set_rotation(PI / 2)
			#get_node("AnimatedSprite2D").stop()
		#move_and_collide(velocity * delta)
	#else:
		#get_node("AnimatedSprite2D").stop()
#
#func flap():
	#velocity.y = FLAP_SPEED
#
#func load_character_animation():
	#var sprite = get_node("AnimatedSprite2D")  # Get the AnimatedSprite2D node
#
	## Create a new SpriteFrames resource
	#var frames = SpriteFrames.new()
#
	## **Create the 'flying' animation before adding frames**
	#frames.add_animation("flying")
	#frames.set_animation_loop("flying", true)  # Ensure the animation loops
#
	## Define paths to the flying animation frames
	#var flying_frames = [
		#"res://characters/" + selected_character + "/bat1.png",
		#"res://characters/" + selected_character + "/bat2.png",
		#"res://characters/" + selected_character + "/bat3.png"
	#]
#
	## Add frames to the 'flying' animation
	#for frame in flying_frames:
		#if FileAccess.file_exists(frame):
			#frames.add_frame("flying", load(frame))
		#else:
			#print("Missing frame: " + frame)
#
	## Assign the frames to the AnimatedSprite2D node
	#sprite.frames = frames
#
	## Set the animation and play it
	#sprite.animation = "flying"
	#sprite.play()
