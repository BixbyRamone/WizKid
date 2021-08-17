extends Area2D

var item = null
var old_item = null

var area_width = ProjectSettings.get("display/window/size/width")
var area_height = ProjectSettings.get("display/window/size/height")


func target_item():
	if item != null:
		if "Sconce" in item.get_parent().name:
			var sconce_light = item.get_parent().get_node("Light2D")
			if sconce_light.visible == true:
				return item != null

func _on_AreaDetectionZone_area_entered(area):
	if "Sconce" in str(area.get_path()):
		if area.get_parent().get_node("Light2D").visible == true:
			item = area
			



func _on_AreaDetectionZone_area_exited(area):
	if area == item:
		item = null
