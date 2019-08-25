extends TileMap

# Code from GDQuest, https://www.youtube.com/watch?v=Yus8zAculWA
# https://github.com/GDquest/Godot-engine-tutorial-demos/tree/master/2018/06-09-grid-based-movement

var tile_size = get_cell_size()
var half_tile_size = tile_size / 2 # use this to put objects in centre of cells
var grid_size = Vector2(38, 23)
var grid = []
export var layout = "x"
export var block_style = "blue_square"
#export var enemy_layout = 1
onready var obstacle = preload("res://scenery/Obstacle.tscn")

# Enumerate things to help with autocomplete
enum block {EMPTY, SHIP, OBSTACLE, ENEMY, EDGE_UD, EDGE_LR, EDGE_CORNER}

func _ready():
	randomize()
	# Create a 2D array for the map data.
	# https://godotengine.org/qa/18011/initialize-an-array-of-size-n
	# Godot doesn't support 2D arrays directly!
	for i in range(grid_size.x):
		grid.append([])
		for j in range(grid_size.y):
			grid[i].append(null) # add nothing in the i'th column
			
	var ship = get_node("Ship")
	var enemy = get_node("EnemyHeart")

	# Create local variable to hold obstacle positions:
	var positions = []
	
	# Go through the whole grid and add a location to the position array if that cell is a 1:
	for j in range (0, grid_size.y):
		for i in range (0, grid_size.x):
			if query_layout(layout, i, j) == "1":
				positions.append(Vector2(i, j))
		
	# Place an obstacle in the random positions that have been defined:
	for pos in positions:
		var new_obstacle = obstacle.instance()
		new_obstacle.block_style = block_style
		new_obstacle.position = map_to_world(pos) + half_tile_size
		grid[pos.x][pos.y] = block.OBSTACLE
		add_child(new_obstacle)
	
func query_layout(chosen_layout, x, y):
	# Queries the chosen layout at the current position and return "0" or "1".
	
	# Code to query data from Zylann:
	# https://godotengine.org/qa/6491/read-&-write
	
	# Firstly check if there is a saved file.
	# The file must be in the format layout_x where x is the exact name of the layout.
	var file = File.new()
	if not file.file_exists("res://scenery/layouts/layout_" + str(chosen_layout) + ".txt"):
	    print("Error - no such file")
	    return
	
	# Open existing file
	if file.open("res://scenery/layouts/layout_" + str(chosen_layout) + ".txt", File.READ) != 0:
	    print("Error opening file")
	    return
	
	# Save the whole layout text as a single string:
	var layout_text = file.get_as_text()
	
	# Get the text at the y'th row by converting y to two digits then reading the text data file.
	# For example, row 16 is stored as:
	# 16x10000000011000000000000000011000000001
	y = str("%02d" % y)
	
	# Set up regex:
	var regex = RegEx.new()
	regex.compile(str(y) + "x\\d{38}")
	var row = ""
	
	row = regex.search(layout_text).get_string()
	return row[x + 3] # offsetting the first 3 characters of each row

func query_cell_contents(pos, direction):
	# Get the position of the place the player wants to move to:
	var grid_pos = world_to_map(pos) + direction
	
	# Return the contents of what's in the target cell.
	# Define a boolean array for top, bottom, left and right. For example, the top left corner is:
	# [true, false, true, false]
	var edges = [grid_pos.y < 0, grid_pos.y >= grid_size.y, grid_pos.x < 0, grid_pos.x >= grid_size.x]
	if edges.count(true) == 2:
		# Object is in a corner:
		return block.EDGE_CORNER
	elif edges[0] or edges[1]:
		# Object is at top or bottom:
		return block.EDGE_UD
	elif edges[2] or edges[3]:
		# Object is at left or right side:
		return block.EDGE_LR
	elif grid[grid_pos.x][grid_pos.y] == null:
		return block.EMPTY
	else:
		return grid[grid_pos.x][grid_pos.y]

func request_move(pawn, direction):
	# Request a move:
	#   Input an object and intended direction.
	#   Returns a position and a block type.
	#   Return nothing and a code if player cannot move there.
	#   Return new position if player can move there.
	
	# Get current and intended position:
	var cell_start = world_to_map(pawn.position)
	var cell_target = cell_start + direction
	
	# Set a variable to get whatever's in the target cell:
	var target_block = test_move(pawn, direction)
	
	if target_block == block.EMPTY:
		return [update_pawn_position(pawn, cell_start, cell_target), block.EMPTY]
	else:
		return [pawn.position, target_block]

func update_pawn_position(pawn, cell_start, cell_target):
	# Set the new cell's type:
	grid[cell_target.x][cell_target.y] = pawn.type
	# Set the old cell to empty:
	# This results in a bug if an object starts on an obstacle, making the obstacle act empty.
	grid[cell_start.x][cell_start.y] = block.EMPTY
	return map_to_world(cell_target) + half_tile_size

# Function to query what is in an adjoining cell from an object.
func test_move(pawn, direction):
	return query_cell_contents(pawn.position, direction)
	
#func get_cell_pawn(coordinates):
#	for node in get_children():
#		if world_to_map(node.position) == coordinates:
#			return(node)