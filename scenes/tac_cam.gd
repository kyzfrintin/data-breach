extends Node2D

onready var game = get_parent()
onready var player = game.get_node("player")
onready var box_image = game.get_node("select_box")
onready var box = game.get_node("select_box/area")
onready var box_shape = box.get_node("shape")
onready var UI = game.get_node("UI")
onready var tac_display = UI.get_node("tac_display")
onready var resource_display = UI.get_node("res_list/list")

var selection = []
var selecting = false
var cam_speed = 6000
var player_alive = true
var selected_units = []
var box_corner : Vector2
var tac_pause := false

var bits := 150.0
var bit_income := 2.5
var RAM := 16
var energy := 50.0

signal pause
signal unpause

func _ready():
	player.connect("death", self, "player_dead")
	box.connect("body_entered", self, "select_box_entered")
	update_resource_display()

func _process(delta):
	if Input.is_action_just_pressed("mode_switch"):
		if game.mode == "hotseat":
			toggle_tac_pause(true)
		else:
			toggle_tac_pause(false)
	if player_alive:
		var mp = get_global_mouse_position()
		if game.mode == "tactics":
			unit_control()
			camera_control(delta)
		else:
			position = player.position
	if tac_pause:
		if Input.is_action_just_pressed("build"):
			game.build_structure(load("res://scenes/structures/RAM.tscn"), "Player", get_global_mouse_position())
			RAM += 8
	var z = $Camera2D.zoom.x
	if Input.is_action_pressed("cam_zoom_in"):
		z -= 0.25
	if Input.is_action_pressed("cam_zoom_out"):
		z += 0.25
	z = clamp(z, 0.4, 20)
	$Camera2D.zoom = Vector2(z,z)

func toggle_tac_pause(on):
	if on:
		$bit_timer.paused = true
		$pause_sound.play()
		$Camera2D.smoothing_enabled = false
		for i in get_tree().get_nodes_in_group("friendly_units"):
			i.pathline.show()
		tac_pause = true
		UI.get_node("tac_display").show()
		for i in game.get_node("ParallaxBackground").get_children():
			var s = 0.03
			if i.get_index() != 3:
				i.motion_scale = Vector2(s,s)
				s += 0.01
		game.mode = "tactics"
		emit_signal("pause")
		$Tween.interpolate_property($Camera2D, 'zoom', $Camera2D.zoom, Vector2(2,2), 0.6, Tween.TRANS_SINE, Tween.EASE_IN)
		$Tween.start()
	else:
		$bit_timer.paused = false
		$unpause_sound.play()
		$Camera2D.smoothing_enabled = true
		for i in selected_units:
			i.toggle_select(false)
		selected_units.clear()
		for i in get_tree().get_nodes_in_group("friendly_units"):
			i.pathline.hide()
		tac_pause = false
		UI.get_node("tac_display").hide()
		for i in game.get_node("ParallaxBackground").get_children():
			var s = 0.3
			if i.get_index() != 3:
				i.motion_scale = Vector2(s,s)
				s += 0.1
		game.mode = "hotseat"
		emit_signal("unpause")
		$Tween.interpolate_property($Camera2D, 'zoom', $Camera2D.zoom, Vector2(0.4,0.4), 0.6, Tween.TRANS_SINE, Tween.EASE_IN)
		$Tween.start()
	tac_display.update_pause_buts()

func camera_control(d):
	var move = Vector2()
	if Input.is_action_pressed("mv_left"):
		move += Vector2(-(600*$Camera2D.zoom.x),0)
	elif Input.is_action_pressed("mv_right"):
		move += Vector2((600*$Camera2D.zoom.x),0)
	if Input.is_action_pressed("mv_up"):
		move += Vector2(0,-(600*$Camera2D.zoom.x))
	elif Input.is_action_pressed("mv_down"):
		move += Vector2(0,(600*$Camera2D.zoom.x))
	position += (move * d)

func send_move_order(loc):
	game.get_node("mp").position = get_global_mouse_position()
	$move_order.play()
	for i in selected_units:
		i.move_order = loc + Vector2(rand_range(-10*selected_units.size(), 10*selected_units.size()),rand_range(-10*selected_units.size(), 10*selected_units.size()))

func update_resource_display():
	resource_display.get_node("bits_label").text = str('<bits = ' + str(bits) + '>  (+ ' + str(bit_income) + ')')
	resource_display.get_node("energy_label").text = str('<energy = ' + str(energy) + '>')
	resource_display.get_node("ram_label").text = str('<avail RAM = ' + str(RAM) + '>')
	$Timer.start()

func unit_control():
	var mp = get_global_mouse_position()
	if Input.is_action_just_pressed("left_mouse"):
		for i in selected_units:
			i.toggle_select(false)
		selection.clear()
		box_corner = mp
		box.monitoring = true
	if Input.is_action_just_released("left_mouse"):
		yield(get_tree(), "idle_frame")
#		print(selection)
		if selection.size() > 0:
			for i in selection:
				if "team" in i and i.team == "Player" and !(i == player):
					unit_selected(i)
		selecting = false
		box.monitoring = false
	if Input.is_action_just_released("right_mouse"):
		if selected_units.size() > 0:
			send_move_order(mp)
	if Input.is_action_pressed("left_mouse"):
		if box_corner.distance_to(mp) > 20:
			selecting = true
			box_image.rect_position = box_corner
			box_image.rect_size = mp - box_corner
			box.position = box_image.rect_size / 2
			box_shape.shape.extents = box_image.rect_size / 2
			if selected_units.size() > 0:
				for i in selected_units:
					i.toggle_select(false)
				selected_units.clear()
			if !box_image.visible:
				box_image.show()
	else:
		if box_image.visible:
			box_image.hide()
	
func select_box_entered(body):
#	print('entered!')
	if selecting:
		selection.append(body)
#		print(selection)

func unit_selected(unit):
	if selected_units.find(unit) == -1:
		selected_units.append(unit)
		unit.toggle_select(true)

func unit_died(unit):
	if selected_units.find(unit) != -1:
		selected_units.remove(selected_units.find(unit))

func player_dead():
	player_alive = false

func _on_bit_timer_timeout():
	bits += bit_income
	$bit_timer.start()
