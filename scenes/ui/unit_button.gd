extends Button

onready var game = get_node("../../../../../../../../")
onready var tac_cam = game.get_node("tac_cam")
onready var units = game.get_node("units/friendly")
onready var scroll = get_node("../../../../HSlider")
onready var container = get_node("../../../../../")
onready var bp = game.get_node("build_pos")
onready var click = container.get_node("button_press")
onready var place = container.get_node("place_unit")

var placing = false
var instance
var ghost
var valid_place := false

export (PackedScene) var unit
export (int) var cost
export (int) var build_time
export (int) var ram_cost

func _ready():
# warning-ignore:return_value_discarded
	connect("pressed", self, "open")
	get_node("../Label").text = (str(cost) + ' BITS')
	
func open():
	if placing: return
	if scroll.value == 0: return
	if get_tree().get_nodes_in_group("player_constructors").size() == 0: return
	var num = scroll.value
	if (game.tac_cam.bits >= cost * num) and (game.tac_cam.RAM >= ram_cost * num):
		click.play()
		game.tac_cam.bits -= cost * num
		game.tac_cam.RAM -= ram_cost * num
		placing = true
		instance = unit.instance()
		instance.team = "Player"
		game.tac_cam.update_resource_display()
		ghost = instance.get_node("Polygon2D").duplicate()
		game.add_child(ghost)
	
func _process(_delta):
	if placing:
		var mp = game.get_node("build_pos").position
		if ghost:
			ghost.position = mp
		var bcol = bp.get_node("Area").get_overlapping_bodies()
		if bcol.size() > 0:
			for i in bcol:
				if i.name == "level_geom":
					valid_place = false
					ghost.color = Color(0.949219, 0.040787, 0.040787)
		else:
			valid_place = true
			ghost.color = Color(0.156863, 0.933333, 0.043137)
		if Input.is_action_just_pressed("left_mouse"):
			place.play()
			ghost.queue_free()
			send_build_order(unit, scroll.value, mp, build_time)
			scroll.value = 0
			placing = false

func send_build_order(u, num, loc, time):
	var con = get_tree().get_nodes_in_group("player_constructors")
	for i in con:
#		i.add_build_order(u, num/con.size(), loc, time)
		i.build_queue.append({
			"unit": u,
			"num": num/con.size(),
			"loc": loc,
			"time": time
		})
	pass
