extends Node
## Captura del Banco Genético del menú principal (sólo para revisión visual; corre en sandbox).
##   run_sandboxed.ps1 -Visual -Scene res://tests/sim/BankShot.tscn -SceneArgs "--scenario=<id>","--screenshot=<ruta.png>"
const SimGuard := preload("res://tests/sim/SimGuard.gd")
const Scenarios := preload("res://tests/sim/Scenarios.gd")

func _ready() -> void:
	var args := SimGuard.parse_args()
	Scenarios.apply_legacy(Scenarios.ALL[str(args.get("scenario", "a3_funcion_pura_late"))].get("legacy", {}))
	var menu: Node = load("res://MainMenu.tscn").instantiate()
	add_child(menu)
	for _i in 3:
		await get_tree().process_frame
	menu.slot_selector_panel.visible = false
	menu._on_legacy_pressed()
	for _i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(str(args["screenshot"]))
	print("[BankShot] captura → %s" % args["screenshot"])
	get_tree().quit(0)
