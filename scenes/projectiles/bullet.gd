extends Area2D

var dir := Vector2()
var speed = 300
var parent
var team

func _ready():
	$spawn_sound.spawn_node = parent
	$Polygon2D.look_at(position + dir)

func _process(delta):
	if !get_node("../tac_cam").tac_pause:
		position += (dir*speed) * delta
		$Timer.paused = false
	else:
		$Timer.paused = true

func _on_bullet_body_entered(body):
	if body == parent: return
	if body.has_method("hit") and body.team != team:
		body.hit(10, parent)
		self.queue_free()
	if "geom" in body.name:
#		print('ouch! wall!')
		self.queue_free()

func _on_Timer_timeout():
	self.queue_free()
