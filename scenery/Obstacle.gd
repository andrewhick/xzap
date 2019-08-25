extends Node2D

# Make the obstacle block style editable outside this scene:
export var block_style = "blue_square"
# Shortcut to call the child sprite:
onready var sprite = get_node("BlockStyle")

func _ready():
	# The following works with load but not preload:
	sprite.texture = load("res://scenery/graphics/" + str(block_style) + ".png")