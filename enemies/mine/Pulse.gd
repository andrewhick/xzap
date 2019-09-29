extends Area2D

export var anim_offset = 0

func _ready():
	$AnimatedSprite.play()
	$AnimatedSprite.frame = anim_offset