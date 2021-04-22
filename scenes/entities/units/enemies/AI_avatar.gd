extends "res://scenes/entities/units/baseAI.gd"

onready var bul_res = preload("res://scenes/projectiles/bullet.tscn")
onready var parent = get_node("../../../ai_controller")

var capturer = true
var general
var capturing
var node_capture = null

signal captured

func _process(delta):
	if is_instance_valid(target):
		if target.is_queued_for_deletion():
			target = null
			return
		$Polygon2D.look_at(target.position)
	elif path:
		$Polygon2D.look_at(Vector2(path[0].x, path[0].y))
	if capturing:
		if node_capture.cap_prog == 100:
			emit_signal("captured", node_capture)
			capturing = false
			node_capture = null

func _ready():
	team = "AI"
	add_to_group("ai_units")

func delegate_attack():
	can_attack = false
	$attack_timer.start(cooldown)
	var bul = bul_res.instance()
	bul.position = position
	bul.team = "AI"
	bul.dir = position.direction_to(target.position)
	bul.parent = self
	game.add_child(bul)

func _on_cap_det_area_entered(area):
	if "aligning" in area.get_parent():
		capturing = true
		node_capture = area.get_parent()

func on_death():
	parent.new_avatar()
