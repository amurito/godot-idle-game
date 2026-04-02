extends Node

# LegacyManager.gd — Autoload Global
# Gestiona los Puntos de Legado (PL) y las mejoras persistentes entre partidas.

const LEGACY_PATH := "user://legacy_bank.json"

# --- ESTADO GLOBAL ---
var legacy_points: int = 0
var unlocked_legacies: Dictionary = {
	"deflacion": false,      # Reduce factor de precios un 5%
	"memoria_recurso": false, # Primera compra gratis
	"red_confianza": false,   # Trueque eficiencia 0.75 -> 0.85
	"impulso_manual": false,  # Click base 1.0 -> 2.0
	"sincronia_total": false, # Bonus biomasa afecta al click
	"inercia_escala": false,   # Bonus md por nivel contabilidad
	"horizonte_estructural": false, # Rompe el cap de alpha y k
	"redireccion_energia": false,   # 10% click power a pasivo
	"legado_alostasis": false, # NG+ Secreto (Homeostasis -> Alostasis)
	"legado_homeorresis": false, # NG+ Secreto (Alostasis -> Homeorresis)
	"semilla_cosmica": false, # NG+ Secreto (Esporulación -> Panspermia)
	"mente_colmena": false, # NG+ Secreto (Singularidad -> IA)
	"metabolismo_glitch": false # NG+ Secreto (Parasitismo -> Survival)
}
var total_runs: int = 0
var last_run_ending: String = ""

# --- DEFINICIÓN DE COSTOS Y DESCRIPCIONES ---
const LEGACY_DATA := {
	"deflacion": {"cost": 4, "name": "Deflación Biótica", "desc": "Reduce un 5% el escalado de precios de todas las mejoras."},
	"memoria_recurso": {"cost": 5, "name": "Memoria de Recurso", "desc": "La primera compra de cada productor es GRATUITA al inicio de la run."},
	"red_confianza": {"cost": 3, "name": "Red de Confianza", "desc": "La eficiencia base del Trueque sube permanentemente del 75% al 85%."},
	"impulso_manual": {"cost": 3, "name": "Impulso Manual", "desc": "Tu click base inicial es el doble de potente (1.0 -> 2.0)."},
	"sincronia_total": {"cost": 7, "name": "Sincronía Total", "desc": "El bonus de biomasa (Beta) ahora también multiplica el poder de tus clicks."},
	"inercia_escala": {"cost": 6, "name": "Inercia de Escala", "desc": "Cada nivel de Contabilidad potencia un +5% extra al Trabajo Manual (md)."},
	"horizonte_estructural": {"cost": 10, "name": "Horizonte Estructural", "desc": "Rompe los límites de Rigidez (k) y Adaptación (α), permitiendo escalado infinito."},
	"redireccion_energia": {"cost": 5, "name": "Redirección de Energía", "desc": "El 10% de tu potencia de Click se suma automáticamente a tus ingresos pasivos por segundo."},
	"legado_alostasis": {"cost": 0, "name": "Resiliencia Alostática", "desc": "El sistema ha aprendido a recalibrarse tras el caos. Bonus permanentes de Alostasis activos."},
	"legado_homeorresis": {"cost": 0, "name": "Trascendencia Cristalina", "desc": "El hongo ya no requiere regular su estrés; directamente, lo ha trascendido."}
}

func _ready():
	load_legacy()

# --- PERSISTENCIA ---
func save_legacy():
	var data = {
		"legacy_points": legacy_points,
		"unlocked_legacies": unlocked_legacies,
		"spores_buffer": internal_spores_total,
		"total_runs": total_runs,
		"last_run_ending": last_run_ending
	}
	var file = FileAccess.open(LEGACY_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("💾 [Legacy] Banco genético guardado.")

func load_legacy():
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	var file = FileAccess.open(LEGACY_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			legacy_points = data.get("legacy_points", 0)
			var loaded_unlocked = data.get("unlocked_legacies", {})
			for key in loaded_unlocked.keys():
				if unlocked_legacies.has(key):
					unlocked_legacies[key] = loaded_unlocked[key]
			
			internal_spores_total = data.get("spores_buffer", 0.0)
			total_runs = data.get("total_runs", 0)
			last_run_ending = data.get("last_run_ending", "")
			print("📂 [Legacy] Banco genético cargado y sincronizado. PL:", legacy_points)
		file.close()

# --- LÓGICA DEL BANCO ---
func can_afford(legacy_id: String) -> bool:
	if not LEGACY_DATA.has(legacy_id): return false
	return legacy_points >= LEGACY_DATA[legacy_id].cost and not unlocked_legacies[legacy_id]

func purchase_legacy(legacy_id: String) -> bool:
	if can_afford(legacy_id):
		legacy_points -= LEGACY_DATA[legacy_id].cost
		unlocked_legacies[legacy_id] = true
		save_legacy()
		return true
	return false

# --- CONVERSIÓN DE ESPORAS (v0.8.42) ---
var internal_spores_total: float = 0.0

func add_spores(amount: float):
	internal_spores_total += amount
	var new_pl = int(internal_spores_total / 50.0)
	if new_pl > 0:
		add_pl(new_pl)
		internal_spores_total -= (new_pl * 50.0)
	save_legacy()

func add_pl(amount: int):
	legacy_points += amount
	save_legacy()
	print("✨ [Legacy] Ganaste +", amount, " PL. Total:", legacy_points)

# --- GETTERS PARA EL JUEGO ---
func get_buff_value(legacy_id: String) -> bool:
	return unlocked_legacies.get(legacy_id, false)

func increment_run():
	total_runs += 1
	save_legacy()
	print("📈 Ciclo Biótico completado. Total: ", total_runs)
