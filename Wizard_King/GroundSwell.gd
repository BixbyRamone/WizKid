extends Node2D

const IDLE_DURATION = 1.0

export var move_to = Vector2.UP * 32
export var speed = 3.0

var follow = Vector2.ZERO

onready var _platform = $Platform
onready var _tween = $Tween
onready var _col_shape = $Platform/CollisionShape2D
onready var _timer = $Timer

func _ready():
	init_tween()
	_col_shape.shape.set_extents(Vector2(16, 16))
	_col_shape.set_deferred("disabled", true)
	
func init_tween():
	_timer.start()
	var duration = move_to.length() / float(speed * 32)
	_tween.interpolate_property(self, "follow", Vector2.ZERO, move_to, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, IDLE_DURATION)
	
	_tween.start()

func _physics_process(delta):
	_platform.position = _platform.position.linear_interpolate(follow, 0.075)


func _on_Timer_timeout():
	_col_shape.set_deferred("disabled", false)
