extends Node

# Sprite containers.

# Player 1 flags
var p1_alive = true
var p1_cdown = false
var p1_fired = false
var p1_dodged = false

# Player 2 flags
var p2_alive = true
var p2_cdown = false
var p2_fired = false
var p2_dodged = false

# Player ammo.
var p1_ammo = 6
var p2_ammo = 6

# Action management.
var player_action
var action_started = false

var game_over = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_check_input()
	if !game_over:	_animate()

func _check_input():
	# Player 1
	if Input.is_action_just_pressed("p1_fire"):
		if p1_alive and !p1_cdown:	if !p1_fired and p1_ammo > -100:	_fire(true)
	if Input.is_action_just_pressed("p1_dodge"):
		if p1_alive and !p1_cdown:	if !p1_dodged:	_dodge(true)
	# Player 2
	if Input.is_action_just_pressed("p2_fire"):
		if p2_alive and !p2_cdown:	if !p2_fired and p2_ammo > -100:	_fire(false)
	if Input.is_action_just_pressed("p2_dodge"):
		if p2_alive and !p2_cdown:	if !p2_dodged:	_dodge(false)

func _animate():
	update_frame($p1, p1_alive, p1_fired, p1_dodged)
	update_frame($p2, p2_alive, p2_fired, p2_dodged)

func update_frame(player, alive, fired, dodged):
	if alive:
		if fired:	player.frame = 1
		elif dodged:	player.frame = 2
		else:	player.frame = 0

func _fire(p1):	
	if p1:
		p1_cdown = true
		p1_fired = true
		p1_ammo -= 1
		if !action_started:
			$countdown.start()
			player_action = "p1_fire"
			action_started = true
		print ("p1 fire. ammo: " + str(p1_ammo))
	else:
		p2_cdown = true
		p2_fired = true
		p2_ammo -= 1
		if !action_started:
			$countdown.start()
			player_action = "p2_fire"
			action_started = true
		print ("p2 fire. ammo: " + str(p2_ammo))

func _dodge(p1):	
	if p1:
		p1_cdown = true
		print ("p1 dodge")
		p1_dodged = true
		if !action_started:
			$countdown.start()
			player_action = "p1_dodge"
			action_started = true
	else:
		p2_cdown = true
		print ("p2 dodge")
		p2_dodged = true
		if !action_started:
			$countdown.start()
			player_action = "p2_dodge"
			action_started = true

func _on_countdown_timeout():
	print (player_action)
	match player_action:
		"p1_fire":
			if !p2_dodged:
				print ("p2 loss")
				p2_alive = false
				_game_over()
			else:
				print ("p2 dodge")
		"p2_fire":
			if !p1_dodged:
				print ("p1 loss")
				p1_alive = false
				_game_over()
			else:
				print ("p1 dodge")
			
		"p1_dodge":
			if p2_fired:
				print ("p1 loss")
				p1_alive = false
				_game_over()
		"p2_dodge":
			if p1_fired:
				print ("p2 loss")
				p2_alive = false
				_game_over()
	
	await get_tree().create_timer(0.25).timeout
	
	if !game_over:
		player_action = ""
		action_started = false
		
		p1_cdown = false
		p1_fired = false
		p1_dodged = false
		
		p2_cdown = false
		p2_fired = false
		p2_dodged = false
	
func _game_over():
	game_over = true
	$game_over.start()

func _on_game_over_timeout():
	if !p1_alive: $p1.frame = 3
	elif !p2_alive: $p2.frame = 3
	$restart.start()

func _on_restart_timeout():
	get_tree().reload_current_scene()
