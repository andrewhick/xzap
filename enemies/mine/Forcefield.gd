extends Node2D

# Hierarchy: Grid > Mine > Forcefield > Pulse
# The forcefield generates a rectangle of pulses, with animation staggered row by row.

# Assumptions:
# Forcefield never moves.
# Forcefields can't technically overlap but are redrawn if another forcefield disappears.
# Forcefield kills ship.
# Forcefield prevents enemies from moving.

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

# Forcefields can be redrawn at any point until they time out:
var allow_redraw = true

onready var global = get_node("/root/Global")
onready var pulse = preload("res://enemies/mine/Pulse.tscn")

# This signal:
# - Asks the parent mine to clean up its children
# - Sends a global signal to all mines to redraw their pulses.
signal forcefield_end

func _ready():
	self.connect("forcefield_end", global, "_on_Forcefield_forcefield_end")
	global.connect("redraw_forcefields", self, "_on_Global_redraw_forcefields")
	draw_forcefield()
	
func _on_Global_redraw_forcefields():
	# Triggered when one forcefield ends.
	# Redraws forcefields for any existing mines, in case there were any overlaps.
	if allow_redraw:
		clear_pulses()
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
	allow_redraw = false
	$Timer.queue_free()
	clear_pulses()
	emit_signal("forcefield_end")
	queue_free()
	
func clear_pulses():
	for n in self.get_children():
		if n.name.match("*Pulse*"):
			grid.set_empty(n.position + mine.position)
			n.queue_free()

func stop_enemy():
	$AnimatedSprite.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	grid.set_empty(position)