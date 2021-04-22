extends KinematicBody2D

export (String, "Player", "Neutral", "AI") var team
export var max_hp := 250.0
onready var game = get_node("../../../")
onready var bul_res = preload("res://scenes/projectiles/bullet.tscn")

var bit_cost = 50
var target = null
var ranger = 200.0
var can_fire = true
var hp = 400.0
var parent

signal death

func _ready():
	hp = max_hp
	update_hp(max_hp)
	$range/CollisionShape2D.shape.radius = ranger
	if team == "Player":
		if !parent:
			parent = get_node("../../../tac_cam")
		$box.color = Color8(138, 242, 270, 255)
	elif team == "AI":
		if !parent:
			parent = get_node("../../../ai_controller")
		$box.color = Color8(260, 71, 61, 255)

func _process(_delta):
	if game.get_node("tac_cam").tac_pause: return
	if is_instance_valid(target):
		$Line2D.look_at(target.position)
		if can_fire:
			can_fire = false
			fire()
			$attack_timer.start()
	if $ProgressBar.modulate.a > 0:
		$ProgressBar.modulate.a -= 0.001
	elif $ProgressBar.visible:
		$ProgressBar.hide()

func _on_range_body_entered(body):
	if is_instance_valid(target): return
	if body == self: return
	if "team" in body and body.has_method("hit"):
		if body.team != team:
			target = body
			target.connect("death", self, "target_died")

func update_hp(value):
	$ProgressBar.value = value
	$ProgressBar.max_value = max_hp
	$ProgressBar.show()
	$ProgressBar.modulate.a = 1

func fire():
	var bul = bul_res.instance()
	bul.position = $Line2D/Position2D.global_position
	bul.team = "Neutral"
	bul.dir = position.direction_to(target.position)
	bul.parent = self
	game.add_child(bul)

func _on_attack_timer_timeout():
	can_fire = true

func target_died(_t):
	target = null
	
func hit(amnt, entity):
	hp -= amnt
	if target:
		if entity != target:
			target = entity
	if hp <= 0:
		emit_signal("death", self)
		die()
	update_hp(hp)

func die():
	queue_free()
