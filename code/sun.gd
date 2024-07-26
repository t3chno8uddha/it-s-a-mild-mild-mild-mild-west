extends Sprite2D

@export var t_timer = 0.75
var timed = false

func _process(_delta):
	if !timed: _flip()

func _flip():
	timed = true
	await get_tree().create_timer(t_timer).timeout
	
	flip_h = !flip_h
	timed = false
