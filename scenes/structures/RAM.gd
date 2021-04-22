extends Node2D

export (String, "Player", "AI") var team

var bit_cost = 50
var parent

func _ready():
	if team == "Player":
		if !parent:
			parent = get_node("../../../tac_cam")
		$box.color = Color8(138, 242, 270, 255)
	else:
		if !parent:
			parent = get_node("../../../ai_controller")
		$box.color = Color8(260, 71, 61, 255)
	parent.RAM += 8
