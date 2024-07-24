extends Node

enum p_status {idle, fired, dodged, dead}

var p = { "1": p_status.idle, "2": p_status.idle }

var game_over = false

var action = ""
var action_playing = false

var t_window = 0.25
var t_fade = 3

func _ready():
	pass

func _process(_delta):
	_get_input("1")
	_get_input("2")

func _get_input(p_num):
	if p[p_num] == p_status.idle:
		if Input.is_action_just_pressed(p_num+"_fire"):
			p[p_num] = p_status.fired
			print (p_num + " fired")
			if action == "":	action = p_num+"_fire"
			
		elif Input.is_action_just_pressed(p_num+"_dodge"):
			p[p_num] = p_status.dodged
			print (p_num + " dodged")
			if action == "":	action = p_num+"_dodge"
	
	if action != "" and !action_playing:
		_showdown()	

func _showdown():
	action_playing = true
	
	await get_tree().create_timer(t_window).timeout
	
	# Switch case to check player actions.
	match action:
		"1_fire":
			if p["2"] != p_status.dodged:	_hit("2")
		"2_fire":
			if p["1"] != p_status.dodged:	_hit("1")
		
		"1_dodge":
			if p["2"] == p_status.fired:	_hit("1")
		"2_dodge":
			if p["1"] == p_status.fired:	_hit("2")
	
	if !game_over:
		p["1"] = p_status.idle
		p["2"] = p_status.idle
		
		action = ""
		action_playing = false
	else:
		await get_tree().create_timer(t_fade).timeout
		# Fade function here
		get_tree().reload_current_scene()

func _hit(p_num):
	print (p_num + " is dead")
	game_over = true
	p[p_num] = p_status.dead
