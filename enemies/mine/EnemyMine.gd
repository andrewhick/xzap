extends "res://enemies/Enemy.gd"

export var red = Color("8B2E24")
export var green = Color("3C8D00")
export var is_green = false
# Load the appropriate animations for whether mine is green or red.
onready var positive_numbers = preload("res://enemies/mine/mine_countdown9.tres")
onready var negative_numbers = preload("res://enemies/mine/mine_neg_countdown9.tres")

# Set the mine's rank. If 1, it is green and will be shot first.
export var rank = 1

func _ready():
	if is_green:
		# This deviates from the original game, to make the numbers distinguishable regardless of colour:
		$AnimatedSprite.set_sprite_frames(negative_numbers)
		$AnimatedSprite.modulate = green
		$MineEdge.modulate = green
	else:
		$AnimatedSprite.set_sprite_frames(positive_numbers)
		$AnimatedSprite.modulate = red
		$MineEdge.modulate = red
		
# Add code for:

# Spawn forcefield and restart animation when finished
# Shoot green mine, move remaining mines up a rank, make rank 1 green