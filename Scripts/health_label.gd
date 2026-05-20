extends Label

func _on_car_health_update(health: float) -> void:
	self.text = str(health)
