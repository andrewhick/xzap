extends Area2D

# No need to declare 'position' as it's built in
export var start_position = Vector2() # in GRID coordinates
export var direction = Vector2()

var grid # for the parent grid

# Set number of moves per second:
var time_passed = 0
var move_number = 0
var calls_per_sec = 20
# Use float here, otherwise this evaluates to 0.
var time_for_one_call = 1 / float(calls_per_sec)

func _ready():
	# Define the parent grid, and type of object from what's enumerated in the parent grid.
	grid = get_parent()
	position = grid.map_to_world(start_position) + grid.half_tile_size
	set_process(true)
		
func _process(delta):
	# Add the time passed since the last frame:
	time_passed += delta
	
	move_number += 1
	if move_number == 2:
		# Pause briefly at the 2nd step:
		time_passed -= 0.5

	# Stop processing if time interval hasn't passed yet or no movement requested:
	if time_passed < time_for_one_call:
		return

	# Try and move character:
	time_passed -= time_for_one_call

	var target_data = grid.force_move(self, direction)
	var target_position = target_data[0]
	var target_block = target_data[1]
	match target_block:
		grid.block.EMPTY:
			# Move and show the explode sprite:
			$Sprite.visible = true
			move_to(target_position)
		grid.block.EDGE_UD, grid.block.EDGE_LR:
			# Extinguish the explosion when it hits an edge
			$CollisionShape2D.set_deferred("disabled", true)
			queue_free()
		grid.block.OBSTACLE, grid.block.ENEMY, grid.block.SHIP, grid.block.BULLET, grid.block.PULSE:
			# Still move, but don't show the sprite
			$Sprite.visible = false
			move_to(target_position)

func move_to(target_position):
	set_process(false)
	position = target_position
	set_process(true)