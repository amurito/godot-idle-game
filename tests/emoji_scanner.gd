# emoji_scanner.gd - Versión corregida y funcional

extends Node2D

var emojis_found = {}
var files_scanned = 0

func _ready():
	print("\n🔍 ESCANEANDO EMOJIS EN EL PROYECTO...\n")
	await get_tree().process_frame
	_scan_directory("res://")
	_print_results()
	print("\n✅ Escaneo completado. Revisa 'res://emojis_list.txt'")
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()

func _scan_directory(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + file_name
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			_scan_directory(full_path + "/")
		else:
			var ext = file_name.get_extension()
			if ext in ["gd", "tscn", "tres", "json"]:
				_scan_file(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _scan_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	file.close()
	files_scanned += 1
	
	# Lista de emojis conocidos para buscar
	var known_emojis = [
		"🍄", "🔥", "☣️", "🕸️", "🤝", "⚖️", "🧠", "🚀", "🕳️", "🎭", "⚱️", "🌀",
		"🌱", "⚡", "💜", "💎", "🌑", "☠️", "💾", "⚙️", "🌿", "🐛", "📤", "🔒", 
		"✅", "❌", "⚠️", "✨", "🏁", "🧬", "🦠", "👑", "🦋", "🟢", "🔵", "🔴", 
		"🟡", "⚪", "🟤", "🟣", "▶", "▼", "▲", "✓", "✗", "→", "↓", "↑", "•", 
		"★", "☆", "▪", "▫", "■", "□", "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩"
	]
	
	for emoji in known_emojis:
		if emoji in content:
			if not emojis_found.has(emoji):
				emojis_found[emoji] = []
			var short_path = file_path.replace("res://", "")
			if short_path not in emojis_found[emoji]:
				emojis_found[emoji].append(short_path)

func _print_results():
	# Línea separadora (sin usar * con string)
	print("\n==================================================")
	print("📋 EMOJIS ENCONTRADOS")
	print("==================================================")
	
	var sorted_emojis = emojis_found.keys()
	sorted_emojis.sort()
	
	for emoji in sorted_emojis:
		var files = emojis_found[emoji]
		print(emoji + "  →  " + ", ".join(files))
	
	print("\n--------------------------------------------------")
	print("📊 Archivos escaneados: " + str(files_scanned))
	print("📊 Emojis únicos: " + str(sorted_emojis.size()))
	
	# Guardar en archivo
	var file = FileAccess.open("res://emojis_list.txt", FileAccess.WRITE)
	if file:
		file.store_line("========== EMOJIS ENCONTRADOS ==========\n")
		for emoji in sorted_emojis:
			file.store_line(emoji + " | " + ", ".join(emojis_found[emoji]))
		file.store_line("\nTotal emojis únicos: " + str(sorted_emojis.size()))
		file.close()
		print("\n✅ Archivo guardado: res://emojis_list.txt")
