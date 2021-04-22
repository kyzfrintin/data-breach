extends Node2D

onready var player = $player
onready var cam_res = preload("res://scenes/tac_cam.tscn")
onready var ai_res = preload("res://scenes/entities/ai_controller.tscn")
var av_res = preload("res://scenes/entities/units/enemies/AI_avatar.tscn")
onready var ui_res = preload("res://scenes/ui/UI.tscn")
onready var node_res = preload("res://scenes/structures/control_node.tscn")
onready var grids = [get_node("ParallaxBackground/gridclose"), get_node("ParallaxBackground/gridfar"), get_node("ParallaxBackground/gridmed")]

var tac_cam
var mode = "hotseat"
var av_start

func _enter_tree():
	load_level()
	
func _ready():
	add_ui()
	get_node("World/navigation").initialise()
	place_nodes()
	add_ai_start()
	$UI/tac_display.update_pause_buts()
	$MixingDeskMusic.quickplay(0)

func add_ai_start():
	var ai = ai_res.instance()
	add_child(ai)
	ai.name = "ai_controller"
	get_node("units/hostile/avatar").parent = ai

func add_ui():
	var ui = ui_res.instance()
	var cam = cam_res.instance()
	add_child(ui)
	add_child(cam)
	tac_cam = cam
	
func load_level():
	var level = RoomHolder.room.instance()
	add_child(level)
#	level.position += RoomHolder.offset
	move_child(level, 1)
#	for i in get_node("World/Navigation2D").get_children():
#		i.global_position = i.global_position.snapped(Vector2(100,100))
	place_mf_and_char(true, RoomHolder.start_pos[1], RoomHolder.start_pos[0])
	place_mf_and_char(false, RoomHolder.enem_start[1], RoomHolder.enem_start[0])

func place_mf_and_char(play, side, pos):
	var p
	var mf
#	pos += RoomHolder.offset
	if play:
		p = $player
		mf = get_node("World/structures/player_mainframe")
	else:
		p = get_node("units/hostile/avatar")
		mf = get_node("World/structures/ai_mainframe")
	mf.global_position = pos
	match side:
		"top":
			p.global_position = pos + Vector2(0,-200)
		"bottom":
			p.global_position = pos + Vector2(0,200)
		"right":
			p.global_position = pos + Vector2(200,0)
		"left":
			p.global_position = pos + Vector2(-200,0)

func place_nodes():
	for i in RoomHolder.node_spots:
		var node = node_res.instance()
		node.position = i
		node.team = "Neutral"
		get_node("World/structures").add_child(node)

func build_structure(struct, team, loc):
	var s = struct.instance()
	s.team = team
	s.position = loc
	$World/structures.add_child(s)
	tac_cam.update_resource_display()
	pass

func _process(_delta):
	$build_pos.position = get_global_mouse_position().snapped(Vector2(50,50))

func _on_MixingDeskMusic_beat(_beat):
	for i in grids:
		$ParallaxBackground/Tween.interpolate_property(i, 'modulate:a', 1.2, i.modulate.a, 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
		$ParallaxBackground/Tween.start()

func get_path_length(a, b):
	var p = $World/navigation.find_path(a, b)
	return p.size()
