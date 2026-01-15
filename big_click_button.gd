extends Button

@onready var reactor = $ReactorVisual
var main : Node = null

func set_main(m):
	main = m
	print("🧬 BigClickButton conectado a:", main)

func _process(_delta):
	if main:
		var p = main.get_click_power()
		reactor.set_power(p)

func _on_mouse_entered():
	reactor.hover()

func _on_mouse_exited():
	reactor.unhover()

func _on_pressed():
	if main:
		reactor.click()
		main._on_BigClickButton_pressed()
