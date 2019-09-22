extends Area2D

onready var global = get_node("/root/Global")

func _ready():
	global.connect("set_red_screen", self, "_on_Global_set_red_screen")
	global.connect("set_game_screen", self, "_on_Global_set_game_screen")

func _on_Global_set_red_screen():
	$C16Border.color = Color("7e453d")
	$C16Border/C16Screen.color = Color("7e453d")
	$C16Border/C16Screen/PlayArea.color = Color("7e453d")
	
func _on_Global_set_game_screen():
	$C16Border.color = Color("000000")
	$C16Border/C16Screen.color = Color("000000")
	$C16Border/C16Screen/PlayArea.color = Color("ffffff")