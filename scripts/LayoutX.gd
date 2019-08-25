extends TileMap

export var block_style = "blue_square"
# will need a variable for mine shapes
var grid_scene # for the parent grid
var grid_size

# This is probably a really bad way to store level data but I like it.
# 0 = gap
# 1 = wall
# s = ship
# h = heart
# c = chaser

# I want to create an array of size 23 here but I can only do this with a for loop as per:
# https://godotengine.org/qa/18011/initialize-an-array-of-size-n
#var d = [] # use for cell data
#d[0] = "10101010101010101010101010101010101010101010101010101010101010101010"
#d[1] = "10000000000000000000000000000000000000000000000000000000000000000001"

func _ready():
	# Define the parent grid, and type of object from what's enumerated in the parent grid.
	grid_scene = get_parent()
	

	
	# For some reason this for statement is not working with child as the variable.
#	for child in get_children():
#	set_cellv(world_to_map(ship.position), ship.type)
#	set_cellv(world_to_map(enemy.position), enemy.type)