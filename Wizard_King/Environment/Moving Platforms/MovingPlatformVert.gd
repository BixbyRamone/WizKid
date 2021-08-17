extends Node2D

const IDLE_DURATION = 1.0

export var move_to = Vector2.UP * 32 * 3
export var speed = 3.0

var follow = Vector2.ZERO

onready var _platform = $KinematicBody2D
onready var _tween = $Tween

func _ready():
	init_tween()
	
func init_tween():
	var duration = move_to.length() / float(speed * 32)
	_tween.interpolate_property(self, "follow", Vector2.ZERO, move_to, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, IDLE_DURATION)
	_tween.interpolate_property(self, "follow", move_to, Vector2.ZERO, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, duration + IDLE_DURATION * 2)
	
	_tween.start()

func _physics_process(delta):
	_platform.position = _platform.position.linear_interpolate(follow, 0.075)
