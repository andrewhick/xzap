extends Node2D

# Make the obstacle block style editable outside this scene:
export var block_style = "blue_square"
# Shortcut to call the child sprite:
onready var sprite = get_node("BlockStyle")

func _ready():
	# The following works with load but not preload:
	sprite.texture = load("res://assets/scenery/" + str(block_style) + ".png")
#	match block_style:
#		"blue_square":
#			# For some reason preload won't work with dynamic strings
#			sprite.texture = preload("res://assets/scenery/blue_square.png")
#		"simple_block":
#			sprite.texture = preload("res://assets/scenery/simple_block.png")
#		"green_triangle":
#			sprite.texture = preload("res://assets/scenery/green_triangle.png")
#		"blue_square_2":
#			sprite.texture = preload("res://assets/scenery/blue_square_2.png")
#		"yellow_square":
#			sprite.texture = preload("res://assets/scenery/yellow_square.png")