extends Node2D

func _ready():
	pass
	#GameEvents.connect("water_tiled_touched", self, "_on_tile_entered")
	
func _on_WaterTileArea_body_entered(body):
	print("water tile touch")
	GameEvents.emit_signal("water_tile_touched")
