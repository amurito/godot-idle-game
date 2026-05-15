extends Node2D

func _ready():
	var paths = [
		"res://fonts/NotoColorEmoji.ttf",
		"res://assets/fonts/NotoColorEmoji.ttf",
        "res://NotoColorEmoji.ttf"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			print("✅ Encontrado: ", p)
		else:
			print("❌ No existe: ", p)
