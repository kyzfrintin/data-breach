extends Button

onready var game = get_node("../../../../../../../../")
onready var tac_cam = game.get_node("tac_cam")
onready var world = game.get_node("World")
onready var structures = game.get_node("World/structures")
onready var container = get_node("../../../../../")
onready var click = container.get_node("button_press")
onready var place = container.get_node("place_struct")
onready var bp = game.get_node("build_pos")

var placing = false
var instance
var ghost
var valid_place := false

export (PackedScene) var structure
export (int) var cost

func _ready():
#	print(game.name)
# warning-ignore:return_value_discarded
	connect("pressed", self, "buy")
	
func buy():
	if placing: return
	if game.tac_cam.bits >= cost:
		click.play()
		game.tac_cam.bits -= cost
		placing = true
		instance = structure.instance()
		instance.team = "Player"
		game.tac_cam.update_resource_display()
		ghost = instance.get_node("box").duplicate()
		game.add_child(ghost)
		
func _process(_delta):
	if placing:
		var mp = bp.position
		if ghost:
			ghost.position = mp
		var acol = bp.get_node("Area").get_overlapping_areas()
		var bcol = bp.get_node("Area").get_overlapping_bodies()
		var areas = 0
		if acol.size() > 0:
			for i in acol:
				if i.name == "range" and i.get_parent().team == "Player":
					areas += 1
					ghost.color = Color(0.156863, 0.933333, 0.043137)
#		if bcol.size() > 0:
#			for i in bcol:
#				if 'geom' in i.name:
#					valid_place = false
#					ghost.color = Color(0.949219, 0.040787, 0.040787)
		if areas > 0:
			valid_place = true
			ghost.color = Color(0.156863, 0.933333, 0.043137)
		else:
			valid_place = false
			ghost.color = Color(0.949219, 0.040787, 0.040787)
		if Input.is_action_just_pressed("left_mouse") and valid_place:
#			print('placed!')
			ghost.queue_free()
			place.play()
			instance.team = "Player"
			instance.parent = game.tac_cam
			world.get_node("structures").add_child(instance)
			instance.global_position = mp
			placing = false
