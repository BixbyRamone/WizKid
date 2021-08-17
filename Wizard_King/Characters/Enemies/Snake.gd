extends KinematicBody2D

const HEALTH = 1
const GRAVITY = 20
const MAX_TERMINAL_VELOCITY = 200
const UP = Vector2.UP
const SPEED = 28
const ACCELERATION = 170
const BOUNCE_POWER = 400

var direction = -1
var velocity = Vector2()
var can_turn = true
var in_roll = false

enum {
	WANDER,
	ROLL
}
var state = WANDER

onready var _animation_player = $AnimationPlayer
onready var _timer = $Timer
onready var _standard_shape = $SlitherCollision
onready var _roll_shape = $RollCollision
onready var _hitbox_standard = $Hitbox/CollisionShape2D
onready var _hitbox_roll = $HitboxRoll/CollisionShape2D
onready var _hurtbox_standard = $Hurtbox/CollisionShape2D
onready var _hurtbox_roll = $HurtboxRoll/CollisionShape2D


func _ready():
	_roll_shape.set_deferred("disabled", true)
	#direction = rng.randi() % 2
	#direction = direction-1
	
	
func _physics_process(delta):
	match state:
			WANDER:
				pass
				#handle_movement(delta)
			ROLL:
				pass
				#handle_roll(delta)
	if in_roll:
		handle_roll(delta)
	else:
		handle_movement(delta)
	bounce(delta)
	
	
func handle_movement(delta):
	_animation_player.play("MoveLeft")
	velocity.y += GRAVITY
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
	
	velocity.x = SPEED * direction

	if is_on_wall() && can_turn:
		direction = -direction
		velocity.x = -velocity.x
		_hitbox_standard.get_parent().position.x = -_hitbox_standard.get_parent().position.x
		_timer.start()
	
	if velocity.x < 0:
		#velocity.x = abs(velocity.x) *-1
		get_node("Sprite").set_flip_h(false)
	if velocity.x > 0:
		#velocity.x = abs(velocity.x)
		get_node("Sprite").set_flip_h(true)
	
	#if is_on_ceiling():
		#in_roll = true

	move_and_slide(velocity, UP)


func handle_roll(delta):
	_standard_shape.set_deferred("disabled", true)
	_roll_shape.set_deferred("disabled", false)
	_hitbox_standard.set_deferred("disabled", true)
	_hitbox_roll.set_deferred("disabled", false)
	_hurtbox_standard.set_deferred("daisabled", true)
	_hurtbox_roll.set_deferred("disabled", false)
	_animation_player.play("Roll")
	
	velocity.y += GRAVITY
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
	
	velocity = velocity.move_toward(Vector2(direction, 0) * SPEED*7, ACCELERATION * delta)
	
	velocity.y = velocity.y - 10
	
	if is_on_wall() && can_turn:
		velocity.x = 0 + direction
		velocity.y = -BOUNCE_POWER
		direction = -direction
		velocity.x = -velocity.x
		_timer.start()
		
		
	move_and_slide(velocity, UP)
	
	
func bounce(delta):
	if is_on_floor() and velocity.y > 0:
		velocity.y = velocity.y / 2

func _on_Timer_timeout():
	can_turn = true


func _on_Hurtbox_area_entered(area):
	if position.y > area.global_position.y:
		in_roll = true


func _on_HurtboxRoll_area_entered(area):
	pass # check area type. take damage if element
