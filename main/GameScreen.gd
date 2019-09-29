extends Area2D

onready var global = get_node("/root/Global")
onready var grid = $C16Border/C16Screen/PlayArea/Grid

func _ready():
	global.connect("set_red_screen", self, "_on_Global_set_red_screen")
	global.connect("set_game_screen", self, "_on_Global_set_game_screen")
	grid.connect("set_red_screen", self, "_on_Grid_set_red_screen")

func _on_Global_set_red_screen():
	set_red_screen()
	
func _on_Grid_set_red_screen():
	set_red_screen()
	
func set_red_screen():
	$C16Border.color = Color("7C190B")
	$C16Border/C16Screen.color = Color("7C190B")
	$C16Border/C16Screen/PlayArea.color = Color("7C190B")	
	
func _on_Global_set_game_screen():
	$C16Border.color = Color("000000")
	$C16Border/C16Screen.color = Color("000000")
	$C16Border/C16Screen/PlayArea.color = Color("ffffff")