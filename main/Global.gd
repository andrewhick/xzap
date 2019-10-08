extends Node

signal new_level
signal score_changed
signal update_lives
signal level_complete
signal set_red_screen
signal set_game_screen
signal game_over
signal lose_a_life

# Guidance on connecting signals:
# https://www.reddit.com/r/godot/comments/4n8rts/explain_to_me_how_to_use_the_signals_in_godot/
# http://kidscancode.org/blog/2017/03/godot_101_07/

# Signals are generally connected from the nodes Global interacts with

# Use this to determine whether in gameplay or awaiting input
enum status {PLAY, ANIMATE, AWAIT, OVER}

export var score = 99999999
export var lives = 3
export var level = 1
export var game_status = status.PLAY
var allow_death_by_forcefield = true
onready var level_end_timer = $LevelEndTimer

signal key_pressed_outside_game
signal redraw_forcefields

func _ready():
	self.connect("key_pressed_outside_game", self, "_on_Global_key_pressed_outside_game")
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Start new level:
		if game_status == status.AWAIT:
			emit_signal("key_pressed_outside_game")
			game_status = status.PLAY
		# Restart game:
		elif game_status == status.OVER:
			lives = 3
			level = 1
			score = 99999999
			emit_signal("key_pressed_outside_game")
			emit_signal("update_lives", lives)
			update_score(score)
			game_status = status.PLAY

func _on_Grid_level_start():
	emit_signal("update_lives", lives)
	emit_signal("set_game_screen")
	
func _on_Enemy_enemy_created():
	score = get_number_of_enemies()
	update_score(score)

func _on_Enemy_enemy_killed(killed_enemy, what_enemy_hit):
	var number_of_enemies = get_number_of_enemies()
	var number_of_mines = get_number_of_mines()
	score = number_of_enemies - 1
	update_score(score)
	emit_signal("update_lives", lives)
	if number_of_enemies == 1:
		if what_enemy_hit.match("*Ship*") and lives == 1:
			# Don't end level as player has lost last life
			print("Ship hit last enemy on last life")
		else:
			level_end_timer.start()

	# If it's a mine that's been killed then resequence mines and make first mine hittable
	if killed_enemy.match("*Mine*"):
		resequence_mines()
	
	# Check if the enemies either are, or are about to be, only mines:
	# Assume that mines are always sequentially ordered.
	if number_of_enemies - number_of_mines <= 1:
		make_first_mine_hittable()
	
	# Assume that a chaser is NOT an enemy.
	
func make_first_mine_hittable():
	for n in get_tree().get_nodes_in_group("mines"):
		if n.rank == 1:
			n.can_be_hit = true
			n.set_green()
	
func resequence_mines():
	for n in get_tree().get_nodes_in_group("mines"):
		n.rank -= 1
	
func get_number_of_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies").size()
	return enemies
	
func get_number_of_mines():
	var mines = get_tree().get_nodes_in_group("mines").size()
	return mines
	
func get_number_of_forcefields():
	var forcefields = get_tree().get_nodes_in_group("forcefields").size()
	return forcefields
	
func _on_Enemy_enemy_hit_ship():
	lose_a_life()
	
func _on_Forcefield_pulse_hit_ship():
	if allow_death_by_forcefield:
		# Prevent further forcefield deaths until all are clear again:
		allow_death_by_forcefield = false
		lose_a_life()
		
func _on_Bullet_bullet_hit_ship():
	lose_a_life()
		
func lose_a_life():
	# Send a signal to animate the grid:
	emit_signal("lose_a_life")
	
	# Update number of lives:
	lives -= 1
	print("Lives -> " + str(lives))
	emit_signal("update_lives", lives) # updates the lives bar
	
	if lives == 0:
		emit_signal("score_changed", score)
		game_over()

func _on_Forcefield_forcefield_end():
	# Once forcefields are clear, allow ship to be killed by them again.
	# Assume that the 'last' forcefield is still on screen at this point:
	if get_number_of_forcefields() <= 1:
		allow_death_by_forcefield = true
	else:
		emit_signal("redraw_forcefields")
	
func update_score(new_score):
	# change number to 8 digits
	new_score = "%08d" % new_score
	# The following signal is connected in Scores.gd
	emit_signal("score_changed", new_score)
	
func _on_LevelEndTimer_timeout():
	emit_signal("level_complete")
	emit_signal("score_changed", "COMPLETE")
	print("Level " + str(level) + "complete")

func _on_Grid_next_level():
	emit_signal("score_changed", "LevelEnd")
	level += 1
	emit_signal("set_red_screen")
	game_status = status.AWAIT

func _on_Global_key_pressed_outside_game():
	emit_signal("new_level", level)

func game_over():
	emit_signal("game_over")