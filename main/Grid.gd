extends TileMap

# Code from GDQuest, https://www.youtube.com/watch?v=Yus8zAculWA
# https://github.com/GDquest/Godot-engine-tutorial-demos/tree/master/2018/06-09-grid-based-movement

var tile_size = get_cell_size()
var half_tile_size = tile_size / 2 # use this to put objects in centre of cells
var grid_size = Vector2(38, 23)
var grid = []
var level_data = {}
export var level = 1
export var layout = "x"
export var block_style = "blue_square"
# Need a way to generate enemy data from a file - JSON or otherwise.
onready var global = get_node("/root/Global")
onready var ship = preload("res://ship/Ship.tscn")
onready var obstacle = preload("res://scenery/Obstacle.tscn")
onready var bullet = preload("res://ship/bullets/Bullet.tscn")
onready var enemy_heart = preload("res://enemies/heart/EnemyHeart.tscn")
onready var enemy_mine = preload("res://enemies/mine/EnemyMine.tscn")
onready var explode = preload("res://enemies/explode/Explode.tscn")
onready var label = preload("res://main/CustomLabel.tscn")
onready var playarea = get_parent()

# Enumerate things to help with autocomplete
enum block {EMPTY, SHIP, OBSTACLE, ENEMY, EDGE_UD, EDGE_LR, EDGE_CORNER, BULLET, PULSE}

signal level_start # triggered when level has been drawn
signal next_level # triggered when you need global to trigger a new level
signal set_red_screen # triggered after game over animation

func _ready():
	# Connect signals. Use global.connect if signal comes from global.
	# Use self.connect if signal comes from grid.
	global.connect("level_complete", self, "_on_Global_level_complete")
	global.connect("lose_a_life", self, "_on_Global_lose_a_life")
	global.connect("game_over", self, "_on_Global_game_over")
	global.connect("new_level", self, "_on_Global_new_level")
	self.connect("level_start", global, "_on_Grid_level_start")
	self.connect("next_level", global, "_on_Grid_next_level")
	randomize()
	create_level(level)
	
func _input(event):
	# If tab is pressed then debug:
	if event.is_action_pressed("ui_focus_next"):
		debug()
	
func create_level(new_level):
	get_level_data(new_level)
	clear_nodes()
	draw_level()
	
func _on_Global_new_level(new_level):
	level = new_level
	create_level(level)
	
func get_level_data(level_no):
	# gets data for the current level as a JSON file.
	# Code based on: https://godotengine.org/qa/8291/how-to-parse-a-json-file-i-wrote-myself
	var file = File.new()
	file.open("res://level_data.json", file.READ)
	var text = file.get_as_text()
	level_data = JSON.parse(text).result
	file.close()
	# Get only the data for the current level:
	level_data = level_data[str(level_no)]
	layout = level_data["layout"]
	block_style = level_data["block_style"]
	
func create_new_grid():
	# Create a 2D array for the map data.
	# https://godotengine.org/qa/18011/initialize-an-array-of-size-n
	# (Godot doesn't support 2D arrays directly!)
	grid = []
	for i in range(grid_size.x):
		grid.append([])
# warning-ignore:unused_variable
		for j in range(grid_size.y):
			grid[i].append(null) # add nothing in the i'th column

func draw_level():
	# Create local variable to hold obstacle positions:
	create_new_grid()
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
		call_deferred("add_child", new_obstacle)
		
	add_ship(Vector2(19, 12))
	place_enemies()
	emit_signal("level_start") # ready to play

func query_layout(chosen_layout, x, y):
	# Queries the chosen layout at the current position and return "0" or "1".
	
	# Code to query data from Zylann:
	# https://godotengine.org/qa/6491/read-&-write
	
	var file = File.new()
	file.open("res://scenery/layouts/layout_" + str(chosen_layout) + ".txt", File.READ)
	# Save the whole layout text as a single string:
	var layout_text = file.get_as_text()
	
	# Get the text at the y'th row by converting y to two digits then reading the text data file.
	# For example, row 16 is stored as:
	# 16x10000000011000000000000000011000000001
	y = str("%02d" % y)
	
	# Set up regex with 1st two digits from row number, then x, then 38 digits:
	var regex = RegEx.new()
	# Look the correct row of data:
	regex.compile(str(y) + "x\\d{38}")
	var row = ""
	row = regex.search(layout_text).get_string()
	return row[x + 3] # offsetting the first 3 characters of each row
	
func place_enemies():
	# Get the enemy data for the current level,
	# Cycle through each enemy and place it at the position
	var enemies = level_data["enemies"]
	for e in enemies:
		var grid_pos = Vector2(e["posx"], e["posy"]) 
		add_enemy(e, grid_pos, Vector2(-1, 1))
		
	# Alternatively generate random enemies - useful for debugging:
#	for n in range (5):
#		var grid_pos = Vector2(randi() % int(grid_size.x), randi() % int(grid_size.y))
#		add_enemy("heart", grid_pos, Vector2(-1, 1))

	
func add_enemy(enemy_data, start_position, direction):
	
	var enemy_type = enemy_data["type"]
	
	# Don't create enemy if the start position is occupied:
	var object = query_cell_contents(map_to_world(start_position), Vector2())
	if object != block.EMPTY:
		print("Can't create enemy at " + str(start_position) + ". There's a " + str(query_cell_contents(start_position, Vector2())) + " in the way")
		return

	var new_enemy
	if enemy_type == "heart":
		new_enemy = enemy_heart.instance()
	elif enemy_type == "mine":
		new_enemy = enemy_mine.instance()
		new_enemy.is_green = enemy_data["mine_is_green"]
		new_enemy.rank = enemy_data["mine_rank"]
		new_enemy.start_number = enemy_data["mine_start_no"]
	else:
		print("Can't create enemy - enemy type doesn't exist.")
		return

	# Trigger a new enemy node start_position (in grid coordinates) and direction
	new_enemy.direction = direction
	new_enemy.start_position = start_position
	new_enemy.enemy_type = enemy_type
	call_deferred("add_child", new_enemy)

func query_cell_contents(pos, direction):
	# Get the world position of the place the player wants to move to
	# and convert it to grid coordinates:
	var grid_pos = world_to_map(pos) + direction
	
	# Return the contents of what's in the target cell.
	# Define a boolean array for whether there's a top, bottom, left or right edge. For example, the top left corner is:
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
	#   Return new world position if player can move there.
	
	# Get current and intended position:
	var cell_start = world_to_map(pawn.position)
	var cell_target = cell_start + direction
	
	# Set a variable to get whatever's in the target cell:
	var target_block = test_move(pawn, direction)
	
	# Update the position if empty, otherwise keep the same position:
	if target_block == block.EMPTY:
		return [update_pawn_position(pawn, cell_start, cell_target), block.EMPTY]
	# If a bullet is about to hit an enemy or ship, allow bullet to move there:
	elif pawn.type == block.BULLET and (target_block == block.ENEMY or target_block == block.SHIP):
#		print(str(pawn.type) + ": " + str(cell_start) + " moving to " + str(cell_target) + " containing " + str(target_block))
		return [update_pawn_position(pawn, cell_start, cell_target), target_block]
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
	
func force_move(pawn, direction):
	# Move an object in a chosen direction regardless of what's in its cell, unless it's at the edge.
	
	# Get current and intended position:
	var cell_start = world_to_map(pawn.position)
	var cell_target = cell_start + direction
	var target_block = test_move(pawn, direction)
	
	# Update the position if empty, otherwise keep the same position
	if target_block == block.EDGE_UD or target_block == block.EDGE_LR:
		return [pawn.position, target_block]
	else:
		return [map_to_world(cell_target) + half_tile_size, block.EMPTY]
		
func add_ship(start_position):
	if query_cell_contents(map_to_world(start_position), Vector2()) != block.EMPTY:
		print("Can't create ship at " + str(start_position) + ". There's a " + str(query_cell_contents(start_position, Vector2())) + " in the way")
		return
		
	var new_ship = ship.instance()
	# Trigger a new bullet node from start_position (in grid coordinates) and direction
	new_ship.start_position = start_position
	call_deferred("add_child", new_ship)
	
func fire_bullet(grid_pos, direction):
	grid_pos = grid_pos + direction # start from immediately in front of the ship
	
	# Don't create a bullet if the start position is occupied:
	if query_cell_contents(map_to_world(grid_pos), Vector2()) != block.EMPTY:
		print("Can't fire from " + str(grid_pos) + ". There's a " + str(query_cell_contents(grid_pos, Vector2())) + " in the way")
		return
	
	# Trigger a new bullet node from start_position (in grid coordinates) and direction
	var new_bullet = bullet.instance()
	new_bullet.direction = direction
	new_bullet.start_position = grid_pos
	call_deferred("add_child", new_bullet)
	
func explode_enemy(start_pos):
	# Create 8 Explode nodes.
	# Cycle through 9 directions, excluding (0, 0).
	# Need to deal with case where enemy is at an edge
	for j in range (-1, 2):
		for i in range (-1, 2):
							
			var direction = Vector2(i, j)
			var grid_pos = world_to_map(start_pos) + direction

			var start_block_contents = query_cell_contents(start_pos, Vector2(i, j))
			if start_block_contents == block.EDGE_UD or start_block_contents == block.EDGE_LR:
				print("Can't explode from " + str(grid_pos) + ". There's a " + str(start_block_contents) + " in the way")
			elif i != 0 or j != 0:
				# start from immediately in front of the enemy
				var new_explode = explode.instance()
				new_explode.direction = direction
				new_explode.start_position = grid_pos
				# Use call_deferred here to avoid messing with the main thread.
				# More info on https://godotengine.org/qa/7336/what-are-the-semantics-of-call_deferred
				# Using add_child(new_explode) causes errors: https://godotengine.org/qa/38401/does-cant-change-this-state-while-flushing-queries-error-mean
				call_deferred("add_child", new_explode)
				
func set_empty(pos):
	# Set a cell empty from absolute position:
	var gpos = world_to_map(pos)
	grid[gpos.x][gpos.y] = block.EMPTY
	
func curtains():
	global.game_status = global.status.ANIMATE
	# Cycles through nodes and moves them gradually left or right:
	for gap in range (20):
		# Pause code: https://twitter.com/reduzio/status/762086309695479808
		yield(get_tree().create_timer(0.1), "timeout")
		for n in self.get_children():
			if not n.name.match("*Label*"):
				var node_gpos = world_to_map(n.position)
				if node_gpos.x <= 18:
					node_gpos.x -= 1
				elif node_gpos.x >= 19:
					node_gpos.x += 1
				
				if node_gpos.x < 0 or node_gpos.x >= grid_size.x:
					n.queue_free()
				else:
					n.position = map_to_world(node_gpos) + half_tile_size
					
	clear_nodes()

func _on_Global_level_complete():
	yield(curtains(), "completed")
	emit_signal("next_level")
	var level_string = "LEVEL " + "%03d" % (level + 1)
	write_text_column(level_string)

func write_text_column(text):
	# Writes text repeatedly down in a column:
	for i in range(9):
		var new_label = label.instance()
		new_label.rect_position = Vector2(112, 32 + i * 16)
		new_label.text = text
		new_label.add_color_override("font_color", Color("#ffffff"))
		call_deferred("add_child", new_label)
		
func debug():
	# Clear existing labels
	for n in self.get_children():
		if n.name.match("*Label*"):
			n.queue_free()

	# Add label for each cell:
	for j in range(grid_size.y):
		for i in range(grid_size.x):
			var new_label = label.instance()
			new_label.rect_position = Vector2(i * 8, j * 8)
			new_label.text = str(query_cell_contents(Vector2(i * 8, j * 8), Vector2()))
			new_label.add_color_override("font_color", Color("#cc6600"))
			call_deferred("add_child", new_label)
	
func _on_Global_lose_a_life():
	var red = float((randi() % 50 + 50)) / 100
	var grn = float((randi() % 50 + 50)) / 100
	var blu = float((randi() % 50 + 50)) / 100
	playarea.color = Color(red, grn, blu, 1)
	
func clear_nodes():
	for n in self.get_children():
		n.propagate_call("queue_free", [])

func _on_Global_game_over():
	yield(curtains(), "completed")
	emit_signal("set_red_screen")	
	write_text_column("Game Over")
	clear_nodes()
	global.game_status = global.status.OVER