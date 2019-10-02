extends HBoxContainer

# This needs to receive signals for when the score changes from the Global singleton
# Connect this to Global
# Receive a signal containing the new score

onready var global = get_node("/root/Global")
var lives_text = "+++"

func _ready():
	global.connect("score_changed", self, "_on_Global_score_changed")
	global.connect("update_lives", self, "_on_Global_update_lives")
	$ScoreBox/Score.text = "%08d" % global.score
	$LivesBox/Lives.text = lives_text
	$LivesBox/SkullBackground.rect_size.x = 0

func _on_Global_score_changed(new_score):
	$ScoreBox/Score.text = str(new_score)
	
func _on_Global_update_lives(new_lives):
	# Accepts a value from 0 to 3
	# Extend SkullBackground to appropriate width, so that the background behind each skull is black
	$LivesBox/SkullBackground.rect_size.x = (3 - new_lives) * 8
	# Change text in lives box. A heart is represented by a +, a skull by -
	new_lives = clamp(new_lives, 0, 3)
	match new_lives:
		0:
			$LivesBox/Lives.text = "---"
		1:
			$LivesBox/Lives.text = "--+"
		2:
			$LivesBox/Lives.text = "-++"
		3:
			$LivesBox/Lives.text = "+++"