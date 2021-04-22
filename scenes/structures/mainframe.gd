extends Node2D

export (String, "Player", "AI") var team

var parent
var hp = 1000
var home_units = []

signal death

func _ready():
	if team == "Player":
		modulate = Color8(138, 242, 270, 255)
	else:
		modulate = Color8(260, 71, 61, 255)

func hit(amnt, entity):
	hp -= amnt
	if hp <= 0:
		emit_signal("death")
		die()

func die():
	queue_free()

func _process(delta):
	$out_box.rotate(0.005)
	$out_box2.rotate(-0.007)
	$out_box3.rotate(0.01)
	for i in home_units:
		if i.healing:
			if i.hp < i.max_hp:
				i.hp += 0.01 * delta
			else:
				i.hp = i.max_hp

func _on_range_body_entered(body):
	match team:
		"AI":
			if body.is_in_group("ai_units"):
				home_units.append(body)
				body.get_node("heal_timer").start()
				if body.retreating:
					body.retreating = false
		"Player":
			if body.is_in_group("friendly_units"):
				home_units.append(body)
				body.get_node("heal_timer").start()

func _on_range_body_exited(body):
	if home_units.find(body) != -1:
		home_units.remove(home_units.find(body))
	
