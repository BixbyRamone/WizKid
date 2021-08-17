extends Node2D

var rng = RandomNumberGenerator.new()
onready var _flame = $AnimatedSprite
onready var _light = $Light2D

func _ready():
	GameEvents.connect("body_entered", self, "_body_entered")
	GameEvents.connect("extinguish_sconce", self, "_extinguish")
	_flame.set_deferred("frame", (rng.randi() % 3) - 1)
	#(rng.randi() % 3) - 1
func _process(delta):
	pass

	
func _extinguish(body):
	if self.name == body.name:
		_flame.set_deferred("visible", false)
		_light.set_deferred("visible", false)
	
	
func _on_Area2D_body_entered(body):
	if body.name == "Player":
		pass
	if "Trogolodyte" in body.name:
		pass

func _on_Area2D_body_exited(body):
	pass # Replace with function body.


func _on_Area2D_area_entered(area):
	if area.name == "FlameArea":
		_flame.set_deferred("visible", true)
		_light.set_deferred("visible", true)
		_light.set_deferred("energy", 1.25)
