extends HBoxContainer

# This needs to receive signals for when the score changes from the Global singleton
# Connect this to Global
# Receive a signal containing the new score

onready var global = get_node("/root/Global")

func _ready():
	global.connect("score_changed", self, "_on_Global_score_changed")
	$ScoreBox/Score.text = "%08d" % global.score

func _on_Global_score_changed(new_score):
	$ScoreBox/Score.text = new_score