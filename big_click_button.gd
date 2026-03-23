extends Button

@onready var main := get_node("/root/UIRoot")
@onready var reactor_visual: Node2D = $ReactorVisual

func _pressed() -> void:
	if main and main.has_method("on_reactor_click"):
		main.on_reactor_click()
func set_active_delta(value: float) -> void:
	reactor_visual.set_active_delta(value)

func set_display_delta(value: float) -> void:
	reactor_visual.set_display_delta(value)
