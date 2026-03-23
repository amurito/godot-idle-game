[33mcommit de6d7da3602590d777aca66ef96a8f647bbf91cc[m[33m ([m[1;36mHEAD[m[33m -> [m[1;32mrelease/v0.6.3[m[33m, [m[1;31morigin/release/v0.6.3[m[33m)[m
Author: Nicolas Maure <nicolasmaure99@gmail.com>
Date:   Wed Jan 7 07:10:29 2026 -0300

    Update HUD estructural + μ integration

[1mdiff --git a/.github/copilot-instructions.md b/.github/copilot-instructions.md[m
[1mnew file mode 100644[m
[1mindex 0000000..e1cabc2[m
[1m--- /dev/null[m
[1m+++ b/.github/copilot-instructions.md[m
[36m@@ -0,0 +1,43 @@[m
[32m+[m[32m# AI Coding Instructions for IDLE — Observatorio fⁿ[m
[32m+[m
[32m+[m[32m## Project Overview[m
[32m+[m[32mIDLE is a Godot-based idle/incremental game that exposes the mathematical structure of an economic simulation system. Unlike traditional idle games, it prioritizes transparency and observation over hidden progression. The game models economic growth as Δ$ = clicks × (a × b × cₙ × μ) + d × md × so + e × me, where terms progressively unlock and dominance shifts between click, manual work, and trade.[m
[32m+[m
[32m+[m[32m## Architecture[m
[32m+[m[32m- **main.gd**: Core game logic, economic model, UI updates, run exports. Contains layered architecture: economic base, mathematical analysis, structural fⁿ model, dynamic persistence convergence.[m
[32m+[m[32m- **version.gd**: Version management and build info.[m
[32m+[m[32m- **producer_item.gd**: Legacy UI component (unused in current version).[m
[32m+[m[32m- **analyze_runs.py / script.py**: Python scripts for analyzing exported run data, generating rankings for structural milestones.[m
[32m+[m[32m- **runs/**: Directory containing exported JSON/CSV run data with timestamps, lap markers, and system state.[m
[32m+[m
[32m+[m[32m## Key Patterns[m
[32m+[m[32m- **Progressive Unlocking**: Formula terms (d, md, e, me) unlock via upgrades, revealing more of the symbolic formula. Use `unlocked_*` booleans and `structural_upgrades` counter.[m
[32m+[m[32m- **Dynamic Persistence**: `persistence_dynamic` lerps toward `get_persistence_target()` using sigmoid `f_n_alpha(n)`. Never reduce `persistence_dynamic` below baseline.[m
[32m+[m[32m- **Lap Markers**: Log significant events (upgrades, dominance transitions) in `lap_events` array with timestamps.[m
[32m+[m[32m- **Scientific HUD**: `update_click_stats_panel()` builds detailed variable display. All values snapped to 0.01 precision.[m
[32m+[m[32m- **Run Exports**: JSON with full state, CSV summary, clipboard text. Exported to `res://runs/` with timestamp filenames.[m
[32m+[m
[32m+[m[32m## Workflows[m
[32m+[m[32m- **Testing Changes**: Run game in Godot editor, observe system behavior in lab mode. Export runs via "Export Run" button, analyze with `python analyze_runs.py`.[m
[32m+[m[32m- **Adding Upgrades**: Follow pattern in upgrade handlers (e.g., `_on_UpgradeClickButton_pressed`): check cost, deduct money, modify variable, scale cost, increment `structural_upgrades`, add lap marker, call `update_ui()`.[m
[32m+[m[32m- **UI Updates**: All labels updated in `update_ui()`. Use `snapped(value, 0.01)` for display. Formula text built dynamically based on unlocks.[m
[32m+[m[32m- **Mathematical Extensions**: New terms should integrate into `get_delta_total()`, `get_contribution_breakdown()`, and symbolic formula display.[m
[32m+[m
[32m+[m[32m## Conventions[m
[32m+[m[32m- Variables prefixed by component: `click_*`, `auto_*`, `trueque_*`, `cognitive_*`.[m
[32m+[m[32m- Constants in ALL_CAPS with descriptive names (e.g., `AUTO_MULTIPLIER_GAIN := 1.06`).[m
[32m+[m[32m- Functions layered: economic (get_*_power), analysis (get_dominant_term), UI (build_*_text).[m
[32m+[m[32m- Time formatted as MM:SS, money rounded, deltas snapped.[m
[32m+[m[32m- Structural upgrades affect `n` parameter, influencing persistence via `pow(K_PERSISTENCE, (1.0 - 1.0 / n))`.[m
[32m+[m
[32m+[m[32m## Dependencies[m
[32m+[m[32m- Godot 4.5+ for game engine.[m
[32m+[m[32m- Python 3+ for analysis scripts (uses pathlib, json, re).[m
[32m+[m[32m- No external libraries; pure GDScript and standard Python.[m
[32m+[m
[32m+[m[32m## Validation[m
[32m+[m[32mAfter changes, run game and verify:[m
[32m+[m[32m- Formula displays correctly with unlocks.[m
[32m+[m[32m- Dominance transitions logged.[m
[32m+[m[32m- Exported runs parseable by Python scripts.[m
[32m+[m[32m- Persistence converges smoothly without overshoot.[m
\ No newline at end of file[m
[1mdiff --git a/.godot/editor/editor_layout.cfg b/.godot/editor/editor_layout.cfg[m
[1mindex 72865b6..4984a20 100644[m
[1m--- a/.godot/editor/editor_layout.cfg[m
[1m+++ b/.godot/editor/editor_layout.cfg[m
[36m@@ -35,8 +35,8 @@[m [mopen_scenes=PackedStringArray("res://main.tscn")[m
 current_scene="res://main.tscn"[m
 center_split_offset=-285[m
 selected_default_debugger_tab_idx=0[m
[31m-selected_main_editor_idx=2[m
[31m-selected_bottom_panel_item=1[m
[32m+[m[32mselected_main_editor_idx=3[m
[32m+[m[32mselected_bottom_panel_item=0[m
 [m
 [EditorWindow][m
 [m
[36m@@ -56,7 +56,7 @@[m [mzoom_factor=1.0[m
 [m
 [GameView][m
 [m
[31m-floating_window_rect=Rect2i(0, 23, 1920, 1017)[m
[32m+[m[32mfloating_window_rect=Rect2i(0, 23, 1920, 1009)[m
 floating_window_screen=0[m
 [m
 [ShaderEditor][m
[1mdiff --git a/.godot/editor/filesystem_cache10 b/.godot/editor/filesystem_cache10[m
[1mindex 956544e..d1232b6 100644[m
[1m--- a/.godot/editor/filesystem_cache10[m
[1m+++ b/.godot/editor/filesystem_cache10[m
[36m@@ -1,335 +1,343 @@[m
 63f7b34db8d8cdea90c76aacccf841ec[m
[31m-::res://::1767706642[m
[31m-changelog 0.5.1TheLab.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-CHANGELOG — v0.6.1 “Observatorio fⁿ — Tagging Layer”.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-CHANGELOG.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-CHANGELOGv0.6.9.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-Changelog_v0.6.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-export_presets.cfg::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-GUIDELINES— Filosofía de diseño del sistema.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-icon.svg::CompressedTexture2D::9216670998058240731::1767706518::1767706518::1::::<><><>0<>0<>bd555fb2458856aea8c8c8acf97ad736<>res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex::[m
[31m-main.gd::GDScript::6318254411727827567::1767706574::0::1::::<>Control<><>0<>0<><>::[m
[31m-main.tres::Theme::1655596882007418082::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-main.tscn::PackedScene::8187026145298395202::1767706574::0::1::::<><><>0<>0<><>::uid://cwauyyqcu0klj::::res://main.gd<>uid://xt8o6hca6a4q::::res://main.tres[m
[31m-papa.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-ProducerItem.tscn::PackedScene::4870387446695148080::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-producer_item.gd::GDScript::7808462353882494901::1767706518::0::1::::<>HBoxContainer<><>0<>0<><>::[m
[31m-producer_item.tscn::PackedScene::7296684604938666336::1767706518::0::1::::<><><>0<>0<><>::uid://djiqh7ws2adm8::::res://producer_item.gd[m
[31m-prompt inicial.md::TextFile::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-README.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-READMEV0.2.ini::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-READMEV0.5.1 The Lab (stable).md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-Readmev0.6.1.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-READMEv0.6.9.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-readmev0.6.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-README_v0.4.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-Release Notes — v0.6.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-releaseNotesv0.5.1_TheLab(Stable).md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-RELEASE_NOTES_v0.6.9.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-ROADMAP.md — Línea evolutiva del proyecto.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-ROADMAPv0.6.9.md::TextFile::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-version.gd::GDScript::5760246935057539874::1767706518::0::1::::<>Node<><>0<>0<><>::[m
[31m-::res://runs/::1767706574[m
[31m-rankings_structurales.csv::Translation::4854605642520857242::1767706574::1767706574::0::::<><><>0<>0<>27d0ff498de251b0982242c2bcf0ee6e<>::[m
[31m-run_30-12-25_16-54.dominante.translation::OptimizedTranslation::212059298806245422::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-54.total.translation::OptimizedTranslation::1180575703846366049::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-54.pasivo.translation::OptimizedTranslation::1198514357306651141::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-41.dominante.translation::OptimizedTranslation::4911362419644591736::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-54.activo.translation::OptimizedTranslation::2989115068875682578::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-41.total.translation::OptimizedTranslation::6131125286164749264::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-54.event.translation::OptimizedTranslation::7154188932077774380::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-41.pasivo.translation::OptimizedTranslation::4632468721615855489::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-41.activo.translation::OptimizedTranslation::982544369868167477::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_15-14.dominante.translation::OptimizedTranslation::8068224801800435189::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_14-39.dominante.translation::OptimizedTranslation::6821897755808565799::1767706649::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-41.event.translation::OptimizedTranslation::7345511482570183792::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_15-14.total.translation::OptimizedTranslation::2843014583496560255::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_14-39.total.translation::OptimizedTranslation::3805026854312601785::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_15-14.pasivo.translation::OptimizedTranslation::2008308158573650735::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_14-39.pasivo.translation::OptimizedTranslation::7549914679124397395::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_13-15.dominante.translation::OptimizedTranslation::8259989462688716957::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_15-14.activo.translation::OptimizedTranslation::6240958534567094294::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_13-15.total.translation::OptimizedTranslation::848832513541123378::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_15-14.event.translation::OptimizedTranslation::3429633260064174347::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_14-39.activo.translation::OptimizedTranslation::5696540645164974206::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_13-15.pasivo.translation::OptimizedTranslation::210200480362706942::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_14-39.event.translation::OptimizedTranslation::1130340051739124781::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_13-15.activo.translation::OptimizedTranslation::9192521431909473854::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_12-44.dominante.translation::OptimizedTranslation::1465798224583328404::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_13-15.event.translation::OptimizedTranslation::5769460118828745557::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_12-44.total.translation::OptimizedTranslation::267385365662915163::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_01-49.dominante.translation::OptimizedTranslation::387275550047722258::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_12-44.pasivo.translation::OptimizedTranslation::6734501169434856013::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_01-49.total.translation::OptimizedTranslation::5454840320485395557::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_12-44.activo.translation::OptimizedTranslation::5982171361702308208::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_23-06.dominante.translation::OptimizedTranslation::5239638854859190308::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_01-49.pasivo.translation::OptimizedTranslation::2833982958234022181::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_12-44.event.translation::OptimizedTranslation::5776591468342883647::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_23-06.total.translation::OptimizedTranslation::4511170896055071501::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_01-49.activo.translation::OptimizedTranslation::1730299625484695269::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_23-06.pasivo.translation::OptimizedTranslation::8547365454744618027::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_01-49.event.translation::OptimizedTranslation::8420063011384659359::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_23-06.activo.translation::OptimizedTranslation::6109708861051822338::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-47.dominante.translation::OptimizedTranslation::2984571904665828410::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_23-06.event.translation::OptimizedTranslation::9181199924270598113::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_20-03.dominante.translation::OptimizedTranslation::7020697091440066547::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_20-03.total.translation::OptimizedTranslation::830079115527101717::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-47.total.translation::OptimizedTranslation::999618650399662117::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-35.dominante.translation::OptimizedTranslation::2963097070785158422::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_20-03.pasivo.translation::OptimizedTranslation::1047073904613467658::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-47.pasivo.translation::OptimizedTranslation::4499785828996715755::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-35.total.translation::OptimizedTranslation::5312984035601799365::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_20-03.activo.translation::OptimizedTranslation::1670195880281708484::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-47.activo.translation::OptimizedTranslation::7354162145557119895::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-35.pasivo.translation::OptimizedTranslation::629100324262431888::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_20-03.event.translation::OptimizedTranslation::4133194790045582668::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-47.event.translation::OptimizedTranslation::4925225183820980324::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-35.activo.translation::OptimizedTranslation::2182389425455255938::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-47.dominante.translation::OptimizedTranslation::9208552027919721783::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-35.event.translation::OptimizedTranslation::9119238400876300256::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-00.dominante.translation::OptimizedTranslation::3693965318119173675::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-47.total.translation::OptimizedTranslation::7636339610013076716::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-00.total.translation::OptimizedTranslation::1273208348232459751::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_17-43.dominante.translation::OptimizedTranslation::5868750517248164682::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-47.pasivo.translation::OptimizedTranslation::6055475678853119539::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-00.pasivo.translation::OptimizedTranslation::1259683884204817139::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_17-43.total.translation::OptimizedTranslation::3390097286464659586::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-47.activo.translation::OptimizedTranslation::7422750033648113450::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-00.activo.translation::OptimizedTranslation::2400378425787145632::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-47.event.translation::OptimizedTranslation::6556822502374620880::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_17-43.pasivo.translation::OptimizedTranslation::385272700817635945::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-00.event.translation::OptimizedTranslation::8397995606948800659::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_17-43.activo.translation::OptimizedTranslation::7306015554246199697::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_07-16.dominante.translation::OptimizedTranslation::5056845570120428462::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_05-08.dominante.translation::OptimizedTranslation::5440700426053677123::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_17-43.event.translation::OptimizedTranslation::8599438081248108265::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_07-16.total.translation::OptimizedTranslation::301648249256344083::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_05-08.total.translation::OptimizedTranslation::3675383910493865298::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_07-16.pasivo.translation::OptimizedTranslation::8454756451879223112::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-53.dominante.translation::OptimizedTranslation::8734132304362663162::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_05-08.pasivo.translation::OptimizedTranslation::2347354892194881033::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_07-16.activo.translation::OptimizedTranslation::2966053179714412487::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-53.total.translation::OptimizedTranslation::6104112128459712082::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_05-08.activo.translation::OptimizedTranslation::6207307456562680582::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_07-16.event.translation::OptimizedTranslation::4229030286916796540::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-53.pasivo.translation::OptimizedTranslation::3124894669086020473::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_05-08.event.translation::OptimizedTranslation::6691282588501147947::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-53.activo.translation::OptimizedTranslation::4220431737893065702::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-32.dominante.translation::OptimizedTranslation::153230561201038380::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_03-07.dominante.translation::OptimizedTranslation::2565715286858552525::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-53.event.translation::OptimizedTranslation::8904504170698549268::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-32.total.translation::OptimizedTranslation::6068772303831571476::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_03-07.total.translation::OptimizedTranslation::7283714000062823483::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-32.pasivo.translation::OptimizedTranslation::4889243659101908609::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_01-01-26_15-59.dominante.translation::OptimizedTranslation::3654343334748780426::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_03-07.pasivo.translation::OptimizedTranslation::8621746972166671276::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-32.activo.translation::OptimizedTranslation::1156152215250871922::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_01-01-26_15-59.total.translation::OptimizedTranslation::3879521438138322425::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_03-07.activo.translation::OptimizedTranslation::8220551828063643286::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-32.event.translation::OptimizedTranslation::486859961176645080::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_01-01-26_15-59.pasivo.translation::OptimizedTranslation::1367988248300080360::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_03-07.event.translation::OptimizedTranslation::6883469482646903402::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_01-01-26_15-59.activo.translation::OptimizedTranslation::382303001882559994::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-13.dominante.translation::OptimizedTranslation::80369856958959227::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_01-01-26_15-59.event.translation::OptimizedTranslation::7059929679838782041::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-01.dominante.translation::OptimizedTranslation::5476633678512834879::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-13.total.translation::OptimizedTranslation::1443590861569009004::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-01.total.translation::OptimizedTranslation::3918487314087293566::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-13.pasivo.translation::OptimizedTranslation::7314757975884053327::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-01.pasivo.translation::OptimizedTranslation::7878548035880381892::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-53.dominante.translation::OptimizedTranslation::6408697079272767860::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-13.activo.translation::OptimizedTranslation::1145381709383248350::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-01.activo.translation::OptimizedTranslation::2213692409418578022::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-53.total.translation::OptimizedTranslation::5128066391109794299::1767706648::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-13.event.translation::OptimizedTranslation::2139494699030822245::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-01.event.translation::OptimizedTranslation::3550614965418314199::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-53.pasivo.translation::OptimizedTranslation::6920157720104216143::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-53.activo.translation::OptimizedTranslation::3820357337753248562::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-43.dominante.translation::OptimizedTranslation::7070077061340940203::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-30.dominante.translation::OptimizedTranslation::4281974752832433385::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-43.total.translation::OptimizedTranslation::959579767236355602::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-53.event.translation::OptimizedTranslation::7007613321111290416::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-30.total.translation::OptimizedTranslation::8047827318998816821::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-43.pasivo.translation::OptimizedTranslation::2264411856892963098::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-30.pasivo.translation::OptimizedTranslation::3640372490207307451::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-43.activo.translation::OptimizedTranslation::987897020764143542::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-12.dominante.translation::OptimizedTranslation::8402570349701483731::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-30.activo.translation::OptimizedTranslation::5220579737174499905::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-43.event.translation::OptimizedTranslation::8692080277354107727::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-30.event.translation::OptimizedTranslation::7146279562512869258::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-12.total.translation::OptimizedTranslation::636273839248443633::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-11.dominante.translation::OptimizedTranslation::5785914204985220875::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-12.pasivo.translation::OptimizedTranslation::7788325017411380000::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-08.dominante.translation::OptimizedTranslation::154591323919249364::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-11.total.translation::OptimizedTranslation::8080517889980838368::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-12.activo.translation::OptimizedTranslation::6850799942025475436::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-08.total.translation::OptimizedTranslation::329158798998469944::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-11.pasivo.translation::OptimizedTranslation::8570987079882519592::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-12.event.translation::OptimizedTranslation::1475398202312761363::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-08.pasivo.translation::OptimizedTranslation::7160352101858829077::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-11.activo.translation::OptimizedTranslation::3762325476623631373::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-08.activo.translation::OptimizedTranslation::7447290067883190470::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-59.dominante.translation::OptimizedTranslation::6480560379178816527::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-11.event.translation::OptimizedTranslation::924625162777764666::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-08.event.translation::OptimizedTranslation::6521959846214896123::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-59.total.translation::OptimizedTranslation::3681186598210632904::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-59.pasivo.translation::OptimizedTranslation::2425003436818124551::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-01.dominante.translation::OptimizedTranslation::5827327526907481261::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-09.dominante.translation::OptimizedTranslation::3187725268693927700::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-09.total.translation::OptimizedTranslation::3260958834526752352::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-59.activo.translation::OptimizedTranslation::6360569779201108688::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-01.total.translation::OptimizedTranslation::837266241329117873::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-09.pasivo.translation::OptimizedTranslation::4367712276678081751::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-59.event.translation::OptimizedTranslation::2053612445036685610::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-01.pasivo.translation::OptimizedTranslation::6951548084823054427::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-09.activo.translation::OptimizedTranslation::1470312565828942594::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-01.activo.translation::OptimizedTranslation::8352024791668613442::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-54.dominante.translation::OptimizedTranslation::4047344319484944945::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-09.event.translation::OptimizedTranslation::1350577915955535122::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-01.event.translation::OptimizedTranslation::4308270719500575760::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-54.total.translation::OptimizedTranslation::7146148413077709666::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-27.dominante.translation::OptimizedTranslation::2468030706083047787::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-29.dominante.translation::OptimizedTranslation::5741347969762550641::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-54.pasivo.translation::OptimizedTranslation::945126166770738777::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-27.total.translation::OptimizedTranslation::2815578088045112815::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-29.total.translation::OptimizedTranslation::4873267141622813268::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-54.activo.translation::OptimizedTranslation::2492417833569508510::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-27.pasivo.translation::OptimizedTranslation::3346553733345113916::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-29.pasivo.translation::OptimizedTranslation::1312671953164435128::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-54.event.translation::OptimizedTranslation::4431372649807299838::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-27.activo.translation::OptimizedTranslation::5717168721879718315::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-29.activo.translation::OptimizedTranslation::8330810771346774027::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-27.event.translation::OptimizedTranslation::544251613687706496::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-29.event.translation::OptimizedTranslation::1001989746564104793::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-24.dominante.translation::OptimizedTranslation::2570174035008277352::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-03.dominante.translation::OptimizedTranslation::235009393996493702::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-24.total.translation::OptimizedTranslation::7039204574906051731::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-07.dominante.translation::OptimizedTranslation::5575920319577577968::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-03.total.translation::OptimizedTranslation::6749522222838243660::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-07.total.translation::OptimizedTranslation::7210861823116516802::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-24.pasivo.translation::OptimizedTranslation::6155586320061949938::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-03.pasivo.translation::OptimizedTranslation::4493404777737662795::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-07.pasivo.translation::OptimizedTranslation::3754370582332969668::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-24.activo.translation::OptimizedTranslation::3125401541040793659::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-03.activo.translation::OptimizedTranslation::1462918674808537518::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-07.activo.translation::OptimizedTranslation::919909423830224771::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-24.event.translation::OptimizedTranslation::9165770312101445205::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-07.event.translation::OptimizedTranslation::8163093430563075861::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-03.event.translation::OptimizedTranslation::4986188908650504356::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-07.dominante.translation::OptimizedTranslation::5264210591226477462::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-43.dominante.translation::OptimizedTranslation::4358684929621395619::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_22-50.dominante.translation::OptimizedTranslation::3732639331404559145::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-07.total.translation::OptimizedTranslation::6866627637897753782::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-43.total.translation::OptimizedTranslation::1290352856214775182::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_22-50.total.translation::OptimizedTranslation::8070376532582245356::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-07.pasivo.translation::OptimizedTranslation::7778863177962346234::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_22-50.pasivo.translation::OptimizedTranslation::3400507182234787014::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-43.pasivo.translation::OptimizedTranslation::8793724969856425270::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-43.activo.translation::OptimizedTranslation::4172148007315608044::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-07.activo.translation::OptimizedTranslation::3289444191698815377::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_22-50.activo.translation::OptimizedTranslation::794135125245396303::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-07.event.translation::OptimizedTranslation::806449031478325010::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_22-50.event.translation::OptimizedTranslation::626893753538949474::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-43.event.translation::OptimizedTranslation::3056775783418417189::1767706647::0::1::::<><><>0<>0<><>::[m
[31m-run100$.md::TextFile::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_01-01-26_15-59.csv::Translation::6825673155644819956::1767706518::1767706648::1::::<><><>0<>0<>ecc2bcf3d1493a5f34f61901f5700cd6<>res://runs/run_01-01-26_15-59.event.translation<*>res://runs/run_01-01-26_15-59.activo.translation<*>res://runs/run_01-01-26_15-59.pasivo.translation<*>res://runs/run_01-01-26_15-59.total.translation<*>res://runs/run_01-01-26_15-59.dominante.translation::[m
[31m-run_01-01-26_15-59.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_02-01-2026_20-32.csv::Translation::4043508092099423085::1767706574::1767706574::0::::<><><>0<>0<>5eddb8481e893d8df83df64cdfda4d3e<>::[m
[31m-run_02-01-2026_20-32.json::JSON::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_02-01-2026_20-38.csv::Translation::2429948380519666189::1767706574::1767706574::0::::<><><>0<>0<>2a90d5d70492e887a6f1636f785c7173<>::[m
[31m-run_02-01-2026_20-38.json::JSON::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_02-01-2026_20-51.csv::Translation::1342338585495178258::1767706574::1767706574::0::::<><><>0<>0<>e3d3853140432deef53fb69c9910258b<>::[m
[31m-run_02-01-2026_20-51.json::JSON::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_02-01-2026_20-57.csv::Translation::1748251016496977938::1767706574::1767706574::0::::<><><>0<>0<>b4e2f11358b0155c9eac3ed0a486de2e<>::[m
[31m-run_02-01-2026_20-57.json::JSON::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_02-01-2026_20-58.csv::Translation::6336963681900064122::1767706574::1767706574::0::::<><><>0<>0<>7fb84d1033d56890293c40611d2ae115<>::[m
[31m-run_02-01-2026_20-58.json::JSON::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_02-01-2026_21-05.csv::Translation::8852698275177181402::1767706574::1767706574::0::::<><><>0<>0<>16b65e888846f3a0347cf0259aab90f1<>::[m
[31m-run_02-01-2026_21-05.json::JSON::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_04-01-2026_22-37.csv::Translation::374158838391536472::1767706574::1767706574::0::::<><><>0<>0<>5042a2cb228f419875d4de7bc00ba807<>::[m
[31m-run_04-01-2026_22-37.json::JSON::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_04-01-2026_23-03.csv::Translation::2919474102859212870::1767706574::1767706648::0::::<><><>0<>0<>58abb9d66f7f1e18a27c6a31878183c3<>::[m
[31m-run_04-01-2026_23-03.json::JSON::-1::1767706574::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_03-07.csv::Translation::5836064322128543460::1767706518::1767706648::1::::<><><>0<>0<>3886116f3aedb56384505e3c14911b30<>res://runs/run_28-12-25_03-07.event.translation<*>res://runs/run_28-12-25_03-07.activo.translation<*>res://runs/run_28-12-25_03-07.pasivo.translation<*>res://runs/run_28-12-25_03-07.total.translation<*>res://runs/run_28-12-25_03-07.dominante.translation::[m
[31m-run_28-12-25_03-07.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-32.csv::Translation::2136381545372629805::1767706518::1767706648::1::::<><><>0<>0<>f12446a2f823e05ef3cc75a0a1ed32c2<>res://runs/run_28-12-25_04-32.event.translation<*>res://runs/run_28-12-25_04-32.activo.translation<*>res://runs/run_28-12-25_04-32.pasivo.translation<*>res://runs/run_28-12-25_04-32.total.translation<*>res://runs/run_28-12-25_04-32.dominante.translation::[m
[31m-run_28-12-25_04-32.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_04-53.csv::Translation::9162763460628274933::1767706518::1767706648::1::::<><><>0<>0<>cde8e243505f87cdd562453b109717b2<>res://runs/run_28-12-25_04-53.event.translation<*>res://runs/run_28-12-25_04-53.activo.translation<*>res://runs/run_28-12-25_04-53.pasivo.translation<*>res://runs/run_28-12-25_04-53.total.translation<*>res://runs/run_28-12-25_04-53.dominante.translation::[m
[31m-run_28-12-25_04-53.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_05-08.csv::Translation::2306358516665976695::1767706518::1767706648::1::::<><><>0<>0<>f8ad3851f1556d1179f22084e5d43259<>res://runs/run_28-12-25_05-08.event.translation<*>res://runs/run_28-12-25_05-08.activo.translation<*>res://runs/run_28-12-25_05-08.pasivo.translation<*>res://runs/run_28-12-25_05-08.total.translation<*>res://runs/run_28-12-25_05-08.dominante.translation::[m
[31m-run_28-12-25_05-08.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_07-16.csv::Translation::19522242411955765::1767706518::1767706648::1::::<><><>0<>0<>9a13901cdf5afbc67734fcf5ae57d890<>res://runs/run_28-12-25_07-16.event.translation<*>res://runs/run_28-12-25_07-16.activo.translation<*>res://runs/run_28-12-25_07-16.pasivo.translation<*>res://runs/run_28-12-25_07-16.total.translation<*>res://runs/run_28-12-25_07-16.dominante.translation::[m
[31m-run_28-12-25_07-16.json::Translation::8507013206275832331::1767706518::1767706648::1::::<><><>0<>0<>66f24b26fdb34b699eb13ef5028bd61c<>res://runs/run_28-12-25_17-43.event.translation<*>res://runs/run_28-12-25_17-43.activo.translation<*>res://runs/run_28-12-25_17-43.pasivo.translation<*>res://runs/run_28-12-25_17-43.total.translation<*>res://runs/run_28-12-25_17-43.dominante.translation::[m
[31m-run_28-12-25_17-43.csv::Translation::8507013206275832331::1767706518::1767706518::1::::<><><>0<>0<>66f24b26fdb34b699eb13ef5028bd61c<>res://runs/run_28-12-25_17-43.event.translation<*>res://runs/run_28-12-25_17-43.activo.translation<*>res://runs/run_28-12-25_17-43.pasivo.translation<*>res://runs/run_28-12-25_17-43.total.translation<*>res://runs/run_28-12-25_17-43.dominante.translation::[m
[31m-run_28-12-25_17-43.json::Translation::3587715808060224653::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-00.csv::Translation::3587715808060224653::1767706518::1767706648::1::::<><><>0<>0<>719fa419cd0084ca58271a5c6f1f1586<>res://runs/run_28-12-25_18-00.event.translation<*>res://runs/run_28-12-25_18-00.activo.translation<*>res://runs/run_28-12-25_18-00.pasivo.translation<*>res://runs/run_28-12-25_18-00.total.translation<*>res://runs/run_28-12-25_18-00.dominante.translation::[m
[31m-run_28-12-25_18-00.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_18-47.csv::Translation::5615512359189040633::1767706518::1767706648::1::::<><><>0<>0<>70520372c790b6b5ab917052ee82790d<>res://runs/run_28-12-25_18-47.event.translation<*>res://runs/run_28-12-25_18-47.activo.translation<*>res://runs/run_28-12-25_18-47.pasivo.translation<*>res://runs/run_28-12-25_18-47.total.translation<*>res://runs/run_28-12-25_18-47.dominante.translation::[m
[31m-run_28-12-25_18-47.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-35.csv::Translation::1311275759402444099::1767706518::1767706648::1::::<><><>0<>0<>1a3dddd81415b520ff5f7215a28cc7ad<>res://runs/run_28-12-25_19-35.event.translation<*>res://runs/run_28-12-25_19-35.activo.translation<*>res://runs/run_28-12-25_19-35.pasivo.translation<*>res://runs/run_28-12-25_19-35.total.translation<*>res://runs/run_28-12-25_19-35.dominante.translation::[m
[31m-run_28-12-25_19-35.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_19-47.csv::Translation::7041069540024066888::1767706518::1767706648::1::::<><><>0<>0<>cbfbdefd22e9959ea9266eb3824599bf<>res://runs/run_28-12-25_19-47.event.translation<*>res://runs/run_28-12-25_19-47.activo.translation<*>res://runs/run_28-12-25_19-47.pasivo.translation<*>res://runs/run_28-12-25_19-47.total.translation<*>res://runs/run_28-12-25_19-47.dominante.translation::[m
[31m-run_28-12-25_19-47.json::Translation::80795747517759973::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_20-03.csv::Translation::80795747517759973::1767706518::1767706648::1::::<><><>0<>0<>87325681cc485fac7168e5a81cc411a4<>res://runs/run_28-12-25_20-03.event.translation<*>res://runs/run_28-12-25_20-03.activo.translation<*>res://runs/run_28-12-25_20-03.pasivo.translation<*>res://runs/run_28-12-25_20-03.total.translation<*>res://runs/run_28-12-25_20-03.dominante.translation::[m
[31m-run_28-12-25_20-03.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_28-12-25_23-06.csv::Translation::1869447288149139518::1767706518::1767706648::1::::<><><>0<>0<>ef1aa10868fd470f9537512a493f4484<>res://runs/run_28-12-25_23-06.event.translation<*>res://runs/run_28-12-25_23-06.activo.translation<*>res://runs/run_28-12-25_23-06.pasivo.translation<*>res://runs/run_28-12-25_23-06.total.translation<*>res://runs/run_28-12-25_23-06.dominante.translation::[m
[31m-run_28-12-25_23-06.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_01-49.csv::Translation::28158917278566109::1767706518::1767706648::1::::<><><>0<>0<>1d86fb6dbbd32f8a15df9fd630317636<>res://runs/run_30-12-25_01-49.event.translation<*>res://runs/run_30-12-25_01-49.activo.translation<*>res://runs/run_30-12-25_01-49.pasivo.translation<*>res://runs/run_30-12-25_01-49.total.translation<*>res://runs/run_30-12-25_01-49.dominante.translation::[m
[31m-run_30-12-25_01-49.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_12-44.csv::Translation::2833318974675372841::1767706518::1767706648::1::::<><><>0<>0<>7b7c419d4e891bae6dd9841691125bf7<>res://runs/run_30-12-25_12-44.event.translation<*>res://runs/run_30-12-25_12-44.activo.translation<*>res://runs/run_30-12-25_12-44.pasivo.translation<*>res://runs/run_30-12-25_12-44.total.translation<*>res://runs/run_30-12-25_12-44.dominante.translation::[m
[31m-run_30-12-25_12-44.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_13-15.csv::Translation::1872978466216759336::1767706518::1767706648::1::::<><><>0<>0<>36d7fdcd96720645866403aff55e54f0<>res://runs/run_30-12-25_13-15.event.translation<*>res://runs/run_30-12-25_13-15.activo.translation<*>res://runs/run_30-12-25_13-15.pasivo.translation<*>res://runs/run_30-12-25_13-15.total.translation<*>res://runs/run_30-12-25_13-15.dominante.translation::[m
[31m-run_30-12-25_13-15.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_14-39.csv::Translation::245148404653824611::1767706518::1767706649::1::::<><><>0<>0<>1fbc1a8aeefe08748cee5b7714d72d42<>res://runs/run_30-12-25_14-39.event.translation<*>res://runs/run_30-12-25_14-39.activo.translation<*>res://runs/run_30-12-25_14-39.pasivo.translation<*>res://runs/run_30-12-25_14-39.total.translation<*>res://runs/run_30-12-25_14-39.dominante.translation::[m
[31m-run_30-12-25_14-39.json::Translation::8641504494565377922::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_15-14.csv::Translation::8641504494565377922::1767706518::1767706649::1::::<><><>0<>0<>2ed330dc38e2c2338e1aeb5c7812c467<>res://runs/run_30-12-25_15-14.event.translation<*>res://runs/run_30-12-25_15-14.activo.translation<*>res://runs/run_30-12-25_15-14.pasivo.translation<*>res://runs/run_30-12-25_15-14.total.translation<*>res://runs/run_30-12-25_15-14.dominante.translation::[m
[31m-run_30-12-25_15-14.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-41.csv::Translation::6904928854539744142::1767706518::1767706649::1::::<><><>0<>0<>4e9f8f64490809f8d6950213e848985d<>res://runs/run_30-12-25_16-41.event.translation<*>res://runs/run_30-12-25_16-41.activo.translation<*>res://runs/run_30-12-25_16-41.pasivo.translation<*>res://runs/run_30-12-25_16-41.total.translation<*>res://runs/run_30-12-25_16-41.dominante.translation::[m
[31m-run_30-12-25_16-41.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_16-54.csv::Translation::4217493248924468888::1767706518::1767706649::1::::<><><>0<>0<>12e8cf55c45fd6aae948a50954a6621a<>res://runs/run_30-12-25_16-54.event.translation<*>res://runs/run_30-12-25_16-54.activo.translation<*>res://runs/run_30-12-25_16-54.pasivo.translation<*>res://runs/run_30-12-25_16-54.total.translation<*>res://runs/run_30-12-25_16-54.dominante.translation::[m
[31m-run_30-12-25_16-54.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-07.csv::Translation::4107819359191162995::1767706518::1767706647::1::::<><><>0<>0<>861539ac5fde125078daa97942b61048<>res://runs/run_30-12-25_17-07.event.translation<*>res://runs/run_30-12-25_17-07.activo.translation<*>res://runs/run_30-12-25_17-07.pasivo.translation<*>res://runs/run_30-12-25_17-07.total.translation<*>res://runs/run_30-12-25_17-07.dominante.translation::[m
[31m-run_30-12-25_17-07.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_17-43.csv::Translation::1597272448307060193::1767706518::1767706647::1::::<><><>0<>0<>76aa50700c52f20171b55908e73f40b3<>res://runs/run_30-12-25_17-43.event.translation<*>res://runs/run_30-12-25_17-43.activo.translation<*>res://runs/run_30-12-25_17-43.pasivo.translation<*>res://runs/run_30-12-25_17-43.total.translation<*>res://runs/run_30-12-25_17-43.dominante.translation::[m
[31m-run_30-12-25_17-43.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_22-50.csv::Translation::2370510899271326598::1767706518::1767706647::1::::<><><>0<>0<>7639221a373b5122ec6751c73068a7a9<>res://runs/run_30-12-25_22-50.event.translation<*>res://runs/run_30-12-25_22-50.activo.translation<*>res://runs/run_30-12-25_22-50.pasivo.translation<*>res://runs/run_30-12-25_22-50.total.translation<*>res://runs/run_30-12-25_22-50.dominante.translation::[m
[31m-run_30-12-25_22-50.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-03.csv::Translation::3812881367551223655::1767706518::1767706647::1::::<><><>0<>0<>63e9fca2a983c6ee350bfdf40e52504e<>res://runs/run_30-12-25_23-03.event.translation<*>res://runs/run_30-12-25_23-03.activo.translation<*>res://runs/run_30-12-25_23-03.pasivo.translation<*>res://runs/run_30-12-25_23-03.total.translation<*>res://runs/run_30-12-25_23-03.dominante.translation::[m
[31m-run_30-12-25_23-03.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-07.csv::Translation::8175920940720760097::1767706518::1767706647::1::::<><><>0<>0<>7c9389a86a66d611b2ed9264e56e89a8<>res://runs/run_30-12-25_23-07.event.translation<*>res://runs/run_30-12-25_23-07.activo.translation<*>res://runs/run_30-12-25_23-07.pasivo.translation<*>res://runs/run_30-12-25_23-07.total.translation<*>res://runs/run_30-12-25_23-07.dominante.translation::[m
[31m-run_30-12-25_23-07.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-24.csv::Translation::3152167403735109266::1767706518::1767706647::1::::<><><>0<>0<>06cf5062a524dd85269253e29068eb13<>res://runs/run_30-12-25_23-24.event.translation<*>res://runs/run_30-12-25_23-24.activo.translation<*>res://runs/run_30-12-25_23-24.pasivo.translation<*>res://runs/run_30-12-25_23-24.total.translation<*>res://runs/run_30-12-25_23-24.dominante.translation::[m
[31m-run_30-12-25_23-24.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_30-12-25_23-29.csv::Translation::1508049799582572423::1767706518::1767706647::1::::<><><>0<>0<>7533f12cc50c0672d3d33a614ceef623<>res://runs/run_30-12-25_23-29.event.translation<*>res://runs/run_30-12-25_23-29.activo.translation<*>res://runs/run_30-12-25_23-29.pasivo.translation<*>res://runs/run_30-12-25_23-29.total.translation<*>res://runs/run_30-12-25_23-29.dominante.translation::[m
[31m-run_30-12-25_23-29.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-27.csv::Translation::1524113954524087122::1767706518::1767706647::1::::<><><>0<>0<>fff01a35f377ca15a6d8b1a3087db385<>res://runs/run_31-12-25_00-27.event.translation<*>res://runs/run_31-12-25_00-27.activo.translation<*>res://runs/run_31-12-25_00-27.pasivo.translation<*>res://runs/run_31-12-25_00-27.total.translation<*>res://runs/run_31-12-25_00-27.dominante.translation::[m
[31m-run_31-12-25_00-27.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_00-54.csv::Translation::3695962115136008021::1767706518::1767706647::1::::<><><>0<>0<>2a2789c5303142283e410d6cd16e4a4e<>res://runs/run_31-12-25_00-54.event.translation<*>res://runs/run_31-12-25_00-54.activo.translation<*>res://runs/run_31-12-25_00-54.pasivo.translation<*>res://runs/run_31-12-25_00-54.total.translation<*>res://runs/run_31-12-25_00-54.dominante.translation::[m
[31m-run_31-12-25_00-54.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-01.csv::Translation::8499027897703536553::1767706518::1767706647::1::::<><><>0<>0<>e73c078a19e0638fb46b8d50a15b86f3<>res://runs/run_31-12-25_01-01.event.translation<*>res://runs/run_31-12-25_01-01.activo.translation<*>res://runs/run_31-12-25_01-01.pasivo.translation<*>res://runs/run_31-12-25_01-01.total.translation<*>res://runs/run_31-12-25_01-01.dominante.translation::[m
[31m-run_31-12-25_01-01.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-09.csv::Translation::527899436823683977::1767706518::1767706647::1::::<><><>0<>0<>1e07d938fbeea84bc565bc485011567c<>res://runs/run_31-12-25_01-09.event.translation<*>res://runs/run_31-12-25_01-09.activo.translation<*>res://runs/run_31-12-25_01-09.pasivo.translation<*>res://runs/run_31-12-25_01-09.total.translation<*>res://runs/run_31-12-25_01-09.dominante.translation::[m
[31m-run_31-12-25_01-09.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_01-59.csv::Translation::8507507965603555424::1767706518::1767706647::1::::<><><>0<>0<>03ec78f2e82c8280db37aadba8168632<>res://runs/run_31-12-25_01-59.event.translation<*>res://runs/run_31-12-25_01-59.activo.translation<*>res://runs/run_31-12-25_01-59.pasivo.translation<*>res://runs/run_31-12-25_01-59.total.translation<*>res://runs/run_31-12-25_01-59.dominante.translation::[m
[31m-run_31-12-25_01-59.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-08.csv::Translation::2303029040270798263::1767706518::1767706647::1::::<><><>0<>0<>0f773eacd10e0188c50e8e5ca17c955d<>res://runs/run_31-12-25_03-08.event.translation<*>res://runs/run_31-12-25_03-08.activo.translation<*>res://runs/run_31-12-25_03-08.pasivo.translation<*>res://runs/run_31-12-25_03-08.total.translation<*>res://runs/run_31-12-25_03-08.dominante.translation::[m
[31m-run_31-12-25_03-08.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_03-11.csv::Translation::1374890907232064277::1767706518::1767706647::1::::<><><>0<>0<>b46e99ceaea8c1e5d558ceb9c5b62503<>res://runs/run_31-12-25_03-11.event.translation<*>res://runs/run_31-12-25_03-11.activo.translation<*>res://runs/run_31-12-25_03-11.pasivo.translation<*>res://runs/run_31-12-25_03-11.total.translation<*>res://runs/run_31-12-25_03-11.dominante.translation::[m
[31m-run_31-12-25_03-11.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-12.csv::Translation::4322169815720478976::1767706518::1767706647::1::::<><><>0<>0<>ac40d4d007c043eec1ed2050ad701fef<>res://runs/run_31-12-25_04-12.event.translation<*>res://runs/run_31-12-25_04-12.activo.translation<*>res://runs/run_31-12-25_04-12.pasivo.translation<*>res://runs/run_31-12-25_04-12.total.translation<*>res://runs/run_31-12-25_04-12.dominante.translation::[m
[31m-run_31-12-25_04-12.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-30.csv::Translation::7580747159092822718::1767706518::1767706647::1::::<><><>0<>0<>f748b3ff285fcd3af45fc6f244c99d17<>res://runs/run_31-12-25_04-30.event.translation<*>res://runs/run_31-12-25_04-30.activo.translation<*>res://runs/run_31-12-25_04-30.pasivo.translation<*>res://runs/run_31-12-25_04-30.total.translation<*>res://runs/run_31-12-25_04-30.dominante.translation::[m
[31m-run_31-12-25_04-30.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-43.csv::Translation::8191543524178138373::1767706518::1767706647::1::::<><><>0<>0<>00fb16d18d7822341a911c3113887e21<>res://runs/run_31-12-25_04-43.event.translation<*>res://runs/run_31-12-25_04-43.activo.translation<*>res://runs/run_31-12-25_04-43.pasivo.translation<*>res://runs/run_31-12-25_04-43.total.translation<*>res://runs/run_31-12-25_04-43.dominante.translation::[m
[31m-run_31-12-25_04-43.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_04-53.csv::Translation::8936924081781261060::1767706518::1767706648::1::::<><><>0<>0<>e972440c13903fae82f0d9f008e7e4be<>res://runs/run_31-12-25_04-53.event.translation<*>res://runs/run_31-12-25_04-53.activo.translation<*>res://runs/run_31-12-25_04-53.pasivo.translation<*>res://runs/run_31-12-25_04-53.total.translation<*>res://runs/run_31-12-25_04-53.dominante.translation::[m
[31m-run_31-12-25_04-53.json::Translation::4953330488016321708::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-01.csv::Translation::4953330488016321708::1767706518::1767706648::1::::<><><>0<>0<>f564f8940e429593cb3482925d3ee74a<>res://runs/run_31-12-25_05-01.event.translation<*>res://runs/run_31-12-25_05-01.activo.translation<*>res://runs/run_31-12-25_05-01.pasivo.translation<*>res://runs/run_31-12-25_05-01.total.translation<*>res://runs/run_31-12-25_05-01.dominante.translation::[m
[31m-run_31-12-25_05-01.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-run_31-12-25_05-13.csv::Translation::103739118346016384::1767706518::1767706648::1::::<><><>0<>0<>537bfb203adeab996bb9e2d0e5897ad4<>res://runs/run_31-12-25_05-13.event.translation<*>res://runs/run_31-12-25_05-13.activo.translation<*>res://runs/run_31-12-25_05-13.pasivo.translation<*>res://runs/run_31-12-25_05-13.total.translation<*>res://runs/run_31-12-25_05-13.dominante.translation::[m
[31m-run_31-12-25_05-13.json::JSON::-1::1767706518::0::1::::<><><>0<>0<><>::[m
[31m-::res://screens/::1767706518[m
[31m-v0.2.1.png::CompressedTexture2D::4190600635964208180::1767706518::1767706518::1::::<><><>0<>0<>11a13d850da6f05a33e0467fa024569a<>res://.godot/imported/v0.2.1.png-89a6179c33da8c99d8ef42ffc7aca077.ctex::[m
[31m-v0.2.2.png::CompressedTexture2D::9055056716685860181::1767706518::1767706518::1::::<><><>0<>0<>9da660d9a7d958416ddc0494961567ea<>res://.godot/imported/v0.2.2.png-f9d74542af0626b6ad91aae43b60202d.ctex::[m
[31m-v0.5.1TheLab.png::CompressedTexture2D::6817490758953657653::1767706518::1767706518::1::::<><><>0<>0<>88b6cc1216f53fd7ab75f3bda7f28937<>res://.godot/imported/v0.5.1TheLab.png-51c54c3a32333169fafd2fcb81a3bec3.ctex::[m
[31m-v0.6 simbologia.png::CompressedTexture2D::2344069700869151062::1767706518::1767706518::1::::<><><>0<>0<>71feacc2bfc132e50cbbcf8c68ffac27<>res://.godot/imported/v0.6 simbologia.png-0abc217a5209a58bb83aaa22389e2666.ctex::[m
[32m+[m[32m::res://::1767755145[m
[32m+[m[32mchangelog 0.5.1TheLab.md::TextFile::-1::1766810188::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mCHANGELOG — v0.6.1 “Observatorio fⁿ — Tagging Layer”.md::TextFile::-1::1766977639::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mCHANGELOG.md::TextFile::-1::1766652139::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mCHANGELOGv0.6.9.md::TextFile::-1::1767320951::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mChangelog_v0.6.md::TextFile::-1::1766911240::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mexport_presets.cfg::TextFile::-1::1766976141::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mGUIDELINES— Filosofía de diseño del sistema.md::TextFile::-1::1766811305::0::1::::<><><>0<>0<><>::[m
[32m+[m[32micon.svg::CompressedTexture2D::9216670998058240731::1766454533::1766454545::1::::<><><>0<>0<>bd555fb2458856aea8c8c8acf97ad736<>res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex::[m
[32m+[m[32mmain.gd::GDScript::6318254411727827567::1767756772::0::1::::<>Control<><>0<>0<><>::[m
[32m+[m[32mmain.tres::Theme::1655596882007418082::1766547266::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mmain.tscn::PackedScene::8187026145298395202::1767755145::0::1::::<><><>0<>0<><>::uid://cwauyyqcu0klj::::res://main.gd<>uid://xt8o6hca6a4q::::res://main.tres[m
[32m+[m[32mpapa.md::TextFile::-1::1766911486::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mProducerItem.tscn::PackedScene::4870387446695148080::1766534713::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mproducer_item.gd::GDScript::7808462353882494901::1766534915::0::1::::<>HBoxContainer<><>0<>0<><>::[m
[32m+[m[32mproducer_item.tscn::PackedScene::7296684604938666336::1766534770::0::1::::<><><>0<>0<><>::uid://djiqh7ws2adm8::::res://producer_item.gd[m
[32m+[m[32mprompt inicial.md::TextFile::-1::1767323258::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mREADME.md::TextFile::-1::1766913566::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mREADMEV0.2.ini::TextFile::-1::1766650622::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mREADMEV0.5.1 The Lab (stable).md::TextFile::-1::1766809545::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mReadmev0.6.1.md::TextFile::-1::1766977669::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mREADMEv0.6.9.md::TextFile::-1::1767320937::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mreadmev0.6.md::TextFile::-1::1766911168::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mREADME_v0.4.md::TextFile::-1::1766653097::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mRelease Notes — v0.6.md::TextFile::-1::1766911353::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mreleaseNotesv0.5.1_TheLab(Stable).md::TextFile::-1::1766810444::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mRELEASE_NOTES_v0.6.9.md::TextFile::-1::1767320959::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mROADMAP.md — Línea evolutiva del proyecto.md::TextFile::-1::1766811206::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mROADMAPv0.6.9.md::TextFile::-1::1767320954::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mversion.gd::GDScript::5760246935057539874::1766955471::0::1::::<>Node<><>0<>0<><>::[m
[32m+[m[32m::res://runs/::1767755488[m
[32m+[m[32mrankings_structurales.csv::Translation::4854605642520857242::1767577123::1767578077::0::::<><><>0<>0<>27d0ff498de251b0982242c2bcf0ee6e<>::[m
[32m+[m[32mrun100$.md::TextFile::-1::1767394145::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_01-01-26_15-59.activo.translation::OptimizedTranslation::4823629911707552706::1767294421::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_01-01-26_15-59.csv::Translation::6825673155644819956::1767293982::1767294421::1::::<><><>0<>0<>ecc2bcf3d1493a5f34f61901f5700cd6<>res://runs/run_01-01-26_15-59.event.translation<*>res://runs/run_01-01-26_15-59.activo.translation<*>res://runs/run_01-01-26_15-59.pasivo.translation<*>res://runs/run_01-01-26_15-59.total.translation<*>res://runs/run_01-01-26_15-59.dominante.translation::[m
[32m+[m[32mrun_01-01-26_15-59.dominante.translation::OptimizedTranslation::5371874675532616037::1767294421::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_01-01-26_15-59.event.translation::OptimizedTranslation::3222960544297564369::1767294421::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_01-01-26_15-59.json::JSON::-1::1767293982::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_01-01-26_15-59.pasivo.translation::OptimizedTranslation::1042821021710503180::1767294421::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_01-01-26_15-59.total.translation::OptimizedTranslation::9185184658081470807::1767294421::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_02-01-2026_20-32.csv::Translation::4043508092099423085::1767396726::1767396728::0::::<><><>0<>0<>5eddb8481e893d8df83df64cdfda4d3e<>::[m
[32m+[m[32mrun_02-01-2026_20-32.json::JSON::-1::1767396726::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_02-01-2026_20-38.csv::Translation::2429948380519666189::1767397130::1767397915::0::::<><><>0<>0<>2a90d5d70492e887a6f1636f785c7173<>::[m
[32m+[m[32mrun_02-01-2026_20-38.json::JSON::-1::1767397130::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_02-01-2026_20-51.csv::Translation::1342338585495178258::1767397873::1767397915::0::::<><><>0<>0<>e3d3853140432deef53fb69c9910258b<>::[m
[32m+[m[32mrun_02-01-2026_20-51.json::JSON::-1::1767397873::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_02-01-2026_20-57.csv::Translation::1748251016496977938::1767398267::1767398267::0::::<><><>0<>0<>b4e2f11358b0155c9eac3ed0a486de2e<>::[m
[32m+[m[32mrun_02-01-2026_20-57.json::JSON::-1::1767398267::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_02-01-2026_20-58.csv::Translation::6336963681900064122::1767398339::1767399815::0::::<><><>0<>0<>7fb84d1033d56890293c40611d2ae115<>::[m
[32m+[m[32mrun_02-01-2026_20-58.json::JSON::-1::1767398339::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_02-01-2026_21-05.csv::Translation::8852698275177181402::1767398724::1767399815::0::::<><><>0<>0<>16b65e888846f3a0347cf0259aab90f1<>::[m
[32m+[m[32mrun_02-01-2026_21-05.json::JSON::-1::1767398724::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_04-01-2026_22-37.csv::Translation::374158838391536472::1767577040::1767577044::0::::<><><>0<>0<>5042a2cb228f419875d4de7bc00ba807<>::[m
[32m+[m[32mrun_04-01-2026_22-37.json::JSON::-1::1767577040::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_04-01-2026_23-03.csv::Translation::2919474102859212870::1767578598::1767735330::0::::<><><>0<>0<>58abb9d66f7f1e18a27c6a31878183c3<>::[m
[32m+[m[32mrun_04-01-2026_23-03.json::JSON::-1::1767578598::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_06-01-2026_20-01.csv::Translation::1987699482361529022::1767740517::1767743159::0::::<><><>0<>0<>cbbc5e0e82e30237a3885962698179f6<>::[m
[32m+[m[32mrun_06-01-2026_20-01.json::JSON::-1::1767740517::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_06-01-2026_20-46.csv::Translation::1076174019788033112::1767743195::1767743197::0::::<><><>0<>0<>6914414c546d8c6f4c5616bb6a62b86b<>::[m
[32m+[m[32mrun_06-01-2026_20-46.json::JSON::-1::1767743195::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_06-01-2026_23-57.csv::Translation::791466316801122064::1767754639::1767755143::0::::<><><>0<>0<>b515c67e214cafbd093a312238d951c3<>::[m
[32m+[m[32mrun_06-01-2026_23-57.json::JSON::-1::1767754639::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_07-01-2026_00-11.csv::Translation::4966623586887736369::1767755488::1767756796::0::::<><><>0<>0<>e481b971bbab1891870364ec42fc3368<>::[m
[32m+[m[32mrun_07-01-2026_00-11.json::JSON::-1::1767755488::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_03-07.activo.translation::OptimizedTranslation::985341975667798858::1766902431::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_03-07.csv::Translation::5836064322128543460::1766902079::1766902431::1::::<><><>0<>0<>3886116f3aedb56384505e3c14911b30<>res://runs/run_28-12-25_03-07.event.translation<*>res://runs/run_28-12-25_03-07.activo.translation<*>res://runs/run_28-12-25_03-07.pasivo.translation<*>res://runs/run_28-12-25_03-07.total.translation<*>res://runs/run_28-12-25_03-07.dominante.translation::[m
[32m+[m[32mrun_28-12-25_03-07.dominante.translation::OptimizedTranslation::8906460480255146487::1766902431::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_03-07.event.translation::OptimizedTranslation::7978585333812805700::1766902431::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_03-07.json::JSON::-1::1766902079::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_03-07.pasivo.translation::OptimizedTranslation::7697220768312104855::1766902431::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_03-07.total.translation::OptimizedTranslation::5700947972077231108::1766902431::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-32.activo.translation::OptimizedTranslation::7988807253692589604::1766907124::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-32.csv::Translation::2136381545372629805::1766907120::1766907124::1::::<><><>0<>0<>f12446a2f823e05ef3cc75a0a1ed32c2<>res://runs/run_28-12-25_04-32.event.translation<*>res://runs/run_28-12-25_04-32.activo.translation<*>res://runs/run_28-12-25_04-32.pasivo.translation<*>res://runs/run_28-12-25_04-32.total.translation<*>res://runs/run_28-12-25_04-32.dominante.translation::[m
[32m+[m[32mrun_28-12-25_04-32.dominante.translation::OptimizedTranslation::6016747515561358909::1766907124::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-32.event.translation::OptimizedTranslation::5883851163063930391::1766907124::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-32.json::JSON::-1::1766907120::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-32.pasivo.translation::OptimizedTranslation::4893765670996685410::1766907124::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-32.total.translation::OptimizedTranslation::2841293475998847677::1766907124::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-53.activo.translation::OptimizedTranslation::7424528399496804442::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-53.csv::Translation::9162763460628274933::1766908386::1766911633::1::::<><><>0<>0<>cde8e243505f87cdd562453b109717b2<>res://runs/run_28-12-25_04-53.event.translation<*>res://runs/run_28-12-25_04-53.activo.translation<*>res://runs/run_28-12-25_04-53.pasivo.translation<*>res://runs/run_28-12-25_04-53.total.translation<*>res://runs/run_28-12-25_04-53.dominante.translation::[m
[32m+[m[32mrun_28-12-25_04-53.dominante.translation::OptimizedTranslation::7022921590130925092::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-53.event.translation::OptimizedTranslation::2363361769130925214::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-53.json::JSON::-1::1766908386::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-53.pasivo.translation::OptimizedTranslation::5214145173001428680::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_04-53.total.translation::OptimizedTranslation::4087627624844385672::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_05-08.activo.translation::OptimizedTranslation::2545611609573215884::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_05-08.csv::Translation::2306358516665976695::1766909289::1766911633::1::::<><><>0<>0<>f8ad3851f1556d1179f22084e5d43259<>res://runs/run_28-12-25_05-08.event.translation<*>res://runs/run_28-12-25_05-08.activo.translation<*>res://runs/run_28-12-25_05-08.pasivo.translation<*>res://runs/run_28-12-25_05-08.total.translation<*>res://runs/run_28-12-25_05-08.dominante.translation::[m
[32m+[m[32mrun_28-12-25_05-08.dominante.translation::OptimizedTranslation::7755833389909477957::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_05-08.event.translation::OptimizedTranslation::680263704002891569::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_05-08.json::JSON::-1::1766909289::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_05-08.pasivo.translation::OptimizedTranslation::8751309663241355703::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_05-08.total.translation::OptimizedTranslation::5280599723911185931::1766911633::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_07-16.activo.translation::OptimizedTranslation::5815419074834112951::1766953285::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_07-16.csv::Translation::19522242411955765::1766917008::1766953285::1::::<><><>0<>0<>9a13901cdf5afbc67734fcf5ae57d890<>res://runs/run_28-12-25_07-16.event.translation<*>res://runs/run_28-12-25_07-16.activo.translation<*>res://runs/run_28-12-25_07-16.pasivo.translation<*>res://runs/run_28-12-25_07-16.total.translation<*>res://runs/run_28-12-25_07-16.dominante.translation::[m
[32m+[m[32mrun_28-12-25_07-16.dominante.translation::OptimizedTranslation::2888156152146084454::1766953285::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_07-16.event.translation::OptimizedTranslation::5423549638502556721::1766953285::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_07-16.json::JSON::-1::1766917008::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_07-16.pasivo.translation::OptimizedTranslation::2091479675535509393::1766953285::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_07-16.total.translation::OptimizedTranslation::3413805202042964595::1766953285::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_17-43.activo.translation::OptimizedTranslation::2390943574212277689::1766955350::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_17-43.csv::Translation::8507013206275832331::1766954613::1766955350::1::::<><><>0<>0<>66f24b26fdb34b699eb13ef5028bd61c<>res://runs/run_28-12-25_17-43.event.translation<*>res://runs/run_28-12-25_17-43.activo.translation<*>res://runs/run_28-12-25_17-43.pasivo.translation<*>res://runs/run_28-12-25_17-43.total.translation<*>res://runs/run_28-12-25_17-43.dominante.translation::[m
[32m+[m[32mrun_28-12-25_17-43.dominante.translation::OptimizedTranslation::8297662059360385867::1766955350::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_17-43.event.translation::OptimizedTranslation::6130704558371345821::1766955350::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_17-43.json::JSON::-1::1766954613::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_17-43.pasivo.translation::OptimizedTranslation::5872841678841271298::1766955350::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_17-43.total.translation::OptimizedTranslation::215590777446691575::1766955350::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-00.activo.translation::OptimizedTranslation::998851660026119475::1766957102::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-00.csv::Translation::3587715808060224653::1766955621::1766957102::1::::<><><>0<>0<>719fa419cd0084ca58271a5c6f1f1586<>res://runs/run_28-12-25_18-00.event.translation<*>res://runs/run_28-12-25_18-00.activo.translation<*>res://runs/run_28-12-25_18-00.pasivo.translation<*>res://runs/run_28-12-25_18-00.total.translation<*>res://runs/run_28-12-25_18-00.dominante.translation::[m
[32m+[m[32mrun_28-12-25_18-00.dominante.translation::OptimizedTranslation::1424834063480930194::1766957102::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-00.event.translation::OptimizedTranslation::7304665336521957960::1766957102::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-00.json::JSON::-1::1766955621::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-00.pasivo.translation::OptimizedTranslation::6185883469481454084::1766957102::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-00.total.translation::OptimizedTranslation::4098635681088783446::1766957102::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-47.activo.translation::OptimizedTranslation::285098320401467234::1766960191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-47.csv::Translation::5615512359189040633::1766958440::1766960191::1::::<><><>0<>0<>70520372c790b6b5ab917052ee82790d<>res://runs/run_28-12-25_18-47.event.translation<*>res://runs/run_28-12-25_18-47.activo.translation<*>res://runs/run_28-12-25_18-47.pasivo.translation<*>res://runs/run_28-12-25_18-47.total.translation<*>res://runs/run_28-12-25_18-47.dominante.translation::[m
[32m+[m[32mrun_28-12-25_18-47.dominante.translation::OptimizedTranslation::7849051166416622174::1766960191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-47.event.translation::OptimizedTranslation::144534317799040550::1766960191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-47.json::JSON::-1::1766958440::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-47.pasivo.translation::OptimizedTranslation::2461586435670342288::1766960191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_18-47.total.translation::OptimizedTranslation::5066187210699239889::1766960191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-35.activo.translation::OptimizedTranslation::5414616809583897944::1766961373::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-35.csv::Translation::1311275759402444099::1766961341::1766961373::1::::<><><>0<>0<>1a3dddd81415b520ff5f7215a28cc7ad<>res://runs/run_28-12-25_19-35.event.translation<*>res://runs/run_28-12-25_19-35.activo.translation<*>res://runs/run_28-12-25_19-35.pasivo.translation<*>res://runs/run_28-12-25_19-35.total.translation<*>res://runs/run_28-12-25_19-35.dominante.translation::[m
[32m+[m[32mrun_28-12-25_19-35.dominante.translation::OptimizedTranslation::2944733329243023430::1766961373::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-35.event.translation::OptimizedTranslation::1701366636153163554::1766961373::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-35.json::JSON::-1::1766961341::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-35.pasivo.translation::OptimizedTranslation::1073281936578307191::1766961373::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-35.total.translation::OptimizedTranslation::8551097065284091985::1766961373::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-47.activo.translation::OptimizedTranslation::6423334187854466818::1766962295::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-47.csv::Translation::7041069540024066888::1766962024::1766962295::1::::<><><>0<>0<>cbfbdefd22e9959ea9266eb3824599bf<>res://runs/run_28-12-25_19-47.event.translation<*>res://runs/run_28-12-25_19-47.activo.translation<*>res://runs/run_28-12-25_19-47.pasivo.translation<*>res://runs/run_28-12-25_19-47.total.translation<*>res://runs/run_28-12-25_19-47.dominante.translation::[m
[32m+[m[32mrun_28-12-25_19-47.dominante.translation::OptimizedTranslation::2136970382140577114::1766962295::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-47.event.translation::OptimizedTranslation::2815866814177189390::1766962295::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-47.json::JSON::-1::1766962024::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-47.pasivo.translation::OptimizedTranslation::270127820630414313::1766962295::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_19-47.total.translation::OptimizedTranslation::430585122176159887::1766962295::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_20-03.activo.translation::OptimizedTranslation::4327894008111676164::1766963881::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_20-03.csv::Translation::80795747517759973::1766963017::1766963881::1::::<><><>0<>0<>87325681cc485fac7168e5a81cc411a4<>res://runs/run_28-12-25_20-03.event.translation<*>res://runs/run_28-12-25_20-03.activo.translation<*>res://runs/run_28-12-25_20-03.pasivo.translation<*>res://runs/run_28-12-25_20-03.total.translation<*>res://runs/run_28-12-25_20-03.dominante.translation::[m
[32m+[m[32mrun_28-12-25_20-03.dominante.translation::OptimizedTranslation::3758866665216114604::1766963881::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_20-03.event.translation::OptimizedTranslation::9005861062462769025::1766963881::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_20-03.json::JSON::-1::1766963017::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_20-03.pasivo.translation::OptimizedTranslation::2771859843216169308::1766963881::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_20-03.total.translation::OptimizedTranslation::9084165369149098032::1766963881::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_23-06.activo.translation::OptimizedTranslation::8580427414549054394::1766973978::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_23-06.csv::Translation::1869447288149139518::1766973975::1766973978::1::::<><><>0<>0<>ef1aa10868fd470f9537512a493f4484<>res://runs/run_28-12-25_23-06.event.translation<*>res://runs/run_28-12-25_23-06.activo.translation<*>res://runs/run_28-12-25_23-06.pasivo.translation<*>res://runs/run_28-12-25_23-06.total.translation<*>res://runs/run_28-12-25_23-06.dominante.translation::[m
[32m+[m[32mrun_28-12-25_23-06.dominante.translation::OptimizedTranslation::5866275744967621272::1766973978::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_23-06.event.translation::OptimizedTranslation::8418307732335558690::1766973978::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_23-06.json::JSON::-1::1766973975::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_23-06.pasivo.translation::OptimizedTranslation::781146779531114268::1766973978::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_28-12-25_23-06.total.translation::OptimizedTranslation::7180594419964410693::1766973978::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_01-49.activo.translation::OptimizedTranslation::4450437085980501643::1767071232::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_01-49.csv::Translation::28158917278566109::1767070175::1767071233::1::::<><><>0<>0<>1d86fb6dbbd32f8a15df9fd630317636<>res://runs/run_30-12-25_01-49.event.translation<*>res://runs/run_30-12-25_01-49.activo.translation<*>res://runs/run_30-12-25_01-49.pasivo.translation<*>res://runs/run_30-12-25_01-49.total.translation<*>res://runs/run_30-12-25_01-49.dominante.translation::[m
[32m+[m[32mrun_30-12-25_01-49.dominante.translation::OptimizedTranslation::3058958844969922930::1767071233::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_01-49.event.translation::OptimizedTranslation::5753263799113997910::1767071232::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_01-49.json::JSON::-1::1767070175::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_01-49.pasivo.translation::OptimizedTranslation::6731411482107222372::1767071232::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_01-49.total.translation::OptimizedTranslation::1091813284390817::1767071233::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_12-44.activo.translation::OptimizedTranslation::5686746411831602897::1767109482::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_12-44.csv::Translation::2833318974675372841::1767109478::1767109482::1::::<><><>0<>0<>7b7c419d4e891bae6dd9841691125bf7<>res://runs/run_30-12-25_12-44.event.translation<*>res://runs/run_30-12-25_12-44.activo.translation<*>res://runs/run_30-12-25_12-44.pasivo.translation<*>res://runs/run_30-12-25_12-44.total.translation<*>res://runs/run_30-12-25_12-44.dominante.translation::[m
[32m+[m[32mrun_30-12-25_12-44.dominante.translation::OptimizedTranslation::8058599114434997218::1767109482::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_12-44.event.translation::OptimizedTranslation::8066306031961628375::1767109482::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_12-44.json::JSON::-1::1767109478::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_12-44.pasivo.translation::OptimizedTranslation::5459547120240452172::1767109482::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_12-44.total.translation::OptimizedTranslation::2644114217361868677::1767109482::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_13-15.activo.translation::OptimizedTranslation::4724885277790352558::1767115570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_13-15.csv::Translation::1872978466216759336::1767111325::1767115570::1::::<><><>0<>0<>36d7fdcd96720645866403aff55e54f0<>res://runs/run_30-12-25_13-15.event.translation<*>res://runs/run_30-12-25_13-15.activo.translation<*>res://runs/run_30-12-25_13-15.pasivo.translation<*>res://runs/run_30-12-25_13-15.total.translation<*>res://runs/run_30-12-25_13-15.dominante.translation::[m
[32m+[m[32mrun_30-12-25_13-15.dominante.translation::OptimizedTranslation::2490516531519789790::1767115570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_13-15.event.translation::OptimizedTranslation::2795957078379708100::1767115570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_13-15.json::JSON::-1::1767111325::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_13-15.pasivo.translation::OptimizedTranslation::1276122126666342779::1767115570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_13-15.total.translation::OptimizedTranslation::9114424611893755156::1767115570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_14-39.activo.translation::OptimizedTranslation::6179504959050416613::1767116815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_14-39.csv::Translation::245148404653824611::1767116349::1767116815::1::::<><><>0<>0<>1fbc1a8aeefe08748cee5b7714d72d42<>res://runs/run_30-12-25_14-39.event.translation<*>res://runs/run_30-12-25_14-39.activo.translation<*>res://runs/run_30-12-25_14-39.pasivo.translation<*>res://runs/run_30-12-25_14-39.total.translation<*>res://runs/run_30-12-25_14-39.dominante.translation::[m
[32m+[m[32mrun_30-12-25_14-39.dominante.translation::OptimizedTranslation::4808826185544022030::1767116815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_14-39.event.translation::OptimizedTranslation::7416678695150896943::1767116815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_14-39.json::JSON::-1::1767116349::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_14-39.pasivo.translation::OptimizedTranslation::2279187565907930524::1767116815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_14-39.total.translation::OptimizedTranslation::914960206555982898::1767116815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_15-14.activo.translation::OptimizedTranslation::6967108956611107890::1767118513::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_15-14.csv::Translation::8641504494565377922::1767118492::1767118513::1::::<><><>0<>0<>2ed330dc38e2c2338e1aeb5c7812c467<>res://runs/run_30-12-25_15-14.event.translation<*>res://runs/run_30-12-25_15-14.activo.translation<*>res://runs/run_30-12-25_15-14.pasivo.translation<*>res://runs/run_30-12-25_15-14.total.translation<*>res://runs/run_30-12-25_15-14.dominante.translation::[m
[32m+[m[32mrun_30-12-25_15-14.dominante.translation::OptimizedTranslation::7474309811663312219::1767118513::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_15-14.event.translation::OptimizedTranslation::384162821158508111::1767118513::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_15-14.json::JSON::-1::1767118492::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_15-14.pasivo.translation::OptimizedTranslation::8130531022506739982::1767118513::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_15-14.total.translation::OptimizedTranslation::1818044385200815756::1767118513::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-41.activo.translation::OptimizedTranslation::2988484932882862069::1767123713::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-41.csv::Translation::6904928854539744142::1767123702::1767123713::1::::<><><>0<>0<>4e9f8f64490809f8d6950213e848985d<>res://runs/run_30-12-25_16-41.event.translation<*>res://runs/run_30-12-25_16-41.activo.translation<*>res://runs/run_30-12-25_16-41.pasivo.translation<*>res://runs/run_30-12-25_16-41.total.translation<*>res://runs/run_30-12-25_16-41.dominante.translation::[m
[32m+[m[32mrun_30-12-25_16-41.dominante.translation::OptimizedTranslation::5177639238724629550::1767123713::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-41.event.translation::OptimizedTranslation::3859174676493011808::1767123713::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-41.json::JSON::-1::1767123702::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-41.pasivo.translation::OptimizedTranslation::1027018297546255019::1767123713::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-41.total.translation::OptimizedTranslation::1407956866545644201::1767123713::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-54.activo.translation::OptimizedTranslation::5965103515152634219::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-54.csv::Translation::4217493248924468888::1767124451::1767125264::1::::<><><>0<>0<>12e8cf55c45fd6aae948a50954a6621a<>res://runs/run_30-12-25_16-54.event.translation<*>res://runs/run_30-12-25_16-54.activo.translation<*>res://runs/run_30-12-25_16-54.pasivo.translation<*>res://runs/run_30-12-25_16-54.total.translation<*>res://runs/run_30-12-25_16-54.dominante.translation::[m
[32m+[m[32mrun_30-12-25_16-54.dominante.translation::OptimizedTranslation::4510287401315442640::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-54.event.translation::OptimizedTranslation::6819379845717570644::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-54.json::JSON::-1::1767124451::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-54.pasivo.translation::OptimizedTranslation::1155773721316918685::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_16-54.total.translation::OptimizedTranslation::6173393286444553108::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-07.activo.translation::OptimizedTranslation::6712553710990703084::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-07.csv::Translation::4107819359191162995::1767125262::1767125264::1::::<><><>0<>0<>861539ac5fde125078daa97942b61048<>res://runs/run_30-12-25_17-07.event.translation<*>res://runs/run_30-12-25_17-07.activo.translation<*>res://runs/run_30-12-25_17-07.pasivo.translation<*>res://runs/run_30-12-25_17-07.total.translation<*>res://runs/run_30-12-25_17-07.dominante.translation::[m
[32m+[m[32mrun_30-12-25_17-07.dominante.translation::OptimizedTranslation::198980855484217426::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-07.event.translation::OptimizedTranslation::3967248257868809548::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-07.json::JSON::-1::1767125262::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-07.pasivo.translation::OptimizedTranslation::782492064403356181::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-07.total.translation::OptimizedTranslation::6560013089013134900::1767125264::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-43.activo.translation::OptimizedTranslation::164145979232558012::1767136018::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-43.csv::Translation::1597272448307060193::1767127419::1767136018::1::::<><><>0<>0<>76aa50700c52f20171b55908e73f40b3<>res://runs/run_30-12-25_17-43.event.translation<*>res://runs/run_30-12-25_17-43.activo.translation<*>res://runs/run_30-12-25_17-43.pasivo.translation<*>res://runs/run_30-12-25_17-43.total.translation<*>res://runs/run_30-12-25_17-43.dominante.translation::[m
[32m+[m[32mrun_30-12-25_17-43.dominante.translation::OptimizedTranslation::3646960443889431509::1767136018::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-43.event.translation::OptimizedTranslation::350259331846934395::1767136018::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-43.json::JSON::-1::1767127419::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-43.pasivo.translation::OptimizedTranslation::5898995486868333044::1767136018::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_17-43.total.translation::OptimizedTranslation::891656235518781075::1767136018::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_22-50.activo.translation::OptimizedTranslation::2925708793328052465::1767146570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_22-50.csv::Translation::2370510899271326598::1767145831::1767146570::1::::<><><>0<>0<>7639221a373b5122ec6751c73068a7a9<>res://runs/run_30-12-25_22-50.event.translation<*>res://runs/run_30-12-25_22-50.activo.translation<*>res://runs/run_30-12-25_22-50.pasivo.translation<*>res://runs/run_30-12-25_22-50.total.translation<*>res://runs/run_30-12-25_22-50.dominante.translation::[m
[32m+[m[32mrun_30-12-25_22-50.dominante.translation::OptimizedTranslation::2507152336654905031::1767146570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_22-50.event.translation::OptimizedTranslation::962493583520243647::1767146570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_22-50.json::JSON::-1::1767145831::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_22-50.pasivo.translation::OptimizedTranslation::4820275763721401835::1767146570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_22-50.total.translation::OptimizedTranslation::2320689371595252827::1767146570::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-03.activo.translation::OptimizedTranslation::8882609269943891245::1767146641::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-03.csv::Translation::3812881367551223655::1767146609::1767146641::1::::<><><>0<>0<>63e9fca2a983c6ee350bfdf40e52504e<>res://runs/run_30-12-25_23-03.event.translation<*>res://runs/run_30-12-25_23-03.activo.translation<*>res://runs/run_30-12-25_23-03.pasivo.translation<*>res://runs/run_30-12-25_23-03.total.translation<*>res://runs/run_30-12-25_23-03.dominante.translation::[m
[32m+[m[32mrun_30-12-25_23-03.dominante.translation::OptimizedTranslation::1382358339521357192::1767146641::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-03.event.translation::OptimizedTranslation::2095347406011119300::1767146641::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-03.json::JSON::-1::1767146609::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-03.pasivo.translation::OptimizedTranslation::7935505713959990186::1767146641::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-03.total.translation::OptimizedTranslation::6095479895468772734::1767146641::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-07.activo.translation::OptimizedTranslation::8076402107873323030::1767147358::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-07.csv::Translation::8175920940720760097::1767146852::1767147358::1::::<><><>0<>0<>7c9389a86a66d611b2ed9264e56e89a8<>res://runs/run_30-12-25_23-07.event.translation<*>res://runs/run_30-12-25_23-07.activo.translation<*>res://runs/run_30-12-25_23-07.pasivo.translation<*>res://runs/run_30-12-25_23-07.total.translation<*>res://runs/run_30-12-25_23-07.dominante.translation::[m
[32m+[m[32mrun_30-12-25_23-07.dominante.translation::OptimizedTranslation::5883785860987626877::1767147358::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-07.event.translation::OptimizedTranslation::1628305983107209311::1767147358::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-07.json::JSON::-1::1767146852::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-07.pasivo.translation::OptimizedTranslation::4731238566396850184::1767147358::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-07.total.translation::OptimizedTranslation::6673758587564689154::1767147358::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-24.activo.translation::OptimizedTranslation::5394805003976083090::1767147860::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-24.csv::Translation::3152167403735109266::1767147849::1767147860::1::::<><><>0<>0<>06cf5062a524dd85269253e29068eb13<>res://runs/run_30-12-25_23-24.event.translation<*>res://runs/run_30-12-25_23-24.activo.translation<*>res://runs/run_30-12-25_23-24.pasivo.translation<*>res://runs/run_30-12-25_23-24.total.translation<*>res://runs/run_30-12-25_23-24.dominante.translation::[m
[32m+[m[32mrun_30-12-25_23-24.dominante.translation::OptimizedTranslation::5359427826207129391::1767147860::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-24.event.translation::OptimizedTranslation::6476746579231736086::1767147860::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-24.json::JSON::-1::1767147849::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-24.pasivo.translation::OptimizedTranslation::5607814033999775543::1767147860::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-24.total.translation::OptimizedTranslation::8311365104457765345::1767147860::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-29.activo.translation::OptimizedTranslation::1782860995999725978::1767151342::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-29.csv::Translation::1508049799582572423::1767148158::1767151342::1::::<><><>0<>0<>7533f12cc50c0672d3d33a614ceef623<>res://runs/run_30-12-25_23-29.event.translation<*>res://runs/run_30-12-25_23-29.activo.translation<*>res://runs/run_30-12-25_23-29.pasivo.translation<*>res://runs/run_30-12-25_23-29.total.translation<*>res://runs/run_30-12-25_23-29.dominante.translation::[m
[32m+[m[32mrun_30-12-25_23-29.dominante.translation::OptimizedTranslation::5390595364982859321::1767151342::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-29.event.translation::OptimizedTranslation::5148934568439902438::1767151342::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-29.json::JSON::-1::1767148158::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-29.pasivo.translation::OptimizedTranslation::2695762194437102056::1767151342::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_30-12-25_23-29.total.translation::OptimizedTranslation::3198391024377289859::1767151342::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-27.activo.translation::OptimizedTranslation::6502786061513003202::1767152815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-27.csv::Translation::1524113954524087122::1767151651::1767152815::1::::<><><>0<>0<>fff01a35f377ca15a6d8b1a3087db385<>res://runs/run_31-12-25_00-27.event.translation<*>res://runs/run_31-12-25_00-27.activo.translation<*>res://runs/run_31-12-25_00-27.pasivo.translation<*>res://runs/run_31-12-25_00-27.total.translation<*>res://runs/run_31-12-25_00-27.dominante.translation::[m
[32m+[m[32mrun_31-12-25_00-27.dominante.translation::OptimizedTranslation::2588573083033680008::1767152815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-27.event.translation::OptimizedTranslation::8061806258668373562::1767152815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-27.json::JSON::-1::1767151651::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-27.pasivo.translation::OptimizedTranslation::4352605124847140186::1767152815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-27.total.translation::OptimizedTranslation::4144075038716967917::1767152815::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-54.activo.translation::OptimizedTranslation::7691551291032427176::1767153589::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-54.csv::Translation::3695962115136008021::1767153261::1767153590::1::::<><><>0<>0<>2a2789c5303142283e410d6cd16e4a4e<>res://runs/run_31-12-25_00-54.event.translation<*>res://runs/run_31-12-25_00-54.activo.translation<*>res://runs/run_31-12-25_00-54.pasivo.translation<*>res://runs/run_31-12-25_00-54.total.translation<*>res://runs/run_31-12-25_00-54.dominante.translation::[m
[32m+[m[32mrun_31-12-25_00-54.dominante.translation::OptimizedTranslation::6850112853244333193::1767153590::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-54.event.translation::OptimizedTranslation::5611416695906268149::1767153589::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-54.json::JSON::-1::1767153261::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-54.pasivo.translation::OptimizedTranslation::503080047696064180::1767153590::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_00-54.total.translation::OptimizedTranslation::6532982808889078897::1767153590::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-01.activo.translation::OptimizedTranslation::843370644542688254::1767153715::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-01.csv::Translation::8499027897703536553::1767153713::1767153715::1::::<><><>0<>0<>e73c078a19e0638fb46b8d50a15b86f3<>res://runs/run_31-12-25_01-01.event.translation<*>res://runs/run_31-12-25_01-01.activo.translation<*>res://runs/run_31-12-25_01-01.pasivo.translation<*>res://runs/run_31-12-25_01-01.total.translation<*>res://runs/run_31-12-25_01-01.dominante.translation::[m
[32m+[m[32mrun_31-12-25_01-01.dominante.translation::OptimizedTranslation::7840192898275265921::1767153715::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-01.event.translation::OptimizedTranslation::6779099727204259053::1767153715::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-01.json::JSON::-1::1767153713::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-01.pasivo.translation::OptimizedTranslation::1899229051398984518::1767153715::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-01.total.translation::OptimizedTranslation::3276720236873990997::1767153715::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-09.activo.translation::OptimizedTranslation::4866391449236017963::1767154191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-09.csv::Translation::527899436823683977::1767154158::1767154191::1::::<><><>0<>0<>1e07d938fbeea84bc565bc485011567c<>res://runs/run_31-12-25_01-09.event.translation<*>res://runs/run_31-12-25_01-09.activo.translation<*>res://runs/run_31-12-25_01-09.pasivo.translation<*>res://runs/run_31-12-25_01-09.total.translation<*>res://runs/run_31-12-25_01-09.dominante.translation::[m
[32m+[m[32mrun_31-12-25_01-09.dominante.translation::OptimizedTranslation::3495274713503796400::1767154191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-09.event.translation::OptimizedTranslation::1423271228542736261::1767154191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-09.json::JSON::-1::1767154158::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-09.pasivo.translation::OptimizedTranslation::3767935011153409444::1767154191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-09.total.translation::OptimizedTranslation::2616742678959050288::1767154191::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-59.activo.translation::OptimizedTranslation::7026032934605101150::1767159073::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-59.csv::Translation::8507507965603555424::1767157152::1767159073::1::::<><><>0<>0<>03ec78f2e82c8280db37aadba8168632<>res://runs/run_31-12-25_01-59.event.translation<*>res://runs/run_31-12-25_01-59.activo.translation<*>res://runs/run_31-12-25_01-59.pasivo.translation<*>res://runs/run_31-12-25_01-59.total.translation<*>res://runs/run_31-12-25_01-59.dominante.translation::[m
[32m+[m[32mrun_31-12-25_01-59.dominante.translation::OptimizedTranslation::1517506390569755017::1767159073::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-59.event.translation::OptimizedTranslation::3111679364927089153::1767159073::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-59.json::JSON::-1::1767157152::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-59.pasivo.translation::OptimizedTranslation::687416804610117134::1767159073::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_01-59.total.translation::OptimizedTranslation::5817426979243176381::1767159073::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-08.activo.translation::OptimizedTranslation::6450537929575755061::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-08.csv::Translation::2303029040270798263::1767161292::1767161675::1::::<><><>0<>0<>0f773eacd10e0188c50e8e5ca17c955d<>res://runs/run_31-12-25_03-08.event.translation<*>res://runs/run_31-12-25_03-08.activo.translation<*>res://runs/run_31-12-25_03-08.pasivo.translation<*>res://runs/run_31-12-25_03-08.total.translation<*>res://runs/run_31-12-25_03-08.dominante.translation::[m
[32m+[m[32mrun_31-12-25_03-08.dominante.translation::OptimizedTranslation::4365305048281879856::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-08.event.translation::OptimizedTranslation::8933499659381844568::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-08.json::JSON::-1::1767161292::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-08.pasivo.translation::OptimizedTranslation::496311782668687422::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-08.total.translation::OptimizedTranslation::114258431330647409::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-11.activo.translation::OptimizedTranslation::7604283242126186431::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-11.csv::Translation::1374890907232064277::1767161504::1767161675::1::::<><><>0<>0<>b46e99ceaea8c1e5d558ceb9c5b62503<>res://runs/run_31-12-25_03-11.event.translation<*>res://runs/run_31-12-25_03-11.activo.translation<*>res://runs/run_31-12-25_03-11.pasivo.translation<*>res://runs/run_31-12-25_03-11.total.translation<*>res://runs/run_31-12-25_03-11.dominante.translation::[m
[32m+[m[32mrun_31-12-25_03-11.dominante.translation::OptimizedTranslation::3057918820575226086::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-11.event.translation::OptimizedTranslation::7602148360177238647::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-11.json::JSON::-1::1767161504::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-11.pasivo.translation::OptimizedTranslation::2095449942044375922::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_03-11.total.translation::OptimizedTranslation::8175588921302638759::1767161675::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-12.activo.translation::OptimizedTranslation::1003323915551266509::1767165210::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-12.csv::Translation::4322169815720478976::1767165136::1767165210::1::::<><><>0<>0<>ac40d4d007c043eec1ed2050ad701fef<>res://runs/run_31-12-25_04-12.event.translation<*>res://runs/run_31-12-25_04-12.activo.translation<*>res://runs/run_31-12-25_04-12.pasivo.translation<*>res://runs/run_31-12-25_04-12.total.translation<*>res://runs/run_31-12-25_04-12.dominante.translation::[m
[32m+[m[32mrun_31-12-25_04-12.dominante.translation::OptimizedTranslation::4225252585708967291::1767165210::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-12.event.translation::OptimizedTranslation::5148633908637441575::1767165210::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-12.json::JSON::-1::1767165136::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-12.pasivo.translation::OptimizedTranslation::8699770891517293564::1767165210::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-12.total.translation::OptimizedTranslation::3072229752608731619::1767165210::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-30.activo.translation::OptimizedTranslation::1386585077235812787::1767166366::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-30.csv::Translation::7580747159092822718::1767166259::1767166366::1::::<><><>0<>0<>f748b3ff285fcd3af45fc6f244c99d17<>res://runs/run_31-12-25_04-30.event.translation<*>res://runs/run_31-12-25_04-30.activo.translation<*>res://runs/run_31-12-25_04-30.pasivo.translation<*>res://runs/run_31-12-25_04-30.total.translation<*>res://runs/run_31-12-25_04-30.dominante.translation::[m
[32m+[m[32mrun_31-12-25_04-30.dominante.translation::OptimizedTranslation::8455215062842568386::1767166366::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-30.event.translation::OptimizedTranslation::8912463043916672588::1767166366::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-30.json::JSON::-1::1767166259::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-30.pasivo.translation::OptimizedTranslation::4228253299991404515::1767166366::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-30.total.translation::OptimizedTranslation::8467151616366750733::1767166366::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-43.activo.translation::OptimizedTranslation::5335576635216216557::1767167525::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-43.csv::Translation::8191543524178138373::1767167025::1767167525::1::::<><><>0<>0<>00fb16d18d7822341a911c3113887e21<>res://runs/run_31-12-25_04-43.event.translation<*>res://runs/run_31-12-25_04-43.activo.translation<*>res://runs/run_31-12-25_04-43.pasivo.translation<*>res://runs/run_31-12-25_04-43.total.translation<*>res://runs/run_31-12-25_04-43.dominante.translation::[m
[32m+[m[32mrun_31-12-25_04-43.dominante.translation::OptimizedTranslation::4956024011341833489::1767167525::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-43.event.translation::OptimizedTranslation::3061223439341691930::1767167525::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-43.json::JSON::-1::1767167025::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-43.pasivo.translation::OptimizedTranslation::8721712697053878135::1767167525::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-43.total.translation::OptimizedTranslation::7839245780062009522::1767167525::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-53.activo.translation::OptimizedTranslation::3808959571400618992::1767167985::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-53.csv::Translation::8936924081781261060::1767167589::1767167985::1::::<><><>0<>0<>e972440c13903fae82f0d9f008e7e4be<>res://runs/run_31-12-25_04-53.event.translation<*>res://runs/run_31-12-25_04-53.activo.translation<*>res://runs/run_31-12-25_04-53.pasivo.translation<*>res://runs/run_31-12-25_04-53.total.translation<*>res://runs/run_31-12-25_04-53.dominante.translation::[m
[32m+[m[32mrun_31-12-25_04-53.dominante.translation::OptimizedTranslation::3718735665197226432::1767167985::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-53.event.translation::OptimizedTranslation::5747353891064095622::1767167985::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-53.json::JSON::-1::1767167589::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-53.pasivo.translation::OptimizedTranslation::2366691290816476221::1767167985::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_04-53.total.translation::OptimizedTranslation::3759324769901991225::1767167985::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-01.activo.translation::OptimizedTranslation::369390005170284253::1767168503::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-01.csv::Translation::4953330488016321708::1767168108::1767168503::1::::<><><>0<>0<>f564f8940e429593cb3482925d3ee74a<>res://runs/run_31-12-25_05-01.event.translation<*>res://runs/run_31-12-25_05-01.activo.translation<*>res://runs/run_31-12-25_05-01.pasivo.translation<*>res://runs/run_31-12-25_05-01.total.translation<*>res://runs/run_31-12-25_05-01.dominante.translation::[m
[32m+[m[32mrun_31-12-25_05-01.dominante.translation::OptimizedTranslation::8326416273310885563::1767168503::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-01.event.translation::OptimizedTranslation::8977806969453093728::1767168503::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-01.json::JSON::-1::1767168108::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-01.pasivo.translation::OptimizedTranslation::6088721096551867332::1767168503::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-01.total.translation::OptimizedTranslation::6951689448384817956::1767168503::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-13.activo.translation::OptimizedTranslation::1628610986977858960::1767168944::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-13.csv::Translation::103739118346016384::1767168832::1767168945::1::::<><><>0<>0<>537bfb203adeab996bb9e2d0e5897ad4<>res://runs/run_31-12-25_05-13.event.translation<*>res://runs/run_31-12-25_05-13.activo.translation<*>res://runs/run_31-12-25_05-13.pasivo.translation<*>res://runs/run_31-12-25_05-13.total.translation<*>res://runs/run_31-12-25_05-13.dominante.translation::[m
[32m+[m[32mrun_31-12-25_05-13.dominante.translation::OptimizedTranslation::6648034416738362018::1767168945::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-13.event.translation::OptimizedTranslation::1997192564745849633::1767168944::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-13.json::JSON::-1::1767168832::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-13.pasivo.translation::OptimizedTranslation::2351110557121138320::1767168945::0::1::::<><><>0<>0<><>::[m
[32m+[m[32mrun_31-12-25_05-13.total.translation::OptimizedTranslation::6722024993119174941::1767168945::0::1::::<><><>0<>0<><>::[m
[32m+[m[32m::res://screens/::1766822126[m
[32m+[m[32mv0.2.1.png::CompressedTexture2D::4190600635964208180::1766615088::1766617132::1::::<><><>0<>0<>11a13d850da6f05a33e0467fa024569a<>res://.godot/imported/v0.2.1.png-89a6179c33da8c99d8ef42ffc7aca077.ctex::[m
[32m+[m[32mv0.2.2.png::CompressedTexture2D::9055056716685860181::1766621137::1766621149::1::::<><><>0<>0<>9da660d9a7d958416ddc0494961567ea<>res://.godot/imported/v0.2.2.png-f9d74542af0626b6ad91aae43b60202d.ctex::[m
[32m+[m[32mv0.5.1TheLab.png::CompressedTexture2D::6817490758953657653::1766805235::1766805252::1::::<><><>0<>0<>88b6cc1216f53fd7ab75f3bda7f28937<>res://.godot/imported/v0.5.1TheLab.png-51c54c3a32333169fafd2fcb81a3bec3.ctex::[m
[32m+[m[32mv0.6 simbologia.png::CompressedTexture2D::2344069700869151062::1766821894::1766822126::1::::<><><>0<>0<>71feacc2bfc132e50cbbcf8c68ffac27<>res://.godot/imported/v0.6 simbologia.png-0abc217a5209a58bb83aaa22389e2666.ctex::[m
[1mdiff --git a/.godot/editor/main.tscn-editstate-3070c538c03ee49b7677ff960a3f5195.cfg b/.godot/editor/main.tscn-editstate-3070c538c03ee49b7677ff960a3f5195.cfg[m
[1mindex 1781866..275b10e 100644[m
[1m--- a/.godot/editor/main.tscn-editstate-3070c538c03ee49b7677ff960a3f5195.cfg[m
[1m+++ b/.godot/editor/main.tscn-editstate-3070c538c03ee49b7677ff960a3f5195.cfg[m
[36m@@ -187,4 +187,4 @@[m [mAnim={[m
 "zfar": 4000.01,[m
 "znear": 0.05[m
 }[m
[31m-selected_nodes=Array[NodePath]([NodePath("/root/@EditorNode@21413/@Panel@14/@VBoxContainer@15/DockHSplitLeftL/DockHSplitLeftR/DockHSplitMain/@VBoxContainer@26/DockVSplitCenter/@VSplitContainer@62/@VBoxContainer@63/@EditorMainScreen@103/MainScreen/@CanvasItemEditor@10871/@VSplitContainer@10516/@HSplitContainer@10518/@HSplitContainer@10520/@Control@10521/@SubViewportContainer@10522/@SubViewport@10523/Main/UIRootContainer/ProductionPanel/CapitalProductivoPanel/UpgradeCognitiveButton")])[m
[32m+[m[32mselected_nodes=Array[NodePath]([NodePath("/root/@EditorNode@20438/@Panel@14/@VBoxContainer@15/DockHSplitLeftL/DockHSplitLeftR/DockHSplitMain/@VBoxContainer@26/DockVSplitCenter/@VSplitContainer@62/@VBoxContainer@63/@EditorMainScreen@103/MainScreen/@CanvasItemEditor@10871/@VSplitContainer@10516/@HSplitContainer@10518/@HSplitContainer@10520/@Control@10521/@SubViewportContainer@10522/@SubViewport@10523/Main/UIRootContainer/ProductionPanel/CapitalProductivoPanel/CognitiveMuLabel")])[m
[1mdiff --git a/.godot/editor/project_metadata.cfg b/.godot/editor/project_metadata.cfg[m
[1mindex 9bfb92a..e387fca 100644[m
[1m--- a/.godot/editor/project_metadata.cfg[m
[1m+++ b/.godot/editor/project_metadata.cfg[m
[36m@@ -6,7 +6,7 @@[m [mhide_selection=false[m
 [m
 [editor_metadata][m
 [m
[31m-executable_path="C:/Users/Recepción/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe"[m
[32m+[m[32mexecutable_path="C:/Users/nicol/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe"[m
 use_advanced_connections=false[m
 [m
 [dialog_bounds][m
[1mdiff --git a/.godot/editor/script_editor_cache.cfg b/.godot/editor/script_editor_cache.cfg[m
[1mindex 113f5f6..bf19359 100644[m
[1m--- a/.godot/editor/script_editor_cache.cfg[m
[1m+++ b/.godot/editor/script_editor_cache.cfg[m
[36m@@ -3,11 +3,11 @@[m
 state={[m
 "bookmarks": PackedInt32Array(),[m
 "breakpoints": PackedInt32Array(),[m
[31m-"column": 1,[m
[32m+[m[32m"column": 0,[m
 "folded_lines": Array[int]([]),[m
 "h_scroll_position": 0,[m
[31m-"row": 765,[m
[31m-"scroll_position": 757.0,[m
[32m+[m[32m"row": 770,[m
[32m+[m[32m"scroll_position": 761.0,[m
 "selection": false,[m
 "syntax_highlighter": "GDScript"[m
 }[m
[1mdiff --git a/.godot/uid_cache.bin b/.godot/uid_cache.bin[m
[1mindex 0b265f7..ae02b4b 100644[m
Binary files a/.godot/uid_cache.bin and b/.godot/uid_cache.bin differ
[1mdiff --git a/analyze_runs.py b/analyze_runs.py[m
[1mindex 01437a1..c78cb0a 100644[m
[1m--- a/analyze_runs.py[m
[1m+++ b/analyze_runs.py[m
[36m@@ -111,6 +111,7 @@[m [mdef analyze_structural_rankings(runs):[m
     print("\n📈 RANKING — Primer cruce Δ$ ≥ 100")[m
     for i, r in enumerate(sort_time(delta_100_times), 1):[m
         print(f"{i:02}) {r[0]}   {r[1]}   Δ$={r[2]}")[m
[32m+[m[41m    [m
 [m
 [m
 # ================= MAIN =================[m
[1mdiff --git a/main.gd b/main.gd[m
[1mindex 57a2c74..bff5093 100644[m
[1m--- a/main.gd[m
[1m+++ b/main.gd[m
[36m@@ -22,7 +22,7 @@[m [mvar click_multiplier: float = 1.0[m
 var click_multiplier_upgrade_cost: float = 200.0[m
 [m
 # Persistencia base estructural (c₀)[m
[31m-var persistence_base: float = 1.4[m
[32m+[m[32mvar persistence_base: float = 10.4[m
 # Estado dinámico observado (cₙ)[m
 var persistence_dynamic: float = 1.4[m
 [m
[36m@@ -69,10 +69,14 @@[m [mconst K_PERSISTENCE := 1.25[m
 # === CAPITAL COGNITIVO (μ) === v0.7[m
 var cognitive_level := 0[m
 var cognitive_mu := 1.0[m
[32m+[m[32mvar cognitive_cost: float = 15000.0[m
[32m+[m[32mvar cognitive_cost_scale: float = 1.45[m
 [m
[31m-const COGNITIVE_STEP_COST := 12000.0[m
[31m-const COGNITIVE_COST_SCALE := 1.6[m
[32m+[m[32mconst COGNITIVE_COST := 15000.0[m
[32m+[m[32mconst COGNITIVE_COST_SCALE := 1.45[m
 const COGNITIVE_MULTIPLIER := 0.05[m
[32m+[m[32m# μ dinámico observado[m
[32m+[m[32mvar mu_structural: float = 1.0[m
 [m
 [m
 # =============== SESIÓN / LAB MODE ===================[m
[36m@@ -151,21 +155,23 @@[m [mvar unlocked_delta_100 := false[m
 [m
 @onready var upgrade_cognitive_button = $UIRootContainer/ProductionPanel/CapitalProductivoPanel/UpgradeCognitiveButton[m
 [m
[32m+[m[32m@onready var cognitive_mu_label = $UIRootContainer/ProductionPanel/CapitalProductivoPanel/CognitiveMuLabel[m
[32m+[m
 # =====================================================[m
 #  CAPA 1 — MODELO ECONÓMICO[m
 # =====================================================[m
 [m
 func get_click_power() -> float:[m
[31m-	return click_value * click_multiplier * persistence_dynamic * get_cognitive_mu()[m
[32m+[m	[32mreturn click_value * click_multiplier * persistence_dynamic * get_mu_structural_factor()[m
 [m
 func get_auto_income_effective() -> float:[m
[31m-	return income_per_second * auto_multiplier * manual_specialization[m
[32m+[m	[32mreturn income_per_second * auto_multiplier * manual_specialization * get_mu_structural_factor()[m
 [m
 func get_trueque_raw() -> float:[m
 	return trueque_level * trueque_base_income * trueque_efficiency[m
 [m
 func get_trueque_income_effective() -> float:[m
[31m-	return get_trueque_raw() * trueque_network_multiplier[m
[32m+[m	[32mreturn get_trueque_raw() * trueque_network_multiplier * get_mu_structural_factor()[m
 [m
 [m
 func get_passive_total() -> float:[m
[36m@@ -174,6 +180,14 @@[m [mfunc get_passive_total() -> float:[m
 func get_delta_total() -> float:[m
 	return get_click_power() + get_passive_total()[m
 [m
[32m+[m[32mfunc get_mu_structural_factor(n: int = cognitive_level) -> float:[m
[32m+[m	[32m# μ = 1 + log(1+n) * 0.08[m
[32m+[m	[32m# Crece lento pero nunca se aplana del todo[m
[32m+[m	[32mif n <= 0:[m
[32m+[m		[32mreturn 1.0[m
[32m+[m
[32m+[m	[32mreturn 1.0 + log(1.0 + float(n)) * 0.08[m
[32m+[m
 [m
 # =====================================================[m
 #  CAPA 2 — ANÁLISIS MATEMÁTICO[m
[36m@@ -329,19 +343,26 @@[m [mfunc get_structural_state() -> String:[m
 func update_structural_hud_model_block() -> Dictionary:[m
 	return compute_structural_model()[m
 [m
[31m-# CAPITAL COGNITIVO[m
[31m-func _on_UpgradeCognitiveButton_pressed() -> void:[m
[31m-	if money < COGNITIVE_STEP_COST:[m
[32m+[m[32m# =====================================================[m
[32m+[m[32m#  CAPITAL COGNITIVO (μ) — v0.7[m
[32m+[m[32mfunc _on_UpgradeCognitiveButton_pressed():[m
[32m+[m	[32mif money < cognitive_cost:[m
 		return[m
 [m
[31m-	money -= COGNITIVE_STEP_COST[m
[32m+[m	[32mmoney -= cognitive_cost[m
 	cognitive_level += 1[m
[32m+[m	[32mcognitive_cost *= cognitive_cost_scale[m
[32m+[m
[32m+[m	[32mmu_structural = get_mu_structural_factor()[m
[32m+[m
[32m+[m	[32madd_lap("Upgrade estructural → Capital Cognitivo (μ ↑ nivel %d)" % cognitive_level)[m
 [m
[31m-	add_lap("Upgrade estructural → Capital Cognitivo (μ ↑ nivel " + str(cognitive_level) + ")")[m
 	structural_upgrades += 1[m
 [m
[32m+[m	[32mupdate_cognitive_button()[m
 	update_ui()[m
[31m-[m
[32m+[m[32mfunc update_cognitive_button():[m
[32m+[m	[32mupgrade_cognitive_button.text = "Capital Cognitivo (μ) (+1 nivel)\n" +  "Costo: $" + str(snapped(cognitive_cost, 0.01)) + "\n" + "μ = " + str(snapped(mu_structural, 0.01))[m
 # =====================================================[m
 #  LAP MARKERS[m
 # =====================================================[m
[36m@@ -354,7 +375,9 @@[m [mfunc add_lap(event: String) -> void:[m
 		"activo_ps": snapped(get_click_power() * CLICK_RATE, 0.01),[m
 		"pasivo_ps": snapped(get_passive_total(), 0.01),[m
 		"dominante": get_dominant_term(),[m
[31m-		"mu": get_cognitive_mu()[m
[32m+[m		[32m"mu": snapped(get_mu_structural_factor(), 0.01),[m
[32m+[m		[32m"mu_level": cognitive_level,[m
[32m+[m
 	})[m
 [m
 [m
[36m@@ -519,9 +542,6 @@[m [mfunc _on_ExportRunButton_pressed():[m
 	print("   CSV :", csv_path)[m
 	print("   📋 Copiada al portapapeles")[m
 [m
[31m-# === Clipboard ===[m
[31m-	DisplayServer.clipboard_set(_build_clipboard_text(meta))[m
[31m-[m
 	# === Feedback in-game ===[m
 	system_message_label.text = "Run exportada — %s %s\nGuardada en /runs" % [meta.fecha_humana, meta.hora_humana][m
 [m
[36m@@ -543,34 +563,19 @@[m [mfunc build_formula_text() -> String:[m
 		t += "  +  e · me"[m
 [m
 	t += "\n  cₙ = c₀ · k^(1 − 1/n)"[m
[31m-	t += "\n  μ = 1 + log(1 + nivel cognitivo) · 0.05"[m
[32m+[m	[32mt += "\n  μ = 1 + log(1 + nivel cognitivo) · 0.08"[m
 [m
 	return t[m
 [m
 [m
 func build_formula_values() -> String:[m
[31m-	var c0: float = snapped(persistence_base, 0.01)[m
[31m-	var fn: float = snapped(get_persistence_target(), 0.01)[m
[31m-	var cn: float = snapped(persistence_dynamic * get_cognitive_mu(), 0.01)[m
[31m-[m
[31m-	var t := "c₀ = %s   fⁿ = %s   cₙ = %s\n" % [c0, fn, cn][m
[31m-	t += "μ = %s   nivel = %d\n" % [snapped(cognitive_mu, 0.01), cognitive_level][m
[31m-	t += "= clicks × (%s × %s × %s × μ=%s)" % [snapped(click_value, 0.01), snapped(click_multiplier, 0.01), cn,[m
[31m-	snapped(cognitive_mu, 0.01)[m
[31m-	][m
[31m-[m
[31m-	if unlocked_d:[m
[31m-		t += "\n  +  %s/s × %s × %s" % [[m
[31m-			snapped(income_per_second, 0.01),[m
[31m-			snapped(auto_multiplier, 0.01),[m
[31m-			snapped(manual_specialization, 0.01)[m
[31m-		][m
[32m+[m	[32mvar c0 float:= snapped(persistence_base, 0.01)[m
[32m+[m	[32mvar fn float:= snapped(get_persistence_target(), 0.01)[m
[32m+[m	[32mvar cn float:= snapped(persistence_dynamic, 0.01)[m
[32m+[m	[32mvar mu float:= snapped(get_mu_structural_factor(), 0.01)[m
 [m
[31m-	if unlocked_e:[m
[31m-		t += "\n  +  %s/s × %s" % [[m
[31m-			snapped(get_trueque_raw(), 0.01),[m
[31m-			snapped(trueque_network_multiplier, 0.01)[m
[31m-		][m
[32m+[m	[32mvar t := "" t += "c₀ = %s   fⁿ = %s   cₙ = %s\n" % [c0, fn, cn][m
[32m+[m	[32mt += "μ = %s   nivel cognitivo = %d" % [mu, cognitive_level][m
 [m
 	return t[m
 [m
[36m@@ -749,7 +754,6 @@[m [mfunc _on_UpgradeTruequeNetworkButton_pressed():[m
 	add_lap("Desbloqueado me (Red de Intercambio)")[m
 	update_ui()[m
 [m
[31m-[m
 # =====================================================[m
 #  UI — SOLO LEE RESULTADOS (v0.6.3 — HUD científico)[m
 # =====================================================[m
[36m@@ -764,10 +768,11 @@[m [mfunc update_ui():[m
 	money_label.text = "Dinero: $" + str(round(money))[m
 	big_click_button.text = "PUSH\n(+" + str(snapped(get_click_power(), 0.01)) + ")"[m
 	system_achievements_label.text = "μ (Capital Cognitivo) = " + str(get_cognitive_mu()) + "\n" + "Nivel cognitivo = " + str(cognitive_level)[m
[31m-	cognitive_mu_label.text = "μ (Capital Cognitivo) = " + str(snapped(cognitive_mu, 0.01)) + "\n" + "Nivel cognitivo = " + str(cognitive_level)[m
[32m+[m	[32mcognitive_mu_label.text = "μ (Capital Cognitivo) = " + str(snapped(mu_structural, 0.01)) + "\nNivel cognitivo = " + str(cognitive_level)[m
 [m
 	formula_label.text = build_formula_text() + "\n" + build_formula_values()[m
 	marginal_label.text = build_marginal_contribution()[m
[32m+[m	[32mupdate_cognitive_button()[m
 [m
 [m
 	update_click_stats_panel()[m
[36m@@ -881,3 +886,6 @@[m [mfunc update_click_stats_panel() -> void:[m
 	upgrade_trueque_button.text = "Trueque (+1)\nCosto: $%s" % [str(round(trueque_cost))][m
 [m
 	upgrade_trueque_network_button.text = "Red de Intercambio (×%s)\nCosto: $%s" % [str(snapped(TRUEQUE_NETWORK_GAIN, 0.01)), str(round(trueque_network_upgrade_cost))][m
[32m+[m
[32m+[m	[32m# === BOTÓN CAPITAL COGNITIVO (μ) ===[m
[41m+	[m
[1mdiff --git a/main.tscn b/main.tscn[m
[1mindex 7246414..eee2ae9 100644[m
[1m--- a/main.tscn[m
[1m+++ b/main.tscn[m
[36m@@ -176,6 +176,9 @@[m [mtext = "Trueque ( +e /s )[m
 Costo: $X[m
 "[m
 [m
[32m+[m[32m[node name="CognitiveMuLabel" type="Label" parent="UIRootContainer/ProductionPanel/CapitalProductivoPanel"][m
[32m+[m[32mlayout_mode = 2[m
[32m+[m
 [node name="RightPanel" type="VBoxContainer" parent="UIRootContainer"][m
 custom_minimum_size = Vector2(0, 300)[m
 layout_mode = 2[m
[1mdiff --git a/runs/run_06-01-2026_20-01.csv b/runs/run_06-01-2026_20-01.csv[m
[1mnew file mode 100644[m
[1mindex 0000000..c9236db[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_20-01.csv[m
[36m@@ -0,0 +1,2 @@[m
[32m+[m[32mfecha;hora;tiempo_sesion;delta_total;dominio[m
[32m+[m[32m06/01/2026;20:01;Tiempo de sesión: 67:14;Δ$ estimado / s = +216.43;CLICK domina el sistema[m
[1mdiff --git a/runs/run_06-01-2026_20-01.csv.import b/runs/run_06-01-2026_20-01.csv.import[m
[1mnew file mode 100644[m
[1mindex 0000000..f4b5bf4[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_20-01.csv.import[m
[36m@@ -0,0 +1,15 @@[m
[32m+[m[32m[remap][m
[32m+[m
[32m+[m[32mimporter="csv_translation"[m
[32m+[m[32mtype="Translation"[m
[32m+[m[32muid="uid://3k4ec2fe6o03"[m
[32m+[m[32mvalid=false[m
[32m+[m
[32m+[m[32m[deps][m
[32m+[m
[32m+[m[32msource_file="res://runs/run_06-01-2026_20-01.csv"[m
[32m+[m
[32m+[m[32m[params][m
[32m+[m
[32m+[m[32mcompress=true[m
[32m+[m[32mdelimiter=0[m
[1mdiff --git a/runs/run_06-01-2026_20-01.json b/runs/run_06-01-2026_20-01.json[m
[1mnew file mode 100644[m
[1mindex 0000000..03610ac[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_20-01.json[m
[36m@@ -0,0 +1,12 @@[m
[32m+[m[32m{[m
[32m+[m	[32m"activo_vs_pasivo": "--- Activo vs Pasivo ---\nActivo (CLICK): 46.5%\nPasivo (d+e): 53.5%\nΔ$ activo / s = +100.72\nΔ$ pasivo / s = +115.7",[m
[32m+[m	[32m"delta_total_s": "Δ$ estimado / s = +216.43",[m
[32m+[m	[32m"distribucion_aporte": "--- Distribución de aporte (productores) ---\nClick: 46.5%\nTrabajo Manual: 18.6%\nTrueque: 34.9%",[m
[32m+[m	[32m"dominio": "CLICK domina el sistema",[m
[32m+[m	[32m"fecha": "06/01/2026",[m
[32m+[m	[32m"hora": "20:01",[m
[32m+[m	[32m"lap_markers": "--- Lap markers (historial) ---\n39:05 → Desbloqueado me (Red de Intercambio)\n55:50 → Desbloqueado e (Trueque)\n55:57 → Especialización de Oficio → x1.21\n56:02 → Especialización de Oficio → x1.33\n56:16 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 7)\n56:18 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 8)\n56:23 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 9)\n66:55 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 10)\n66:56 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 11)\n66:58 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 12)\n66:59 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 13)\n67:11 → Desbloqueado md (Ritmo de Trabajo)\n",[m
[32m+[m	[32m"produccion_jugador": "=== Producción activa ===\na = 21.0    Click base\nb = 2.13    Multiplicador\ncₙ(actual) = 1.99\n\nd = 15.0/s    Trabajo Manual\nmd = 2.01    Ritmo de Trabajo\nso = 1.33    Especialización de Oficio\n\ne = 48.0/s    Trueque corregido\nme = 1.57    Red de intercambio\n\n--- MODELO ESTRUCTURAL (teórico) ---\nfⁿ = 1.99\ncₙ(modelo) = 1.99\nε(modelo) = 0.0\n\nk = 1.25\nn = 45\n",[m
[32m+[m	[32m"tiempo_sesion": "Tiempo de sesión: 67:14",[m
[32m+[m	[32m"version": "0.6.3"[m
[32m+[m[32m}[m
\ No newline at end of file[m
[1mdiff --git a/runs/run_06-01-2026_20-46.csv b/runs/run_06-01-2026_20-46.csv[m
[1mnew file mode 100644[m
[1mindex 0000000..b305998[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_20-46.csv[m
[36m@@ -0,0 +1,2 @@[m
[32m+[m[32mfecha;hora;tiempo_sesion;delta_total;dominio[m
[32m+[m[32m06/01/2026;20:46;Tiempo de sesión: 111:51;Δ$ estimado / s = +297.21;Trueque domina el sistema[m
[1mdiff --git a/runs/run_06-01-2026_20-46.csv.import b/runs/run_06-01-2026_20-46.csv.import[m
[1mnew file mode 100644[m
[1mindex 0000000..6590bcd[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_20-46.csv.import[m
[36m@@ -0,0 +1,15 @@[m
[32m+[m[32m[remap][m
[32m+[m
[32m+[m[32mimporter="csv_translation"[m
[32m+[m[32mtype="Translation"[m
[32m+[m[32muid="uid://plkot1q8xqvg"[m
[32m+[m[32mvalid=false[m
[32m+[m
[32m+[m[32m[deps][m
[32m+[m
[32m+[m[32msource_file="res://runs/run_06-01-2026_20-46.csv"[m
[32m+[m
[32m+[m[32m[params][m
[32m+[m
[32m+[m[32mcompress=true[m
[32m+[m[32mdelimiter=0[m
[1mdiff --git a/runs/run_06-01-2026_20-46.json b/runs/run_06-01-2026_20-46.json[m
[1mnew file mode 100644[m
[1mindex 0000000..d799bc8[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_20-46.json[m
[36m@@ -0,0 +1,12 @@[m
[32m+[m[32m{[m
[32m+[m	[32m"activo_vs_pasivo": "--- Activo vs Pasivo ---\nActivo (CLICK): 35.9%\nPasivo (d+e): 64.1%\nΔ$ activo / s = +106.56\nΔ$ pasivo / s = +190.65",[m
[32m+[m	[32m"delta_total_s": "Δ$ estimado / s = +297.21",[m
[32m+[m	[32m"distribucion_aporte": "--- Distribución de aporte (productores) ---\nClick: 35.9%\nTrabajo Manual: 28.3%\nTrueque: 35.9%",[m
[32m+[m	[32m"dominio": "Trueque domina el sistema",[m
[32m+[m	[32m"fecha": "06/01/2026",[m
[32m+[m	[32m"hora": "20:46",[m
[32m+[m	[32m"lap_markers": "--- Lap markers (historial) ---\n99:22 → Especialización de Oficio → x1.46\n99:24 → Especialización de Oficio → x1.61\n99:27 → Especialización de Oficio → x1.77\n99:31 → Especialización de Oficio → x1.95\n111:29 → Desbloqueado me (Red de Intercambio)\n111:29 → Transición de dominio → Trueque domina el sistema\n111:35 → Desbloqueado md (Ritmo de Trabajo)\n111:36 → Desbloqueado d (Trabajo Manual)\n111:38 → Desbloqueado md (Ritmo de Trabajo)\n111:38 → Desbloqueado d (Trabajo Manual)\n111:41 → Desbloqueado md (Ritmo de Trabajo)\n111:42 → Desbloqueado d (Trabajo Manual)\n",[m
[32m+[m	[32m"produccion_jugador": "=== Producción activa ===\na = 22.0    Click base\nb = 2.13    Multiplicador\ncₙ(actual) = 1.99\n\nd = 18.0/s    Trabajo Manual\nmd = 2.4    Ritmo de Trabajo\nso = 1.95    Especialización de Oficio\n\ne = 54.0/s    Trueque corregido\nme = 1.97    Red de intercambio\n\n--- MODELO ESTRUCTURAL (teórico) ---\nfⁿ = 1.99\ncₙ(modelo) = 1.99\nε(modelo) = 0.0\n\nk = 1.25\nn = 56\n",[m
[32m+[m	[32m"tiempo_sesion": "Tiempo de sesión: 111:51",[m
[32m+[m	[32m"version": "0.6.3"[m
[32m+[m[32m}[m
\ No newline at end of file[m
[1mdiff --git a/runs/run_06-01-2026_23-57.csv b/runs/run_06-01-2026_23-57.csv[m
[1mnew file mode 100644[m
[1mindex 0000000..53e0ed2[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_23-57.csv[m
[36m@@ -0,0 +1,2 @@[m
[32m+[m[32mfecha;hora;tiempo_sesion;delta_total;dominio[m
[32m+[m[32m06/01/2026;23:57;Tiempo de sesión: 09:14;Δ$ estimado / s = +285.52;CLICK domina el sistema[m
[1mdiff --git a/runs/run_06-01-2026_23-57.csv.import b/runs/run_06-01-2026_23-57.csv.import[m
[1mnew file mode 100644[m
[1mindex 0000000..c191b60[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_23-57.csv.import[m
[36m@@ -0,0 +1,15 @@[m
[32m+[m[32m[remap][m
[32m+[m
[32m+[m[32mimporter="csv_translation"[m
[32m+[m[32mtype="Translation"[m
[32m+[m[32muid="uid://ljnlm2ic6mtc"[m
[32m+[m[32mvalid=false[m
[32m+[m
[32m+[m[32m[deps][m
[32m+[m
[32m+[m[32msource_file="res://runs/run_06-01-2026_23-57.csv"[m
[32m+[m
[32m+[m[32m[params][m
[32m+[m
[32m+[m[32mcompress=true[m
[32m+[m[32mdelimiter=0[m
[1mdiff --git a/runs/run_06-01-2026_23-57.json b/runs/run_06-01-2026_23-57.json[m
[1mnew file mode 100644[m
[1mindex 0000000..bf3b2ab[m
[1m--- /dev/null[m
[1m+++ b/runs/run_06-01-2026_23-57.json[m
[36m@@ -0,0 +1,12 @@[m
[32m+[m[32m{[m
[32m+[m	[32m"activo_vs_pasivo": "--- Activo vs Pasivo ---\nActivo (CLICK): 40.8%\nPasivo (d+e): 59.2%\nΔ$ activo / s = +116.41\nΔ$ pasivo / s = +169.11",[m
[32m+[m	[32m"delta_total_s": "Δ$ estimado / s = +285.52",[m
[32m+[m	[32m"distribucion_aporte": "--- Distribución de aporte (productores) ---\nClick: 40.8%\nTrabajo Manual: 25.1%\nTrueque: 34.1%",[m
[32m+[m	[32m"dominio": "CLICK domina el sistema",[m
[32m+[m	[32m"fecha": "06/01/2026",[m
[32m+[m	[32m"hora": "23:57",[m
[32m+[m	[32m"lap_markers": "--- Lap markers (historial) ---\n05:54 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 6)\n06:34 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 7)\n06:57 → Desbloqueado e (Trueque)\n06:57 → Desbloqueado e (Trueque)\n07:01 → Desbloqueado me (Red de Intercambio)\n07:09 → Desbloqueado me (Red de Intercambio)\n07:24 → Desbloqueado md (Ritmo de Trabajo)\n07:24 → Desbloqueado d (Trabajo Manual)\n07:26 → Desbloqueado md (Ritmo de Trabajo)\n07:26 → Desbloqueado md (Ritmo de Trabajo)\n08:30 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 8)\n08:35 → Upgrade estructural → Persistencia (baseline elevado)\n",[m
[32m+[m	[32m"produccion_jugador": "=== Producción activa ===\na = 22.0    Click base\nb = 2.26    Multiplicador\ncₙ(actual) = 1.99\n\nd = 17.0/s    Trabajo Manual\nmd = 2.69    Ritmo de Trabajo\nso = 1.33    Especialización de Oficio\n\ne = 42.0/s    Trueque corregido\nme = 1.97    Red de intercambio\n\n--- MODELO ESTRUCTURAL (teórico) ---\nfⁿ = 1.99\ncₙ(modelo) = 1.99\nε(modelo) = 0.0\n\nk = 1.25\nn = 47\n",[m
[32m+[m	[32m"tiempo_sesion": "Tiempo de sesión: 09:14",[m
[32m+[m	[32m"version": "0.6.3"[m
[32m+[m[32m}[m
\ No newline at end of file[m
[1mdiff --git a/runs/run_07-01-2026_00-11.csv b/runs/run_07-01-2026_00-11.csv[m
[1mnew file mode 100644[m
[1mindex 0000000..fb629c3[m
[1m--- /dev/null[m
[1m+++ b/runs/run_07-01-2026_00-11.csv[m
[36m@@ -0,0 +1,2 @@[m
[32m+[m[32mfecha;hora;tiempo_sesion;delta_total;dominio[m
[32m+[m[32m07/01/2026;00:11;Tiempo de sesión: 05:38;Δ$ estimado / s = +262.95;CLICK domina el sistema[m
[1mdiff --git a/runs/run_07-01-2026_00-11.csv.import b/runs/run_07-01-2026_00-11.csv.import[m
[1mnew file mode 100644[m
[1mindex 0000000..ab9bcf6[m
[1m--- /dev/null[m
[1m+++ b/runs/run_07-01-2026_00-11.csv.import[m
[36m@@ -0,0 +1,15 @@[m
[32m+[m[32m[remap][m
[32m+[m
[32m+[m[32mimporter="csv_translation"[m
[32m+[m[32mtype="Translation"[m
[32m+[m[32muid="uid://cc04tg7umyvkj"[m
[32m+[m[32mvalid=false[m
[32m+[m
[32m+[m[32m[deps][m
[32m+[m
[32m+[m[32msource_file="res://runs/run_07-01-2026_00-11.csv"[m
[32m+[m
[32m+[m[32m[params][m
[32m+[m
[32m+[m[32mcompress=true[m
[32m+[m[32mdelimiter=0[m
[1mdiff --git a/runs/run_07-01-2026_00-11.json b/runs/run_07-01-2026_00-11.json[m
[1mnew file mode 100644[m
[1mindex 0000000..9a69e6e[m
[1m--- /dev/null[m
[1m+++ b/runs/run_07-01-2026_00-11.json[m
[36m@@ -0,0 +1,12 @@[m
[32m+[m[32m{[m
[32m+[m	[32m"activo_vs_pasivo": "--- Activo vs Pasivo ---\nActivo (CLICK): 43.0%\nPasivo (d+e): 57.0%\nΔ$ activo / s = +113.12\nΔ$ pasivo / s = +149.83",[m
[32m+[m	[32m"delta_total_s": "Δ$ estimado / s = +262.95",[m
[32m+[m	[32m"distribucion_aporte": "--- Distribución de aporte (productores) ---\nClick: 43.0%\nTrabajo Manual: 20.9%\nTrueque: 36.0%",[m
[32m+[m	[32m"dominio": "CLICK domina el sistema",[m
[32m+[m	[32m"fecha": "07/01/2026",[m
[32m+[m	[32m"hora": "00:11",[m
[32m+[m	[32m"lap_markers": "--- Lap markers (historial) ---\n03:45 → Desbloqueado me (Red de Intercambio)\n03:57 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 3)\n04:18 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 4)\n04:27 → Upgrade estructural → Capital Cognitivo (μ ↑ nivel 5)\n04:34 → Desbloqueado e (Trueque)\n04:37 → Desbloqueado e (Trueque)\n04:43 → Desbloqueado me (Red de Intercambio)\n05:08 → Desbloqueado me (Red de Intercambio)\n05:09 → Desbloqueado e (Trueque)\n05:11 → Upgrade estructural → Persistencia (baseline elevado)\n05:11 → Desbloqueado md (Ritmo de Trabajo)\n05:19 → Desbloqueado d (Trabajo Manual)\n",[m
[32m+[m	[32m"produccion_jugador": "=== Producción activa ===\na = 22.0    Click base\nb = 2.26    Multiplicador\ncₙ(actual) = 1.99\n\nd = 16.0/s    Trabajo Manual\nmd = 2.26    Ritmo de Trabajo\nso = 1.33    Especialización de Oficio\n\ne = 42.0/s    Trueque corregido\nme = 1.97    Red de intercambio\n\n--- MODELO ESTRUCTURAL (teórico) ---\nfⁿ = 1.99\ncₙ(modelo) = 1.99\nε(modelo) = 0.0\n\nk = 1.25\nn = 40\n",[m
[32m+[m	[32m"tiempo_sesion": "Tiempo de sesión: 05:38",[m
[32m+[m	[32m"version": "0.6.3"[m
[32m+[m[32m}[m
\ No newline at end of file[m
