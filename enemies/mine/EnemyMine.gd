extends "res://enemies/Enemy.gd"

export var red = Color("8B2E24")
export var green = Color("3C8D00")
export var is_green = false

# Variables to use for forcefield
export var size_u = 4
export var size_d = 4
export var size_l = 4
export var size_r = 4
export var start_number = 3
export var ongoing_direction = Vector2()

# Load the appropriate animations for whether mine is green or red.
onready var positive_numbers = preload("res://enemies/mine/mine_countdown9.tres")
onready var negative_numbers = preload("res://enemies/mine/mine_neg_countdown9.tres")
onready var forcefield = preload("res://enemies/mine/Forcefield.tscn")
onready var current_animation = positive_numbers

func _ready():
	if is_green:
		set_green()
	else:
		current_animation = positive_numbers
		$AnimatedSprite.modulate = red
		$MineEdge.modulate = red

	$AnimatedSprite.set_sprite_frames(current_animation)
	$AnimatedSprite.frame = 9 - start_number
	can_be_hit = false # This is defined in the parent class
	
func set_green():
	# This deviates from the original game, to make the numbers distinguishable regardless of colour:
	current_animation = negative_numbers
	$AnimatedSprite.modulate = green
	$MineEdge.modulate = green
	$AnimatedSprite.set_sprite_frames(current_animation)

func _on_AnimatedSprite_animation_finished():
	# Store the current direction for later.
	ongoing_direction = direction
	# Stop moving the mine and create the forcefield.
	direction = Vector2()
	create_forcefield(size_u, size_d, size_l, size_r)

func create_forcefield(u, d, l, r):
	# Create a forcefield with defined size: up, down, left and right.
	# Assume all forcefields last the same duration.
#	print("Creating forcefield with mine going in " + str(ongoing_direction))
	var new_ff = forcefield.instance()
	new_ff.size_u = u
	new_ff.size_d = d
	new_ff.size_l = l
	new_ff.size_r = r
	new_ff.gpos = grid.world_to_map(position)
	new_ff.connect("forcefield_end", self, "_on_Forcefield_forcefield_end")
	call_deferred("add_child", new_ff)

func _on_Forcefield_forcefield_end():
	direction = ongoing_direction
	if direction == Vector2():
		print("Nudging mine which had come to a halt")
		direction = Vector2(1, 1)
	$AnimatedSprite.frame = 9 - start_number