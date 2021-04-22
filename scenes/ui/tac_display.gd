extends Control

onready var game = get_node("../../")
#onready var cam = game.get_node("tac_cam")

# Called when the node enters the scene tree for the first time.
#func _ready():
#	update_pause_buts()

func paused():
	update_pause_buts()

func unpaused():
	update_pause_buts()

func _on_pause_pressed():
	game.tac_cam.tac_pause = true
	game.tac_cam.get_node("bit_timer").paused = true
	game.tac_cam.emit_signal("pause")
	update_pause_buts()

func _on_resume_pressed():
	game.tac_cam.tac_pause = false
	game.tac_cam.get_node("bit_timer").paused = false
	game.tac_cam.emit_signal("unpause")
	update_pause_buts()

func update_pause_buts():
	$pause_buts/HBoxContainer/resume.disabled = (!game.tac_cam.tac_pause)
	$pause_buts/HBoxContainer/pause.disabled = (game.tac_cam.tac_pause)
	
