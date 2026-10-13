extends Node

# EvoManager.gd — Autoload
# Maneja la evolución del genoma y las mutaciones irreversibles.
# Actúa de forma autónoma: observa a BiosphereEngine y main.gd,
# muta su propio estado y emite señales para que main actúe.

signal mutation_unlocked(mutation_id: String)
signal mutation_activated(mutation_id: String, display_name: String)
signal run_ended_by_mutation(route: String, reason: String)
@warning_ignore("unused_signal")
signal primordio_iniciado()
@warning_ignore("unused_signal")
signal primordio_abortado(abort_count: int, reason: String)
@warning_ignore("unused_signal")
signal seta_formada_signal()

## Emitida en cada tick de autólisis que tira el d20 de Fagocitosis Doble.
## roll: cara obtenida (1-20); success_min: cara mínima para el 2º devour; extra: devours extra logrados (0/1/2).
signal autofagia_dice_rolled(roll: int, success_min: int, extra: int)

var genome := {
	"hiperasimilacion": "dormido",
	"parasitismo": "dormido",
	"red_micelial": "dormido",
	"esporulacion": "dormido",
	"simbiosis": "dormido",
	"homeostasis": "dormido",
	"trascendencia": "dormido",
	"depredador": "dormido",
	"met_oscuro": "dormido",
	"allostasis": "dormido",
	"homeorhesis": "dormido"
}

var mutation_hyperassimilation := false
var mutation_symbiosis := false
var mutation_homeostasis := false
var mutation_red_micelial := false
var mutation_sporulation := false
var mutation_parasitism := false
var mutation_allostasis := false
var mutation_homeorhesis := false

var red_micelial_phase := 0
enum RedBranch { NONE, COLONIZATION, SYMBIOSIS }
var red_branch_selected: int = RedBranch.NONE

# === CICLO BIOLÓGICO: PRIMORDIO ===
var primordio_active: bool = false
var primordio_timer: float = 0.0
var primordio_abort_count: int = 0
var seta_formada: bool = false
var nucleo_conciencia := false # Hito final Rama Azul

# Primordio biológico ACTIVO (Fase 2): maduración por banda de ε + integridad
var primordio_integrity: float = 100.0
var primordio_pert_timer: float = 0.0
var primordio_regar_cd: float = 0.0

# Panspermia (Fase 3): lanzamiento post-ESPORULACIÓN — carga vs calor (dos presiones)
var panspermia_charge: float = 0.0
var panspermia_heat: float = 0.0
var panspermia_misfires: int = 0  # sobrecargas acumuladas; al llegar al máx → aborta a esporulación

# Singularidad (Fase 4, rama azul): integración de cómputo — sincronía vs temperatura
var nucleo_sync: float = 0.0
var nucleo_temp: float = 0.0

# === RAMA VERDE · COLONIZACIÓN activa (Empuje de Frontera) ===
var colonizacion_pert_timer: float = 0.0   # acumulador hacia el próximo evento de retracción
var colonizacion_phase_time: float = 0.0   # s en fase de empuje (escala la mordida de retracción)

# === NG+ SECRETOS ===
var mutation_depredador := false
var depredador_timer: float = 0.0
var _depredador_active_tick: float = 0.0
var _depredador_status_timer: float = 0.0
const DEPREDADOR_STATUS_INTERVAL := 10.0
# Timer de inestabilidad (post-activación): ventana antes de la implosión.
# Cuenta hacia arriba mientras el Depredador está activo. Si llega al máximo
# sin resolverse (sellar MET.OSCURO o consumir todos los upgrades) → COLAPSO.
var depredador_inestabilidad: float = 0.0
const DEPREDADOR_INESTABILIDAD_MAX := 60.0
# Compras de tiempo: cada una resta DEP_TIME_EXTENSION al timer y encarece la siguiente.
var depredador_timer_buys: int = 0
var _depredador_countdown_last: int = -1
var _met_oscuro_countdown_last: int = -1
var _parasitismo_countdown_last: int = -1
var _hyper_active_timer: float = 0.0   # tiempo activo en hiperasimilación sin depredador

# === NG+ METABOLISMO OSCURO (Post-Depredador) ===
var mutation_met_oscuro := false
var met_oscuro_timer: float = 0.0  # Progreso de activación (0→15s)
var met_oscuro_devoured_count: int = 0  # Upgrades devorados durante la run
# Runtime process vars (fase activa)
var _met_oscuro_income_accum: float = 0.0
var _met_oscuro_status_timer: float = 0.0
var _met_oscuro_active_time: float = 0.0
const MET_OSCURO_STATUS_INTERVAL := 12.0

# === FUSIÓN CATABÓLICA (transmutación que revierte HIPERASIMILACIÓN) ===
var mutation_fusion_catabolica := false
var fusion_burst_timer: float = 0.0      # Metabolismo Híbrido: s restantes de la ráfaga ×2
var fusion_burst_cooldown: float = 0.0   # s de cooldown tras la ráfaga
var fusion_burst_count: int = 0          # usos de Metabolismo Híbrido (estadística / logros)
var fusion_burst_money: float = 0.0      # $ generados mientras la ráfaga estaba activa (gate del sello)
var _fusion_money_mark: float = -1.0     # total_money_generated en el último tick (−1 = sin marca: tras cargar)
var fusion_cd_level: int = 0             # niveles comprados de reducción de cooldown (sink de dinero)

# === AYUNO PRIMORDIAL (transmutación SOMBRA — anti-Hiperasimilación) ===
var mutation_ayuno_primordial := false
var ayuno_silencio: float = 0.0          # S — recurso central (amplifica pasivo, base del burst)
var ayuno_silencio_peak: float = 0.0     # máximo histórico de la run (para NG+)
var ayuno_silencio_total: float = 0.0    # acumulado total (para sello 2)
var ayuno_longest_streak: float = 0.0    # s consecutivos con B<1 y ε<0.10 (para sello 3)
var ayuno_cycles: int = 0                # veces que se usó ROMPER EL AYUNO (para sello 1)
var ayuno_streak_timer: float = 0.0      # timer del streak limpio actual
var ayuno_burst_active: bool = false     # true durante los 15 s del burst
var ayuno_burst_timer: float = 0.0       # s restantes del burst
var ayuno_ascesis_level: int = 0         # niveles del upgrade ASCESIS [W]
var _ayuno_burst_saved_mult: float = 1.0 # mult fijado al activar el burst (1 + S/50 al momento)

# === AUTOFAGIA NECRÓTICA (sub-ruta de Met. Oscuro) ===
var mutation_autolisis := false
var autolisis_devour_count: int = 0
var autolisis_devour_timer: float = 0.0
# Mejoras de autofagia (multinivel capeadas): aceleran/duplican los devours
var autofagia_speed_level: int = 0   # Enzimas Líticas → -5s por nivel (piso 5s)
var autofagia_double_level: int = 0  # Fagocitosis Doble → chance devour extra por nivel
var autofagia_burst_cooldown: float = 0.0  # Digestión Masiva: cooldown restante (s)

# === NECROSIS CONTROLADA (sub-ruta de Met. Oscuro, doble economía Ν) ===
var mutation_necrosis := false
var necrosis_omega: float = Balance.NECROSIS_OMEGA_START     # Ω controlado por la ruta (override del clamp de MO)
var necromasa: float = 0.0           # moneda Ν acumulada (atada al flujo real)
var necrosis_agent_count: int = 0    # Agentes Necróticos comprados
var necrosis_active_time: float = 0.0  # s con necrosis activa (para logro de velocidad)
var necrosis_toxicidad: float = 0.0    # [0,1] envenenamiento del sustrato (frena la Ν)
var necrosis_tox_maxed: bool = false   # true si la toxicidad llegó a saturarse (overdosis, persistente para logro)
var necrosis_overdose: bool = false    # true mientras el bloqueo de sobredosis está activo (efímero)
var necrosis_catalyst_level: int = 0   # Catalizador Necrótico: niveles de multiplicador de Ν

# === PROTOCOLO OMEGA-CERO (final del árbol oscuro — síntesis de las 3 sub-rutas) ===
var mutation_omega_cero := false
var omega_cero_phi: float = 0.0          # Φ acumulada (recurso de cierre, amplificada por Ω bajo)
var omega_cero_devour_count: int = 0     # devours realizados en la síntesis
var omega_cero_devour_timer: float = 0.0 # acumulador del loop de devour
var omega_cero_omega: float = Balance.OMEGA_CERO_OMEGA_START       # Ω controlado por la ruta (override del clamp de MO)
var omega_cero_kernel: float = 0.0       # Núcleo Φ fijado al cerrar (phi/target) → intensidad del buff NG+
var _omega_cero_starve_ticks: int = 0    # ticks consecutivos sin material (inanición de síntesis)

# === REMISIÓN METABÓLICA (última post-MO — sanación / floración) ===
var mutation_remision := false           # ruta activa
var remision_omega: float = Balance.REMISION_OMEGA_START         # Ω controlado por la ruta (override del clamp de MO)
var remision_theta: float = 0.0          # s continuos dentro de banda (recurso de cierre "Salud")
var remision_band_timer: float = 0.0     # reloj del desplazamiento senoidal del centro de banda
var remision_sealable: bool = false      # true una vez Θ alcanzó el target (no se revierte salvo involución)
var remision_locked_run: bool = false    # bloquea re-entrar a REMISIÓN esta run tras involucionar
var control_omega_last_ms: int = 0       # timestamp del último pulso de Control de Ω (cooldown)

# === NG+ METABOLISMO GLITCH ===
var _glitch_was_active: bool = false

# === INVOLUCIÓN (TransmutationLogic) ===
var transmut_base_time: float = 0.0      # s con la mutación A activa (agenda del botón de reversión)
var transmut_money_mark: float = -1.0    # total_money_generated cuando empezó A (base de la digestión)
var transmut_reverted: Dictionary = {}   # genome_id → true: A revertida esta run, no se reactiva
var _ayuno_mirror_countdown_last: int = -1  # último segundo avisado del espejo de Ayuno

# === CAOS ORQUESTADO (Transmutación de Homeostasis — CaosOrquestadoLogic) ===
var mutation_caos_orquestado := false
var caos_money_mark: float = 0.0          # total_money_generated al revertir (sello de volumen)
var caos_red_time: float = 0.0            # s acumulados con ε ≥ CAOS_RED_EPS
var caos_charge: float = 0.0              # carga de caos: crece sola y es piso de ε (el Colapso la vacía)
var caos_burst_timer: float = 0.0         # s restantes del Colapso Dirigido
var caos_burst_saved_mult: float = 1.0    # multiplicador fijado al disparar el Colapso
var caos_cooldown: float = 0.0
var caos_cd_level: int = 0
var caos_collapse_count: int = 0
var caos_charged_collapses: int = 0       # Colapsos con ε ≥ CAOS_RED_EPS (sello)
var caos_peak_collapse_eps: float = 0.0   # mayor ε cobrado en un Colapso
var caos_min_collapse_eps: float = 99.0   # menor ε cobrado (logro MYTHIC: todos ≥ CAOS_MYTHIC_EPS)
var batuta_used: bool = false             # legado Batuta: ε → 0 una vez por run

# === CORO SIMBIÓTICO (Transmutación de Simbiosis — CoroSimbioticoLogic) ===
var mutation_coro_simbiotico := false
var coro_stacks: float = 0.0              # ritmo: se cuenta en todas las runs (legado Eco del Coro)
var coro_money_mark: float = 0.0
var coro_overload_timer: float = 0.0      # s restantes de Sobrecarga
var coro_cooldown: float = 0.0
var coro_overload_count: int = 0
var coro_w_level: int = 0
var coro_rhythm_time: float = 0.0         # s acumulados con ≥ CORO_SEAL_STACKS
var coro_peak_stacks: float = 0.0
var coro_fortissimo_streak: float = 0.0   # s seguidos con ≥ CORO_MYTHIC_STACKS sin Sobrecarga

# === MICELIO OMNISCIENTE (Transmutación de Red Micelial — MicelioOmniscienteLogic) ===
var mutation_micelio_omnisciente := false
var micelio_pool: float = 0.0             # micelio libre (presupuesto para conectar)
var micelio_nodes: Dictionary = {}        # upgrade_id → micelio conectado (0..MICELIO_NODE_MAX)
var micelio_drift_timer: float = 0.0
var micelio_full_time: float = 0.0        # s seguidos con los 9 nodos llenos (sello)
var micelio_peak_network: float = 0.0     # mayor micelio conectado en total (PL NG+)
var micelio_disconnects: int = 0          # desconexiones manuales (MYTHIC Ojo de la Red: 0)
var micelio_first_full: String = ""       # primer nodo lleno (legado Nodo Latente)
var micelio_manual_buys: int = 0          # compras a mano tras revertir (MYTHIC Ojo de la Red: 0)

## ── Clasificación del estado ────────────────────────────────────────────────
## Toda variable de EvoManager está en SaveSchema o en TRANSIENT_VARS (SaveSchema.validate lo
## verifica): agregar una variable de ruta sin decidir si persiste es un error, no un olvido.
## Transitorias = se recalculan solas o son efímeras dentro de la sesión (timers de status,
## countdowns de log, acumuladores sub-tick). Si una de estas debería sobrevivir a un reload,
## pasala a SaveSchema.
const TRANSIENT_VARS := [
	"primordio_regar_cd",
	"_depredador_active_tick", "_depredador_status_timer", "_depredador_countdown_last",
	"_met_oscuro_countdown_last", "_parasitismo_countdown_last", "_hyper_active_timer",
	"_met_oscuro_income_accum", "_met_oscuro_status_timer", "_met_oscuro_active_time",
	"ayuno_streak_timer", "autofagia_burst_cooldown", "_omega_cero_starve_ticks", "_fusion_money_mark",
	"_ayuno_mirror_countdown_last",
	"control_omega_last_ms", "_glitch_was_active",
]
## No se reinician entre runs: el cooldown de Control de Ω usa reloj real.
const RESET_KEEP := ["control_omega_last_ms"]
## Valores de declaración de cada variable (ver reset()). Caché interno: no es estado de juego.
var _reset_defaults: Dictionary = {}

## Guarda inmediatamente tras una activación irreversible importante.
## Previene el bug: autosave captura MO activo sin subruta activa + money>1M
## → reload cierra la run como METABOLISMO OSCURO en el primer tick.
func _save_after_mutation() -> void:
	var main := get_tree().get_first_node_in_group("main")
	if is_instance_valid(main):
		SaveManager.save_game(main)

## Vuelve todo el estado de la run a los valores de su DECLARACIÓN (capturados en _init), salvo
## RESET_KEEP. Una variable nueva queda cubierta sólo con declararla: antes había que repetirla
## a mano acá (~90 líneas) y olvidarse una dejaba estado de la run anterior colgado.
func reset() -> void:
	for k in _reset_defaults:
		set(k, _deep_copy(_reset_defaults[k]))

func _init() -> void:
	for p in get_property_list():
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and not (p.name in RESET_KEEP) and p.name != "_reset_defaults":
			_reset_defaults[p.name] = _deep_copy(get(p.name))

static func _deep_copy(v: Variant) -> Variant:
	if typeof(v) == TYPE_DICTIONARY or typeof(v) == TYPE_ARRAY:
		return v.duplicate(true)
	return v

func update_genome():
	if RunManager.run_closed:
		return
	if GenomeEvaluator.handle_terminal_mutations():
		return
	var ctx := GenomeEvaluator.build_eval_context()
	GenomeEvaluator.update_ayuno_espejo(ctx)
	GenomeEvaluator.update_hiperasimilacion(ctx)
	GenomeEvaluator.update_parasitismo(ctx)
	GenomeEvaluator.update_met_oscuro(ctx)
	GenomeEvaluator.update_depredador(ctx)
	GenomeEvaluator.update_simbiosis(ctx)
	GenomeEvaluator.update_homeostasis(ctx)
	GenomeEvaluator.update_allostasis(ctx)
	GenomeEvaluator.update_homeorhesis(ctx)
	GenomeEvaluator.update_red_micelial(ctx)
	GenomeEvaluator.update_esporulacion(ctx)
	GenomeEvaluator.check_automatic_activations()


func is_any_latent_tier1() -> bool:
	return genome.simbiosis == "latente" or genome.homeostasis == "latente" or genome.red_micelial == "latente"

func is_homeostasis_ready() -> bool:
	return RunManager.is_homeostasis_candidate()

func is_simbiosis_ready() -> bool:
	var hifas = BiosphereEngine.hifas
	var acc = UpgradeManager.level("accounting")
	var ap = EconomyManager.get_active_passive_breakdown()
	var act_domina = ap.activo > ap.pasivo
	# Árbol: "Estabilidad del ecosistema > 40%" → Ω ≥ 0.40
	return acc >= 1 and hifas >= 5.0 and StructuralModel.omega >= 0.40 and act_domina

func is_red_micelial_ready() -> bool:
	var hifas = BiosphereEngine.hifas
	var biomasa = BiosphereEngine.biomasa
	var acc = UpgradeManager.level("accounting")
	var ap = EconomyManager.get_active_passive_breakdown()
	var act_domina = ap.activo > ap.pasivo
	var eps = StructuralModel.epsilon_runtime
	return hifas >= 11.5 and biomasa >= 5.0 and eps < 0.65 and acc >= 1 and not act_domina

func is_allostasis_ready() -> bool:
	var ok_dist = RunManager.disturbances_survived >= 3
	var ok_resil = RunManager.resilience_score >= 150.0
	var ok_omega = StructuralModel.omega_min >= 0.40
	var ok_delta = EconomyManager.delta_per_sec >= 200.0
	var ok_acc = UpgradeManager.level("accounting") >= 2
	return ok_dist and ok_resil and ok_omega and ok_delta and ok_acc


## Fase "procesos de ruta" del logic tick: a lo sumo una familia activa por tick (el elif es la
## precedencia: Met. Oscuro y sus sub-rutas > Fusión > Ayuno > Depredador > progreso Depredador).
## El glitch corre siempre (se auto-gatea).
func tick_route_processes(dt: float) -> void:
	if mutation_met_oscuro:
		process_met_oscuro(dt)
		if mutation_autolisis:
			process_autolisis(dt)
		if mutation_necrosis:
			process_necrosis(dt)
		if mutation_omega_cero:
			process_omega_cero(dt)
		if mutation_remision:
			process_remision(dt)
	elif mutation_fusion_catabolica:
		process_fusion(dt)  # ráfaga Metabolismo Híbrido + cooldown
	elif mutation_ayuno_primordial:
		process_ayuno(dt)  # drain B + acumular Silencio + burst
	elif mutation_depredador:
		process_depredador(dt)  # Glitch Survival
	elif depredador_timer > 0.0 and depredador_timer < 30.0:
		process_depredador_progress(dt)
	process_glitch(dt)
	CaosOrquestadoLogic.process(dt)  # se auto-gatea (corre en paralelo a la cadena de arriba)
	CoroSimbioticoLogic.process(dt)  # ritmo (todas las runs) + Coro Simbiótico si está activo
	MicelioOmniscienteLogic.process(dt)  # se auto-gatea
	TransmutationLogic.tick(dt)  # agenda del botón de reversión (sólo si hay una A revertible)

## ALOSTASIS (desde Homeostasis, botón del panel de mutación): activa la mutación y aplica el
## bonus de entrada. Antes vivía en main._trigger_allostasis().
func trigger_allostasis() -> void:
	activate_mutation("allostasis")
	RunManager.homeostasis_mode = false  # salimos de homeostasis pura
	EconomyManager.money += 50000.0
	StructuralModel.epsilon_runtime *= 0.5  # reset de estrés para que pueda respirar
	LogManager.add(tr("LAP_ERA_ALOSTATICA"))

## Elección de sub-rama de Red Micelial. Antes vivía en main._on_branch_selected().
##   COLONIZACIÓN: trabajo manual ×1.5 (mutation_auto_factor) · SIMBIOSIS: piso de Ω 0.50
func select_red_branch(branch: int) -> void:
	red_branch_selected = branch
	if branch == RedBranch.COLONIZATION:
		LogManager.add(tr("LOG_RAMA_COLONIZACION"))
		EconomyManager.mutation_auto_factor *= 1.5
	elif branch == RedBranch.SYMBIOSIS:
		LogManager.add(tr("LOG_RAMA_SIMBIOSIS"))
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.50)

func activate_mutation(id: String) -> void:
	match id:
		"hiperasimilacion": activate_hyperassimilation()
		"homeostasis": activate_homeostasis()
		"red_micelial": activate_red_micelial()
		"esporulacion": activate_sporulation()
		"parasitismo": activate_parasitism()
		"simbiosis": activate_symbiosis()
		"allostasis": activate_allostasis()
		"depredador": activate_depredador()
		"homeorhesis": activate_homeorhesis()
		"met_oscuro": activate_met_oscuro()

func _set_genome_state(mutation: String, new_state: String):
	# Si la clave no existe, la creamos en lugar de crashear
	if not genome.has(mutation):
		genome[mutation] = "dormido"
	
	if genome[mutation] != new_state:
		genome[mutation] = new_state
		if new_state == "latente":
			mutation_unlocked.emit(mutation)


func activate_allostasis():
	if mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis or mutation_coro_simbiotico or mutation_micelio_omnisciente: return
	LogManager.add(tr("LOG_ALOSTASIS_EVO"))
	mutation_allostasis = true
	mutation_activated.emit("allostasis", tr("MUT_ALLOSTASIS"))
	AchievementManager.on_mutation_activated("allostasis")
	
func activate_homeorhesis():
	if mutation_red_micelial or mutation_hyperassimilation or mutation_parasitism or mutation_symbiosis or mutation_coro_simbiotico or mutation_micelio_omnisciente: return
	LogManager.add(tr("LOG_HOMEORRESIS_EVO"))
	mutation_homeorhesis = true
	mutation_activated.emit("homeorhesis", tr("MUT_HOMEORHESIS"))
	AchievementManager.on_mutation_activated("homeorhesis")

func activate_depredador():
	if mutation_homeostasis or mutation_caos_orquestado or mutation_red_micelial or mutation_symbiosis or mutation_coro_simbiotico or mutation_micelio_omnisciente or mutation_parasitism: return
	if mutation_fusion_catabolica: return  # motor ya estabilizado: la transmutación cierra el glitch del Depredador
	LogManager.add(tr("LOG_GLITCH_ALERT"))
	mutation_depredador = true
	depredador_inestabilidad = 0.0  # arranca la cuenta hacia la implosión
	depredador_timer_buys = 0
	mutation_activated.emit("depredador", tr("MUT_DEPREDADOR"))
	AchievementManager.on_depredador_activated()

	if not LegacyManager.get_buff_value("metabolismo_glitch"):
		LegacyManager.grant_buff("metabolismo_glitch")
		UIManager.show_toast(tr("TOAST_MG_UNLOCKED"))
	_save_after_mutation()

func activate_met_oscuro():
	if mutation_met_oscuro: return
	if not mutation_depredador: return  # Solo post-Depredador
	mutation_met_oscuro = true
	LogManager.add(tr("LOG_MO_ACTIVATED"))
	LogManager.add(tr("LOG_MO_EFFECTS"))
	LogManager.add(tr("LOG_MO_CLOSE"))
	mutation_activated.emit("met_oscuro", tr("MUT_MET_OSCURO"))
	AchievementManager.on_met_oscuro_activated()
	# Recalcular estrés/omega tras aplicar los nerfs permanentes
	StructuralModel.omega = 0.10
	StructuralModel.omega_min = min(StructuralModel.omega_min, 0.10)
	_save_after_mutation()

func activate_hyperassimilation():
	if mutation_homeostasis or mutation_caos_orquestado or mutation_parasitism or mutation_symbiosis or mutation_coro_simbiotico or mutation_micelio_omnisciente: return
	# Revertida esta run (Transmutación) o reemplazada por su Sombra: no se reactiva.
	if transmut_reverted.get("hiperasimilacion", false) or mutation_ayuno_primordial: return
	mutation_hyperassimilation = true
	LogManager.add(tr("LOG_HIPER_EFFECTS"))
	mutation_activated.emit("hiperasimilacion", tr("MUT_HIPERASIMILACION"))
	AchievementManager.on_mutation_activated("hiperasimilacion")
	# No cerrar si Depredador puede cargarse: venimos de PARASITISMO O trascendencia_count > 1
	var depredador_gate: bool = LegacyManager.last_run_ending == "PARASITISMO" \
		or LegacyManager.trascendencia_count > 1
	if not depredador_gate:
		run_ended_by_mutation.emit("HIPERASIMILACION", "El sistema prioriza absorción total sobre estabilidad")

# ── FUSIÓN CATABÓLICA (transmutación) ──────────────────────────────
## Activa la ruta revertida. NO cierra la run: es jugable y se sella voluntariamente.
func activate_fusion_catabolica():
	if mutation_fusion_catabolica: return
	mutation_fusion_catabolica = true
	mutation_hyperassimilation = false  # la reversión apaga la hiper (TransmutationLogic.revert)
	LogManager.add(tr("LOG_FUSION_EFFECTS"))
	mutation_activated.emit("fusion_catabolica", tr("MUT_FUSION_CATABOLICA"))
	AchievementManager.on_mutation_activated("fusion_catabolica")
	UIManager.show_toast(tr("TOAST_FUSION_ON"))
	_save_after_mutation()

## Dispara la ráfaga Metabolismo Híbrido (×2 a todo el ingreso) si no hay cooldown.
func activate_fusion_burst() -> void:
	if not mutation_fusion_catabolica or RunManager.run_closed: return
	if fusion_burst_timer > 0.0 or fusion_burst_cooldown > 0.0: return
	fusion_burst_timer = Balance.FUSION_BURST_DURATION
	fusion_burst_count += 1
	_fusion_money_mark = EconomyManager.total_money_generated  # sólo cuenta lo generado desde ahora
	UIManager.show_toast(tr("TOAST_FUSION_BURST_ON"))

## Tick de Fusión Catabólica: avanza la ráfaga / cooldown del Metabolismo Híbrido.
func process_fusion(dt: float) -> void:
	# Plata generada en ráfaga: lo que creció total_money_generated desde el tick anterior (pasivo
	# + clicks del intervalo) mientras la ráfaga estaba activa. Se cuenta ANTES de descontar el timer.
	var total: float = EconomyManager.total_money_generated
	if fusion_burst_timer > 0.0 and _fusion_money_mark >= 0.0:
		fusion_burst_money += maxf(0.0, total - _fusion_money_mark)
	_fusion_money_mark = total
	if fusion_burst_timer > 0.0:
		fusion_burst_timer -= dt
		if fusion_burst_timer <= 0.0:
			fusion_burst_timer = 0.0
			fusion_burst_cooldown = fusion_effective_cooldown()
			UIManager.show_toast(tr("TOAST_FUSION_BURST_OFF"))
	elif fusion_burst_cooldown > 0.0:
		fusion_burst_cooldown = max(0.0, fusion_burst_cooldown - dt)

## El multiplicador activo de la ráfaga (×2 mientras corre, ×1 si no).
func fusion_burst_mult() -> float:
	return Balance.FUSION_BURST_MULT if fusion_burst_timer > 0.0 else 1.0

## Cooldown efectivo de la ráfaga según niveles comprados (reducción compuesta, no baja del piso).
func fusion_effective_cooldown() -> float:
	var cd := Balance.FUSION_BURST_COOLDOWN * pow(1.0 - Balance.FUSION_CD_REDUCE_PCT, fusion_cd_level)
	return maxf(Balance.FUSION_CD_FLOOR, cd)

## Costo del próximo nivel de reducción de cooldown.
func fusion_cd_cost() -> float:
	return Balance.FUSION_CD_COST_BASE * pow(Balance.FUSION_CD_COST_GROWTH, fusion_cd_level)

## ¿Ya está en el piso de cooldown? (no se puede comprar más)
func fusion_cd_maxed() -> bool:
	return fusion_effective_cooldown() <= Balance.FUSION_CD_FLOOR

## ¿Se puede comprar otra reducción de cooldown?
func can_buy_fusion_cd() -> bool:
	return mutation_fusion_catabolica and not RunManager.run_closed \
		and not fusion_cd_maxed() \
		and EconomyManager.money >= fusion_cd_cost()

## Compra un nivel de reducción de cooldown (tecla W / botón).
func buy_fusion_cd() -> void:
	if not can_buy_fusion_cd(): return
	EconomyManager.money -= fusion_cd_cost()
	fusion_cd_level += 1
	# Aplicar de inmediato al cooldown en curso para que se sienta el efecto.
	if fusion_burst_cooldown > 0.0:
		fusion_burst_cooldown = minf(fusion_burst_cooldown, fusion_effective_cooldown())
	UIManager.show_toast(tr("TOAST_FUSION_CD_BUY") % fusion_effective_cooldown())

## ¿Se cumplen las condiciones para habilitar el sello del final?
func fusion_seal_ready() -> bool:
	return mutation_fusion_catabolica \
		and EconomyManager.total_money_generated >= Balance.FUSION_SEAL_MONEY \
		and fusion_burst_money >= Balance.FUSION_SEAL_BURST_MONEY \
		and StructuralModel.get_structural_upgrades() >= Balance.FUSION_SEAL_STRUCTURAL_N

# ── AYUNO PRIMORDIAL (transmutación SOMBRA) ────────────────────────────────
## Activa la ruta revertida. NO cierra la run: es jugable y se sella voluntariamente.
func activate_ayuno_primordial() -> void:
	if mutation_ayuno_primordial: return
	mutation_ayuno_primordial = true
	mutation_hyperassimilation = false  # la reversión apaga la hiper
	LogManager.add(tr("LOG_AYUNO_EFFECTS"))
	mutation_activated.emit("ayuno_primordial", tr("MUT_AYUNO_PRIMORDIAL"))
	AchievementManager.on_mutation_activated("ayuno_primordial")
	UIManager.show_toast(tr("TOAST_AYUNO_ON"))
	_save_after_mutation()

## Tick de Ayuno Primordial: drena B, acumula Silencio, gestiona burst.
func process_ayuno(dt: float) -> void:
	if not mutation_ayuno_primordial or RunManager.run_closed: return
	# Drain proporcional: cuanto más B tengas, más rápido drena → presión real
	var drain: float = Balance.AYUNO_BIOMASA_DRAIN + BiosphereEngine.biomasa * Balance.AYUNO_BIOMASA_DRAIN_PCT
	BiosphereEngine.biomasa = maxf(0.0, BiosphereEngine.biomasa - drain * dt)
	# S sube más rápido con B bajo: incentivo a aguantar el dolor económico
	var ascesis_bonus: float = 1.0 + ayuno_ascesis_level * Balance.AYUNO_ASCESIS_RATE_BONUS
	var b_bonus: float = 1.0 + maxf(0.0, (5.0 - BiosphereEngine.biomasa) / 5.0)
	ayuno_silencio += ascesis_bonus * b_bonus * dt
	ayuno_silencio_total += ascesis_bonus * b_bonus * dt
	ayuno_silencio_peak = maxf(ayuno_silencio_peak, ayuno_silencio)
	# Streak = tiempo continuo sin romper el ayuno ([Q] lo reinicia)
	ayuno_streak_timer += dt
	ayuno_longest_streak = maxf(ayuno_longest_streak, ayuno_streak_timer)
	# Tick del burst
	if ayuno_burst_active:
		ayuno_burst_timer -= dt
		if ayuno_burst_timer <= 0.0:
			ayuno_burst_timer = 0.0
			ayuno_burst_active = false
			UIManager.show_toast(tr("TOAST_AYUNO_BURST_OFF"))

## Multiplicador de pasivo durante el ayuno (S acumulado amplifica el ingreso pasivo).
func ayuno_silencio_mult() -> float:
	if not mutation_ayuno_primordial: return 1.0
	var s_factor: float = 1.0 + ayuno_silencio * Balance.AYUNO_SILENCIO_FACTOR
	var asc_factor: float = 1.0 + ayuno_ascesis_level * Balance.AYUNO_ASCESIS_PASSIVE_BONUS
	return s_factor * asc_factor

## Multiplicador extra durante el burst (×(1 + S/50) al momento de romper, luego fijo 15s).
func ayuno_burst_mult() -> float:
	return _ayuno_burst_saved_mult if ayuno_burst_active else 1.0

## [Q] ROMPER EL AYUNO: libera el Silencio acumulado como burst de 15 s.
func activate_ayuno_burst() -> void:
	if not mutation_ayuno_primordial or RunManager.run_closed: return
	if ayuno_burst_active: return
	_ayuno_burst_saved_mult = 1.0 + ayuno_silencio / Balance.AYUNO_BURST_DIVISOR
	ayuno_silencio = 0.0
	ayuno_streak_timer = 0.0
	BiosphereEngine.biomasa += Balance.AYUNO_BURST_BIO_SPIKE
	ayuno_burst_active = true
	ayuno_burst_timer = Balance.AYUNO_BURST_DURATION
	ayuno_cycles += 1
	UIManager.show_toast(tr("TOAST_AYUNO_BURST_ON"))

## Costo del próximo nivel de ASCESIS.
func ayuno_ascesis_cost() -> float:
	return Balance.AYUNO_ASCESIS_COST * pow(Balance.AYUNO_ASCESIS_SCALE, ayuno_ascesis_level)

## ¿Se puede comprar ASCESIS?
func can_buy_ayuno_ascesis() -> bool:
	return mutation_ayuno_primordial and not RunManager.run_closed \
		and EconomyManager.money >= ayuno_ascesis_cost()

## [W] ASCESIS: mejora la tasa de acumulación de Silencio.
func buy_ayuno_ascesis() -> void:
	if not can_buy_ayuno_ascesis(): return
	EconomyManager.money -= ayuno_ascesis_cost()
	ayuno_ascesis_level += 1
	UIManager.show_toast(tr("TOAST_AYUNO_ASCESIS_BUY") % ayuno_ascesis_level)

## ¿Se cumplen las 3 condiciones de sello?
func ayuno_seal_ready() -> bool:
	return mutation_ayuno_primordial \
		and ayuno_cycles >= Balance.AYUNO_SELLO_CYCLES \
		and ayuno_silencio_total >= Balance.AYUNO_SELLO_TOTAL \
		and ayuno_longest_streak >= Balance.AYUNO_SELLO_STREAK

func activate_homeostasis():
	if mutation_homeostasis or mutation_caos_orquestado or mutation_symbiosis or mutation_coro_simbiotico or mutation_micelio_omnisciente: return
	mutation_homeostasis = true
	mutation_hyperassimilation = false # bloqueo cruzado
	mutation_activated.emit("homeostasis", tr("MUT_HOMEOSTASIS"))
	AchievementManager.on_mutation_activated("homeostasis")

func activate_red_micelial():
	if mutation_homeostasis or mutation_caos_orquestado or mutation_hyperassimilation or mutation_symbiosis or mutation_coro_simbiotico or mutation_micelio_omnisciente: return
	mutation_red_micelial = true
	mutation_activated.emit("red_micelial", tr("MUT_RED_MICELIAL"))
	AchievementManager.on_red_micelial_activated()

func activate_sporulation():
	if mutation_sporulation: return
	if not mutation_red_micelial or red_micelial_phase != 2: return
	if mutation_homeostasis or mutation_caos_orquestado or mutation_hyperassimilation: return

	mutation_sporulation = true
	mutation_activated.emit("esporulacion", tr("MUT_ESPORULACION"))
	AchievementManager.on_mutation_activated("esporulacion")
	run_ended_by_mutation.emit("ESPORULACION", "El sistema abandona la coherencia local y se dispersa en esporas")

func activate_parasitism():
	if mutation_homeostasis or mutation_caos_orquestado or mutation_symbiosis or mutation_coro_simbiotico or mutation_micelio_omnisciente or mutation_parasitism: return
	mutation_parasitism = true
	mutation_hyperassimilation = false
	BiosphereEngine.apply_parasitism_buffs()
	mutation_activated.emit("parasitismo", tr("MUT_PARASITISMO"))
	AchievementManager.on_mutation_activated("parasitismo")
	# El parasitismo no cierra la run inmediatamente, requiere un hito de drenaje o colapso.

func check_parasitism_final(_main: Control):
	if not mutation_parasitism or RunManager.run_closed: return
	
	# Condición de victoria por parasitismo: 1 PL (mínimo histórico)
	if BiosphereEngine.biomasa >= 15.0 and EconomyManager.money < 1000.0:
		LegacyManager.add_pl(1)
		RunManager.close_run("PARASITISMO", tr("CLOSE_EVO_PARASITISMO_BANCARROTA"))
	elif BiosphereEngine.biomasa >= 25.0:
		LegacyManager.add_pl(1)
		RunManager.close_run("PARASITISMO", tr("CLOSE_EVO_PARASITISMO_MASA"))

func activate_symbiosis():
	if mutation_homeostasis or mutation_caos_orquestado or mutation_hyperassimilation or mutation_red_micelial or mutation_micelio_omnisciente: return
	mutation_symbiosis = true
	mutation_activated.emit("simbiosis", tr("MUT_SIMBIOSIS"))

# =============================================================
# CICLO BIOLÓGICO: PRIMORDIO — delegates a PrimordioLogic
# (lógica extraída a PrimordioLogic.gd; vars de estado permanecen aquí)
# =============================================================
func check_red_micelial_transition(m: Node) -> void: PrimordioLogic.check_red_micelial_transition(m)
func update_primordio(m: Node) -> void: PrimordioLogic.update_primordio(m)
func primordio_regar() -> void: PrimordioLogic.primordio_regar()
func try_iniciar_primordio() -> bool: return PrimordioLogic.try_iniciar_primordio()
func is_panspermia_window() -> bool: return PrimordioLogic.is_panspermia_window()
func panspermia_pulse_cost() -> float: return PrimordioLogic.panspermia_pulse_cost()
func process_panspermia(dt: float) -> void: PrimordioLogic.process_panspermia(dt)
func panspermia_pulse() -> bool: return PrimordioLogic.panspermia_pulse()
func is_colonizacion_pushable() -> bool: return PrimordioLogic.is_colonizacion_pushable()
func colonizacion_pulse() -> void: PrimordioLogic.colonizacion_pulse()
func process_colonizacion(dt: float) -> void: PrimordioLogic.process_colonizacion(dt)

# ==================== CARNAVAL DE MUTACIONES ====================
## Aplica una mutación del carnaval: limpia todas las flags y activa solo la indicada
func carnaval_set_mutation(id: String) -> void:
	# Limpiar flags Y genome states de las mutaciones rotativas + segundo nivel disruptivo
	mutation_hyperassimilation = false
	mutation_symbiosis = false
	mutation_homeostasis = false
	mutation_red_micelial = false
	mutation_parasitism = false
	mutation_depredador = false
	mutation_met_oscuro = false
	red_micelial_phase = 0
	genome["hiperasimilacion"] = "dormido"
	genome["simbiosis"] = "dormido"
	genome["homeostasis"] = "dormido"
	genome["red_micelial"] = "dormido"
	genome["parasitismo"] = "dormido"
	genome["depredador"] = "dormido"
	genome["met_oscuro"] = "dormido"
	# Resetear efectos persistentes de parasitismo que de otro modo matan la producción
	EconomyManager.parasitism_corrosion = 1.0
	# Las flags de segundo nivel (allostasis, homeorhesis, etc.) no se tocan — son sub-rutas
	match id:
		"homeostasis":
			mutation_homeostasis = true
			genome["homeostasis"] = "activo"
		"simbiosis":
			mutation_symbiosis = true
			genome["simbiosis"] = "activo"
		"red_micelial":
			mutation_red_micelial = true
			# phase = 0 en carnaval: efectos básicos sin primordio ni bifurcación
			genome["red_micelial"] = "activo"
		"parasitismo":
			mutation_parasitism = true
			genome["parasitismo"] = "activo"
		"hiperasimilacion":
			mutation_hyperassimilation = true
			genome["hiperasimilacion"] = "activo"
	print("🎭 [CARNAVAL] Mutación activa → %s" % id)

# =====================================================
#  PROCESS METHODS — NG+ ROUTES (delegates a DarkTreeLogic)
# =====================================================

func process_met_oscuro(dt: float) -> bool: return DarkTreeLogic.process_met_oscuro(dt)
func activate_autolisis() -> void: DarkTreeLogic.activate_autolisis()
func autofagia_devour_interval() -> float: return DarkTreeLogic.autofagia_devour_interval()
func autofagia_double_chance() -> float: return DarkTreeLogic.autofagia_double_chance()
func process_autolisis(dt: float) -> void: DarkTreeLogic.process_autolisis(dt)
func autofagia_colapsar() -> void: DarkTreeLogic.autofagia_colapsar()
func autofagia_upgrade_cost(kind: String) -> Dictionary: return DarkTreeLogic.autofagia_upgrade_cost(kind)
func autofagia_double_gate_req() -> int: return DarkTreeLogic.autofagia_double_gate_req()
func can_buy_autofagia_upgrade(kind: String) -> bool: return DarkTreeLogic.can_buy_autofagia_upgrade(kind)
func buy_autofagia_upgrade(kind: String) -> bool: return DarkTreeLogic.buy_autofagia_upgrade(kind)
func can_autofagia_digest_burst() -> bool: return DarkTreeLogic.can_autofagia_digest_burst()
func autofagia_digest_burst() -> int: return DarkTreeLogic.autofagia_digest_burst()
func activate_necrosis() -> void: DarkTreeLogic.activate_necrosis()
func necrosis_mult() -> float: return DarkTreeLogic.necrosis_mult()
func necrosis_index() -> float: return DarkTreeLogic.necrosis_index()
func necrosis_agent_cost() -> float: return DarkTreeLogic.necrosis_agent_cost()
func can_buy_necrosis_agent() -> bool: return DarkTreeLogic.can_buy_necrosis_agent()
func buy_necrosis_agent() -> bool: return DarkTreeLogic.buy_necrosis_agent()
func necrosis_efficiency() -> float: return DarkTreeLogic.necrosis_efficiency()
func necrosis_passive_rate() -> float: return DarkTreeLogic.necrosis_passive_rate()
func necrosis_click_preview() -> float: return DarkTreeLogic.necrosis_click_preview()
func necrosis_catalyst_mult() -> float: return DarkTreeLogic.necrosis_catalyst_mult()
func add_necromasa_from_click(power: float) -> void: DarkTreeLogic.add_necromasa_from_click(power)
func necrosis_catalyst_cost() -> float: return DarkTreeLogic.necrosis_catalyst_cost()
func can_buy_necrosis_catalyst() -> bool: return DarkTreeLogic.can_buy_necrosis_catalyst()
func buy_necrosis_catalyst() -> bool: return DarkTreeLogic.buy_necrosis_catalyst()
func necrosis_purge_cost() -> float: return DarkTreeLogic.necrosis_purge_cost()
func necrosis_tox_floor() -> float: return DarkTreeLogic.necrosis_tox_floor()
func can_purge_necrosis() -> bool: return DarkTreeLogic.can_purge_necrosis()
func purge_necrosis() -> bool: return DarkTreeLogic.purge_necrosis()
func process_necrosis(dt: float) -> void: DarkTreeLogic.process_necrosis(dt)
func omega_cero_gate_ready() -> bool: return DarkTreeLogic.omega_cero_gate_ready()
func activate_omega_cero() -> void: DarkTreeLogic.activate_omega_cero()
func omega_cero_phi_mult() -> float: return DarkTreeLogic.omega_cero_phi_mult()
func omega_cero_progress() -> float: return DarkTreeLogic.omega_cero_progress()
func omega_cero_can_seal() -> bool: return DarkTreeLogic.omega_cero_can_seal()
func process_omega_cero(dt: float) -> void: DarkTreeLogic.process_omega_cero(dt)
func omega_cero_seal() -> void: DarkTreeLogic.omega_cero_seal()
func remision_gate_ready() -> bool: return DarkTreeLogic.remision_gate_ready()
func activate_remision() -> void: DarkTreeLogic.activate_remision()
func remision_band_center() -> float: return DarkTreeLogic.remision_band_center()
func remision_in_band() -> bool: return DarkTreeLogic.remision_in_band()
func remision_nudge(dir: int) -> void: DarkTreeLogic.remision_nudge(dir)
func remision_progress() -> float: return DarkTreeLogic.remision_progress()
func remision_can_seal() -> bool: return DarkTreeLogic.remision_can_seal()
func process_remision(dt: float) -> void: DarkTreeLogic.process_remision(dt)
func remision_seal() -> void: DarkTreeLogic.remision_seal()
func control_omega_available() -> bool: return DarkTreeLogic.control_omega_available()
func control_omega_nudge(dir: int) -> void: DarkTreeLogic.control_omega_nudge(dir)
func process_depredador(dt: float) -> void: DarkTreeLogic.process_depredador(dt)
func depredador_time_cost() -> float: return DarkTreeLogic.depredador_time_cost()
func buy_depredador_time() -> bool: return DarkTreeLogic.buy_depredador_time()
func process_depredador_progress(dt: float) -> void: DarkTreeLogic.process_depredador_progress(dt)
func process_glitch(dt: float) -> int: return DarkTreeLogic.process_glitch(dt)
