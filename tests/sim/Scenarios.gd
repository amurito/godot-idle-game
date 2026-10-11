extends RefCounted
## Scenarios — runs predefinidas para el simulador.
##
## Cada escenario define:
##   desc     : qué pregunta de diseño/rendimiento responde
##   legacy   : estado del banco ANTES de arrancar la run (se aplica en memoria, sin persistir)
##              { trascendencia_count, legacy_points, last_run_ending, endings: [..],
##                buffs: {id: nivel}, cosmic: [ids], post_tras_route }
##   bot      : configuración de BotPolicy (ver BotPolicy.gd)
##   max_t    : segundos de juego simulados como máximo (la run puede cerrar antes)
##   sample_every : cada cuántos segundos se toma una muestra del estado
##
## Perfiles de jugador realistas: quien busca Hiperasimilación mantiene el pasivo bajo (>80% activo
## es requisito) y no compra Contabilidad; quien busca Homeostasis o Red Micelial ahorra para
## Contabilidad, porque sin ella la "Masa Crítica" (GenomeEvaluator.update_parasitismo) cierra la
## run en Parasitismo a los 420 s.

const ALL := {
	# ── Run nueva (T0) ─────────────────────────────────────────────────────────
	"fresh_hiper": {
		"desc": "T0, clicker 7 cps que busca Hiperasimilación: sin Contabilidad, pasivo < 15%.",
		"legacy": {},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0},
		"max_t": 1800.0, "sample_every": 10.0,
	},
	"fresh_buy_all": {
		"desc": "T0, clicker 6 cps que compra lo más barato y nunca Contabilidad → trampa de Masa Crítica (420 s).",
		"legacy": {},
		"bot": {"click_cps": 6.0, "buy": "cheapest", "avoid": ["accounting"]},
		"max_t": 1800.0, "sample_every": 10.0,
	},
	"fresh_idle": {
		"desc": "T0, clickea 60 s y se va (AFK). ¿Cuánto tarda Parasitismo? ¿Funciona el anti-stuck?",
		"legacy": {},
		"bot": {"click_cps": 4.0, "click_until": 60.0, "buy": "cheapest"},
		"max_t": 1800.0, "sample_every": 10.0,
	},
	"fresh_homeostasis": {
		"desc": "T0, balanceado: ahorra para Contabilidad, clickea 3 cps → 0.3 cps y elige Homeostasis.",
		"legacy": {},
		"bot": {"click_schedule": [[0.0, 3.0], [300.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "homeostasis"},
		"max_t": 2400.0, "sample_every": 10.0,
	},
	"fresh_red_micelial": {
		"desc": "T0, pasivo: ahorra para Contabilidad, clickea poco, elige Red Micelial y rama Colonización.",
		"legacy": {},
		"bot": {"click_schedule": [[0.0, 2.0], [240.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "red_micelial", "branch": "colonization"},
		"max_t": 2400.0, "sample_every": 10.0,
	},

	# ── Transmutaciones (T3+) ───────────────────────────────────────────────────
	"ng_ayuno_lazy": {
		"desc": "T3 + AYUNO. Activa Ayuno clickeando y después NO toca nada. ¿Se sella solo?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_ayuno": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"stop_click_when": ["ayuno_primordial"], "ayuno_seal": true},
		"max_t": 1800.0, "sample_every": 10.0,
	},
	"ng_ayuno_player": {
		"desc": "T3 + AYUNO jugado: rompe el ayuno con S≥120, compra Ascesis y sella apenas puede.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_ayuno": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"stop_click_when": ["ayuno_primordial"],
			"ayuno_burst_at": 120.0, "ayuno_ascesis": true, "ayuno_seal": true},
		"max_t": 1800.0, "sample_every": 10.0,
	},
	"ng_fusion_player": {
		"desc": "T3 + FUSIÓN CATABÓLICA jugada: ráfaga Q en cada cooldown, compra CD (W) y sella.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"fusion_bursts": true, "fusion_cd": true, "fusion_seal": true},
		"max_t": 2400.0, "sample_every": 10.0,
	},
	"ng_fusion_smart": {
		"desc": "T3 + FUSIÓN: como ng_fusion_player, pero compra Contabilidad apenas activa Fusión para esquivar la Masa Crítica (420 s). ¿Es sellable?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"unavoid_on": {"accounting": "fusion_catabolica"}, "priority": ["accounting"],
			"save_for_priority": true, "save_from": 0.0,
			"fusion_bursts": true, "fusion_cd": true, "fusion_seal": true},
		"max_t": 5400.0, "sample_every": 30.0,
	},
}


## Aplica el estado de legado en memoria (NO llama a save_legacy). Debe ejecutarse antes de
## instanciar main.tscn, porque main._ready() aplica los buffs del banco al arrancar la run.
static func apply_legacy(legacy: Dictionary) -> void:
	if legacy.is_empty():
		return
	LegacyManager.trascendencia_count = int(legacy.get("trascendencia_count", LegacyManager.trascendencia_count))
	LegacyManager.legacy_points = int(legacy.get("legacy_points", LegacyManager.legacy_points))
	LegacyManager.last_run_ending = str(legacy.get("last_run_ending", LegacyManager.last_run_ending))
	LegacyManager.post_tras_route = str(legacy.get("post_tras_route", LegacyManager.post_tras_route))
	for ending in legacy.get("endings", []):
		LegacyManager.endings_achieved[str(ending)] = true
	var buffs: Dictionary = legacy.get("buffs", {})
	for id in buffs:
		LegacyManager._set_buff_level(str(id), int(buffs[id]))
	for cid in legacy.get("cosmic", []):
		LegacyManager.cosmic_unlocked[str(cid)] = true
