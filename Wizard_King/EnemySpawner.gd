extends Node2D

export (PackedScene) var goose
export (PackedScene) var snake
export (PackedScene) var squirrel
export (PackedScene) var troglodyte

var pos_R_up: Vector2
var pos_R_low: Vector2
var pos_L_up: Vector2
var pos_L_low: Vector2
var pos_o: Vector2
var pos_neg_o
var level = ""

onready var _timer = $Timer

var rng = RandomNumberGenerator.new()
var game_is_running = true
var spawn_location: int
var enemies_present = 0
export var enememy_limit:int = 5



func _ready():
	GameEvents.connect("player_killed", self, "_player_killed")
	GameEvents.connect("enemy_killed", self, "_enemy_killed")
	level = get_parent().name
	
	get_spawn_locations(get_viewport_rect().size)
	
	_timer.start()


func _process(delta):
	if game_is_running:
		get_spawn_locations(get_viewport_rect().size)
	

func _on_Timer_timeout():
	spawn_location = rng.randi_range(0, 3)
	var enemy = troglodyte.instance()
	
	match spawn_location:
		0:
			enemy.position = pos_R_up
		1:
			enemy.position = pos_R_low
		2:
			enemy.position = pos_L_up
		3:
			enemy.position = pos_L_low
		4:
			enemy.position = pos_o
		5:
			enemy.position = pos_neg_o
	if enemies_present < enememy_limit:
		add_child(enemy)
		enemies_present+=1
		print(enemies_present)
		# enemies need to be removed from limit once killed
		# enemies need to be removed when too far from player


func get_spawn_locations(view_size):
	#level name needs to be dynamic
	var player = get_node("/root/" + level + "/Player")#get_tree().get_root().get_node("Player")
	if player != null:
		pos_R_up = Vector2(player.position.x + view_size.x/2 + 50, player.position.y - view_size.y + view_size.y * .3)
		pos_R_low = Vector2(player.position.x + view_size.x/2 + 50, player.position.y - view_size.y - view_size.y * .3)
		pos_L_up = Vector2(player.position.x - view_size.x/2 -50, player.position.y - view_size.y + view_size.y * .3)
		pos_L_low = Vector2(player.position.x - view_size.x/2 -5, player.position.y - view_size.y - view_size.y * .3)
		#pos_o = Vector2(player.position.x + 45, player.position.y - view_size.y + 50)
		#pos_neg_o = Vector2(player.position.x - 45, player.position.y - view_size.y + 50)


func _enemy_killed():
	enemies_present-=1


func _player_killed():
	game_is_running = false
