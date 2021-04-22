extends Node2D

var game
var controller 
var mission = null
var mis_stat = "idle"
var moving = false
var retreating = false
var fighting = false

var point_man = null
var units = []
var full_hp = 0.0
var total_hp = 0.0

func _ready():
	setup_army()

func setup_army():
	for i in units:
		i.general = self
		full_hp += i.hp
		i.connect("death", self, "unit_died")
		i.connect("engaged", self, "enemy_engaged")
		if "capturer" in i:
			point_man = i
			units.remove(units.find(i))
			i.connect("captured", self, "captured_node")
			
func captured_node(node):
	mission = null
	mis_stat = "idle"
	controller.nodes.append(node)

func unit_died(u):
	units.remove(units.find(u))

func _on_Timer_timeout():
	var hp := 0.0
	for i in units:
		if !is_instance_valid(i):
			units.remove(units.find(i))
		else:
			hp += i.hp
	total_hp = hp
#	print(units.size())
	$Timer.start()
	
func enemy_engaged(t):
	for i in units:
		i.target = t
	fighting = true
	retreating = false
	moving = false

#btree tasks

func task_has_mission(task):
	if mission:
		task.succeed()
	else:
		task.fail()

func task_is_fighting(task):
	if fighting:
		task.succeed()
	else:
		task.failed()

func task_is_losing(task):
	if total_hp <= (full_hp * 0.3):
		task.succeed()
	else:
		task.failed()

func task_is_moving(task):
	if moving:
		task.succeed()
	else:
		task.failed()

func task_is_army_alive(task):
	if units.size() > 0:
		task.succeed()
	else:
		task.failed()
	
func task_is_mission_defended(task):
	var def = mission.defences
	if def.size() > 0:
		task.succeed()
	else:
		task.failed()

func task_goto_mission(task):
	if !moving:
		for i in units:
			i.move_order = mission.position + Vector2(rand_range(-10*units.size(), 10*units.size()),rand_range(-10*units.size(), 10*units.size()))
		if point_man:
			point_man.move_order = mission.position
		moving = true
		fighting = false
		retreating = false
		mis_stat = "in_progress"
		task.succeed()
	else:
		task.failed()

func task_at_mission(task):
	var u = []
	for i in units:
		if i != null:
			u.append(i)
	if point_man:
		u.append(point_man)
	var num = units.size()
	var n = mission
	for i in u:
		if i.global_position.distance_to(n.global_position) < 250:
			num -=1
	if num == 0:
		task.succeed()
	else:
		task.failed()

func task_is_capturing(task):
	if point_man:
		if point_man.capturing:
			task.succeed()
		else:
			task.failed()
	else:
		task.failed()

func task_capture_mission(task):
	if point_man:
		point_man.move_order = mission.position
		task.succeed()
	else:
		task.failed()
	
func task_retreat(task):
	fighting = false
	moving = false
	retreating = true
	for i in units:
		i.target = null
		i.get_node("scan_timer").stop()
		i.retreating = true
		i.move_order = controller.forward_base.position + Vector2(rand_range(-10*units.size(), 10*units.size()),rand_range(-10*units.size(), 10*units.size()))
	task.succeed()

func task_disband(task):
	queue_free()
	task.succeed()


