extends Node2D

# A forcefield is a child of a mine.
# This allows the forcefield and the child to interact with each other.
# The forcefield itself has no area, and only creates child nodes (pulses).
# The pulses created by the forcefield, however, are added as a child of the grid.
# This is consistent with the way enemies and bullets are created.

# To do:
# Create a single row of variable width that animates
# Create multiple rows
# Stagger the animation row by row
# Build interactions

# Assumptions:
# Forcefield never moves
# if forcefields overlap
# Redraw if another forcefield disappears
# Forcefield kills ship
# Forcefield prevents enemies from moving

export var gpos = Vector2() # Grid pos of mine (centre of forcefield)
onready var mine = get_parent()
onready var grid = mine.get_parent() # grandparent

# Define sizes as the extent, in each direction, of the forcefield from the mine,
# not including the area parallel with the mine itself
export var size_u = 4
export var size_d = 4
export var size_l = 4
export var size_r = 4
export var duration = 5 # number of seconds the forcefield lasts

# Set number of moves per second:
var time_passed = 0
export var calls_per_sec = 10
# Use float here, otherwise this evaluates to 0.
var time_for_one_call = 1 / float(calls_per_sec)

onready var pulse = preload("res://enemies/mine/Pulse.tscn")

signal forcefield_end

func _ready():
	draw_forcefield()

func draw_forcefield():
	# Add nodes row by row.
	# Give each row an offset where to start animation from.
	# Set variables to prevent forcefield being drawn off screen
	var up = clamp(gpos.y - size_u, 0, gpos.y)
	var down = clamp(gpos.y + size_d, gpos.y, grid.grid_size.y - 1)
	var left = clamp(gpos.x - size_l, 0, gpos.x)
	var right = clamp(gpos.x + size_r, gpos.x, grid.grid_size.x - 1)
	var anim_offset = 0
	print("Drawing forcefield from " + str(left) + "," + str(up) + " to " + str(right) + "," + str(down))
	print("  centered on " + str(gpos))
	
	for j in range (up, down + 1):
		for i in range (left, right + 1):
			if i != gpos.x or j != gpos.y:
				place_pulse(Vector2(i, j), anim_offset)	
		anim_offset += 1
		anim_offset = anim_offset % 8
		
func place_pulse(pulse_gpos, offset):
	# Depending on what's in the target cell, places a pulse at a grid position with animation offset.
	# Position is relative to parent mine by default, so subtract the parent mine's position:
	var pulse_pos = grid.map_to_world(pulse_gpos - gpos)
	# Find out what is in target position:
	var target_block = grid.query_cell_contents(pulse_pos + mine.position, Vector2())
	match target_block:
		grid.block.SHIP:
			emit_signal("pulse_hit_ship")
		grid.block.EMPTY:
			# Only create the pulse if the cell is empty:
			# Set grid element:
			grid.grid[pulse_gpos.x][pulse_gpos.y] = grid.block.PULSE
			# Create new pulse:
			var new_pulse = pulse.instance()
			new_pulse.anim_offset = offset
			new_pulse.position = pulse_pos
			call_deferred("add_child", new_pulse)

func _on_Timer_timeout():
	emit_signal("forcefield_end")
	print("Removing forcefield")
	$Timer.queue_free()
	for n in self.get_children():
		if n.name.match("*Pulse*"):
			grid.set_empty(n.position + mine.position)
			n.queue_free()
	
	# Check if there are any other mines around and redraw their forcefields
	queue_free()
		
func stop_enemy():
	$AnimatedSprite.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	grid.set_empty(position)