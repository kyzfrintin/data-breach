extends Node2D

export (String, "Player", "AI") var team

onready var game = get_node("../../../")
var parent
var build_queue = []

signal build_complete
signal all_builds_complete

var bit_cost = 50

func _ready():
	if team == "Player":
		$box.color = Color8(138, 242, 270, 255)
		add_to_group("player_constructors")
		parent = game.get_node("tac_cam")
	elif team == "AI":
		$box.color = Color8(260, 71, 61, 255)
		add_to_group("ai_constructors")
		parent = game.get_node("ai_controller")
	connect("all_builds_complete", parent, "on_build_finish")

func _process(_delta):
	if build_queue.size() > 0:
		for i in build_queue:
			add_build_order(i.get("unit"), i.get("num"), i.get("loc"), i.get("time"))
			build_queue.remove(build_queue.find(i))
			yield(self, "build_complete")
		emit_signal("all_builds_complete")
	
func add_build_order(unit, num, loc, time):
	if game.get_node("tac_cam").tac_pause:
		yield(game.get_node("tac_cam"), "unpause")
	for i in num:
		var u = unit.instance()
		u.position = $Position2D.global_position
		u.move_order = loc + Vector2(rand_range(-10*num, 10*num),rand_range(-10*num, 10*num))
		yield(get_tree().create_timer(time), "timeout")
		if team == "Player":
			u.team = "Player"
			game.get_node("units/friendly").add_child(u)
		else:
			u.team = "AI"
			game.get_node("units/hostile").add_child(u)
			parent.unassigned_units.append(u)
	emit_signal("build_complete")
