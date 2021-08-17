extends TileMap

func _ready():
	GameEvents.connect("player_obscurred", self, "hide_tiles")
	GameEvents.connect("player_unobscured", self, "show_tiles")
	self.show()
	
func hide_tiles():
	self.hide()

func show_tiles():
	self.show()
