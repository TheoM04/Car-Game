extends Label

func _on_music_player_beat(n: int) -> void:
	if self is Label:
		self.text = str(n+1)
	else:
		set_visible(n % 2 == 1)
