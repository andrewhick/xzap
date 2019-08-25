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
onready var obstacle = preload("res://scenes/Obstacle.tscn")

# Enumerate things to help with autocomplete
enum block {EMPTY, SHIP, OBSTACLE, ENEMY, EDGE_UD, EDGE_LR, EDGE_CORNER}

func _ready():
	randomize()
	# Create a 2D array for the map data.
	# This seems to be the best way to do it because Godot doesn't support 2D arrays directly.
	for i in range(grid_size.x):
		grid.append([])
		for j in range(grid_size.y):
			grid[i].append(null) # add nothing in the i'th column
			
	var ship = get_node("Ship")
	var enemy = get_node("EnemyHeart")
	
#	var layout = LayoutX.instance()
#	add_child(layout)

	# Create obstacles:
	var positions = [] # local variable to create obstacles
	
	add_layout(layout)
	
	# Choose random locations to place obstacles:
	for n in range (75):
		var grid_pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
		if not grid_pos in positions:
			positions.append(grid_pos)
		
	# Place an obstacle in the random positions that have been defined:
	for pos in positions:
		var new_obstacle = obstacle.instance()
		new_obstacle.block_style = "yellow_square"
		new_obstacle.position = map_to_world(pos) + half_tile_size
		grid[pos.x][pos.y] = block.OBSTACLE
		add_child(new_obstacle)
		
func add_layout(chosen_layout):
	# load data from a file based on layout
	var layout_text = load("res://assets/scenery/layouts/layout_x.txt")
	print(str(layout_text))

func query_cell_contents(pos, direction):
	# Get the position of the place the player wants to move to:
	var grid_pos = world_to_map(pos) + direction
	
	# Return the contents of what's in the target cell.
	# Define edge vector for top, bottom, left and right:
	var edges = [grid_pos.y < 0, grid_pos.y >= grid_size.y, grid_pos.x < 0, grid_pos.x >= grid_size.x]
#	print ("Up Down Left Right: " + str(edges))
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
	
#func get_cell_pawn(coordinates):
#	for node in get_children():
#		if world_to_map(node.position) == coordinates:
#			return(node)

# Request a move:
# Input an object and intended direction.
# Returns a position and a block type.
# Return nothing and a code if player cannot move there.
# Return new position if player can move there.
func request_move(pawn, direction):
	# Get current and intended position:
	var cell_start = world_to_map(pawn.position)
	var cell_target = cell_start + direction
	# Set a variable to test whether a move is possible or not
	var target_block = test_move(pawn, direction)
	
	if target_block == block.EMPTY:
		# Need to find a way of not doing this when testing a cell:
		return [update_pawn_position(pawn, cell_start, cell_target), block.EMPTY]
	else:
#		print (str(pawn.get_name()) + " has hit a thing with index " + str(pawn.type))
		return [pawn.position, target_block]

func update_pawn_position(pawn, cell_start, cell_target):
	grid[cell_target.x][cell_target.y] = pawn.type
	grid[cell_start.x][cell_start.y] = block.EMPTY
	return map_to_world(cell_target) + half_tile_size

# Function to query what is in an adjoining cell from an object.
func test_move(pawn, direction):
	return query_cell_contents(pawn.position, direction)