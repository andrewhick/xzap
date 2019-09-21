extends Node

signal score_changed
signal lives_changed
signal level_complete
signal game_over
signal lose_a_life

# Guidance on connecting signals:
# https://www.reddit.com/r/godot/comments/4n8rts/explain_to_me_how_to_use_the_signals_in_godot/
# http://kidscancode.org/blog/2017/03/godot_101_07/

# enemy_hit should already be connected from EnemyHeart

export var score = 99999999
export var lives = 3
export var level = 1
onready var level_end_timer = $LevelEndTimer

func _ready():
	pass
	
func _on_Grid_level_start():
	print("Start level " + str(level))
	update_score(get_number_of_enemies())
	emit_signal("lives_changed", lives)

func _on_EnemyHeart_enemy_hit(name):
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
	
func _on_EnemyHeart_enemy_hit_ship():
	# Send a signal to animate the grid:
	emit_signal("lose_a_life")
	
	# Update number of lives:
	lives -= 1
	print("Number of lives left: " + str(lives))
	emit_signal("lives_changed", lives) # updates the lives bar
	
	if lives == 0:
		emit_signal("score_changed", "GAMEOVER")
		game_over()
	
func update_score(new_score):
	# change number to 8 digits
	new_score = "%08d" % new_score
	# The following signal is connected in Scores.gd
	emit_signal("score_changed", new_score)
	
func _on_LevelEndTimer_timeout():
	emit_signal("level_complete")
	emit_signal("score_changed", "COMPLETE")
	print("Level complete :)")

func _on_Grid_next_level():
	emit_signal("score_changed", "LVL END ")
	
func game_over():
	emit_signal("game_over")
	