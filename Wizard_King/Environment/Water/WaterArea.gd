extends Area2D



func _on_WaterArea_body_entered(body):
	GameEvents.emit_signal("water_entered", body)


func _on_WaterArea_body_exited(body):
	GameEvents.emit_signal("water_exited", body)
