extends "res://scenes/entities/units/baseAI.gd"

onready var bul_res = preload("res://scenes/projectiles/bullet.tscn")

var ram_cost = 2

signal selected

func _process(delta):
	if is_instance_valid(target):
		if target.is_queued_for_deletion():
			target = null
			return
		$aim.look_at(target.position)
	elif path:
		$aim.look_at(Vector2(path[0].x,path[0].y))

func toggle_select(on):
	if on:
		$select_particle.emitting = true
	else:
		$select_particle.emitting = false

func _ready():
# warning-ignore:return_value_discarded
	$AnimationPlayer.playback_speed = rand_range(0.85,1.5)
	connect("selected", tac_cam, "unit_selected", [self])
	connect("death", tac_cam, "unit_died", [self])
	add_to_group("friendly_units")
	
func delegate_attack():
	can_attack = false
	$attack_timer.start(cooldown)
	var bul = bul_res.instance()
	bul.position = $aim/Line2D/Position2D.global_position
	bul.team = "Player"
	bul.dir = position.direction_to(target.position)
	bul.parent = self
	game.add_child(bul)

func _on_base_ally_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
#		print(name + ' selected!')
		emit_signal("selected")

func on_death():
	pathline.queue_free()
	if tac_cam.selected_units.find(self) != -1:
		tac_cam.selected_units.remove(tac_cam.selected_units.find(self))
	tac_cam.RAM += ram_cost
