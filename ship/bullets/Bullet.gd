extends Area2D

# No need to declare 'position' as it's built in
export var start_position = Vector2() # in grid coordinates
export var direction = Vector2()
onready var animation = get_node("AnimatedSprite")

var type # for the object's type (BULLET)
var grid # for the parent grid

# Set number of moves per second:
var time_passed = 0
var calls_per_sec = 20
# Use float here, otherwise this evaluates to 0.
var time_for_one_call = 1 / float(calls_per_sec)

# apply a velocity
# destroy when hits an edge
	
func _ready():
	# Define the parent grid, and type of object from what's enumerated in the parent grid.
	grid = get_parent()
	type = grid.block.BULLET
	position = grid.map_to_world(start_position) + grid.half_tile_size
		
	grid.grid[start_position.x][start_position.y] = type

	$AnimatedSprite.animation = "default"
	$AnimatedSprite.play()

func _process(delta):
	# Add the time passed since the last frame:
	time_passed += delta
			
	# Stop processing if time interval hasn't passed yet or no movement requested:
	if time_passed < time_for_one_call:
		return

	# Try and move character:
	time_passed -= time_for_one_call
		
	var target_data = grid.request_move(self, direction)
	var target_position = target_data[0]
	var target_block = target_data[1]
	match target_block:
		grid.block.EMPTY:
			move_to(target_position)
		grid.block.OBSTACLE, grid.block.EDGE_UD, grid.block.EDGE_LR:
			extinguish_bullet(target_position)
		grid.block.SHIP:
			# add code to remove bullet and kill player
			print("Bullet hit ship!")
			move_to(target_position)
		grid.block.ENEMY:
			# add code to remove bullet and kill enemy
			move_to(target_position)

func move_to(target_position):
	set_process(false)
	position = target_position
	set_process(true)
	
func extinguish_bullet(bullet_position):
	var bp = grid.world_to_map(bullet_position)
	$AnimatedSprite.animation = "hit_left"
	grid.grid[bp.x][bp.y] = grid.block.EMPTY
	yield(animation, "animation_finished")
	queue_free()

func _on_Bullet_area_entered(area):
#	print("Bullet has hit " + area.get_name())
	if area.get_name().match("*Enemy*"):
		$AnimatedSprite.stop()
		$CollisionShape2D.set_deferred("disabled", true)
		queue_free()