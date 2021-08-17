extends KinematicBody2D

export var GRAVITY = 20
export var MAX_TERMINAL_VELOCITY = 200
export var SPEED = 40
export var ACCELERATION = 300
export var FRICTION = 200
var UP = Vector2.UP

var active_grav = 0

enum {
	WANDER,
	RUN,
	ATTACK,
	IDLE
}	

export (PackedScene) var acorn

var state = WANDER

var direction: int
var rng = RandomNumberGenerator.new()
var facing: int
var velocity = Vector2()
var target = Vector2()
var in_viewport = false
var gravity: float
var ready_to_attack = true
var player: KinematicBody2D

onready var _stats = $Stats
onready var _animation_player = $AnimationPlayer
onready var _timer = $DirectionTimer
onready var _sprite = $Sprite
onready var _player_detection_zone = $PlayerDetectionZone
onready var _player_attack_zone = $PlayerAttackZone
onready var _attack_zone_col = $PlayerAttackZone/CollisionShape2D
onready var _visibility_notifier = $VisibilityNotifier2D
onready var _removal_timer = $RemovalTimer
onready var _attack_reset = $AttackReset

func _ready():
	GameEvents.connect("water_entered", self, "_water_area_entered")
	direction = -1
	_timer.start(1.5)
	gravity = GRAVITY
	

func _physics_process(delta):
	velocity.y += gravity
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
	
	match state:
		WANDER:
			if velocity.x != 0:
				_animation_player.play("Run")
			if velocity.x == 0:
				_animation_player.play("Idle")
			_sprite.flip_h = velocity.x > 0
			run_from_player()
			attack_player()
			handle_movement(delta)
		RUN:
			_animation_player.play("Run")
			var player = _player_detection_zone.player
			if player == null:
					player = _player_attack_zone.player
			if player == null:
				state = WANDER
			if player:
				handle_flee(delta, player)
			_sprite.flip_h = velocity.x > 0
		ATTACK:
			velocity.x = 0
			if ready_to_attack && !is_on_wall():
				var player = _player_attack_zone.player
				_animation_player.play("Throw")
				handle_attack()
				yield(get_tree().create_timer(.6), "timeout")
			if !_animation_player.is_playing() || is_on_wall():
				state = RUN
			if player:
				_sprite.flip_h = player.global_position > global_position

		IDLE:
			velocity.y += gravity
			velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
			_animation_player.play("Sniff")
			run_from_player()
			attack_player()
	
	if is_on_wall():
		gravity = 0
		velocity.y = -SPEED
		set_deferred("rotation_degrees", -90)
	if !is_on_wall():	
		gravity = GRAVITY
		set_deferred("rotation_degrees", 0)
	
	check_for_in_tile()
	move_and_slide(velocity, UP)
	

func check_for_in_tile():
	if test_move(transform, Vector2(1, 0)) \
		and test_move(transform, Vector2(-1, 0)) \
		and test_move(transform, Vector2(0, 1)) \
		and test_move(transform, Vector2(0, -1)):
			GameEvents.emit_signal("enemy_killed")
			queue_free()
			
			
func run_from_player():
	if _player_detection_zone.can_see_player():
		state = RUN


func attack_player():
	if _player_attack_zone.can_see_player():
		state = ATTACK

func handle_attack():
	var new_acorn = acorn.instance()
	add_child(new_acorn)
	ready_to_attack = false
	_attack_reset.start()
	

func handle_movement(delta):
	velocity.y += gravity
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
		
	if is_on_wall():
		direction = -direction
		
	velocity.x = SPEED * direction
	if direction != 0:
		facing = direction
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	

func handle_flee(delta, player):
	velocity.y += gravity
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
		
	var fleeDirection = (global_position - player.global_position).normalized()
		
	direction = fleeDirection.x
	velocity = velocity.move_toward(fleeDirection * SPEED * 10, ACCELERATION * delta)
	

func _water_area_entered(body):
	if body.name == self.name:
		GameEvents.emit_signal("enemy_killed")
		queue_free()
	
func _on_Stats_no_health():
	GameEvents.emit_signal("enemy_killed")
	queue_free()


func _on_Stats_health_changed(value):
	pass # Replace with function body.


func _on_DirectionTimer_timeout():
	direction = rng.randi() % 2
	direction = direction-1
	_timer.start(3.5)


func _on_RemovalTimer_timeout():
	print("Should be removed: ", self.name)


func _on_Hurtbox_area_entered(area):
	if area.name == "Hitbox":
		var player_hitbox_bottom = area.get_child(0).global_position.y + area.get_child(0).shape.height / 2
		#if global_position.y > player_hitbox_bottom:
		_stats.health -= 1
		velocity.x = -velocity.x
	if area.name == "FireWhirlHitBox":
		_stats.health -= 5
		velocity.x = -velocity.x * 1.45


func _on_AttackReset_timeout():
	ready_to_attack = true


func _on_PlayerDetectionZone_body_entered(body):
	_attack_zone_col.set_deferred("disabled", true)
	player = body


func _on_PlayerDetectionZone_body_exited(body):
	_attack_zone_col.set_deferred("disabled", false)


