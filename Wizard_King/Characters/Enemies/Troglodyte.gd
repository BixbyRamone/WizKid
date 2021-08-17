extends KinematicBody2D

export var GRAVITY = 20
export var MAX_TERMINAL_VELOCITY = 200
export var SPEED = 10
export var ATTACK_SPEED = 90
export var ACCELERATION = 100
export var FRICTION = 1000
export var JUMP_POWER = 350

enum {
	WANDER, #0
	CRAWL, #1
	ATTACK, #2
	LEAP, #3
	DROP, #4
	EXT_WALK, #5
	EXT_CRAWL, #6
	SNUFF, #7
	BLOW, #8
	JUMP
}

var state = WANDER

var grav_dir = 1
var UP = Vector2.UP
var direction: int = 1
var rng = RandomNumberGenerator.new()
var velocity = Vector2()
var target = Vector2()
var alert = false
var flipped = false
var goal
var sconce_dist = 10
var can_jump = true
var in_viewport = false

onready var _stats = $Stats
onready var _animation_player = $AnimationPlayer
onready var _timer = $DirectionTimer
onready var _sprite = $Sprite
onready var _stand_collision = $CollisionShapeStand
onready var _crawl_collision = $CollisionShapeCrawl
#onready var _crawl_collision_flip = $CollisionShapeCrawlFlip
onready var _player_detection_zone = $Position2D/PlayerDetectionZone
onready var _area_detection_zone = $AreaDetectionZone
onready var _view_collision = $Position2D/PlayerDetectionZone/CollisionShape2D
onready var _visibility_notifier = $VisibilityNotifier2D
onready var _removal_timer = $RemovalTimer
onready var _flip_timer = $FlipTimer
onready var _torch_finder = $AreaDetectionZone
onready var _floor_check = $FloorChecker

func _ready():
	GameEvents.connect("water_entered", self, "_on_WaterArea_body_entered")
	GameEvents.connect("water_exited", self, "_on_WaterArea_body_exited")

	_floor_check.position.x = _stand_collision.shape.get_radius() * direction
	_timer.start()
	_flip_timer.start()
	
func _physics_process(delta):
	
	velocity.y += GRAVITY * grav_dir
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)

	match state:
		WANDER:
			if velocity.x != 0:
				_animation_player.play("Walk")
			if abs(velocity.x) < 2:
				_animation_player.play("Idle")
				
			_floor_check.set_deferred("position", Vector2(_stand_collision.shape.get_radius() * direction, _floor_check.position.y))
			#_floor_check.position.x = _stand_collision.shape.get_radius() * direction
			seek_player()
			locate_torches()

			handle_movement(delta, SPEED)
		CRAWL:
			change_collision_to_crawl()
			_floor_check.set_deferred("position", Vector2(_stand_collision.shape.get_height() * direction, _floor_check.position.y))
			if velocity.x != 0:
				_animation_player.play("Crawl")
			else:
				_animation_player.play("CrawlIdle")
			
			seek_player()
			locate_torches()
			handle_movement(delta, SPEED * 2)
		
			if flipped:
				pass
		ATTACK:
			change_collision_to_crawl()
			_view_collision.scale = Vector2(1.5, 2)
			if velocity.x != 0:
				_animation_player.play("Crawl")
			else:
				_animation_player.play("CrawlIdle")
				
			_floor_check.position.x = _stand_collision.shape.get_height() * direction
			
			
			var player = _player_detection_zone.player
			
			if player != null and is_on_floor() or is_on_ceiling():
				handle_attack(delta, player)
			elif is_on_floor() or is_on_ceiling():
				state = CRAWL
		LEAP:
			velocity.x = 0
			change_collision_to_stand()
			_animation_player.play("Jump")
			
			if  !flipped and is_on_floor():
				state = CRAWL
			if flipped and is_on_ceiling():
				state = CRAWL

		EXT_WALK:
			var item = _area_detection_zone.item

			if item != null:
				handle_attack(delta, item)
			if item == null:
				state = WANDER
			if is_on_wall():
				item = null
				direction = -direction
			seek_player()
		EXT_CRAWL:
			var item = _area_detection_zone.item
			if item != null:
				handle_attack(delta, item)
			if item == null:
				state = CRAWL
			seek_player()
		SNUFF:
			velocity = Vector2.ZERO
			_animation_player.play("Snuff")
			yield(get_tree().create_timer(_animation_player.current_animation_length), "timeout")
			GameEvents.emit_signal("extinguish_sconce", goal.get_parent())

			if goal.get_parent().get_node("Light2D").visible == false:
				state = WANDER
		BLOW:
			velocity = Vector2.ZERO
			_animation_player.play("Blow")
			yield(get_tree().create_timer(_animation_player.current_animation_length), "timeout")
			GameEvents.emit_signal("extinguish_sconce", goal.get_parent())
			if goal.get_parent().get_node("Light2D").visible == false:
				state = CRAWL
	
	if direction == 1:
		_sprite.flip_h = true
		_player_detection_zone.set_deferred("rotation_degrees", 180)
		_torch_finder.set_deferred("rotation_degrees", 180)

	if direction == -1:
		_sprite.flip_h = false
		_player_detection_zone.set_deferred("rotation_degrees", 0)
		_torch_finder.set_deferred("rotation_degrees", 0)
	
	var snap = Vector2.DOWN * 16 if can_jump else Vector2.ZERO
	
	if is_on_floor() or is_on_ceiling():
		velocity.y = 0
	
	if is_on_floor():
		_sprite.flip_v = false
	if is_on_ceiling():
		snap = Vector2.UP * 16 if can_jump else Vector2.ZERO
		_sprite.flip_v = true
	#move_and_slide(velocity, UP)
	check_for_in_tile()
	move_and_slide_with_snap(velocity, snap, UP)

	
func seek_player():
	if _player_detection_zone.can_see_player():
		state = ATTACK


func locate_torches():
	if _area_detection_zone.target_item() and state == WANDER:
		state = EXT_WALK
	if _area_detection_zone.target_item() and state == CRAWL:
		state = EXT_CRAWL


func change_collision_to_crawl():
	_crawl_collision.set_deferred("disabled", false)
	_stand_collision.set_deferred("disabled", true)


func change_collision_to_stand():
	_stand_collision.set_deferred("disabled", false)
	_crawl_collision.set_deferred("disabled", true)
	#_crawl_collision_flip.set_deferred("disabled", true)
	
		
func handle_movement(delta, speed):
	if is_on_wall() or !_floor_check.is_colliding() and is_on_floor():
		direction = direction * -1
	
	velocity.x = SPEED * direction	
	velocity = velocity.move_toward(Vector2(direction, 0) * speed, ACCELERATION * delta)
	
	if direction == 0:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	

func handle_attack(delta, target):
	goal = target
	var attackDirection = (target.global_position - global_position).normalized()
	if attackDirection.x > 0:
		direction = 1
		#facing = direction
	if attackDirection.x < 0:
		direction = -1
		#facing = direction
	
	if can_jump and is_on_wall() and is_on_floor():
		can_jump = false
		#velocity.y = -JUMP_POWER
		
		velocity.x = velocity.x/1.5
		jump_delay_reset()
	
		
	if state == ATTACK:
		velocity.x = ATTACK_SPEED * direction
		velocity = velocity.move_toward(attackDirection * ATTACK_SPEED, ACCELERATION * delta)
	
	if state == WANDER || state == EXT_WALK:
		state = EXT_WALK
		velocity.x = SPEED * direction
		velocity = velocity.move_toward(attackDirection * SPEED, ACCELERATION * delta)
		if global_position.distance_to(target.global_position) < 20:
			state = SNUFF
	
	if state == CRAWL || state == EXT_CRAWL:
		state = EXT_CRAWL
		velocity.x = SPEED * 2 * direction
		velocity = velocity.move_toward(attackDirection * SPEED * 2, ACCELERATION * delta)
		if global_position.distance_to(target.global_position) < 30:
			state = BLOW

func handle_extinguish(delta, target):
	var torch_direction = (target.global_position - global_position).normalized()
	if torch_direction.x > 0:
		direction = 1
		#facing = direction
	if torch_direction.x < 0:
		direction = -1
		#facing = direction
	
	velocity = velocity.move_toward(torch_direction * SPEED, ACCELERATION * delta)


func flip():
	_crawl_collision.position.y = -_crawl_collision.position.y
	
	
func jump_delay_reset():
	yield(get_tree().create_timer(1), "timeout")
	can_jump = true
	
	
func _on_DirectionTimer_timeout():
	if direction != 0:
		direction = 0
	else:
		rng.randomize()
		direction = (rng.randi() % 3) - 1
	
	if direction != 0:
		_timer.start(5)
	else:
		_timer.start(2.5)
	

func _on_FlipTimer_timeout():
	if state == CRAWL:
		flip()
		grav_dir = -grav_dir
		state = LEAP
		
		
func check_for_in_tile():
	if test_move(transform, Vector2(1, 0)) \
		and test_move(transform, Vector2(-1, 0)) \
		and test_move(transform, Vector2(0, 1)) \
		and test_move(transform, Vector2(0, -1)):
			queue_free()
