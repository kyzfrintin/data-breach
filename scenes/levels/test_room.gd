extends Node2D


var mode = "hotseat"

func _process(delta):
	$Camera2D.position = $player.position
