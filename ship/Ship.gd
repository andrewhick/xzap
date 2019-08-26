extends Area2D

# Code adapted from the following:
# - Godot's Dodge The Creeps tutorial
# https://docs.godotengine.org/en/3.1/getting_started/step_by_step/your_first_game.html#player-scene
# - Nathan Lovato's GDQuest tutorials:
# https://www.youtube.com/watch?v=BWBD3i00AfM
# https://github.com/GDquest/Godot-engine-tutorial-demos/tree/master/2018/06-09-grid-based-movement
# - Custom timer from sparks:
# https://godotengine.org/qa/14012/answered-how-to-change-update-speed

var type # for the object's type (SHIP)
var grid # for the parent grid
var direction = Vector2()
var face_direction = Vector2(0, -1) # face up by default

# Set number of moves per second:
var time_passed = 0
var calls_per_sec = 11
# Use float here, otherwise this evaluates to 0.
var time_for_one_call = 1 / float(calls_per_sec)

func _ready():
	# Define the parent grid, and type of object from what's enumerated in the parent grid.
	grid = get_parent()
	type = grid.block.SHIP
	position = grid.map_to_world(Vector2(19, 12)) + grid.half_tile_size

	$AnimatedSprite.animation = "up"
	$AnimatedSprite.flip_v = false
	$AnimatedSprite.flip_h = false
	$AnimatedSprite.play()

func _input(event):
	# Change the animation and flip direction based on input
	if event.is_action_pressed("ui_accept"):
		print("Ready to fire at position " + str(grid.world_to_map(position)) + " and direction " + str(face_direction))
		grid.fire_bullet(grid.world_to_map(position), face_direction)
	if event.is_action_pressed("ui_up"):
		$AnimatedSprite.animation = "up"
		face_direction = Vector2(0, -1)
		$AnimatedSprite.flip_v = false
		$AnimatedSprite.flip_h = false
	elif event.is_action_pressed("ui_down"):
		$AnimatedSprite.animation = "up" # reuse :up" animation for down
		face_direction = Vector2(0, 1)
		$AnimatedSprite.flip_v = true
		$AnimatedSprite.flip_h = false
	if event.is_action_pressed("ui_left"):
		$AnimatedSprite.animation = "right" # reuse "right" animation for left
		face_direction = Vector2(-1, 0)
		$AnimatedSprite.flip_v = false
		$AnimatedSprite.flip_h = true
	elif event.is_action_pressed("ui_right"):
		$AnimatedSprite.animation = "right"
		face_direction = Vector2(1, 0)
		$AnimatedSprite.flip_v = false
		$AnimatedSprite.flip_h = false

func _process(delta):
	# Add the time passed since the last frame:
	time_passed += delta

	# Reset the direction:
	direction = Vector2()

	if Input.is_action_pressed("ui_up"):
		direction.y = -1
	elif Input.is_action_pressed("ui_down"):
		direction.y = 1
	if Input.is_action_pressed("ui_left"):
		direction.x = -1
	elif Input.is_action_pressed("ui_right"):
		direction.x = 1
		
	# Prevent diagonal motion and prioritise left/right motion, as per the game
	if direction.y != 0 and direction.x != 0:
		direction.y = 0
			
	# Stop processing if time interval hasn't passed yet or no movement requested:
	if time_passed < time_for_one_call:
		return

	# Try and move character:
	time_passed -= time_for_one_call
	if direction == Vector2():
		return
		
	var target_data = grid.request_move(self, direction)
	var target_position = target_data[0]
	var target_block = target_data[1]
	if target_block == grid.block.EMPTY:
#		print("Moving to: " + str(grid.world_to_map(target_position)))
		move_to(target_position)

func move_to(target_position):
	set_process(false)
	position = target_position
	set_process(true)
		
#func _on_Player_body_entered(body):
#	# The body argument above flags an error because it's never used.
#	emit_signal("hit")
#	# Set the collision to disabled so it doesn't keep happening.
#	# set_deferred causes it to wait until safe to disable the collision.
#	$CollisionShape2D.set_deferred("disabled", true)