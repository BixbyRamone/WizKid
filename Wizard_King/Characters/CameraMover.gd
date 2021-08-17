extends KinematicBody2D

export var pan = 100
export var max_speed = 100

onready var _timer = $Timer

var player_pos = Vector2.ZERO
var look_up = false
var look_down = false
var velocity = Vector2.ZERO
var last_input = Vector2.ZERO
var time_to_move = false

func _ready():
	player_pos = position
	GameEvents.connect("look_down", self, "_on_look_down")
	GameEvents.connect("look_up", self, "_on_look_up")
	
func _physics_process(delta):
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2(0, 0):
		last_input = input_vector
		
	if look_up == true && self.position.y > -30:
		move_and_slide(Vector2(0, -500), Vector2.UP)
	if look_down == true && self.position.y < 30:
		move_and_slide(Vector2(0, 500), Vector2.UP)
		
	if Input.is_action_just_released("ui_down") || Input.is_action_just_released("ui_up"):
		look_up = false
		look_down = false
		
	if Input.is_action_pressed("ui_left") || Input.is_action_pressed("ui_right"):
		_timer.set_wait_time(_timer.wait_time)
		_timer.start()

	if last_input.x != 0 and input_vector.x == 0 and time_to_move == true:
		velocity += last_input * pan * delta
		velocity = velocity.clamped(max_speed * delta)
		
	var collided_body = move_and_collide(velocity)

	if collided_body != null:
		if collided_body.local_shape.name == "CollisionShape2D" || collided_body.local_shape.name == "CollisionShape2D2":
			time_to_move = false
			velocity = Vector2.ZERO
		
func _on_look_up():
	look_up = true
	
func _on_look_down():
	look_down = true


func _on_Timer_timeout():
	time_to_move = true
