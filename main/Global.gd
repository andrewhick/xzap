extends Node

signal score_changed

# Guidance on connecting signals:
# https://www.reddit.com/r/godot/comments/4n8rts/explain_to_me_how_to_use_the_signals_in_godot/
# http://kidscancode.org/blog/2017/03/godot_101_07/

# enemy_hit should already be connected from EnemyHeart

export var score = 1000

func _ready():
	print("Score ready to initiate")
	update_score(score)

func _on_EnemyHeart_enemy_hit(name):
	print("HIT by " + name)
	score -= 1
	update_score(score)
	
func get_number_of_enemies():
	return 999
	
func update_score(new_score):
	# change number to 8 digits
	# render the score in the label
	new_score = "%08d" % new_score
	emit_signal("score_changed", new_score)