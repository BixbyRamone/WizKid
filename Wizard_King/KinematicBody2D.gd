extends KinematicBody2D


export var MAX_SPEED = 120
export var MAX_WATER_SPEED = 100
export var ACCELERATION = 170
export var WATER_ACCELERATION = 100
export var AIR_ACCELERATION = 10
export var GRAVITY = 20
export var WATER_GRAVITY = 5
export var MAX_TERMINAL_VELOCITY = 200
export var MAX_WATER_TERMINAL_VEL = 100
export var JUMP_POWER = 325
export var WATER_JUMP_POWER = 100
export var HIGH_JUMP_POWER = 400
export var FRICTION = 1000
export var DUCK_FRICTION = 100
export var BACKFLIP_MULTIPLYER = -1.1
export var wind_level : int = 1
export var water_level : int = 1
export var fire_level : int = 1
export var earth_level : int = 1

export (PackedScene) var Goose

const UP = Vector2.UP

var stats = PlayerStats
var face_right = false
var ducked = false
var is_in_skid = false
var is_in_water = false
var velocity = Vector2()
var camera_velocity = Vector2()
var look_up = false
var look_down = false
var jump_forgive = true
var jump_was_pressed = false
var fire_on = false
var is_in_flip = false
var is_hit = false
var earth_col_spot

onready var translate_check : float = self.transform.origin.x
onready var _animation_player = $AnimationPlayer
onready var _animation_tree = $AnimationTree
onready var _animation_state = _animation_tree.get("parameters/playback")
onready var _collision_shape = $CollisionShape2D
onready var _hurtbox_shape_col = $Hurtbox/CollisionShape2D
onready var _breath = $Breath
onready var _look_timer = $Look
onready var _camera = $CameraMover
onready var _jump_assist = $JumpAssist
onready var _jump_hitbox = $Hitbox/CollisionShape2D
onready var _stats = $Stats
onready var _char_sprite = $Sprite
onready var _flame_whirl = $Sprite/FireWhirl
onready var _flameR = $Sprite/Flame/AnimatedSpriteR
onready var _flameR_area = $Sprite/Flame/AnimatedSpriteR/FlameArea/CollisionShape2D
onready var _flameR_light = $Sprite/Flame/AnimatedSpriteR/Light2D
onready var _flameL = $Sprite/Flame/AnimatedSpriteL
onready var _flameL_area = $Sprite/Flame/AnimatedSpriteL/FlameArea/CollisionShape2D
onready var _flameL_light = $Sprite/Flame/AnimatedSpriteL/Light2D2
onready var _firewhirl_hitbox = $FireWhirlHitBox/CollisionShape2D
onready var _enemy_spawn_timer = $EnemySpawnTimer
onready var _camera_collider = $CameraCollider


func _ready():
	stats.connect("no_health", self, "_on_Stats_no_health")
	GameEvents.connect("hit_invince", self, "_hit_invince")
	#_hurtbox_shape_col.set_deferred("disabled", true)
	

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector.normalized()
	
	if input_vector.x != 0:
		_animation_tree.set("parameters/Run/blend_position", input_vector)
		_animation_tree.set("parameters/Jump/blend_position", input_vector)
		_animation_tree.set("parameters/Idle/blend_position", Vector2(input_vector.x, 0))
		_animation_tree.set("parameters/Fall/blend_position", input_vector)
		_animation_tree.set("parameters/Flip/blend_position", input_vector)
		_animation_tree.set("parameters/Flame/blend_position", input_vector)
		_animation_tree.set("parameters/IdleDuck/blend_position", input_vector)
		_animation_tree.set("parameters/IsHit/blend_position", input_vector)
		_animation_tree.set("parameters/IdleSwim/blend_position", input_vector)
		_animation_tree.set("parameters/Swim/blend_position", input_vector)
		_animation_tree.set("paramaters/IdleLookUp/blend_position", input_vector)
		
	
	if !is_in_water:
		handle_movement(delta, input_vector)
	if is_in_water:
		water_movement(delta, input_vector)

func handle_movement(delta, input_vector: Vector2):
	if input_vector.x != 0:
		if input_vector.x > 0:
			face_right = true
		elif input_vector.x < 0:
			face_right = false
		
		if is_on_floor():
			_animation_state.travel("Run")
		if jump_was_pressed:
			_animation_state.travel("Jump")
		if !is_on_floor():
			_animation_state.travel("Fall")
	elif fire_on:
		_animation_state.travel("Flame")
	else:
		_animation_state.travel("Idle")
	if is_hit:
		_animation_state.travel("IsHit")
		
	velocity.y += GRAVITY
	velocity.y = min(velocity.y, MAX_TERMINAL_VELOCITY)
	
	if Input.is_action_just_pressed("Jump") and input_vector.y != 1:
		jump_was_pressed = true
		remember_jump_time()
		if jump_forgive:
			velocity.y = -JUMP_POWER
			
	if is_on_floor():
		is_in_flip = false
		if !jump_was_pressed:
			_flame_whirl.set_deferred("visible", false)
			_flame_whirl.stop()
			_firewhirl_hitbox.set_deferred("disabled", true)
		if jump_was_pressed:
			velocity.y = -JUMP_POWER
			
		jump_forgive = true
		
		if input_vector.x > 0:
			#face_right = true
			_flameL.set_deferred("visible", false)
			_flameL_area.set_deferred("disabled", true)
			_flameL_light.set_deferred("visible", false)
			is_in_skid = false
			if  velocity.x < -MAX_SPEED/4:
				is_in_skid = true
		elif input_vector.x < 0:
			#face_right = false
			if is_on_floor():
				_flameR.set_deferred("visible", false)
				_flameR_area.set_deferred("disabled", true)
				_flameR_light.set_deferred("visible", false)
				is_in_skid = false
			if is_on_floor() and velocity.x > MAX_SPEED/4:
				is_in_skid = true
		
		if jump_was_pressed and is_in_skid:
			is_in_flip = true
			if fire_on:
				_firewhirl_hitbox.set_deferred("disabled", false)
				_flame_whirl.set_deferred("visible", true)
				_flame_whirl.play()
				if face_right:
					_flame_whirl.set_deferred("flip_h", true)
				else:
					_flame_whirl.set_deferred("flip_h", false)
			jump_was_pressed = true
			velocity = Vector2(velocity.x * BACKFLIP_MULTIPLYER, -HIGH_JUMP_POWER)
			
		if Input.is_action_just_pressed("Jump") and input_vector.y == 1:
			drop()
			
		if Input.is_action_just_pressed("ui_up"):
			look_up = true
			_look_timer.start()
		if Input.is_action_just_pressed("ui_down"):
			look_down = true
			_look_timer.start()
	if Input.is_action_just_released("ui_down") || Input.is_action_just_released("ui_up"):
		look_up = false
		look_down = false
		_look_timer.stop()
		_camera.set_deferred("position", Vector2(0, -10))
			
	if !is_on_floor():
		coyote_time()
		
	if input_vector != Vector2.ZERO && !look_down && !look_up:
		velocity = velocity.move_toward(Vector2(input_vector) * MAX_SPEED, ACCELERATION * delta)
	elif is_on_floor():
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	if Input.is_action_just_pressed("Wind"):
		velocity = velocity + wind(input_vector)
		
	
	if Input.is_action_just_pressed("Earth"):
		if earth_col_spot !=null:
			earth(earth_col_spot)
		
		
	if Input.is_action_pressed("Fire") and !is_in_flip:
		fire_on = true
	else:
		fire_on = false
		_flameR.set_deferred("visible", false)
		_flameR_light.set_deferred("visible", false)
		_flameR_area.set_deferred("disabled", true)
		
		_flameL.set_deferred("visible", false)
		_flameL_light.set_deferred("visible", false)
		_flameL_area.set_deferred("disabled", true)
	if velocity.x > -30 and velocity.x < 30 and input_vector.x == 0:
		is_in_skid = false
			
	if fire_on:
		if face_right:
			_flameR.set_deferred("visible", true)
			_flameR_light.set_deferred("visible", true)
			_flameR_area.set_deferred("disabled", false)
			
			_flameL.set_deferred("visible", false)
			_flameL_light.set_deferred("visible", false)
			_flameL_area.set_deferred("disabled", true)
		elif !face_right:
			
			_flameL.set_deferred("visible", true)
			_flameL_light.set_deferred("visible", true)
			_flameL_area.set_deferred("disabled", false)
			
			_flameR.set_deferred("visible", false)
			_flameR_light.set_deferred("visible", false)
			_flameR_area.set_deferred("disabled", true)
		
	if input_vector.y == 1 and is_on_floor():
		duck()
	else:
		ducked = false
		_collision_shape.set_deferred("position", Vector2.ZERO)
		_collision_shape.set_deferred("scale", Vector2.ONE)
		_hurtbox_shape_col.set_deferred("position", Vector2.ZERO)
		_hurtbox_shape_col.set_deferred("scale", Vector2.ONE)
		
	if input_vector.y == -1 and is_on_floor():
		_animation_state.travel("IdleLookUp")
		
	if is_on_ceiling():
		velocity.y = 0
		
	if is_on_wall() and velocity.y > 0:
		velocity = velocity.move_toward(Vector2(0, velocity.y), FRICTION * 1.2 * delta)
	
	if !is_on_floor():
		coyote_time()
		
	var snap = Vector2.DOWN * 16 if !jump_was_pressed else Vector2.ZERO
	
	check_for_in_tile()
	
	animate_jump(velocity)
	
	move_and_slide_with_snap(velocity, snap, UP)
	
	var slides = get_slide_count()
	if(slides && !ducked):
		slope(slides)

	_camera.move_and_slide(camera_velocity, UP)


func check_for_in_tile():
	if test_move(transform, Vector2(1, 0)) \
		and test_move(transform, Vector2(-1, 0)) \
		and test_move(transform, Vector2(0, 1)) \
		and test_move(transform, Vector2(0, -1)):
			queue_free()
			
			
func slope(slides: int):
	for i in slides:
		if slides != 0:
			var touched = get_slide_collision(i)
			earth_col_spot = touched
			if is_on_floor() && touched.normal.y < 1.0 && velocity.x != 0.0:
				velocity.y = touched.normal.y
			
			
func water_movement(delta, input_vector: Vector2):
	fire_on = false
	_animation_state.travel("IdleSwim")
	if is_on_floor():
		_animation_state.travel("Idle")
		
	velocity.y += WATER_GRAVITY
	if velocity.y >= MAX_TERMINAL_VELOCITY:
		pass
	velocity.y = min(velocity.y, MAX_WATER_TERMINAL_VEL)
	
	if input_vector != Vector2.ZERO && !is_on_floor():
		_animation_state.travel("Swim")
	if input_vector != Vector2.ZERO && is_on_floor():
		_animation_state.travel("Run")
		
	if input_vector.x >= 0:
		face_right = true
	elif input_vector.x < 0:
		face_right = false
		
	if Input.is_action_just_pressed("Jump") and input_vector.y != 1:
		velocity.y = -WATER_JUMP_POWER
		if face_right:
			_animation_player.play("SwimRight")
		if !face_right:
			_animation_player.play("SwimLeft")
			
	if Input.is_action_just_pressed("Jump") and input_vector.y == 1:
		velocity.y = WATER_JUMP_POWER
		
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(Vector2(input_vector) * MAX_WATER_SPEED, WATER_ACCELERATION * delta)
		if is_on_floor():
			velocity.x = velocity.x / 1.05
	elif input_vector == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2(0, velocity.y), FRICTION * delta)
		
	move_and_slide(velocity, UP)
	
	
func wind(inp_vect : Vector2) -> Vector2:
	var wind_vel = Vector2(50, 400)
	if inp_vect != Vector2.ZERO:
		wind_vel = wind_vel * inp_vect
	elif face_right:
		wind_vel = Vector2(150, 0)
	elif !face_right:
		wind_vel = Vector2(-150, 0)
	#is_in_skid = false
	return wind_vel
	

func earth(collision):
	GameEvents.emit_signal("earth_tile", collision, self.position)
	pass
	
func animate_jump(vel: Vector2) -> void:
	if !is_on_floor() and !is_in_skid:
		_animation_state.travel("Jump")
			
	if !is_on_floor() and is_in_skid:
		_collision_shape.hide()
		_animation_state.travel("Flip")
		if face_right and vel.y < 0:
			_animation_state.travel("Flip")
		if !face_right and vel.y < 0:
			_animation_state.travel("Flip")


func duck():
	_collision_shape.set_deferred("position", Vector2(1, 3))
	_collision_shape.set_deferred("scale", Vector2(1, 0.8))
	#_collision_shape.show()
	_hurtbox_shape_col.set_deferred("position", Vector2(1, 3.25))
	_hurtbox_shape_col.set_deferred("scale", Vector2(1, 0.8))
	ducked = true
	_animation_state.travel("IdleDuck")
	if face_right:
		pass
		#_animation_player.play("DuckRight")
	else:
		is_in_skid = false
		pass
		#_animation_player.play("DuckLeft")
		
		
func coyote_time():
	yield(get_tree().create_timer(0.1), "timeout")
	jump_forgive = false


func remember_jump_time():
	yield(get_tree().create_timer(0.1), "timeout")
	jump_was_pressed = false
	

func drop():
		self.position.y += 1


func _on_Area2D_body_entered(body):
	if body.name == "Player":
		GameEvents.emit_signal("player_obscurred")


func _on_Area2D_body_exited(body):
	if body.name == "Player":
		GameEvents.emit_signal("player_unobscured")


func _on_WaterArea_body_entered(body):
	if body.name == "Player":
		is_in_water = true
		_breath.start()


func _on_WaterArea_body_exited(body):
	if body.name == "Player":
		is_in_water = false
		_breath.stop()
		
		
func _hit_invince():
	is_hit = true
	yield(get_tree().create_timer(.4), "timeout")
	is_hit = false


func _on_Breath_timeout():
	_breath.stop()
	pass # Replace with function body.


func _on_NextArea_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene("res://Forest.tscn")


func _on_Look_timeout():
	if look_up:
		GameEvents.emit_signal("look_up")
	if look_down:
		GameEvents.emit_signal("look_down")


func _on_Hitbox_area_entered(area):
	var enemy_hitbox_top = area.get_node("CollisionShape2D").global_position.y# - area.get_node("CollisionShape2D").shape.height / 2
	if _jump_hitbox.global_position.y < enemy_hitbox_top:
		velocity.y = -JUMP_POWER
		if jump_was_pressed:
			velocity.y = velocity.y * 1.2


func _on_Hurtbox_area_entered(area):
	if !is_hit:
		var enemy_velocity = area.get_parent().velocity.x
		# velocity.x = direction of enemy velocity, times either player velocioty or 150 (whichever is bigger)
		velocity.x = (int(enemy_velocity > 0) - int(enemy_velocity < 0) ) * max(abs(enemy_velocity) * 1.1 + velocity.x, 150)
		#_stats.health -= 1
		stats.health -= 1
		GameEvents.emit_signal("hit_invince")



func _on_Stats_no_health():
	_enemy_spawn_timer.stop()
	GameEvents.emit_signal("player_killed")
	queue_free()


func _on_FireWhirl_animation_finished():
	_flame_whirl.set_deferred("visible", false)
	_firewhirl_hitbox.set_deferred("disabled", true)
	_flame_whirl.stop()


func _on_EnemySpawnTimer_timeout():
	#$CameraMover/Camera2D/SpawnPathR.offset
	pass # Replace with function body.


func _sconce_entered(body) -> void:
	GameEvents.emit_signal("body_entered", body)
