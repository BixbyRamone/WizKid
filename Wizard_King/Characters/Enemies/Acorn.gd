extends KinematicBody2D

export var GRAVITY = 20
export var MAX_TERMINAL_VELOCITY = 200
export var MAX_SPEED = 120
export var ACCELERATION = 170
export var THROW_POWER = Vector2(400, -500)


var velocity = Vector2.ZERO
var is_dead = false
var player: KinematicBody2D

onready var is_just_thrown = true

onready var _hitbox = $Hitbox


func _physics_process(delta):
	var throw_dir: Vector2
	rotation_degrees += 10
	velocity.y += GRAVITY
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
	var direction = Vector2.ZERO
	
	if player != null:
		throw_dir = player.global_position - position
		direction = (player.global_position - global_position).normalized()
		direction = Vector2(direction.x, .5)
		
	#var scene = get_tree().current_scene
	#get_parent().remove_child(self)
	#scene.add_child(self)
	
	if player == null:
		queue_free()

	if is_just_thrown:
		velocity = THROW_POWER * direction
		is_just_thrown = false
	
	if is_dead:
		velocity = Vector2(0, GRAVITY* 6)
	
	move_and_collide(velocity * delta)


func launch(direction):
	var temp = global_transform
	var scene = get_tree().current_scene
	get_parent().remove_child(self)
	scene.add_child(self)
	velocity = THROW_POWER * Vector2(direction, 1)

func _on_VisibilityNotifier2D_screen_exited():
	yield(get_tree().create_timer(0.2), "timeout")
	queue_free()


func _on_Hurtbox_area_entered(area):
	_hitbox.set_deferred("disabled", true)
	is_dead = true


func _on_PlayerDetectionZone_body_entered(body):
	player = body
