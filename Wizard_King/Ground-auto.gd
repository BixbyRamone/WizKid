extends TileMap

export (PackedScene) var ground_swell

const UP = Vector2.UP

func _ready():
	GameEvents.connect("earth_tile", self, "_remove_tile")

func _physics_process(delta):
	if get_child(0) is KinematicBody2D:
		var kin_bod = get_child(0)
		kin_bod.move_and_slide(Vector2(0, -10), UP)
		#self.remove_child(kin_bod)
		#kin_bod.queue_free()
		
		
func _input(event):
	if event is InputEventMouseButton:
		var cell = world_to_map(Vector2(event.position.x, event.position.y))
		var cell_id = get_cell(event.position.x, event.position.y)
		self.set_cell(cell.x, cell.y, TileMap.INVALID_CELL)


func _remove_tile(collision, position):
	if collision.collider == self:
		var tile_pos = collision.collider.world_to_map(position)
		tile_pos -= collision.normal
		var tile = collision.collider.get_cell(tile_pos.x, tile_pos.y)

		if tile > -1:
			self.set_cellv(tile_pos, -1)
			update_bitmask_area(tile_pos)
			
			var platform = ground_swell.instance()
			platform.position = map_to_world(tile_pos) + Vector2(16, 48)
			add_child(platform)
			yield(get_tree().create_timer(2.8), "timeout")
			self.set_cellv(tile_pos, tile)
			update_bitmask_area(tile_pos)
			platform.queue_free()
	
func create_ground_swell(tile_pos: Vector2):
	var ground_rise = KinematicBody2D.new()
	var g_r_collider = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	ground_rise.collision_layer = 32
	ground_rise.collision_mask = 0
	add_child(ground_rise)
	
	rectangle.set_extents(Vector2(16, 16))
	g_r_collider.set_shape(rectangle)
	ground_rise.position = map_to_world(tile_pos)# + Vector2(0, 28)
	ground_rise.add_child(g_r_collider)
	pass
