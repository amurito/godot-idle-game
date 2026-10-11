extends Node
## MockMain — sustituto mínimo de main.gd para probar SaveManager sin instanciar la escena.
## build_save_data(main) lee estos campos y apply_save_data(main, data) los escribe y termina
## llamando a main.update_ui(), que acá no hace nada (la vista no forma parte del contrato
## de serialización).

var memory_trigger_count: int = 0
var institutions_unlocked: bool = false


func update_ui() -> void:
	pass


func reset_local_state() -> void:
	pass
