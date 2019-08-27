extends Area2D

var type # for the object's type (ENEMY)
var grid # for the parent grid
export var direction = Vector2(-1, 1)
var alt_direction = direction
var target_data
var target_position
var target_block
var diversion_block
export var start_position = Vector2(30, 5)

# Set number of moves per second:
var time_passed = 0
var calls_per_sec = 4
# Use float here, otherwise this evaluates to 0.
var time_for_one_call = 1 / float(calls_per_sec)

func _ready():
	# Define the parent grid, and type of object from what's enumerated in the parent grid.
	grid = get_parent()
	type = grid.block.ENEMY
	grid.grid[start_position.x][start_position.y] = type
	
	position = grid.map_to_world(start_position) + grid.half_tile_size
	$AnimatedSprite.play()

func _process(delta):
	# Add the time passed since the last frame:
	time_passed += delta
	
	# Check if time interval has passed. If so, try and move character:
	if time_passed < time_for_one_call:
		return

	time_passed -= time_for_one_call

	# Now try and move enemy.
	# As each enemy has the same movement, will eventually want to move this code to a separate scene:
	
	# 1st move attempt:
	target_data = grid.request_move(self, direction)
	target_position = target_data[0]
	target_block = target_data[1]
	match target_block:
		grid.block.EMPTY:
			move_to(target_position)
			return
		grid.block.EDGE_CORNER:
			# Rebound completely from a corner:
			direction = -direction
			alt_direction = direction
		grid.block.EDGE_UD:
			# Reverse y direction only if hitting top/bottom:
			direction.y = -direction.y
			alt_direction = direction
		grid.block.EDGE_LR:
			# Reverse x direction only if hitting left/right:
			direction.x = -direction.x
			alt_direction = direction
		grid.block.OBSTACLE, grid.block.SHIP, grid.block.ENEMY, grid.block.BULLET:
			# Try moving sideways if can't move diagonally:
			if test_direction(self, Vector2(direction.x, 0)):
				alt_direction = Vector2(direction.x, 0)
			# Otherwise, try vertically:
			elif test_direction(self, Vector2(0, direction.y)):
				alt_direction = Vector2(0, direction.y)
			else:
				# Reverse direction 180 degrees if stuck in a corner:
				direction = -direction
				alt_direction = direction

	# 2nd move attempt, possibly in an alternative direction:
	# On the assumption that we've made the best move possible, move the enemy.
	# If the enemy is fully trapped then it stays still.
	target_data = grid.request_move(self, alt_direction)
	target_position = target_data[0]
	target_block = target_data[1]
	move_to(target_position)

# Check an alternative direction and return true if vacant:
func test_direction(object, direction_to_test):
	diversion_block = grid.test_move(object, direction_to_test)
	return diversion_block == grid.block.EMPTY

func move_to(target_position):
	set_process(false)
	position = target_position
	set_process(true)
		
#func _on_Player_body_entered(body):
#	emit_signal("hit")
#	# Set the collision to disabled so it doesn't keep happening.
#	# set_deferred causes it to wait until safe to disable the collision.
#	$CollisionShape2D.set_deferred("disabled", true)