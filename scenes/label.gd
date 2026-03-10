extends Label


var initial_offset: Vector2

func _ready() -> void:
	initial_offset = position
	top_level = true

func _process(_delta: float) -> void:
	if get_parent():
		global_position = get_parent().global_position + initial_offset
		rotation = 0
	
