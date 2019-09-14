extends Node

signal score_changed
signal level_complete
signal game_over

# Guidance on connecting signals:
# https://www.reddit.com/r/godot/comments/4n8rts/explain_to_me_how_to_use_the_signals_in_godot/
# http://kidscancode.org/blog/2017/03/godot_101_07/

# enemy_hit should already be connected from EnemyHeart

export var score = 99999999
onready var level_end_timer = $LevelEndTimer

func _ready():
	pass
	
func _on_Grid_level_start():
	print("Level START.")
	update_score(get_number_of_enemies())

func _on_EnemyHeart_enemy_hit(name):
	print("Signal: Heart hit by " + name)
	var number_of_enemies = get_number_of_enemies()
	# Show number of enemies - 1 because enemy has not yet been deleted
	update_score(number_of_enemies - 1)
	if number_of_enemies == 1:
		level_end_timer.start()
		print("About to end level")
	
func get_number_of_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies").size()
	return enemies
	
func update_score(new_score):
	# change number to 8 digits
	new_score = "%08d" % new_score
	# The following signal is connected in Scores.gd
	emit_signal("score_changed", new_score)

func _on_LevelEndTimer_timeout():
	emit_signal("level_complete")
	emit_signal("score_changed", "COMPLETE")
	print("Level complete :)")
