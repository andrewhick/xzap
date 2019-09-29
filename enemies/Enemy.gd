extends Area2D

# This script covers the base movement for an enemy heart.
# More complex enemies have their own script which inherits from this one.

var type # for the object's type (ENEMY)
var grid # for the parent grid
var alt_direction = direction
var target_data
var target_position
var target_block
var diversion_block
export var enemy_type = "heart"
export var start_position = Vector2(30, 5)
export var direction = Vector2(-1, 1)
onready var global = get_node("/root/Global")

# Set number of moves per second:
var time_passed = 0
export var calls_per_sec = 4
# Use float here, otherwise this evaluates to 0.
var time_for_one_call = 1 / float(calls_per_sec)

signal enemy_created
signal enemy_hit
signal enemy_hit_ship

func _ready():
	self.connect("enemy_created", global, "_on_Enemy_enemy_created")
	self.connect("enemy_hit", global, "_on_Enemy_enemy_hit")
	self.connect("enemy_hit_ship", global, "_on_Enemy_enemy_hit_ship")
	
	# Define the parent grid, and type of object from what's enumerated in the parent grid.
	grid = get_parent()
	type = grid.block.ENEMY
	grid.grid[start_position.x][start_position.y] = type
	position = grid.map_to_world(start_position) + grid.half_tile_size
	$AnimatedSprite.play()
	emit_signal("enemy_created")

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
		grid.block.OBSTACLE, grid.block.SHIP, grid.block.ENEMY, grid.block.BULLET, grid.block.PULSE:
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
		
func _on_Enemy_area_entered(area):
	# area is the thing that entered the enemy's space
#	print("Enemy " + enemy_type + " got hit by ", area.get_name())
	if area.get_name().match("*Bullet*"):
		emit_signal("enemy_hit", area.get_name())
		stop_enemy()
		grid.explode_enemy(position)
		queue_free()
		
	if area.get_name().match("*Ship*"): # (and not a red mine)
		stop_enemy()
		emit_signal("enemy_hit", area.get_name())
		emit_signal("enemy_hit_ship")
		queue_free()
		
func stop_enemy():
	$AnimatedSprite.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	grid.set_empty(position)