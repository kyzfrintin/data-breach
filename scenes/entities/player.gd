extends KinematicBody2D

onready var game = get_parent()
onready var bul_res = preload("res://scenes/projectiles/bullet.tscn")

export var speed = 25
export var max_hp := 500.0
export var accel = 0.04
export var decel = 0.04

var capturer = true
var team = "Player"
var can_fire = true
var hp = 20.0
var velocity : Vector2

signal death

func _ready():
	hp = max_hp
	update_hp(max_hp)

func _process(delta):
	var move = Vector2()
	if game.mode == "hotseat":
		$Polygon2D.look_at(get_global_mouse_position())
		move = movement_input(delta)
		attack_input()
	move = move_and_slide(move)

func movement_input(delta):
	var move = Vector2()
	if Input.is_action_pressed("mv_left"):
		move += Vector2(-speed,0)
	elif Input.is_action_pressed("mv_right"):
		move += Vector2(speed,0)
	if Input.is_action_pressed("mv_up"):
		move += Vector2(0,-speed)
	elif Input.is_action_pressed("mv_down"):
		move += Vector2(0,speed)
	if move == Vector2(0,0):
		velocity = lerp(velocity, move, decel)
	else:
		velocity = lerp(velocity, move, accel)
	return velocity * (delta*1000)

func attack_input():
	if Input.is_action_pressed("left_mouse") and can_fire:
		$attack_timer.start()
		can_fire = false
		var bul = bul_res.instance()
		bul.position = position
		bul.team = "Player"
		bul.dir = position.direction_to(get_global_mouse_position())
		bul.parent = self
		game.add_child(bul)

func hit(amnt, _entity):
	hp -= amnt
	if hp <= 0:
		hp = 0
		die()
	update_hp(hp)

func update_hp(value):
	$ProgressBar.value = value
	$ProgressBar.max_value = max_hp

func die():
	emit_signal("death")
	queue_free()

func _on_attack_timer_timeout():
	can_fire =true
