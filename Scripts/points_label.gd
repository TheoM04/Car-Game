extends Label

func _ready():
	text = "0"

func set_points(points: int):
	text = str(points)
