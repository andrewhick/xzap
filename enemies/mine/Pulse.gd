extends Area2D

export var anim_offset = 0

func _ready():
	$AnimatedSprite.play()
	$AnimatedSprite.frame = anim_offset
	
func _on_Pulse_area_entered(area):
	if area.get_name().match("*Ship*"):
		print("Forcefield pulse hit ship")
		emit_signal("pulse_hit_ship")
		queue_free()