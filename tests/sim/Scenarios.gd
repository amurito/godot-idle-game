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
	"fresh_simbiosis": {
		"desc": "T0, activo: ahorra para Contabilidad, clickea 4 cps y elige Simbiosis. ¿Cuánto vive Simbiosis antes de cerrar?",
		"legacy": {},
		"bot": {"click_cps": 4.0, "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "simbiosis"},
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
		"desc": "T3 + AYUNO (Sombra por espejo): clickea 2 min para armar pasivo, deja de clickear → ayuno, y no toca nada más. ¿Se sella solo?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_ayuno": 1}},
		"bot": {"click_cps": 7.0, "click_until": 120.0, "buy": "cheapest", "ayuno_seal": true},
		"max_t": 1800.0, "sample_every": 10.0,
	},
	"ng_ayuno_trap_huesped": {
		"desc": "AYUNO + llave de HUÉSPED, AFK: el parásito entra durante el ayuno → Trampa del Vacío (la llave de Huésped no rescata; no aparece [T]).",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_ayuno": 1, "transmut_huesped": 1}},
		"bot": {"click_cps": 7.0, "click_until": 120.0, "buy": "cheapest", "transmute": "huesped", "ayuno_burst_at": 40.0},
		"max_t": 1800.0, "sample_every": 10.0,
	},
	"ng_ayuno_player": {
		"desc": "T3 + AYUNO jugado (Sombra por espejo): clickea 2 min, deja de clickear → ayuno; rompe con S≥120, compra Ascesis y sella apenas puede.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_ayuno": 1}},
		"bot": {"click_cps": 7.0, "click_until": 120.0, "buy": "cheapest",
			"ayuno_burst_at": 120.0, "ayuno_ascesis": true, "ayuno_seal": true},
		"max_t": 1800.0, "sample_every": 10.0,
	},
	"ng_fusion_player": {
		"desc": "T3 + FUSIÓN CATABÓLICA jugada: ráfaga Q en cada cooldown, compra CD (W) y sella.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"transmute": "fusion", "fusion_bursts": true, "fusion_cd": true, "fusion_seal": true},
		"max_t": 2400.0, "sample_every": 10.0,
	},
	"ng_hiper_key_no_revert": {
		"desc": "T3 con la llave de Fusión pero sin usar el botón [T]: Hiper sigue su curso normal (camino 'no revierto'). Sirve para ver el botón en modo visual.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1, "transmut_ayuno": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0},
		"max_t": 1200.0, "sample_every": 10.0,
	},
	"ng_fusion_natural": {
		"desc": "T3 + FUSIÓN: entra como Hiper (pasivo < 15%), y una vez en Fusión compra lo más barato de todo (sin tope de pasivo) + Contabilidad. ¿Sella sin buscarlo?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"uncap_passive_on": "fusion_catabolica", "unavoid_on": {"accounting": "fusion_catabolica"},
			"transmute": "fusion", "fusion_bursts": true, "fusion_cd": true, "fusion_seal": true},
		"max_t": 5400.0, "sample_every": 30.0,
	},
	"ng_fusion_hunter": {
		"desc": "T3 + FUSIÓN: jugador que persigue el sello: con Fusión activa sólo compra upgrades estructurales (los que suman n).",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"uncap_passive_on": "fusion_catabolica", "unavoid_on": {"accounting": "fusion_catabolica"},
			"buy_ids_on": {"fusion_catabolica": ["auto", "auto_mult", "trueque", "trueque_net", "trueque_allo",
				"cognitive", "accounting", "specialization", "persistence"]},
			"transmute": "fusion", "fusion_bursts": true, "fusion_cd": true, "fusion_seal": true},
		"max_t": 5400.0, "sample_every": 30.0,
	},
	"ng_fusion_no_cd": {
		"desc": "T3 + FUSIÓN: igual que ng_fusion_natural pero nunca compra [W] (control para medir cuánto vale el cooldown)",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"uncap_passive_on": "fusion_catabolica", "unavoid_on": {"accounting": "fusion_catabolica"},
			"transmute": "fusion", "fusion_bursts": true, "fusion_cd": false, "fusion_seal": true},
		"max_t": 5400.0, "sample_every": 30.0,
	},
	"ng_fusion_optimizer": {
		"desc": "T3 + FUSIÓN: como ng_fusion_natural, pero ahorra para [W] (cooldown) cuando el nivel cuesta ≤ 10 min de ingreso.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"uncap_passive_on": "fusion_catabolica", "unavoid_on": {"accounting": "fusion_catabolica"},
			"transmute": "fusion", "fusion_bursts": true, "fusion_cd": true, "fusion_cd_save_secs": 600.0, "fusion_seal": true},
		"max_t": 5400.0, "sample_every": 30.0,
	},
	"ng_fusion_lazy_bursts": {
		"desc": "T3 + FUSIÓN: juega natural pero casi no usa la ráfaga (sólo 3 veces). ¿Puede sellar?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"uncap_passive_on": "fusion_catabolica", "unavoid_on": {"accounting": "fusion_catabolica"},
			"transmute": "fusion", "fusion_bursts": true, "fusion_burst_limit": 3, "fusion_cd": false, "fusion_seal": true},
		"max_t": 5400.0, "sample_every": 30.0,
	},
	"ng_caos_player": {
		"desc": "T3 + llave de CAOS ORQUESTADO: juega Homeostasis, revierte con [T], clickea para subir ε y cobra Colapsos con ε ≥ 0.8.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HOMEOSTASIS",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_caos": 1}},
		"bot": {"click_schedule": [[0.0, 3.0], [300.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "homeostasis", "transmute": "caos", "cps_when": {"caos_orquestado": 7.0},
			"caos_collapse_at": 0.8, "caos_cd": true, "caos_grand_from": 480.0},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_caos_sinfonia": {
		"desc": "Caos para el MYTHIC: cultiva cobrando con ε < 1.8 (deja de clickear al acercarse) y apuesta UNA sola vez al Gran Colapso, a los 19 min.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HOMEOSTASIS",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_caos": 1}},
		"bot": {"click_schedule": [[0.0, 3.0], [300.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "homeostasis", "transmute": "caos", "cps_when": {"caos_orquestado": 7.0},
			"caos_collapse_at": 0.8, "caos_cd": true, "caos_hold_below": 1.6, "caos_grand_from": 1140.0},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_caos_no_cd": {
		"desc": "T3 + llave de CAOS ORQUESTADO: juega Homeostasis, revierte con [T], clickea para subir ε y cobra Colapsos con ε ≥ 0.8 — sin comprar [W] (control: cuánto vale el cooldown).",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HOMEOSTASIS",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_caos": 1}},
		"bot": {"click_schedule": [[0.0, 3.0], [300.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "homeostasis", "transmute": "caos", "cps_when": {"caos_orquestado": 7.0},
			"caos_collapse_at": 0.8, "caos_cd": false, "caos_grand_from": 480.0},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_coro_player": {
		"desc": "T3 + llave de CORO SIMBIÓTICO: juega Simbiosis, revierte con [T] y toca la partitura con 94 % de precisión (jugador normal).",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "SIMBIOSIS",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "SIMBIOSIS"],
			"buffs": {"transmut_coro": 1}},
		"bot": {"click_cps": 4.0, "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "simbiosis", "transmute": "coro", "rhythm_accuracy": 0.94, "coro_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_micelio_player": {
		"desc": "T3 + llave de MICELIO OMNISCIENTE: juega Red Micelial pasivo, revierte con [T], conecta la red en orden (pasivo primero), a los 2 min corrige el plan (pasa Trueque a Capital Cognitivo) y sella.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "ESPORULACIÓN",
			"endings": ["HIPERASIMILACION", "SIMBIOSIS", "ESPORULACIÓN"],
			"buffs": {"transmut_micelio": 1}},
		"bot": {"click_schedule": [[0.0, 4.0], [420.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "red_micelial", "transmute": "micelio",
			"buy_ids_from": [240.0, ["auto", "auto_mult", "trueque", "trueque_net", "specialization", "cognitive", "accounting", "persistence"]],
			"buy_ids_on": {"micelio_omnisciente": ["click", "auto", "trueque", "click_mult", "auto_mult", "trueque_net", "specialization", "cognitive", "accounting", "persistence"]},
			"micelio_plan": ["auto", "auto_mult", "specialization", "trueque", "trueque_net", "cognitive", "accounting", "click_mult", "click"],
			"micelio_swap": ["trueque", "cognitive", 120.0], "micelio_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_micelio_planner": {
		"desc": "Micelio con plan fijo, sin desconectar, pero comprando a mano (jugador normal prolijo): no debería sacar el MYTHIC.",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "ESPORULACIÓN",
			"endings": ["HIPERASIMILACION", "SIMBIOSIS", "ESPORULACIÓN"],
			"buffs": {"transmut_micelio": 1}},
		"bot": {"click_schedule": [[0.0, 4.0], [420.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "red_micelial", "transmute": "micelio",
			"buy_ids_from": [240.0, ["auto", "auto_mult", "trueque", "trueque_net", "specialization", "cognitive", "accounting", "persistence"]],
			"buy_ids_on": {"micelio_omnisciente": ["click", "auto", "trueque", "click_mult", "auto_mult", "trueque_net", "specialization", "cognitive", "accounting", "persistence"]},
			"micelio_plan": ["auto", "auto_mult", "specialization", "trueque", "trueque_net", "cognitive", "accounting", "click_mult", "click"], "micelio_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_micelio_ojo": {
		"desc": "Micelio con plan Trueque primero, sin desconectar y SIN comprar a mano tras revertir (sólo autocompra): ¿saca el MYTHIC Ojo de la Red?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "ESPORULACIÓN",
			"endings": ["HIPERASIMILACION", "SIMBIOSIS", "ESPORULACIÓN"],
			"buffs": {"transmut_micelio": 1}},
		"bot": {"click_schedule": [[0.0, 4.0], [420.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "red_micelial", "transmute": "micelio",
			"buy_ids_from": [240.0, ["auto", "auto_mult", "trueque", "trueque_net", "specialization", "cognitive", "accounting", "persistence"]],
			"buy_ids_on": {"micelio_omnisciente": []},
			"micelio_plan": ["trueque", "trueque_net", "auto", "auto_mult", "specialization", "accounting", "cognitive", "click", "click_mult"], "micelio_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_micelio_afk": {
		"desc": "Micelio sin conectar nada a mano: sólo la deriva (control: ¿sella jugando AFK?).",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "ESPORULACIÓN",
			"endings": ["HIPERASIMILACION", "SIMBIOSIS", "ESPORULACIÓN"],
			"buffs": {"transmut_micelio": 1}},
		"bot": {"click_schedule": [[0.0, 4.0], [420.0, 0.3]], "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "red_micelial", "transmute": "micelio",
			"buy_ids_from": [240.0, ["auto", "auto_mult", "trueque", "trueque_net", "specialization", "cognitive", "accounting", "persistence"]],
			"buy_ids_on": {"micelio_omnisciente": ["click", "auto", "trueque", "click_mult", "auto_mult", "trueque_net", "specialization", "cognitive", "accounting", "persistence"]},
			"micelio_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_parasito_probe": {
		"desc": "T3 que clickea 2 min y se va (AFK): mide cuánto vive Parasitismo (agenda del botón de Huésped).",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "PARASITISMO",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "SIMBIOSIS"]},
		"bot": {"click_cps": 4.0, "click_until": 120.0, "buy": "cheapest"},
		"max_t": 2400.0, "sample_every": 10.0,
	},	"ng_huesped_player": {
		"desc": "T3 + llave de HUÉSPED: AFK → Parasitismo, revierte con [T] y alimenta al parásito cuando el hambre llega a 68 (no anticipa los antojos).",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "PARASITISMO",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "SIMBIOSIS"],
			"buffs": {"transmut_huesped": 1}},
		"bot": {"click_cps": 4.0, "click_until": 120.0, "buy": "cheapest", "transmute": "huesped",
			"huesped_feed_at": 68.0, "huesped_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_huesped_lazy": {
		"desc": "Huésped descuidado: alimenta recién con hambre 85 (muerde seguido). ¿Sella igual?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "PARASITISMO",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "SIMBIOSIS"],
			"buffs": {"transmut_huesped": 1}},
		"bot": {"click_cps": 4.0, "click_until": 120.0, "buy": "cheapest", "transmute": "huesped",
			"huesped_feed_at": 85.0, "huesped_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_huesped_perfect": {
		"desc": "Huésped prolijo: alimenta a 60 y anticipa cada antojo: ¿saca el MYTHIC Simbionte Perfecto?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "PARASITISMO",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "SIMBIOSIS"],
			"buffs": {"transmut_huesped": 1}},
		"bot": {"click_cps": 4.0, "click_until": 120.0, "buy": "cheapest", "transmute": "huesped",
			"huesped_feed_at": 60.0, "huesped_precraving": true, "huesped_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},

	"ng_coro_sloppy": {
		"desc": "Coro con un jugador impreciso (85 % de golpes a tiempo): ¿llega a sellar?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "SIMBIOSIS",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "SIMBIOSIS"],
			"buffs": {"transmut_coro": 1}},
		"bot": {"click_cps": 4.0, "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "simbiosis", "transmute": "coro", "rhythm_accuracy": 0.85, "coro_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_coro_fortissimo": {
		"desc": "Coro con un jugador muy preciso (99.95 %): ¿saca el MYTHIC Fortissimo (Allegro sin fallar)?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "SIMBIOSIS",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "SIMBIOSIS"],
			"buffs": {"transmut_coro": 1}},
		"bot": {"click_cps": 4.0, "buy": "cheapest",
			"priority": ["accounting"], "save_for_priority": true, "save_from": 45.0,
			"mutation": "simbiosis", "transmute": "coro", "rhythm_accuracy": 0.9995, "coro_seal": true},
		"max_t": 3600.0, "sample_every": 30.0,
	},
	"ng_legacy_showcase": {
		"desc": "T5 con varios legados de ingreso + Convergencia Cíclica: para mirar los chips click×/pas× del header (modo visual).",
		"legacy": {"trascendencia_count": 5, "last_run_ending": "SIMBIOSIS",
			"endings": ["SIMBIOSIS", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"impulso_manual": 1, "aura_dorada": 1, "semilla_cosmica": 1, "mente_colmena": 1,
				"simbiosis_agresiva": 1, "resonancia_simbionte": 1, "metabolismo_glitch": 1},
			"cosmic": ["convergencia_ciclica"]},
		"bot": {"click_cps": 5.0, "buy": "cheapest", "avoid": ["accounting"]},
		"max_t": 120.0, "sample_every": 10.0,
	},
	"ng_fusion_smart": {
		"desc": "T3 + FUSIÓN: como ng_fusion_player, pero compra Contabilidad apenas activa Fusión para esquivar la Masa Crítica (420 s). ¿Es sellable?",
		"legacy": {"trascendencia_count": 3, "last_run_ending": "HIPERASIMILACION",
			"endings": ["HIPERASIMILACION", "PARASITISMO", "HOMEOSTASIS"],
			"buffs": {"transmut_fusion": 1}},
		"bot": {"click_cps": 7.0, "buy": "cheapest", "avoid": ["accounting"], "max_passive_pct": 15.0,
			"unavoid_on": {"accounting": "fusion_catabolica"}, "priority": ["accounting"],
			"save_for_priority": true, "save_from": 0.0,
			"transmute": "fusion", "fusion_bursts": true, "fusion_cd": true, "fusion_seal": true},
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
