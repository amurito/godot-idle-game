---
name: v1.0.0.3
description: v1.0.0.3 publicado (2026-05-17). Refactor main.gd completo, localización EN WIP. Roadmap técnico post-v1 priorizado.
type: project
originSessionId: 1e243521-2f11-48c0-9812-793e482d1702
---
## v0.9.10 — UX y Debug — COMPLETADO ✅
## v0.9.11 — Logros Completos — COMPLETADO ✅
## v0.9.12 — Reactor 3D — COMPLETADO ✅
## v0.9.13 — Historial de Ciclos + Sistema de Slots — COMPLETADO (2026-05-10) ✅

Ver `project_slots_v0913.md` para arquitectura detallada.

---

## v1.0.0 "Primera Luz" → v1.0.0.2 "Génesis" — PUBLICADO ✅ (2026-05-17)

### v1.0.0 — Primera Luz ✅
- Tutorial/onboarding (TutorialManager.gd)
- AudioManager.gd: 7 SFX + música ambient, persistencia, sliders en Settings
- Settings panel: volumen, mute, telemetría, reiniciar tutorial, borrar run
- Créditos, Icono + metadata, Accesibilidad (AccessibilityManager.gd: fs(), contraste, reduce_motion)
- Save export/import JSON

### v1.0.0.2 "Génesis" ✅ (2026-05-15)
- Panel Objetivos: 20 milestones, atajo [K]
- HOMEORHESIS Tier 3: gate extreme_shocks_recovered
- SaveManager: atomic save (tmp→rename→bak) + fallback a .bak en load
- Fix duplicación efectos Homeostasis post-run

---

## v1.0.0.3 (hotfix localización + refactor) — PUBLICADO ✅ (2026-05-17)

### Refactor main.gd god-object — PR #5 mergeado
- Branch `claude/great-turing-aa67fe` → main via PR
- 2235 → 1643 LOC (-26%) en 5 pasos
- 20 GDScript warnings eliminados (params sin usar, integer division, signal duplicada, SubViewport stretch)
- Ver `project_refactor_main_gd.md` para detalle de APIs nuevas

### Bugs corregidos (post-merge, en main directo)
- UTF-8 corruption en main.gd (252 chars: tildes, ×, —, •, █, ▲▼●)
- Reactor 3D: AUTO-OVERRIDE texto se pisaba en modo 3D (button.text vs _3d_power_label)
- IA chip tooltip: "Auto-click x10/s" → "Compra automática de upgrades" (buff no hace click)
- EvoManager.check_red_micelial_transition: main_ref.run_time → RunManager.run_time (crash fix)
- Signal already connected (RunManager.close_run) → guard is_connected()
- SubViewport stretch warning → removed manual vp.size assignment

### Localización ES/EN
- LocaleManager.gd: ~70 claves ES+EN
- Settings panel: 100% traducido
- MainMenu: 90%+ strings player-visible
- main.gd in-game UI: botones, contadores, banco genético
- MainMenu.tscn: botones estáticos usan claves (auto-translate)
- _on_locale_changed() completo para botones dinámicos
- WIP popup al seleccionar EN
- Ver `project_localization.md` para cobertura detallada

---

## Roadmap técnico post-v1.0 — PRIORIZADO

### Fixes aplicados en worktree great-turing-aa67fe (2026-05-17, post-merge)
- **Fix #1:** route_badge_label Label → RichTextLabel + EmojiToRichText.rich() — emojis 🕳️🎭⚱️ rotos en web ✅
- **Fix #2:** AudioManager fallback SafarI/iOS — big_click_button.pressed conectado a _unlock_audio() en main._ready() ✅
- **Fix #3:** export_presets.cfg HTML5 exclude_filter — DebugPanel.gd excluido del bundle web ✅

---

### Inmediato (alta prioridad — riesgo real)
**1. Autobackup en SaveManager** ✅ YA IMPLEMENTADO (v1.0.0.2)
- atomic save: tmp → rename → .bak (SaveManager.gd:124)
- load fallback: si corrupto/vacío → intenta .bak (SaveManager.gd:267-270)

**2. Consolidar versión** ← PENDIENTE
- Borrar `const VERSION` de main.gd (si quedó), usar solo `Version.get_version_string()`
- version.gd tiene: MAJOR.MINOR.PATCH.HOTFIX + NAME

**3. Auditar hot-patches y borrar código muerto** ← PENDIENTE
- Revisar código comentado, funciones no llamadas, flags obsoletos

### Corto plazo
**4. Extraer NG+ routes a scripts propios** ← PARCIALMENTE HECHO
- Mente Colmena, Depredador, Met. Oscuro ya están en EvoManager/RunManager (step4 del refactor)
- CARNAVAL, REENCARNACIÓN, VACÍO: todavía en main.gd o EvoManager como bloque grande
- Target: < 200 LOC por ruta

**5. Balance.gd autoload** ← PENDIENTE
- Constantes dispersas (multiplicadores, gates, caps) → autoload único
- Facilita balance sin buscar en 5 archivos

**6. Cap de laps en LogManager** ← PENDIENTE
- Sin cap, laps pueden crecer indefinidamente en runs largas

### Mediano plazo
**7. run_time / cached_mu / delta_per_sec → managers** ← HECHO en refactor step1 ✅
**8. save_version + migraciones unificadas** ← PENDIENTE
**9. Tabla de PL por route en Resource** ← PENDIENTE

### No tocar
- EconomyManager.get_click_power / get_passive_total: feos pero correctos y auditables
- AchievementManager: ya está aislado, energía mejor en otros frentes

---

## Git / GitHub
- Tags: v0.9.11, v0.9.12, v0.9.13, v1.0.0, v1.0.0.1, v1.0.0.2, v1.0.0.3
- PR #5: merge del branch de refactor (claude/great-turing-aa67fe → main)
- Worktree `great-turing-aa67fe` quedó STALE después del merge — el trabajo post-merge fue directo en main
- Próximo worktree: crear uno nuevo por feature, no reutilizar el stale
