extends KinematicBody2D

export var GRAVITY = 20
export var MAX_TERMINAL_VELOCITY = 200
export var UP = Vector2.UP
export var SPEED = 20
export var ACCELERATION = 300
export var FRICTION = 200
export var FLAP = 400

enum {
	CHASE,
	WANDER,
	AIRBORN,
	RESURFACE
}

var state = WANDER

var direction: int
var rng = RandomNumberGenerator.new()
var facing: int
var velocity = Vector2()
var target = Vector2()
var ready_to_flap = true
var is_in_water = false
var needs_to_resurface = false
var in_viewport = false


onready var _stats = $Stats
onready var _animation_player = $AnimationPlayer
onready var _timer = $DirectionTimer
onready var _sprite = $Sprite
onready var _player_detection_zone = $PlayerDetectionZone
onready var _visibility_notifier = $VisibilityNotifier2D
onready var _removal_timer = $RemovalTimer


func _ready():
	GameEvents.connect("water_entered", self, "_on_WaterArea_body_entered")
	GameEvents.connect("water_exited", self, "_on_WaterArea_body_exited")
	direction = (rng.randi() % 3) - 1
	_timer.start(3.5)


func _physics_process(delta):
	if needs_to_resurface:
		state = RESURFACE
	velocity.y += GRAVITY
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
	
	match state:
		CHASE:
			_timer.stop()
			if !is_in_water:
				_animation_player.play("Threat")
			if is_in_water:
				_animation_player.play("Float")
			
			var player = _player_detection_zone.player
			if player != null:
				_sprite.flip_h = global_position.x < player.global_position.x
			else:
				_sprite.flip_h = velocity.x > 0
			if player != null:
				handle_attack(delta, player)
			else:
				state = WANDER
		WANDER:
			if velocity.x == 0:
				if !is_in_water:
					_animation_player.play("Idle")
				if is_in_water:
					_animation_player.play("FloatIdle")
			if velocity.x != 0:
				if !is_in_water:
					_animation_player.play("Walk")
				if is_in_water:
					_animation_player.play("Float")
		
			_sprite.flip_h = velocity.x > 0
			seek_player()
			handle_movement(delta)
		AIRBORN:
			_sprite.flip_h = velocity.x > 0
			_animation_player.play("Flap")
			if is_on_floor():
				state = WANDER
			if is_in_water:
				state = RESURFACE
		RESURFACE:
			_sprite.flip_h = velocity.x > 0
			_animation_player.play("Flap")
			if is_in_water:
				velocity.y = -80
			if !is_in_water:
				needs_to_resurface = false
				state = WANDER
				
	move_and_slide(velocity, UP)
	#_sprite.flip_h = velocity.x > 0
	

func seek_player():
	if _player_detection_zone.can_see_player():
		state = CHASE
		
		
func handle_movement(delta):
	if !is_in_water:
		velocity.y += GRAVITY
		velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
	if is_in_water:
		velocity.y = 0
		
	if is_on_wall():
		direction = -direction
		
	velocity.x = SPEED * direction
	if direction != 0:
		facing = direction
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	

func handle_water_movement(delta):
	velocity.y = 0
	

func handle_attack(delta, player):
	if !is_in_water:
		velocity.y += GRAVITY
		velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
	if is_in_water:
		velocity.y = 0
	
	var attackDirection = (player.global_position - global_position).normalized()
	if attackDirection.y < -0.005:
		if ready_to_flap && is_on_wall():
			ready_to_flap = false
			velocity.y = -FLAP
			flap_delay_reset()
			state = AIRBORN
		
	velocity = velocity.move_toward(attackDirection * SPEED * 10, ACCELERATION * delta)
	
	#animate_goose()
	#move_and_slide(velocity, UP)
		

func _on_DirectionTimer_timeout():
	direction = (rng.randi() % 3) - 1
	_timer.start(3.5)


func flap_delay_reset():
	yield(get_tree().create_timer(.6), "timeout")
	ready_to_flap = true


func _on_Hurtbox_area_entered(area):
	if area.name == "Hitbox":
		var player_hitbox_bottom = area.get_child(0).global_position.y + area.get_child(0).shape.height / 2
		if global_position.y > player_hitbox_bottom:
			_stats.health -= 1
			velocity.x = -velocity.x
			print(_stats.health)
	if area.name == "FireWhirlHitBox":
		_stats.health -= 5
		velocity.x = -velocity.x * 1.45


func _on_Hitbox_area_entered(area):
	velocity.y = -FLAP/2
	velocity.x = -velocity.x

func _on_Stats_no_health():
	GameEvents.emit_signal("enemy_killed")
	queue_free()


func _on_WaterArea_body_entered(body):
	if "Goose" in body.name:
		is_in_water = true
	if body.name == "ResurfaceCollision":#resurface collision exists on Goose
		needs_to_resurface = true


func _on_WaterArea_body_exited(body):
	if "Goose" in body.name:
		is_in_water = false
	if body.name == "ResurfaceCollision":
		needs_to_resurface = false


func check_for_in_tile():
	if test_move(transform, Vector2(1, 0)) \
		and test_move(transform, Vector2(-1, 0)) \
		and test_move(transform, Vector2(0, 1)) \
		and test_move(transform, Vector2(0, -1)):
			queue_free()
			

func _on_VisibilityNotifier2D_viewport_entered(viewport):
	_removal_timer.stop()
	pass


func _on_VisibilityNotifier2D_viewport_exited(viewport):
	_removal_timer.start()
	pass


func _on_RemovalTimer_timeout():
	GameEvents.emit_signal("enemy_killed")
	queue_free()
