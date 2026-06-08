class_name UITextBuilders

## Builders de texto puro para la UI de HYPHAE: genesis.
## Todas las funciones son static — no requiere instancia ni autoload.
## UIManager llama estos builders y muestra el resultado en los nodos correspondientes.

# ─── HELPERS ──────────────────────────────────────────────────────────────────

static func format_time(t: float) -> String:
	var hours := int(t / 3600)
	var mins  := int(fmod(t, 3600) / 60)
	var secs  := int(fmod(t, 60))
	return "%02d:%02d:%02d" % [hours, mins, secs]

static func format_compact(v: float) -> String:
	if v >= 1_000_000_000.0:
		return "%.2fB" % (v / 1_000_000_000.0)
	elif v >= 1_000_000.0:
		return "%.2fM" % (v / 1_000_000.0)
	elif v >= 1_000.0:
		return "%.1fK" % (v / 1_000.0)
	else:
		return "%.2f" % v

static func epsilon_flag(v: float, limit: float) -> String:
	return "⚠️" if v > limit else "✅"

static func get_system_phase(omega: float) -> String:
	if omega > 0.65: return "Estable / Flexible"
	if omega > 0.45: return "Cristalización Incipiente"
	if omega > 0.25: return "Rigidez Crítica"
	return "Colapso Predictivo"

# ─── FÓRMULA ──────────────────────────────────────────────────────────────────

static func build_formula_text(_main: Node) -> String:
	var has_abc := UpgradeManager.level("click_mult") > 0

	var active_term := "clicks · a"
	if has_abc: active_term += " · b"
	active_term += " · cₙ"

	if LegacyManager.get_buff_value("impulso_manual"):
		active_term = "( " + active_term + " · [color=#ffcc00]im[/color] )"
	if LegacyManager.get_buff_value("resonancia_simbionte"):
		active_term += " · [color=#44ee88]rs[/color]"
	if LegacyManager.get_buff_value("aura_dorada"):
		active_term += " · [color=#ffdd44]au[/color]"
	if RouteManager.is_active("vacio"):
		active_term += " · [color=#bb44ff]vh[/color]"

	var formula_main := active_term

	if StructuralModel.unlocked_d:
		var d_term := "d"
		if StructuralModel.unlocked_md:
			d_term = "d · md"
			if UpgradeManager.level("specialization") > 0:
				d_term += " · so"
		formula_main += " + " + d_term

		if StructuralModel.unlocked_e:
			var e_term := "e"
			if StructuralModel.unlocked_me:
				e_term = "e · me"
			if UpgradeManager.level("trueque_allo") > 0:
				e_term += " · [color=cyan]ea[/color]"
			formula_main += " + " + e_term

	if LegacyManager.get_buff_value("redireccion_energia"):
		formula_main += " + [color=#ffcc00]re[/color]"

	if EconomyManager.cached_mu > 1.01 and UpgradeManager.level("cognitive") > 0:
		formula_main = "[ " + formula_main + " ] · [color=#ff4dff]μ[/color]"

	var lambda_parts: Array = []
	if LegacyManager.get_buff_value("semilla_cosmica"):
		lambda_parts.append("[color=#8899ff]sc[/color]")
	if LegacyManager.get_buff_value("mente_colmena"):
		lambda_parts.append("[color=#ff44ff]mc[/color]")
	var eco_v: float = LegacyManager.get_effect_value("all_income_mult")
	if eco_v > 0.0:
		lambda_parts.append("[color=#44ffaa]ep[/color]")
	if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
		lambda_parts.append("[color=#ffaa44]cc[/color]")
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		lambda_parts.append("[color=#9933cc]mg?[/color]")
	if LegacyManager.get_effect_value("entropia_domesticada_mult") > 0.0:
		lambda_parts.append("[color=#ff6622]ed?[/color]")
	if lambda_parts.size() > 0:
		formula_main += " · [color=#ffdd88]Λ[/color]"

	var plain_str: String = formula_main
	for tag in ["[color=#ffcc00]","[color=#ff4dff]","[color=#44ee88]","[color=#bb44ff]",
				"[color=#ffdd44]","[color=#8899ff]","[color=#ff44ff]","[color=#44ffaa]",
				"[color=#ffaa44]","[color=#9933cc]","[color=#ffdd88]","[color=cyan]","[/color]"]:
		plain_str = plain_str.replace(tag, "")
	var fLen := plain_str.length()
	var fSize := 18
	if   fLen > 95: fSize = 11
	elif fLen > 80: fSize = 12
	elif fLen > 68: fSize = 13
	elif fLen > 55: fSize = 14
	elif fLen > 45: fSize = 15
	elif fLen > 35: fSize = 16

	var t: String = "[font_size=%d]∫$ = " % fSize + formula_main + "[/font_size]\n"

	if lambda_parts.size() > 0:
		t += "[color=#ffdd88][font_size=11]Λ = " + " · ".join(lambda_parts)
		if LegacyManager.get_buff_value("metabolismo_glitch"):
			t += TranslationServer.translate("FORMULA_MG_ACTIVE")
		if LegacyManager.get_effect_value("entropia_domesticada_mult") > 0.0:
			t += TranslationServer.translate("FORMULA_ED_ACTIVE")
		t += "[/font_size][/color]\n"

	var raw_n: int = StructuralModel.get_structural_upgrades()
	if UpgradeManager.level("cognitive") > 0:
		t += "fⁿ = c₀ · κμ^(1 - 1/n)\n\n"
		t += "κμ = k · (1 + α · (μ - 1))\n"
		t += "[color=#cccccc]c₀ = %.2f  cₙ = %.2f  μ = %.2f  n = %d[/color]" % [
			StructuralModel.persistence_base, StructuralModel.persistence_dynamic, EconomyManager.cached_mu, raw_n
		]
	else:
		t += "[color=#cccccc]c₀ = %.2f  cₙ = %.2f  n = %d[/color]" % [
			StructuralModel.persistence_base, StructuralModel.persistence_dynamic, raw_n
		]

	return t

static func build_formula_values(_main: Node) -> String:
	return ""

static func build_marginal_contribution(_main: Node) -> String:
	return ""

# ─── CLICK STATS / LAB ────────────────────────────────────────────────────────

static func update_click_stats_panel(_main: Node) -> String:
	var a := UpgradeManager.value("click")
	var b := UpgradeManager.value("click_mult")
	var c_n := StructuralModel.persistence_dynamic

	var d_raw := UpgradeManager.value("auto")
	var md := UpgradeManager.value("auto_mult")
	var so := UpgradeManager.value("specialization")

	var e_raw := UpgradeManager.value("trueque")
	var me := UpgradeManager.value("trueque_net")

	var ap := EconomyManager.get_active_passive_breakdown()
	var push: float = ap.push_abs

	var t := "[b]" + TranslationServer.translate("LAB_APORTE_ACTUAL") + "[/b]\n"
	t += "[color=#cccccc]" + TranslationServer.translate("LAB_CLICK_PUSH_LINE") % push + "\n"
	if StructuralModel.unlocked_d: t += TranslationServer.translate("LAB_TRABAJO_LINE") % EconomyManager.get_auto_income_effective() + "\n"
	if StructuralModel.unlocked_e: t += TranslationServer.translate("LAB_TRUEQUE_LINE") % EconomyManager.get_trueque_income_effective() + "[/color]\n\n"

	t += "[b]" + TranslationServer.translate("LAB_DELTA_TOTAL") % ap.total + "[/b]\n"
	if ap.total > 0:
		if ap.activo > ap.pasivo:
			t += TranslationServer.translate("LAB_CLICK_DOM") + "\n\n"
		else:
			t += TranslationServer.translate("LAB_RED_DOM") + "\n\n"

	t += "[color=#d946ef]--- " + TranslationServer.translate("LAB_PROD_ACTIVE") + " ---\n"
	t += "a = %.1f   " % a + TranslationServer.translate("LAB_CLICK_BASE") + "\n"
	if UpgradeManager.level("click_mult") > 0:
		t += "b = %.2f   " % b + TranslationServer.translate("LAB_MULTIPLICADOR") + "\n"
	if StructuralModel.persistence_upgrade_unlocked:
		t += "c_n(actual) = %.2f\n" % c_n
	if RouteManager.is_active("vacio"):
		t += "vh = %.0f\n" % RouteManager.production_mult()
	if LegacyManager.get_buff_value("impulso_manual"):
		t += "im = 2.00   " + TranslationServer.translate("LAB_IMPULSO_MANUAL") + "\n"
	t += "\n"

	if StructuralModel.unlocked_d:
		t += "d = %.1f/s   " % d_raw + TranslationServer.translate("LAB_TRABAJO_MANUAL") + "\n"
		if StructuralModel.unlocked_md: t += "md = %.2f   " % md + TranslationServer.translate("LAB_RITMO_TRABAJO") + "\n"
		else: t += "md = -- " + TranslationServer.translate("LAB_LATENTE") + "\n"
		if UpgradeManager.level("specialization") > 0: t += "so = %.2f   " % so + TranslationServer.translate("LAB_ESPECIALIZACION") + "\n"
		t += "\n"

	if StructuralModel.unlocked_e:
		t += "e = %.1f/s   " % e_raw + TranslationServer.translate("LAB_TRUEQUE_CORR") + "\n"
		if StructuralModel.unlocked_me:
			t += "me = %.2f   " % me + TranslationServer.translate("LAB_RED_INTERCAMBIO") + "\n"
			if UpgradeManager.level("trueque_allo") > 0:
				t += "ea = %.2f   " % UpgradeManager.value("trueque_allo") + TranslationServer.translate("LAB_ESCALADO_ALOS") + "\n"
		else: t += "me = -- " + TranslationServer.translate("LAB_LATENTE") + "\n"

	if LegacyManager.get_buff_value("redireccion_energia"):
		t += "re = +%.1f/s   " % (EconomyManager.get_click_power() * 0.10) + TranslationServer.translate("LAB_REDIRECCION") + "\n"

	t += "\n\n--- " + TranslationServer.translate("LAB_MODELO_STRUCT") + " ---\n"
	var n_struct := int(StructuralModel.get_effective_structural_n())
	var k_base := EcoModel.get_k_structural(n_struct)
	var alpha := EcoModel.get_alpha(n_struct)

	t += "k = %.2f\n" % k_base
	t += "α = %.2f\n" % alpha
	if UpgradeManager.level("cognitive") > 0:
		t += "μ = %.2f\n" % EconomyManager.cached_mu
		t += "κμ = %.2f\n" % StructuralModel.get_k_eff()
	t += "n = %d\n" % StructuralModel.get_structural_upgrades()

	if UpgradeManager.level("cognitive") > 0:
		t += "\n\n--- " + TranslationServer.translate("LAB_CAPITAL_COG") + " ---\n"
		t += "μ = %.2f\n" % EconomyManager.cached_mu
		t += TranslationServer.translate("LAB_NIVEL_COG") % UpgradeManager.level("cognitive") + "\n"
		var acc_lvl_d: int = UpgradeManager.level("accounting")
		if acc_lvl_d > 0:
			t += TranslationServer.translate("LAB_CONTAB_MU") % (1.0 + acc_lvl_d * 0.08) + "\n"
		if RunManager.resilience_score > 0.0:
			t += TranslationServer.translate("LAB_RESIL_MU") % [1.0 + min(RunManager.resilience_score / 300.0, 1.0) * 0.30, RunManager.resilience_score] + "\n"

	var has_income_buff := false
	var income_section := "\n--- " + TranslationServer.translate("LAB_LEGADO_MULT") + " ---\n"
	if LegacyManager.get_buff_value("impulso_manual"):
		income_section += TranslationServer.translate("LAB_IM_LINE") + "\n"; has_income_buff = true
	if LegacyManager.get_buff_value("resonancia_simbionte"):
		var rs_val: float = min(1.0 + BiosphereEngine.biomasa * 0.05, 2.5)
		income_section += TranslationServer.translate("LAB_RS_LINE") % [rs_val, BiosphereEngine.biomasa] + "\n"
		has_income_buff = true
	if LegacyManager.get_buff_value("aura_dorada"):
		income_section += TranslationServer.translate("LAB_AU_LINE") + "\n"; has_income_buff = true
	if LegacyManager.get_buff_value("semilla_cosmica"):
		income_section += TranslationServer.translate("LAB_SC_LINE") + "\n"; has_income_buff = true
	if LegacyManager.get_buff_value("mente_colmena"):
		income_section += TranslationServer.translate("LAB_MC_LINE") + "\n"; has_income_buff = true
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		var mg_active := StructuralModel.epsilon_runtime > 0.40
		var mg_state: String = ""
		if mg_active:
			mg_state = TranslationServer.translate("LAB_MG_ACTIVO")
		else:
			mg_state = TranslationServer.translate("LAB_MG_INACTIVO") % StructuralModel.epsilon_runtime
		income_section += TranslationServer.translate("LAB_MG_LINE") % mg_state + "\n"
		has_income_buff = true
	var eco_mult: float = LegacyManager.get_effect_value("all_income_mult")
	if eco_mult > 0.0:
		income_section += TranslationServer.translate("LAB_EP_LINE") % (1.0 + eco_mult) + "\n"; has_income_buff = true
	if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
		var cc_val := 1.0 + LegacyManager.trascendencia_count * 0.05
		income_section += TranslationServer.translate("LAB_CC_LINE") % [cc_val, LegacyManager.trascendencia_count] + "\n"
		has_income_buff = true
	var cog_mult: float = LegacyManager.get_effect_value("cognitivo_income_mult_per_level")
	if cog_mult > 0.0:
		var cog_val := 1.0 + UpgradeManager.level("accounting") * cog_mult
		income_section += TranslationServer.translate("LAB_RC_LINE") % [cog_val, UpgradeManager.level("accounting")] + "\n"
		has_income_buff = true
	var entropia_k: float = LegacyManager.get_effect_value("entropia_domesticada_mult")
	if entropia_k > 0.0:
		var ed_active: bool = StructuralModel.epsilon_runtime > 0.65
		var ed_mult: float = 1.0
		var ed_state: String = TranslationServer.translate("LAB_MG_INACTIVO") % StructuralModel.epsilon_runtime
		if ed_active:
			ed_mult = clampf(1.0 + (StructuralModel.epsilon_runtime - 0.65) * entropia_k, 1.0, 2.0)
			ed_state = TranslationServer.translate("LAB_MG_ACTIVO")
		income_section += TranslationServer.translate("LAB_ED_LINE") % [ed_mult, ed_state] + "\n"
		has_income_buff = true
	if has_income_buff:
		t += income_section

	var has_omega_buff := false
	var omega_section := "\n--- " + TranslationServer.translate("LAB_LEGADO_OMEGA") + " ---\n"
	if LegacyManager.get_buff_value("plasticidad_adaptativa"):
		omega_section += TranslationServer.translate("LAB_PA_LINE") + "\n"; has_omega_buff = true
	if LegacyManager.get_buff_value("legado_homeorresis"):
		omega_section += TranslationServer.translate("LAB_TC_LINE") + "\n"; has_omega_buff = true
	if LegacyManager.get_buff_value("legado_alostasis"):
		omega_section += TranslationServer.translate("LAB_RA_LINE") % RunManager.disturbances_survived + "\n"
		has_omega_buff = true
	var eq_per_dist: float = LegacyManager.get_effect_value("omega_min_per_disturbance")
	if eq_per_dist > 0.0:
		omega_section += TranslationServer.translate("LAB_EH_LINE") % eq_per_dist + "\n"; has_omega_buff = true
	var omega_rec: float = LegacyManager.get_effect_value("omega_recovery_speed")
	if omega_rec > 0.0:
		omega_section += TranslationServer.translate("LAB_SA_LINE") % omega_rec + "\n"; has_omega_buff = true
	if LegacyManager.get_buff_value("cristalizacion_permanente"):
		omega_section += TranslationServer.translate("LAB_CP_LINE") + "\n"; has_omega_buff = true
	if has_omega_buff:
		t += omega_section

	t += "[/color]"
	return t

# ─── EVO CHECKLIST ────────────────────────────────────────────────────────────

static func build_evo_checklist(_main: Node) -> String:
	if RunManager.run_closed:
		return _build_run_end_lore(RunManager.final_route)

	var t := "[color=cyan][b]" + TranslationServer.translate("EVO_NEXT_TRANS") + "[/b][/color]\n"
	var acc := UpgradeManager.level("accounting")
	var ch: String
	var ok_color := "[color=%s]" % AccessibilityManager.cok_hex()
	var fail_color := "[color=%s]" % AccessibilityManager.cno_hex()

	if EvoManager.mutation_homeostasis:
		var tier := RunManager.homeostasis_tier_reached
		if tier == 0:
			t += "[b][color=cyan]" + TranslationServer.translate("EVO_TIER1_TITLE") + "[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.get_en_banda_homeostatica() else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_BAND_EPS") % snapped(StructuralModel.epsilon_runtime, 0.01) + "[/color]\n"
			ch = ok_color + "[x] " if StructuralModel.unlocked_d and StructuralModel.unlocked_e else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_UNLOCKED_DE") + "[/color]\n"
			ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_ACCOUNTING_N1") % acc + "[/color]\n"
			var pct := int(min(RunManager.homeostasis_timer / Balance.HOMEOSTASIS_TIME_REQUIRED, 1.0) * 100.0)
			t += "[color=cyan]" + TranslationServer.translate("EVO_STABILIZING") % [pct, RunManager.homeostasis_timer] + "[/color]\n"
		elif tier == 1:
			t += ok_color + "[x] " + TranslationServer.translate("EVO_TIER1_DONE") + "[/color]\n"
			t += "[b][color=aquamarine]" + TranslationServer.translate("EVO_TIER2_TITLE") + "[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.disturbances_survived >= 3 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_DISTURBANCES") % [RunManager.disturbances_survived, 3] + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.resilience_score >= 150.0 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_RESILIENCE_GE") % [150, int(RunManager.resilience_score)] + "[/color]\n"
			ch = ok_color + "[x] " if StructuralModel.omega_min >= 0.40 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_OMEGA_MIN_GE") % [snapped(0.40, 0.01), snapped(StructuralModel.omega_min, 0.01)] + "[/color]\n"
			var delta_real2: float = EconomyManager.get_contribution_breakdown().total
			ch = ok_color + "[x] " if delta_real2 > 200.0 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_METABOLISM_GT") % [200, snapped(delta_real2, 0.1)] + "[/color]\n"
			ch = ok_color + "[x] " if acc >= 2 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_ACCOUNTING_N2") % acc + "[/color]\n"
		elif tier == 2:
			t += ok_color + "[x] " + TranslationServer.translate("EVO_TIER12_DONE") + "[/color]\n"
			t += "[b][color=gold]" + TranslationServer.translate("EVO_TIER3_TITLE") + "[/color][/b]\n"
			ch = ok_color + "[x] " if RunManager.extreme_shocks_recovered >= 1 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_SHOCK_EXTREME") % RunManager.extreme_shocks_recovered + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.resilience_score >= 400.0 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_RESILIENCE_GE") % [400, int(RunManager.resilience_score)] + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.omega_min_peak >= 0.50 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_OMEGA_PEAK_GE") % [snapped(0.50, 0.01), snapped(RunManager.omega_min_peak, 0.01)] + "[/color]\n"
			ch = ok_color + "[x] " if RunManager.disturbances_survived >= 5 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_DISTURBANCES") % [RunManager.disturbances_survived, 5] + "[/color]\n"
			var delta_real3: float = EconomyManager.get_contribution_breakdown().total
			ch = ok_color + "[x] " if delta_real3 > 300.0 else fail_color + "[ ] "
			t += ch + TranslationServer.translate("EVO_METABOLISM_GT") % [300, snapped(delta_real3, 0.1)] + "[/color]\n"
			var homeo_min_t: float = Balance.HOMEORHESIS_MIN_RUN_TIME
			if LegacyManager.has_cosmic_buff("cicatriz_metabolica"):
				homeo_min_t *= 0.5
			ch = ok_color + "[x] " if RunManager.run_time >= homeo_min_t else fail_color + "[ ] "
			var target_label := "%dmin" % int(homeo_min_t / 60.0)
			t += ch + TranslationServer.translate("EVO_RUN_GE_TIME") % [target_label, format_time(RunManager.run_time)] + "[/color]\n"
		elif tier == 3:
			t += ok_color + "[x] " + TranslationServer.translate("EVO_TIER3_DONE") + "[/color]\n"
		t += "\n"

	if EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		t += "[b]" + TranslationServer.translate("EVO_RED_OBJ_MECH") + "[/b]\n"
		if EvoManager.nucleo_conciencia:
			t += ok_color + "[x] " + TranslationServer.translate("EVO_NUCLEUS_SYNC") + "[/color]\n"
		else:
			var n_eps := StructuralModel.epsilon_runtime
			ch = ok_color + "[x] " if acc >= Balance.NUCLEO_ACC_MIN else fail_color + "[ ] "
			t += ch + (TranslationServer.translate("NUCLEO_COND_ACC") % [acc, Balance.NUCLEO_ACC_MIN]) + "[/color]\n"
			ch = ok_color + "[x] " if StructuralModel.omega >= Balance.NUCLEO_OMEGA_MIN else fail_color + "[ ] "
			t += ch + (TranslationServer.translate("NUCLEO_COND_OMEGA") % [Balance.NUCLEO_OMEGA_MIN, snapped(StructuralModel.omega, 0.01)]) + "[/color]\n"
			ch = ok_color + "[x] " if (n_eps >= Balance.NUCLEO_EPS_LO and n_eps <= Balance.NUCLEO_EPS_HI) else fail_color + "[ ] "
			t += ch + (TranslationServer.translate("NUCLEO_COND_EPS") % [Balance.NUCLEO_EPS_LO, Balance.NUCLEO_EPS_HI, snapped(n_eps, 0.01)]) + "[/color]\n"
			ch = ok_color + "[x] " if BiosphereEngine.biomasa >= Balance.NUCLEO_BIO_MIN else fail_color + "[ ] "
			t += ch + (TranslationServer.translate("NUCLEO_COND_BIO") % [snapped(BiosphereEngine.biomasa, 0.1), Balance.NUCLEO_BIO_MIN]) + "[/color]\n"
			t += "[color=cyan]" + (TranslationServer.translate("NUCLEO_SYNC_METER") % int(EvoManager.nucleo_sync)) + "[/color]\n"

		if LegacyManager.last_run_ending == "SINGULARIDAD" or LegacyManager.last_run_ending == "MENTE COLMENA DISTRIBUIDA":
			t += "\n[color=magenta][b]🧠 " + TranslationServer.translate("EVO_MC_ROUTE") + "[/b][/color]\n"
			var mc_timer: float = RunManager.mente_colmena_timer
			var mc_active: bool = RunManager.mente_colmena_active
			if mc_active:
				t += ok_color + "[x] " + TranslationServer.translate("EVO_MC_ACTIVE") + "[/color]\n"
			elif mc_timer > 0.0:
				var mc_pct := int(mc_timer / Balance.MC_GATE_HOLD * 100.0)
				var filled := int(mc_pct / 5.0)
				var bar := ""
				for i in range(20):
					bar += "█" if i < filled else "░"
				t += "[color=cyan]" + TranslationServer.translate("EVO_MC_SYNC_BAR") % [bar, mc_pct, mc_timer, Balance.MC_GATE_HOLD] + "[/color]\n"
				var ap: Dictionary = EconomyManager.get_active_passive_breakdown()
				var r_act := int(ap.activo)
				var r_pas := int(ap.pasivo)
				var ratio_color := "[color=cyan]" if abs(r_act - 50) <= 2 else "[color=yellow]"
				t += ratio_color + "    " + TranslationServer.translate("EVO_MC_RATIO_DISPLAY") % [r_act, r_pas] + "[/color]\n"
			else:
				t += "[color=#aaaaaa]" + TranslationServer.translate("EVO_MC_RATIO_REQ") + "[/color]\n"
				t += "[color=#aaaaaa]" + TranslationServer.translate("EVO_MC_EPS_REQ") + "[/color]\n"

	elif EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		t += "[b]" + TranslationServer.translate("EVO_RED_OBJ_BIO") + "[/b]\n"
		var mic_ok: bool = BiosphereEngine.micelio >= 60.0 or EvoManager.seta_formada
		ch = ok_color + "[x] " if mic_ok else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_MICELIO_DEV") % int(BiosphereEngine.micelio) + "[/color]\n"
		if not mic_ok and EvoManager.is_colonizacion_pushable():
			t += "[color=#88cc44]    " + (TranslationServer.translate("EVO_COLONIZ_HINT") % [Balance.MICELIO_PULSE_GAIN, Balance.MICELIO_COLONIZ_DECAY]) + "[/color]\n"
		if EvoManager.primordio_active:
			var p_eps: float = StructuralModel.epsilon_runtime
			var p_overheated: bool = p_eps > Balance.PRIMORDIO_BAND_HI
			var band_col: String = fail_color if p_overheated else ok_color
			t += band_col + TranslationServer.translate("PRIMORDIO_BAND_STATUS") % [p_eps, Balance.PRIMORDIO_BAND_HI] + "[/color]\n"
			t += "[color=#88cc44]    " + (TranslationServer.translate("PRIMORDIO_PROG_STATUS") % [int(EvoManager.primordio_timer / Balance.PRIMORDIO_BIO_MATURE * 100.0), int(EvoManager.primordio_integrity)]) + "[/color]\n"
		elif EvoManager.seta_formada:
			t += ok_color + "[x] " + TranslationServer.translate("EVO_BIO_CYCLE_DONE") + "[/color]\n"
		else:
			t += fail_color + "[ ] " + TranslationServer.translate("EVO_SURVIVE_PRIM") + "[/color]\n"
		ch = ok_color + "[x] " if EvoManager.seta_formada else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_SETA_MADURA") + "[/color]\n"
		if EvoManager.seta_formada:
			t += "[color=cyan][b]" + TranslationServer.translate("EVO_READY_ESPOR") + "[/b][/color]\n"

	elif EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 1:
		t += "[b]" + TranslationServer.translate("EVO_RED_PHASE_B") + "[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas > 10.0 else fail_color + "[ ] "
		t += ch + "Hifas > 10  (%s)[/color]\n" % snapped(BiosphereEngine.hifas, 0.1)
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 5.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 5  (%s)[/color]\n" % snapped(BiosphereEngine.biomasa, 0.1)
		ch = ok_color + "[x] " if StructuralModel.epsilon_effective < 0.32 else fail_color + "[ ] "
		t += ch + "ε_ef < 0.32  (%s)[/color]\n" % snapped(StructuralModel.epsilon_effective, 0.01)
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_ACCOUNTING_GE1") % acc + "[/color]\n"
		ch = ok_color + "[x] " if RunManager.run_time > 200.0 else fail_color + "[ ] "
		t += ch + "Tiempo > 200 s  (%s)[/color]\n" % format_time(RunManager.run_time)

	elif EvoManager.mutation_symbiosis and not EvoManager.mutation_red_micelial:
		t += "[b][color=green]" + TranslationServer.translate("EVO_SIM_ACTIVE_TITLE") + "[/color][/b]\n"
		t += "[color=gray]" + TranslationServer.translate("EVO_SIM_SEAL_HINT") + "[/color]\n"

	elif not EvoManager.mutation_red_micelial and not EvoManager.mutation_homeostasis \
		and not EvoManager.mutation_hyperassimilation and not EvoManager.mutation_parasitism \
		and not EvoManager.mutation_symbiosis:
		var ap_snap := EconomyManager.get_active_passive_breakdown()
		var pasivo_domina: bool = ap_snap.pasivo > ap_snap.activo
		var activo_domina: bool = ap_snap.activo > ap_snap.pasivo
		t += "[b]" + TranslationServer.translate("EVO_RED_TITLE") + "[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas >= 11.5 else fail_color + "[ ] "
		t += ch + "Hifas >= 12  (" + str(snapped(BiosphereEngine.hifas, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 5.0 else fail_color + "[ ] "
		t += ch + "Biomasa >= 5  (" + str(snapped(BiosphereEngine.biomasa, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.epsilon_runtime < 0.65 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_EPS_RT_LT65") % snapped(StructuralModel.epsilon_runtime, 0.01) + "[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_ACCOUNTING_GE1") % acc + "[/color]\n"
		ch = ok_color + "[x] " if pasivo_domina else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_PASSIVE_DOM") % [int(ap_snap.pasivo), int(ap_snap.activo)] + "[/color]\n"
		t += "\n[b]" + TranslationServer.translate("EVO_SIM_TITLE") + "[/b]\n"
		ch = ok_color + "[x] " if BiosphereEngine.hifas >= 5.0 else fail_color + "[ ] "
		t += ch + "Hifas >= 5  (" + str(snapped(BiosphereEngine.hifas, 0.1)) + ")[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.omega >= 0.40 else fail_color + "[ ] "
		t += ch + "Ω >= 0.40  (" + str(snapped(StructuralModel.omega, 0.01)) + ")[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_ACCOUNTING_GE1") % acc + "[/color]\n"
		ch = ok_color + "[x] " if activo_domina else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_ACTIVE_DOM") % [int(ap_snap.activo), int(ap_snap.pasivo)] + "[/color]\n"

	if not EvoManager.mutation_homeostasis and not EvoManager.mutation_hyperassimilation \
		and not EvoManager.mutation_sporulation and not EvoManager.mutation_red_micelial \
		and not EvoManager.mutation_symbiosis:
		t += "\n[color=gray]" + TranslationServer.translate("EVO_HOME_HINT_LABEL") + "[/color]\n"
		ch = ok_color + "[x] " if RunManager.get_en_banda_homeostatica() else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_BAND_VALUE") % snapped(StructuralModel.epsilon_runtime, 0.01) + "[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.omega > 0.25 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_OMEGA_025") % snapped(StructuralModel.omega, 0.01) + "[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa < 12.0 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_BIOMASA_LT12") % snapped(BiosphereEngine.biomasa, 0.1) + "[/color]\n"
		ch = ok_color + "[x] " if EconomyManager.delta_per_sec > 30.0 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_METABOLISM_GT") % [30, snapped(EconomyManager.delta_per_sec, 0.1)] + "[/color]\n"
		ch = ok_color + "[x] " if StructuralModel.unlocked_d and StructuralModel.unlocked_e else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_PASSIVES_DE") + "[/color]\n"
		ch = ok_color + "[x] " if acc >= 1 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_ACCOUNTING_GE1") % acc + "[/color]\n"

	if EvoManager.mutation_parasitism:
		t += "\n[color=#ffaa00]" + TranslationServer.translate("EVO_COLLAPSE_OBJ") + "[/color]\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 15.0 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_BIO_DRAIN") % snapped(BiosphereEngine.biomasa, 0.1) + "[/color]\n"
		ch = ok_color + "[x] " if EconomyManager.money < 1000.0 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_LIQUID_LT1K") % snapped(EconomyManager.money, 1) + "[/color]\n"
		t += "\n" + TranslationServer.translate("EVO_OR_SEP") + "\n"
		ch = ok_color + "[x] " if BiosphereEngine.biomasa >= 25.0 else fail_color + "[ ] "
		t += ch + TranslationServer.translate("EVO_BIO_CRITICAL") % snapped(BiosphereEngine.biomasa, 0.1) + "[/color]\n"

	return t

# ─── LORE DE FIN DE RUN ───────────────────────────────────────────────────────

static func _build_run_end_lore(route: String) -> String:
	var lore_data := {
		"HOMEOSTASIS": {
			"emoji": "⚖️", "color": "#00ccff",
			"lore": TranslationServer.translate("LORE_HOME_LORE"),
			"buffs": [TranslationServer.translate("LORE_HOME_B1"), TranslationServer.translate("LORE_HOME_B2"), TranslationServer.translate("LORE_HOME_B3"), TranslationServer.translate("LORE_HOME_B4")],
			"nerfs": [TranslationServer.translate("LORE_HOME_N1"), TranslationServer.translate("LORE_HOME_N2"), TranslationServer.translate("LORE_HOME_N3")]
		},
		"ALLOSTASIS": {
			"emoji": "💜", "color": "#aa55ff",
			"lore": TranslationServer.translate("LORE_ALOS_LORE"),
			"buffs": [TranslationServer.translate("LORE_ALOS_B1"), TranslationServer.translate("LORE_ALOS_B2"), TranslationServer.translate("LORE_ALOS_B3"), TranslationServer.translate("LORE_ALOS_B4")],
			"nerfs": [TranslationServer.translate("LORE_ALOS_N1"), TranslationServer.translate("LORE_ALOS_N2")]
		},
		"HOMEORHESIS": {
			"emoji": "💎", "color": "#00ffee",
			"lore": TranslationServer.translate("LORE_HOMR_LORE"),
			"buffs": [TranslationServer.translate("LORE_HOMR_B1"), TranslationServer.translate("LORE_HOMR_B2"), TranslationServer.translate("LORE_HOMR_B3"), TranslationServer.translate("LORE_HOMR_B4")],
			"nerfs": [TranslationServer.translate("LORE_HOMR_N1"), TranslationServer.translate("LORE_HOMR_N2"), TranslationServer.translate("LORE_HOMR_N3")]
		},
		"SIMBIOSIS": {
			"emoji": "💚", "color": "#00dd66",
			"lore": TranslationServer.translate("LORE_SIMB_LORE"),
			"buffs": [TranslationServer.translate("LORE_SIMB_B1"), TranslationServer.translate("LORE_SIMB_B2"), TranslationServer.translate("LORE_SIMB_B3"), TranslationServer.translate("LORE_SIMB_B4")],
			"nerfs": [TranslationServer.translate("LORE_SIMB_N1"), TranslationServer.translate("LORE_SIMB_N2"), TranslationServer.translate("LORE_SIMB_N3")]
		},
		"SINGULARIDAD": {
			"emoji": "📡", "color": "#ffd060",
			"lore": TranslationServer.translate("LORE_SING_LORE"),
			"buffs": [TranslationServer.translate("LORE_SING_B1"), TranslationServer.translate("LORE_SING_B2"), TranslationServer.translate("LORE_SING_B3")],
			"nerfs": [TranslationServer.translate("LORE_SING_N1"), TranslationServer.translate("LORE_SING_N2")]
		},
		"MENTE COLMENA DISTRIBUIDA": {
			"emoji": "🧠", "color": "#40aaff",
			"lore": TranslationServer.translate("LORE_MENTE_LORE"),
			"buffs": [TranslationServer.translate("LORE_MENTE_B1"), TranslationServer.translate("LORE_MENTE_B2"), TranslationServer.translate("LORE_MENTE_B3"), TranslationServer.translate("LORE_MENTE_B4")],
			"nerfs": [TranslationServer.translate("LORE_MENTE_N1"), TranslationServer.translate("LORE_MENTE_N2")]
		},
		"ESPORULACIÓN": {
			"emoji": "✨", "color": "#aaff44",
			"lore": TranslationServer.translate("LORE_ESPOR_LORE"),
			"buffs": [TranslationServer.translate("LORE_ESPOR_B1"), TranslationServer.translate("LORE_ESPOR_B2"), TranslationServer.translate("LORE_ESPOR_B3")],
			"nerfs": [TranslationServer.translate("LORE_ESPOR_N1"), TranslationServer.translate("LORE_ESPOR_N2"), TranslationServer.translate("LORE_ESPOR_N3")]
		},
		"ESPORULACION": {
			"emoji": "✨", "color": "#aaff44",
			"lore": TranslationServer.translate("LORE_ESPOR_LORE"),
			"buffs": [TranslationServer.translate("LORE_ESPOR_B1"), TranslationServer.translate("LORE_ESPOR_B2")],
			"nerfs": [TranslationServer.translate("LORE_ESPOR_N1"), TranslationServer.translate("LORE_ESPOR_N2")]
		},
		"PANSPERMIA NEGRA": {
			"emoji": "🚀", "color": "#dd22ff",
			"lore": TranslationServer.translate("LORE_PANSP_LORE"),
			"buffs": [TranslationServer.translate("LORE_PANSP_B1"), TranslationServer.translate("LORE_PANSP_B2"), TranslationServer.translate("LORE_PANSP_B3")],
			"nerfs": [TranslationServer.translate("LORE_PANSP_N1"), TranslationServer.translate("LORE_PANSP_N2")]
		},
		"PARASITISMO": {
			"emoji": "☣️", "color": "#ff4400",
			"lore": TranslationServer.translate("LORE_PARAS_LORE"),
			"buffs": [TranslationServer.translate("LORE_PARAS_B1"), TranslationServer.translate("LORE_PARAS_B2"), TranslationServer.translate("LORE_PARAS_B3"), TranslationServer.translate("LORE_PARAS_B4")],
			"nerfs": [TranslationServer.translate("LORE_PARAS_N1"), TranslationServer.translate("LORE_PARAS_N2"), TranslationServer.translate("LORE_PARAS_N3"), TranslationServer.translate("LORE_PARAS_N4"), TranslationServer.translate("LORE_PARAS_N5")]
		},
		"HIPERASIMILACIÓN": {
			"emoji": "🔥", "color": "#ff8800",
			"lore": TranslationServer.translate("LORE_HIPERAS_LORE"),
			"buffs": [TranslationServer.translate("LORE_HIPERAS_B1"), TranslationServer.translate("LORE_HIPERAS_B2"), TranslationServer.translate("LORE_HIPERAS_B3"), TranslationServer.translate("LORE_HIPERAS_B4")],
			"nerfs": [TranslationServer.translate("LORE_HIPERAS_N1"), TranslationServer.translate("LORE_HIPERAS_N2"), TranslationServer.translate("LORE_HIPERAS_N3")]
		},
		"COLAPSO CONTROLADO": {
			"emoji": "⚡", "color": "#ff6622",
			"lore": TranslationServer.translate("LORE_COL_LORE"),
			"buffs": [TranslationServer.translate("LORE_COL_B1"), TranslationServer.translate("LORE_COL_B2"), TranslationServer.translate("LORE_COL_B3")],
			"nerfs": [TranslationServer.translate("LORE_COL_N1"), TranslationServer.translate("LORE_COL_N2"), TranslationServer.translate("LORE_COL_N3")]
		},
		"DEPREDADOR DE REALIDADES": {
			"emoji": "👾", "color": "#ff0055",
			"lore": TranslationServer.translate("LORE_DEP_LORE"),
			"buffs": [TranslationServer.translate("LORE_DEP_B1"), TranslationServer.translate("LORE_DEP_B2"), TranslationServer.translate("LORE_DEP_B3"), TranslationServer.translate("LORE_DEP_B4")],
			"nerfs": [TranslationServer.translate("LORE_DEP_N1"), TranslationServer.translate("LORE_DEP_N2"), TranslationServer.translate("LORE_DEP_N3")]
		},
		"METABOLISMO OSCURO": {
			"emoji": "🌑", "color": "#8844aa",
			"lore": TranslationServer.translate("LORE_MO_LORE"),
			"buffs": [TranslationServer.translate("LORE_MO_B1"), TranslationServer.translate("LORE_MO_B2"), TranslationServer.translate("LORE_MO_B3"), TranslationServer.translate("LORE_MO_B4"), TranslationServer.translate("LORE_MO_B5")],
			"nerfs": [TranslationServer.translate("LORE_MO_N1"), TranslationServer.translate("LORE_MO_N2"), TranslationServer.translate("LORE_MO_N3"), TranslationServer.translate("LORE_MO_N4")]
		},
		"ESCLEROCIO OSCURO": {
			"emoji": "🌑", "color": "#b399c0",
			"lore": TranslationServer.translate("LORE_ESCLEROCIO_LORE"),
			"buffs": [TranslationServer.translate("LORE_ESCLEROCIO_B1"), TranslationServer.translate("LORE_ESCLEROCIO_B2"), TranslationServer.translate("LORE_ESCLEROCIO_B3")],
			"nerfs": [TranslationServer.translate("LORE_ESCLEROCIO_N1"), TranslationServer.translate("LORE_ESCLEROCIO_N2")]
		},
		"AUTOFAGIA NECRÓTICA": {
			"emoji": "🔥", "color": "#d94d00",
			"lore": TranslationServer.translate("LORE_AUTOLISIS_LORE"),
			"buffs": [TranslationServer.translate("LORE_AUTOLISIS_B1"), TranslationServer.translate("LORE_AUTOLISIS_B2")],
			"nerfs": [TranslationServer.translate("LORE_AUTOLISIS_N1"), TranslationServer.translate("LORE_AUTOLISIS_N2")]
		},
	}

	var data = lore_data.get(route, null)
	if data == null:
		return "[color=gray]" + TranslationServer.translate("LORE_RUN_DONE") % route + "[/color]\n"

	if route == "PANSPERMIA NEGRA" and LegacyManager.esclerocio_panspermia_done:
		data.lore = TranslationServer.translate("LORE_PANSP_OSCURA_LORE")
		data.buffs = data.buffs.duplicate()
		data.buffs.append(TranslationServer.translate("LORE_PANSP_OSCURA_B1"))

	var t := ""
	t += "[color=%s][b]%s %s[/b][/color]\n\n" % [data.color, data.emoji, route]
	t += "[color=#cccccc][i]%s[/i][/color]\n\n" % data.lore
	t += "[color=#00ff88][b]" + TranslationServer.translate("LORE_EFFECTS") + "[/b][/color]\n"
	for buff in data.buffs:
		t += "[color=#00ff88]+ %s[/color]\n" % buff
	t += "\n"
	for nerf in data.nerfs:
		t += "[color=#ff4444]- %s[/color]\n" % nerf
	t += "\n[color=gray]" + TranslationServer.translate("LORE_NEW_RUN") + "[/color]"
	return t

# ─── GENOMA ───────────────────────────────────────────────────────────────────

static func build_genome_text() -> String:
	var t := ""
	if RouteManager.is_active("vacio"):
		t += "[b][color=#bb44ff]🕳️ " + TranslationServer.translate("GENOME_VACIO_TITLE") + "[/color][/b]\n"
		t += "[color=#888888]" + TranslationServer.translate("GENOME_VACIO_DESC") + "[/color]\n"
		var _gen: float = EconomyManager.money
		var _run_t: float = RunManager.run_time
		t += "[color=#9955dd]" + TranslationServer.translate("GENOME_ASCESIS_TITLE") + "[/color]\n"
		if _gen < Balance.ASCESIS_MONEY_REQ:
			t += "[color=#666666]" + TranslationServer.translate("GENOME_ASCESIS_GEN") % (_gen / 1000000.0) + "[/color]\n\n"
		elif _run_t < Balance.ASCESIS_MIN_RUN_TIME:
			t += "[color=#666666]" + TranslationServer.translate("GENOME_ASCESIS_TIME") % _run_t + "[/color]\n\n"
		else:
			var bio_ok: bool = BiosphereEngine.biomasa < 0.5
			var sin_p: bool = UpgradeManager.level("auto") == 0 and UpgradeManager.level("trueque") == 0
			var eps_ok: bool = StructuralModel.epsilon_runtime < 0.25
			var clk_ok: bool = EconomyManager.time_since_last_click < Balance.ASCESIS_CLICK_TIMEOUT
			var bio_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if bio_ok else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			var pas_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if sin_p else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			var eps_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if eps_ok else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			var clk_s: String = "[color=%s]OK[/color]" % AccessibilityManager.cok_hex() if clk_ok else "[color=%s]FALLA[/color]" % AccessibilityManager.cno_hex()
			t += TranslationServer.translate("GENOME_ASCESIS_BIO_LBL") + ": " + bio_s + "  " + TranslationServer.translate("GENOME_ASCESIS_PAS_LBL") + ": " + pas_s + "  e: " + eps_s + "  " + TranslationServer.translate("GENOME_ASCESIS_CLK_LBL") + ": " + clk_s + "\n"
			var _rs: Dictionary = RouteManager.get_extra_state()
			var ascesis_t: float = _rs.get("ascesis_timer", 0.0)
			var prog: float = clamp(ascesis_t / float(Balance.ASCESIS_DURATION), 0.0, 1.0)
			var filled: int = int(prog * 20)
			var bar: String = "[" + "X".repeat(filled) + ".".repeat(20 - filled) + "]"
			t += bar + " %ds/%ds\n\n" % [int(ascesis_t), Balance.ASCESIS_DURATION]
	elif RouteManager.is_active("carnaval"):
		var rs: Dictionary = RouteManager.get_extra_state()
		var muts: Array = rs.get("mutations", [])
		var idx: int = rs.get("index", 0)
		var timer: float = rs.get("timer", 0.0)
		var rot: int = rs.get("total_rotations", 0)
		var peak: float = rs.get("peak_money", 0.0)
		if not muts.is_empty():
			t += "[b][color=#ff8833]🎭 " + TranslationServer.translate("ROUTE_CARNAVAL") + "[/color][/b]\n"
			t += TranslationServer.translate("GENOME_CARNAVAL_ROT") % ["[color=#ffaa55]" + muts[idx] + "[/color]", muts[(idx+1)%3], muts[(idx+2)%3]] + "\n"
			var secs_left: int = int(Balance.CARNAVAL_INTERVAL - timer)
			t += "[color=#888888]" + TranslationServer.translate("GENOME_CARNAVAL_NEXT") % secs_left + "[/color]\n"
			t += "[color=#ffdd44]" + TranslationServer.translate("GENOME_CARNAVAL_STATS") % [rot, peak/1000.0] + "[/color]\n\n"
	elif RouteManager.is_active("reencarnacion"):
		t += "[b][color=#44ee99]⚱️ " + TranslationServer.translate("ROUTE_REENCARNACION") + "[/color][/b]\n"
		t += "[color=#888888]" + TranslationServer.translate("GENOME_REENC_DESC") + "[/color]\n\n"
	t += TranslationServer.translate("GENOME_FUNGICO") + "\n"
	t += TranslationServer.translate("MUT_LABEL_HIPERAS") + ": " + TranslationServer.translate("MUT_STATE_" + EvoManager.genome.hiperasimilacion.to_upper()) + "\n"
	t += TranslationServer.translate("MUT_LABEL_PARASIT") + ": " + TranslationServer.translate("MUT_STATE_" + EvoManager.genome.parasitismo.to_upper()) + "\n"
	t += TranslationServer.translate("MUT_LABEL_RED") + ": " + TranslationServer.translate("MUT_STATE_" + EvoManager.genome.red_micelial.to_upper()) + "\n"
	t += TranslationServer.translate("MUT_LABEL_ESPOR") + ": " + TranslationServer.translate("MUT_STATE_" + EvoManager.genome.esporulacion.to_upper()) + "\n"
	t += TranslationServer.translate("MUT_LABEL_SIMBIO") + ": " + TranslationServer.translate("MUT_STATE_" + EvoManager.genome.simbiosis.to_upper()) + "\n"
	var dep_state: String = EvoManager.genome.get("depredador", "dormido")
	if dep_state != "dormido" or EvoManager.mutation_depredador:
		t += TranslationServer.translate("MUT_LABEL_DEP") + ": " + TranslationServer.translate("MUT_STATE_" + dep_state.to_upper()) + "\n"
	var mo_state: String = EvoManager.genome.get("met_oscuro", "dormido")
	if mo_state != "dormido" or EvoManager.mutation_met_oscuro:
		t += TranslationServer.translate("MUT_LABEL_MO") + ": " + TranslationServer.translate("MUT_STATE_" + mo_state.to_upper()) + "\n"

	if EvoManager.mutation_met_oscuro:
		if EvoManager.mutation_autolisis:
			t += "[b][color=#d94d00]🔥 " + TranslationServer.translate("GENOME_AUTOLISIS_TITLE") + "[/color][/b]\n"
			t += "[color=#00ff00]" + TranslationServer.translate("GENOME_AUTOLISIS_BUFF") + "[/color]\n"
			t += "[color=#ff4444]" + TranslationServer.translate("GENOME_AUTOLISIS_NERF") + "[/color]\n"
		else:
			t += "[b][color=#8844aa]🌑 " + TranslationServer.translate("GENOME_MO_TITLE") + "[/color][/b]\n"
			t += "[color=#00ff00]" + TranslationServer.translate("GENOME_MO_BUFF") + "[/color]\n"
			t += "[color=#ff4444]" + TranslationServer.translate("GENOME_MO_NERF") + "[/color]\n"
	elif EvoManager.mutation_depredador:
		t += "[b][color=#ff0055]☠️ " + TranslationServer.translate("GENOME_DEP_TITLE") + "[/color][/b]\n"
		t += "[color=#00ff00]" + TranslationServer.translate("GENOME_DEP_BUFF") + "[/color]\n"
		t += "[color=#ff4444]" + TranslationServer.translate("GENOME_DEP_NERF") + "[/color]\n"
	elif EvoManager.mutation_hyperassimilation:
		t += "[b][color=magenta]⚠️ " + TranslationServer.translate("GENOME_HIPERAS_TITLE") + "[/color][/b]\n"
		t += "[color=#00ff00]" + TranslationServer.translate("GENOME_HIPERAS_BUFF") + "[/color]\n"
		t += "[color=#ff4444]" + TranslationServer.translate("GENOME_HIPERAS_NERF1") + "[/color]\n"
		t += "[color=#ff4444]" + TranslationServer.translate("GENOME_HIPERAS_NERF2") + "[/color]\n"
	elif EvoManager.genome.hiperasimilacion == "latente":
		t += "\n[color=gray]• " + TranslationServer.translate("GENOME_HIPERAS_LATENTE") + "[/color]"

	var _route_prefix: String = TranslationServer.translate("MUT_ROUTE_PREFIX") + ": "
	if EvoManager.mutation_met_oscuro:
		t += "\n🌑 " + _route_prefix + TranslationServer.translate("MUT_MET_OSCURO")
	elif EvoManager.mutation_depredador:
		t += "\n☠️ " + _route_prefix + TranslationServer.translate("MUT_DEPREDADOR")
	elif EvoManager.mutation_homeostasis:
		t += "\n⚖️ " + _route_prefix + TranslationServer.translate("MUT_HOMEOSTASIS")
	elif EvoManager.mutation_hyperassimilation:
		t += "\n⚠️ " + _route_prefix + TranslationServer.translate("MUT_HIPERASIMILACION")
	elif EvoManager.mutation_symbiosis:
		t += "\n🌱 " + _route_prefix + TranslationServer.translate("MUT_SIMBIOSIS")
	elif EvoManager.mutation_parasitism:
		t += "\n🦠 " + _route_prefix + TranslationServer.translate("MUT_PARASITISMO")

	if RunManager.run_closed:
		t += "\n\n" + TranslationServer.translate("GENOME_FINAL") + RunManager.final_route
	return t

# ─── MUTATION STATUS ──────────────────────────────────────────────────────────

static func build_mutation_status_text() -> String:
	var t := "\n[color=#aaaaaa]" + TranslationServer.translate("MSTAT_HEADER") + "[/color]\n"
	var buff := "[color=#00ff00]+"
	var nerf := "[color=#ff4444]-"

	if EvoManager.mutation_hyperassimilation and not EvoManager.mutation_met_oscuro:
		t += "[b][color=magenta]⚠️ " + TranslationServer.translate("MSTAT_HIPERAS_TITLE") + "[/color][/b]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_HIPERAS_B1") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_HIPERAS_N1") + "[/color]\n"

	if EvoManager.mutation_homeostasis:
		var en_banda_home := RunManager.get_en_banda_homeostatica()
		var bonus_color := buff if en_banda_home else "[color=#777777]"
		t += "[b][color=cyan]⚖️ " + TranslationServer.translate("MSTAT_HOME_TITLE") + "[/color][/b]\n"
		t += bonus_color + " " + TranslationServer.translate("MSTAT_HOME_B1") + "[/color]\n"
		t += bonus_color + " " + TranslationServer.translate("MSTAT_HOME_B2") + "[/color]\n"
		t += bonus_color + " " + TranslationServer.translate("MSTAT_HOME_B3") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_HOME_N1") + "[/color]\n"
		if not en_banda_home:
			t += "[color=#ff8844]" + TranslationServer.translate("MSTAT_HOME_OUT_OF_BAND") + "[/color]\n"

	if EvoManager.mutation_symbiosis:
		t += "[b][color=green]🌱 " + TranslationServer.translate("MSTAT_SIMB_TITLE") + "[/color][/b]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_SIMB_B1") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_SIMB_N1") + "[/color]\n"

	if EvoManager.mutation_red_micelial:
		t += "[b][color=#9955ff]🕸️ " + TranslationServer.translate("MSTAT_RED_TITLE") + "[/color][/b]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_RED_B1") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_RED_N1") + "[/color]\n"

	if EvoManager.mutation_met_oscuro:
		t += "[b][color=#8844aa]🌑 " + TranslationServer.translate("MSTAT_MO_TITLE") + "[/color][/b]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_MO_B1") + "[/color]\n"
		if EvoManager.mutation_autolisis:
			t += buff + " " + TranslationServer.translate("MSTAT_AUTOLISIS_B_CLICK") + "[/color]\n"
			t += buff + " " + TranslationServer.translate("MSTAT_AUTOLISIS_B_PASIVO") + "[/color]\n"
		else:
			t += buff + " " + TranslationServer.translate("MSTAT_MO_B2") + "[/color]\n"
			t += nerf + " " + TranslationServer.translate("MSTAT_MO_N4") + "[/color]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_MO_B3") + "[/color]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_MO_B4") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_MO_N1") + "[/color]\n"
		if not EvoManager.mutation_autolisis:
			t += nerf + " " + TranslationServer.translate("MSTAT_MO_N2") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_MO_N3") + "[/color]\n"
		if EvoManager.mutation_autolisis:
			var devours: int = EvoManager.autolisis_devour_count
			var interval: float = EvoManager.autofagia_devour_interval()
			var next_in: float = max(0.0, interval - EvoManager.autolisis_devour_timer)
			var levels_left: int = UpgradeManager.get_owned_levels_count()
			var dbl_pct: int = int(EvoManager.autofagia_double_chance() * 100)
			t += "\n[b][color=#d94d00]🔥 " + TranslationServer.translate("MSTAT_AUTOLISIS_TITLE") + "[/color][/b]\n"
			t += "[color=#ff8855]" + TranslationServer.translate("MSTAT_AUTOLISIS_STATUS") % [devours, levels_left] + "[/color]\n"
			t += "[color=#ffaa55]" + TranslationServer.translate("MSTAT_AUTOLISIS_NEXT2") % [next_in, interval] + "[/color]\n"
			if dbl_pct > 0:
				t += "[color=#ffaa55]" + TranslationServer.translate("MSTAT_AUTOLISIS_DOUBLE") % dbl_pct + "[/color]\n"
			t += "[color=#88ff88]  " + TranslationServer.translate("MSTAT_AUTOLISIS_FEED") + "[/color]\n"
			if devours >= Balance.AUTOFAGIA_COLAPSO_MIN_DEVOURS:
				t += "[color=#ffdd66]  " + TranslationServer.translate("MSTAT_AUTOLISIS_CLOSE_READY") + "[/color]\n"
			else:
				t += "[color=#888888]  " + TranslationServer.translate("MSTAT_AUTOLISIS_CLOSE_WAIT") % Balance.AUTOFAGIA_COLAPSO_MIN_DEVOURS + "[/color]\n"
		else:
			var bio_now: float = BiosphereEngine.biomasa
			var bio_pct: int = int(clamp(bio_now / 100.0 * 100.0, 0.0, 100.0))
			var bar_filled: int = int(bio_pct / 5.0)
			var bio_bar: String = "█".repeat(bar_filled) + "░".repeat(20 - bar_filled)
			var pl_label: String = "+6 PL" if bio_now >= 100.0 else ("+4 PL" if bio_now >= 50.0 else "+2 PL")
			t += "\n[color=#aa66cc]" + TranslationServer.translate("MSTAT_MO_SAT") % pl_label + "[/color]\n"
			t += "[color=#8844aa][%s][/color] [color=white]%.0f / 100[/color]\n" % [bio_bar, bio_now]
			t += "[color=#666688]  " + TranslationServer.translate("MSTAT_MO_SEAL_HINT") + "[/color]\n"
	elif EvoManager.mutation_depredador:
		t += "[b][color=#ff0055]☠️ " + TranslationServer.translate("MSTAT_DEP_TITLE") + "[/color][/b]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_DEP_B1") + "[/color]\n"
		var dev: int = EvoManager.met_oscuro_devoured_count
		var bio: float = BiosphereEngine.biomasa
		var money_now: float = EconomyManager.money
		var inest: float = EvoManager.depredador_inestabilidad
		var inest_max: float = EvoManager.DEPREDADOR_INESTABILIDAD_MAX
		var remaining: float = max(0.0, inest_max - inest)
		var ratio: float = clampf(remaining / inest_max, 0.0, 1.0)
		var filled: int = int(ratio * 12.0)
		var bar: String = "█".repeat(filled) + "░".repeat(12 - filled)
		var bar_color: String = "#00ff88" if ratio > 0.5 else ("#ffaa33" if ratio > 0.25 else "#ff3333")
		t += "[color=%s]⏳ " % bar_color + TranslationServer.translate("MSTAT_DEP_INESTAB") % [bar, remaining] + "[/color]\n"
		var seal_ok: bool = dev >= Balance.MET_OSCURO_DEVOURED_REQ and bio >= Balance.MET_OSCURO_BIO_REQ and money_now < 1000.0
		t += "\n[color=#aaaaaa]" + TranslationServer.translate("MSTAT_DEP_OUT_INTRO") + "[/color]\n"
		t += "  [color=%s]" % ["#9955dd" if seal_ok else "#888888"] + TranslationServer.translate("MSTAT_DEP_OUT_SEAL") + "[/color]\n"
		t += "  [color=#ff5577]" + TranslationServer.translate("MSTAT_DEP_OUT_CONSUME") + "[/color]\n"
		t += "  [color=%s]" % bar_color + TranslationServer.translate("MSTAT_DEP_OUT_COLAPSO") + "[/color]\n"
		t += "\n[color=#aa66cc]" + TranslationServer.translate("MSTAT_DEP_ALT") + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if dev >= Balance.MET_OSCURO_DEVOURED_REQ else "#ff5555"] + TranslationServer.translate("MSTAT_DEP_DEVOURED") % dev + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if bio >= Balance.MET_OSCURO_BIO_REQ else "#ff5555"] + TranslationServer.translate("MSTAT_DEP_BIO25") % bio + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if money_now < 1000.0 else "#ff5555"] + TranslationServer.translate("MSTAT_DEP_MONEY") % money_now + "[/color]\n"
		t += "  [color=#aaaaaa]" + TranslationServer.translate("MSTAT_DEP_SUSTAIN") + "[/color]\n"

	if EvoManager.mutation_parasitism:
		t += "[b][color=#ff4400]🦠 " + TranslationServer.translate("MSTAT_PARAS_TITLE") + "[/color][/b]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_PARAS_B1") + "[/color]\n"
		t += buff + " " + TranslationServer.translate("MSTAT_PARAS_B2") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_PARAS_N1") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_PARAS_N2") + "[/color]\n"
		t += nerf + " " + TranslationServer.translate("MSTAT_PARAS_N3") + "[/color]\n"
		var bio: float = BiosphereEngine.biomasa
		var omg: float = StructuralModel.omega
		var eps: float = StructuralModel.epsilon_effective
		var money: float = EconomyManager.money
		t += "\n[color=#ffaa00]" + TranslationServer.translate("MSTAT_PARAS_CLOSE_A") + "[/color]\n"
		var a1: bool = bio >= 18.0
		var a2: bool = omg < 0.22
		var a3: bool = eps > 0.45
		t += "  [color=%s]" % ["#00ff88" if a1 else "#ff5555"] + TranslationServer.translate("MSTAT_PARAS_BIO18") % bio + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if a2 else "#ff5555"] + TranslationServer.translate("MSTAT_PARAS_OMEGA22") % omg + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if a3 else "#ff5555"] + TranslationServer.translate("MSTAT_PARAS_EPS45") % eps + "[/color]\n"
		t += "[color=#ffaa00]" + TranslationServer.translate("MSTAT_PARAS_CLOSE_B") + "[/color]\n"
		var b1: bool = bio >= 15.0
		var b2: bool = money < 1000.0
		var b3: bool = bio >= 25.0
		t += "  [color=%s]" % ["#00ff88" if (b1 and b2) else "#ff5555"] + TranslationServer.translate("MSTAT_PARAS_B15") % [bio, money] + "[/color]\n"
		t += "  [color=%s]" % ["#00ff88" if b3 else "#ff5555"] + TranslationServer.translate("MSTAT_PARAS_B25") % bio + "[/color]\n"
	return t

# ─── INSTITUTION PANEL ────────────────────────────────────────────────────────

static func build_institution_panel_text(_main: Node) -> String:
	var t := "--- " + TranslationServer.translate("INST_ACCOUNTING_HDR") + " ---\n"
	t += "\n--- " + TranslationServer.translate("INST_EPS_HDR") + " ---\n"
	t += "%s %s = %s\n" % [epsilon_flag(StructuralModel.epsilon_active, 0.15), TranslationServer.translate("INST_EPS_ACTIVE"), snapped(StructuralModel.epsilon_active, 0.01)]
	t += "%s %s = %s\n" % [epsilon_flag(StructuralModel.epsilon_passive, 0.12), TranslationServer.translate("INST_EPS_PASSIVE"), snapped(StructuralModel.epsilon_passive, 0.01)]
	t += "%s %s = %s\n" % [epsilon_flag(StructuralModel.epsilon_complex, 0.08), TranslationServer.translate("INST_EPS_COMPLEX"), snapped(StructuralModel.epsilon_complex, 0.01)]
	t += TranslationServer.translate("INST_OMEGA_MIN") + " = %s\n" % snapped(StructuralModel.omega_min, 0.01)
	t += TranslationServer.translate("INST_ACCOUNTING_LVL") % UpgradeManager.level("accounting") + "\n"
	t += TranslationServer.translate("INST_AMORT") % int(StructuralModel.get_accounting_effect() * 100.0) + "\n"
	t += "\n" + TranslationServer.translate("INST_EPS_PEAK") + " = %s\n" % snapped(StructuralModel.epsilon_peak, 0.01)
	return t

# ─── BIFURCATION DATA ─────────────────────────────────────────────────────────

static func build_bifurcation_data() -> Dictionary:
	var hifas := BiosphereEngine.hifas
	var acc_lvl := UpgradeManager.level("accounting")
	var act_domina: bool = EconomyManager.get_active_passive_breakdown().activo > EconomyManager.get_active_passive_breakdown().pasivo

	var data := {
		"tier_mode": "tier1" if not (EvoManager.mutation_red_micelial or EvoManager.mutation_homeostasis) else ("tier2_homeostasis" if EvoManager.mutation_homeostasis else "tier2_branches")
	}

	if not (EvoManager.mutation_red_micelial or EvoManager.mutation_homeostasis):
		data["header"] = TranslationServer.translate("EVO_BIF_TIER1_HEADER")

		var h_t := LegacyManager.trascendencia_count
		var h_ap: Dictionary = EconomyManager.get_active_passive_breakdown()
		var h_ok_red := StructuralModel.unlocked_d and StructuralModel.unlocked_e
		var h_txt := "[center]" + TranslationServer.translate("EVO_HOME_DESC_TITLE")

		if h_t >= 1:
			var eps_eff := StructuralModel.epsilon_runtime
			var h_ok_eps_ng := eps_eff >= 0.05 and eps_eff <= 0.25
			var h_ok_omega_ng := StructuralModel.omega >= 0.55
			var h_ok_acc_ng := acc_lvl >= 2
			var h_ok_delta_ng := EconomyManager.delta_per_sec > 150.0
			var total_flow: float = float(h_ap["activo"]) + float(h_ap["pasivo"])
			var h_ok_bal: bool = total_flow > 0 and (float(h_ap["pasivo"]) / total_flow) >= 0.30
			var h_ok_bio_ng := BiosphereEngine.biomasa >= 1.0 and BiosphereEngine.biomasa < 10.0
			h_txt += "[color=#ff8800]" + TranslationServer.translate("EVO_HOME_NG_REQ") + "[/color]\n\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_eps_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_eps_ng else "[ ]"] + TranslationServer.translate("EVO_HOME_EPS_NG") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_omega_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_omega_ng else "[ ]"] + TranslationServer.translate("EVO_HOME_OMEGA55") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_bal else AccessibilityManager.cno_hex(), "[x]" if h_ok_bal else "[ ]"] + TranslationServer.translate("EVO_HOME_PASSIVE30") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_delta_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_delta_ng else "[ ]"] + TranslationServer.translate("EVO_HOME_PROD150") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_bio_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_bio_ng else "[ ]"] + TranslationServer.translate("EVO_HOME_BIO_NG") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_acc_ng else AccessibilityManager.cno_hex(), "[x]" if h_ok_acc_ng else "[ ]"] + TranslationServer.translate("EVO_HOME_ACC2") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_red else AccessibilityManager.cno_hex(), "[x]" if h_ok_red else "[ ]"] + TranslationServer.translate("EVO_HOME_DE") + "[/color]\n"
		else:
			var h_ok_eps := RunManager.get_en_banda_homeostatica()
			var h_ok_omega := StructuralModel.omega >= 0.40
			var h_ok_delta := EconomyManager.delta_per_sec > 30.0
			var h_ok_bio := BiosphereEngine.biomasa < 12.0
			var h_ok_acc := acc_lvl >= 1
			var h_ok_dual: bool = h_ap["pasivo"] > 0
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_eps else AccessibilityManager.cno_hex(), "[x]" if h_ok_eps else "[ ]"] + TranslationServer.translate("EVO_HOME_EPS_BASE") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_omega else AccessibilityManager.cno_hex(), "[x]" if h_ok_omega else "[ ]"] + TranslationServer.translate("EVO_HOME_OMEGA40") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_dual else AccessibilityManager.cno_hex(), "[x]" if h_ok_dual else "[ ]"] + TranslationServer.translate("EVO_HOME_DUAL") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_delta else AccessibilityManager.cno_hex(), "[x]" if h_ok_delta else "[ ]"] + TranslationServer.translate("EVO_HOME_META30") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_bio else AccessibilityManager.cno_hex(), "[x]" if h_ok_bio else "[ ]"] + TranslationServer.translate("EVO_HOME_BIO12") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_acc else AccessibilityManager.cno_hex(), "[x]" if h_ok_acc else "[ ]"] + TranslationServer.translate("EVO_HOME_ACC1") + "[/color]\n"
			h_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if h_ok_red else AccessibilityManager.cno_hex(), "[x]" if h_ok_red else "[ ]"] + TranslationServer.translate("EVO_HOME_DE") + "[/color]\n"

		if EvoManager.mutation_homeostasis and RunManager.homeostasis_timer > 0.1:
			var ratio: float = min(RunManager.homeostasis_timer / Balance.HOMEOSTASIS_TIME_REQUIRED, 1.0) * 100.0
			h_txt += "\n[color=#ffff00]" + TranslationServer.translate("EVO_HOME_STAB_PCT") % int(ratio) + "[/color][/center]"
		else:
			h_txt += "\n[color=#555555]" + TranslationServer.translate("EVO_HOME_STAB_REQ") + "[/color][/center]"

		data["homeostasis_text"] = h_txt
		data["homeostasis_ready"] = EvoManager.is_homeostasis_ready()

		var r_ok_hifas := hifas >= 11.5
		var r_ok_bio := BiosphereEngine.biomasa >= 5.0
		var r_ok_eps := StructuralModel.epsilon_runtime < 0.65
		var r_ok_acc := acc_lvl >= 1
		var r_ok_dom := not act_domina

		var r_txt := "[center]" + TranslationServer.translate("EVO_RED_DESC_TITLE")
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_hifas else AccessibilityManager.cno_hex(), "[x]" if r_ok_hifas else "[ ]"] + TranslationServer.translate("EVO_RED_HIFAS115") + "[/color]\n"
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_bio else AccessibilityManager.cno_hex(), "[x]" if r_ok_bio else "[ ]"] + TranslationServer.translate("EVO_RED_BIO5") + "[/color]\n"
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_eps else AccessibilityManager.cno_hex(), "[x]" if r_ok_eps else "[ ]"] + TranslationServer.translate("EVO_RED_EPS065") + "[/color]\n"
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_acc else AccessibilityManager.cno_hex(), "[x]" if r_ok_acc else "[ ]"] + TranslationServer.translate("EVO_RED_ACC1") + "[/color]\n"
		r_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if r_ok_dom else AccessibilityManager.cno_hex(), "[x]" if r_ok_dom else "[ ]"] + TranslationServer.translate("EVO_RED_DOM_PAS") + "[/color][/center]"

		data["red_micelial_text"] = r_txt
		data["red_micelial_ready"] = EvoManager.is_red_micelial_ready()

		var s_ok_hifas := hifas >= 5.0
		var s_ok_eps := StructuralModel.epsilon_runtime >= 0.15 and StructuralModel.epsilon_runtime <= 0.45
		var s_ok_acc := acc_lvl >= 1
		var s_ok_dom := act_domina

		var s_txt := "[center]" + TranslationServer.translate("EVO_SIM_DESC_TITLE")
		s_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if s_ok_hifas else AccessibilityManager.cno_hex(), "[x]" if s_ok_hifas else "[ ]"] + TranslationServer.translate("EVO_SIM_HIFAS5") + "[/color]\n"
		s_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if s_ok_eps else AccessibilityManager.cno_hex(), "[x]" if s_ok_eps else "[ ]"] + TranslationServer.translate("EVO_SIM_EPS_RANGE") + "[/color]\n"
		s_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if s_ok_acc else AccessibilityManager.cno_hex(), "[x]" if s_ok_acc else "[ ]"] + TranslationServer.translate("EVO_SIM_ACC1") + "[/color]\n"
		s_txt += "[color=%s]%s " % [AccessibilityManager.cok_hex() if s_ok_dom else AccessibilityManager.cno_hex(), "[x]" if s_ok_dom else "[ ]"] + TranslationServer.translate("EVO_SIM_DOM_CLICK") + "[/color][/center]"

		data["simbiosis_text"] = s_txt
		data["simbiosis_ready"] = EvoManager.is_simbiosis_ready()

	elif EvoManager.mutation_homeostasis:
		data["header"] = TranslationServer.translate("EVO_TIER2_HEADER")
		var works := EvoManager.is_allostasis_ready()

		var h_txt := "[center]" + TranslationServer.translate("EVO_ALOS_DESC_TITLE")
		h_txt += "[color=#00ff00]" + TranslationServer.translate("EVO_ALOS_BUFF1") + "[/color]\n"
		h_txt += "[color=#00ff00]" + TranslationServer.translate("EVO_ALOS_BUFF2") + "[/color]\n"
		h_txt += "[color=#ff4444]" + TranslationServer.translate("EVO_ALOS_NERF1") + "[/color]\n"
		h_txt += "[color=#ff4444]" + TranslationServer.translate("EVO_ALOS_NERF2") + "[/color][/center]"

		data["allostasis_text"] = h_txt
		data["allostasis_ready"] = works

	else:
		data["header"] = TranslationServer.translate("EVO_BIF_HEADER")

		var col_txt := "[center]" + TranslationServer.translate("EVO_COL_DESC_TITLE") + \
			"[color=#00ff00]" + TranslationServer.translate("EVO_COL_BUFF1") + "[/color]\n" + \
			"[color=#00ff00]" + TranslationServer.translate("EVO_COL_BUFF2") + "[/color]\n" + \
			"[color=#ffaa00]" + TranslationServer.translate("EVO_COL_NOTE") + "[/color][/center]"
		data["colonization_text"] = col_txt
		data["colonization_ready"] = true

		var has_mechanics := UpgradeManager.level("accounting") >= 2
		var mec_txt := "[center]" + TranslationServer.translate("EVO_MEC_DESC_TITLE") + \
			"[color=#00ff00]" + TranslationServer.translate("EVO_MEC_BUFF1") + "[/color]\n" + \
			"[color=#00ff00]" + TranslationServer.translate("EVO_MEC_BUFF2") + "[/color]\n" + \
			("[color=%s]" % AccessibilityManager.cok_hex() + TranslationServer.translate("EVO_MEC_ACC_OK") + "[/color]" if has_mechanics else "[color=%s]" % AccessibilityManager.cno_hex() + TranslationServer.translate("EVO_MEC_ACC_FAIL") + "[/color]") + \
			"[/center]"
		data["symbiosis_text"] = mec_txt
		data["symbiosis_ready"] = has_mechanics

	return data

# ─── EPSILON STICKY ───────────────────────────────────────────────────────────

static func build_epsilon_sticky_text(_main: Control) -> String:
	var t := ""
	t += "%s ε runtime = %s\n" % [epsilon_flag(StructuralModel.epsilon_runtime, 0.30), snapped(StructuralModel.epsilon_runtime, 0.01)]
	t += "Ω = %s (%s)\n" % [snapped(StructuralModel.omega, 0.01), get_system_phase(StructuralModel.omega)]
	t += "Presión = %s" % snapped(StructuralModel.get_structural_pressure(), 1)

	var hiper_genome: String = EvoManager.genome.get("hiperasimilacion", "")
	var depredador_eligible: bool = LegacyManager.last_run_ending == "PARASITISMO" \
		and (EvoManager.mutation_hyperassimilation or hiper_genome == "activo" or hiper_genome == "latente")
	if depredador_eligible and not EvoManager.mutation_depredador:
		if EvoManager.depredador_timer > 0.0:
			var pct := EvoManager.depredador_timer / 30.0
			var filled := int(pct * 16)
			var bar := "█".repeat(filled) + "░".repeat(16 - filled)
			t += "\n\n☠️ DEPREDADOR [%s] %d%%" % [bar, int(pct * 100)]
			t += "\nε %.2f · %.0f/30s" % [StructuralModel.epsilon_runtime, EvoManager.depredador_timer]
		else:
			var eps_ok: bool = StructuralModel.epsilon_runtime > 0.95
			t += "\n\n☠️ DEPREDADOR DISPONIBLE"
			t += "\nHIPER: %s · ε %.2f%s" % [
				hiper_genome.to_upper(),
				StructuralModel.epsilon_runtime,
				" ✓" if eps_ok else " → necesita > 0.95"
			]

	if EvoManager.mutation_depredador and not EvoManager.mutation_met_oscuro:
		var bio := BiosphereEngine.biomasa
		var dev := EvoManager.met_oscuro_devoured_count
		var mt := EvoManager.met_oscuro_timer
		var req := Balance.MET_OSCURO_REQUIRED_TIME
		if mt > 0.0:
			var pct := mt / req
			var filled := int(pct * 16)
			var bar := "█".repeat(filled) + "░".repeat(16 - filled)
			t += "\n\n🌑 MET.OSCURO [%s] %d%%" % [bar, int(pct * 100)]
			t += "\nEstabilizando %.1f/%ds" % [mt, int(req)]
		else:
			var d_ok: bool = dev >= 3
			var b_ok: bool = bio >= 25.0
			var r_ok: bool = EconomyManager.money < 1000.0
			t += "\n\n🌑 MET.OSCURO DISPONIBLE"
			t += "\nDev:%d/3%s · Bio:%.0f/25%s · $:%.0f<1k%s" % [
				dev, " ✓" if d_ok else "",
				bio, " ✓" if b_ok else "",
				EconomyManager.money, " ✓" if r_ok else ""
			]
	elif EvoManager.mutation_met_oscuro:
		t += "\n\n🌑 MET.OSCURO ACTIVO"
		t += "\nBio %.1f · Pasivo %.1f/s" % [BiosphereEngine.biomasa, BiosphereEngine.biomasa * 0.8]
		t += "\nCierre auto: Bio≥100 o $≥1M"

	return t
