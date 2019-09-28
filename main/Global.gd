extends Node

signal new_level
signal score_changed
signal lives_changed
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
enum status {PLAY, DRAW, AWAIT}

export var score = 99999999
export var lives = 3
export var level = 1
export var game_status = status.PLAY
onready var level_end_timer = $LevelEndTimer

signal key_pressed_on_await

func _ready():
	self.connect("key_pressed_on_await", self, "_on_Global_key_pressed_on_await")
	
func _input(event):
	if event.is_action_pressed("ui_accept") and game_status == status.AWAIT:
		emit_signal("key_pressed_on_await")
		game_status = status.PLAY

func _on_Grid_level_start():
	print("Start level " + str(level))
	update_score(get_number_of_enemies())
	emit_signal("lives_changed", lives)
	emit_signal("set_game_screen")

func _on_Enemy_enemy_hit(name):
	var number_of_enemies = get_number_of_enemies()
	# Show number of enemies - 1 because enemy has not yet been deleted
	update_score(number_of_enemies - 1)
	emit_signal("lives_changed", lives)
	if number_of_enemies == 1:
		if name.match("*Ship*") and lives == 1:
			# Don't end level as player has lost last life
			pass
		else:
			level_end_timer.start()
	
func get_number_of_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies").size()
	return enemies
	
func _on_Enemy_enemy_hit_ship():
	# Send a signal to animate the grid:
	emit_signal("lose_a_life")
	
	# Update number of lives:
	lives -= 1
	print("Number of lives is now: " + str(lives))
	emit_signal("lives_changed", lives) # updates the lives bar
	
	if lives == 0:
		emit_signal("score_changed", "GameOver")
		game_over()
	
func update_score(new_score):
	# change number to 8 digits
	new_score = "%08d" % new_score
	# The following signal is connected in Scores.gd
	emit_signal("score_changed", new_score)
	
func _on_LevelEndTimer_timeout():
	emit_signal("level_complete")
	emit_signal("score_changed", "COMPLETE")
	print("Level complete")

func _on_Grid_next_level():
	emit_signal("score_changed", "LevelEnd")
	level += 1
	emit_signal("set_red_screen")
	game_status = status.AWAIT

func _on_Global_key_pressed_on_await():
	emit_signal("new_level", level)
	emit_signal("score_changed", "NewLevel")
	print("New level: " + str(level))

func game_over():
	emit_signal("set_red_screen")
	emit_signal("game_over")