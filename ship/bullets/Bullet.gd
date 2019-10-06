extends Area2D

# No need to declare 'position' as it's built in
export var start_position = Vector2() # in grid coordinates
export var direction = Vector2()
onready var animation = get_node("AnimatedSprite")
onready var global = get_node("/root/Global")

var type # for the object's type (BULLET)
var grid # for the parent grid
var is_rebounding = false

# Set number of moves per second:
var time_passed = 0
var calls_per_sec = 20
# Use float here, otherwise this evaluates to 0.
var time_for_one_call = 1 / float(calls_per_sec)

signal bullet_hit_ship
	
func _ready():
	self.connect("bullet_hit_ship", global, "_on_Bullet_bullet_hit_ship")
	
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
		grid.block.OBSTACLE, grid.block.EDGE_UD, grid.block.EDGE_LR, grid.block.PULSE:
			extinguish_bullet(target_position)
		grid.block.SHIP:
			# add code to remove bullet and kill player
			print("Bullet hit ship!")
			move_to(target_position)
		grid.block.ENEMY:
			# Signals will then remove or rebound bullet and kill enemy.
			move_to(target_position)
		grid.block.BULLET:
			if not is_rebounding:
				stop_bullet()
			else:
				move_to(target_position)

func move_to(target_position):
	set_process(false)
	position = target_position
	set_process(true)
	
func extinguish_bullet(bullet_position):
	grid.set_empty(bullet_position)
	$AnimatedSprite.animation = "hit_left"
	yield(animation, "animation_finished")
	queue_free()

func _on_Bullet_area_entered(area):
	# Keep this - useful for debugging:
	# print(self.get_name() + " has hit " + area.get_name())
	if area.get_name().match("*Enemy*"):
		if area.can_be_hit == false:
			rebound_bullet()
		else:
			stop_bullet()
			
	elif area.get_name().match("*Ship*"):
		# If bullet is at same position as ship, it's a hit, otherwise fine
		var ship_gpos = grid.world_to_map(area.position)
		var bullet_gpos = grid.world_to_map(self.position)
		print("Bullet at " + str(bullet_gpos) + " hit ship at " + str(ship_gpos))
		if ship_gpos == bullet_gpos:
			print("Rebounding bullet has hit ship")
			emit_signal("bullet_hit_ship")
			stop_bullet()
		
	elif area.get_name().match("*Bullet*") and not self.is_rebounding:
		# In the game, rebounding bullets take precedence over normal ones
		# so this removes any that isn't rebounding.
		# This is an additional chance to catch stray bullets from _process
		stop_bullet()
		
	elif area.get_name().match("*Pulse*"):
		stop_bullet()
		
	else:
		print("Bullet hit " + area.get_name() + " and I don't know what to do")
		
func rebound_bullet():
	print("Rebound bullet")
	grid.set_empty(position)
	is_rebounding = true
	direction = -direction
	$AnimatedSprite.animation = "rebound"
	
func stop_bullet():
	grid.set_empty(position)
	$AnimatedSprite.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	queue_free()