extends Node

var tutorial = true
var tutorial_closed = false

enum p_status {idle, fired, dodged, dead, flash, empty}
var p = { "1": p_status.idle, "2": p_status.idle }
var p_cooldown = { "1": false, "2": false }

var p_ammo = { "1": 6, "2": 6 }

var p_score = { "1": 0, "2": 0 }

var game_over = false

var action = ""
var action_playing = false
var previous_action = ""

@export var bgm : AudioStreamPlayer2D

@export var t_window = 0.25
@export var t_fade = 1.5
@export var t_gunfire = 0.6
@export var t_dodge = 0.5
@export var t_flash = 0.1
@export var t_score = 1.5
@export var t_death = 0.75

@export var fire_effects = []
@export var hammer_effects = []
@export var dodge_effect = []
@export var thud_effect = []

@export var t_timer = 0.75
var timed = false

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
	thud_effect = [ preload("res://assets/sfx/thud.mp3") ]

func _process(_delta):
	if !tutorial:
		_get_input("1")
		_get_input("2")
		
		_animate("1")
		_animate("2")
	elif tutorial_closed: 
		$tutorial.queue_free()
		bgm.playing = true
		tutorial = false 
	
	if !timed: _flip()
	
	if Input.is_key_pressed(KEY_SPACE): tutorial_closed = true
	#elif Input.is_key_pressed(KEY_ESCAPE): get_tree().quit()
	#elif Input.is_key_pressed(KEY_ESCAPE): get_tree().reload_current_scene()
	elif Input.is_key_pressed(KEY_R): get_tree().reload_current_scene()

func _flip():
	timed = true
	await get_tree().create_timer(t_timer).timeout
	
	$environment_bg/sun.flip_h = !$environment_bg/sun.flip_h
	#$environment_bg/ground_d.flip_h = !$environment_bg/ground_d.flip_h
	#$environment_bg/sky_d.flip_h = !$environment_bg/sky_d.flip_h
	
	timed = false

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
	
	var s
	
	if p_num == "1": s = $player_1/smoke
	else: s = $player_2/smoke
	
	if p[p_num] == p_status.idle:
		if p_cooldown[p_num] == false:
			if Input.is_action_just_released(p_num+"_fire"):
				#print (p_num + " fired")
				p[p_num] = p_status.flash
				
				s.emitting = true
				
				p_ammo[p_num] -= 1
				_sfx_play(fire_effects)
				
				p_action = p_num+"_fire"
				if action == "": action = p_action
				
				_cooldown(p_num, p_action, t_gunfire)
			if Input.is_action_just_pressed(p_num+"_dodge"):
				#print (p_num + " dodged")
				p[p_num] = p_status.dodged
				
				_sfx_play(dodge_effect)
				
				p_action = p_num+"_dodge"
				
				if action == "": action = p_action
				
				_cooldown(p_num, p_action, t_dodge)
			if Input.is_action_just_pressed(p_num+"_fire"):
				_sfx_play(hammer_effects)

func _sfx_play(sfx):
	var player = AudioStreamPlayer2D.new()
	add_child(player)
	
	var random_sfx = sfx[randi() % sfx.size()]
	
	player.stream = random_sfx 
	player.play()

func _cooldown(p_num, p_action, p_timer):
	p_cooldown[p_num] = true
	
	if !action_playing && action != "":
		var previousAction = action
		
		await get_tree().create_timer(t_window).timeout
		
		match previousAction:
			"1_fire":
				print ("1_fire")
				if p["2"] != p_status.dodged:	_hit("2", "1")
			"2_fire":
				print ("2_fire")
				if p["1"] != p_status.dodged:	_hit("1", "2")
			
			"1_dodge":
				print ("1_dodge")
				if p["2"] == p_status.fired:	_hit("1", "2")
			"2_dodge":
				print ("2_dodge")
				if p["1"] == p_status.fired:	_hit("2", "1")
		
		action_playing = false
	
	await get_tree().create_timer(p_timer).timeout
	
	if !game_over:
		if p_ammo[p_num] == 0:
			game_over = true
			await get_tree().create_timer(t_death   ).timeout
			
			var w_id
			
			if p_num == "1": w_id = "2"
			else: w_id = "1"
			
			p_score[w_id] += 1
			p[w_id] = p_status.idle
			
			p[p_num] = p_status.empty
			#print (p_num + " is out")
			
			var s
			
			if p_num == "1": s = $player_1
			else: s = $player_2
			
			s.frame = 5 
			
			_game_over()
			
			return
		
		p_cooldown[p_num] = false
		
		p[p_num] = p_status.idle
		
		if p_action == action: action = ""
		action_playing = false

func _hit(p_num, w_id):
	if !game_over:
		game_over = true
		p_score[w_id] += 1
		
		await get_tree().create_timer(t_death).timeout
		#print (p_num + " is dead")
		
		p[p_num] = p_status.dead
		
		var s
		
		if p_num == "1": s = $player_1
		else: s = $player_2
		
		s.frame = 3
		
		_game_over()

func _game_over():
	_sfx_play(thud_effect)
	
	await get_tree().create_timer(t_death).timeout
	
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
	
	#print ("reloaded")
