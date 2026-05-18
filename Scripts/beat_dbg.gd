extends Label

var visible_at

func _ready() -> void:
	set_visible(false)

func _process(_delta: float) -> void:
	pass

func _on_music_player_beat(n: int) -> void:
	set_visible(n % 2 == 0)
