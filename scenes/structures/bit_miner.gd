extends Node2D

export (String, "Player", "AI") var team

onready var game = get_node("../../../")

var bit_cost = 50
var parent

func _ready():
	if team == "Player":
		if !parent:
			parent = game.get_node("tac_cam")
		$box.color = Color8(138, 242, 270, 255)
	else:
		if !parent:
			parent = game.get_node("ai_controller")
		$box.color = Color8(260, 71, 61, 255)
	parent.bit_income += 0.5
#	print(parent.name)
