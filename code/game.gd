extends Node

enum p_status {idle, fired, dodged, dead, flash, empty}
var p = { "1": p_status.idle, "2": p_status.idle }
var p_cooldown = { "1": false, "2": false }

var p_ammo = { "1": 6, "2": 6 }

var p_score = { "1": 0, "2": 0 }

var game_over = false

var action = ""
var action_playing = false

@export var t_window = 0.25
@export var t_fade = 2
@export var t_cooldown = 1
@export var t_flash = 0.1
@export var t_score = 2

@export var fire_effects = []
@export var hammer_effects = []
@export var dodge_effect = []

func _ready():
	fire_effects = [
		preload("res://assets/sfx/fire/fire_1.mp3"),
		preload("res://assets/sfx/fire/fire_2.mp3"),
		preload("res://assets/sfx/fire/fire_3.mp3"),
	]
	hammer_effects = [
		preload("res://assets/sfx/hammer/hammer_1.mp3"),
		preload("res://assets/sfx/hammer/hammer_2.mp3"),
		preload("res://assets/sfx/hammer/hammer_3.mp3"),
	]
	dodge_effect = [ preload("res://assets/sfx/dodge.mp3") ]

func _process(_delta):
	_get_input("1")
	_get_input("2")
	
	_animate("1")
	_animate("2")

func _animate(p_num):
	var s
	
	if p_num == "1": s = $player_1
	else: s = $player_2 
	
	match p[p_num]:
		p_status.idle: s.frame = 0
		p_status.fired: s.frame = 1
		p_status.dodged: s.frame = 2
		p_status.dead: s.frame = 3
		p_status.empty: s.frame = 5
		p_status.flash:
			$flash.visible = true
			s.frame = 4
			
			await get_tree().create_timer(t_flash).timeout
			
			$flash.visible = false
			p[p_num] = p_status.fired

func _get_input(p_num):
	var p_action = ""
	
	if p[p_num] == p_status.idle:
		if p_cooldown[p_num] == false:
			if Input.is_action_just_released(p_num+"_fire"):
				print (p_num + " fired")
				p[p_num] = p_status.flash
				
				p_ammo[p_num] -= 1
				_sfx_play(fire_effects)
				
				p_action = p_num+"_fire"
				_cooldown(p_num, p_action)
				
				if action == "":	action = p_action
				
			elif Input.is_action_just_pressed(p_num+"_dodge"):
				print (p_num + " dodged")
				p[p_num] = p_status.dodged
				
				_sfx_play(dodge_effect)
				
				p_action = p_num+"_dodge"
				_cooldown(p_num, p_action)
				
				if action == "":	action = p_action
			
			elif Input.is_action_just_pressed(p_num+"_fire"):
				_sfx_play(hammer_effects)
	
	#if action != "" and !action_playing:
	#	_showdown()	

func _sfx_play(sfx):
	var player = AudioStreamPlayer2D.new()
	add_child(player)
	
	var random_sfx = sfx[randi() % sfx.size()]
	
	player.stream = random_sfx 
	player.play()

func _cooldown(p_num, p_action):
	p_cooldown[p_num] = true
	
	await get_tree().create_timer(t_window).timeout
	
	if action != "" and !action_playing:
		match action:
			"1_fire":
				if p["2"] != p_status.dodged:	_hit("2", "1")
			"2_fire":
				if p["1"] != p_status.dodged:	_hit("1", "2")
			
			"1_dodge":
				if p["2"] == p_status.fired:	_hit("1", "2")
			"2_dodge":
				if p["1"] == p_status.fired:	_hit("2", "1")
	
	await get_tree().create_timer(t_cooldown - t_window).timeout
	
	if !game_over:
		if p_ammo[p_num] == 0:
			p[p_num] = p_status.empty
			
			game_over = true
			
			await get_tree().create_timer(t_cooldown).timeout
			print (p_num + " is out")
			
			_game_over()
			return
		
		p_cooldown[p_num] = false
		
		p[p_num] = p_status.idle
		
		if p_action == action:
			action = ""
		action_playing = false

func _hit(p_num, w_id):
	game_over = true
	
	p_score[w_id] += 1
	
	await get_tree().create_timer(t_cooldown).timeout
	print (p_num + " is dead")
	
	p[p_num] = p_status.dead
	_game_over()

func _game_over():
	await get_tree().create_timer(t_fade).timeout
	
	$score.text = str(p_score["1"]) + " - " + str(p_score["2"])
	
	$fade.visible = true;
	await get_tree().create_timer(t_score).timeout
	$fade.visible = false;
	
	p_ammo["1"] = 6; p_ammo["2"] = 6
	p_cooldown["1"] = false; p_cooldown["2"] = false
	p["1"] = p_status.idle; p["2"] = p_status.idle
	
	action = ""
	action_playing = false
	game_over = false
	
	print ("reloaded")
