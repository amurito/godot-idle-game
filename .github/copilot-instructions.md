# AI Coding Instructions for IDLE — Observatorio fⁿ

## Project Overview
IDLE is a Godot-based idle/incremental game that exposes the mathematical structure of an economic simulation system. Unlike traditional idle games, it prioritizes transparency and observation over hidden progression. The game models economic growth as Δ$ = clicks × (a × b × cₙ × μ) + d × md × so + e × me, where terms progressively unlock and dominance shifts between click, manual work, and trade.

## Architecture
- **main.gd**: Core game logic, economic model, UI updates, run exports. Contains layered architecture: economic base, mathematical analysis, structural fⁿ model, dynamic persistence convergence.
- **version.gd**: Version management and build info.
- **producer_item.gd**: Legacy UI component (unused in current version).
- **analyze_runs.py / script.py**: Python scripts for analyzing exported run data, generating rankings for structural milestones.
- **runs/**: Directory containing exported JSON/CSV run data with timestamps, lap markers, and system state.

## Key Patterns
- **Progressive Unlocking**: Formula terms (d, md, e, me) unlock via upgrades, revealing more of the symbolic formula. Use `unlocked_*` booleans and `structural_upgrades` counter.
- **Dynamic Persistence**: `persistence_dynamic` lerps toward `get_persistence_target()` using sigmoid `f_n_alpha(n)`. Never reduce `persistence_dynamic` below baseline.
- **Lap Markers**: Log significant events (upgrades, dominance transitions) in `lap_events` array with timestamps.
- **Scientific HUD**: `update_click_stats_panel()` builds detailed variable display. All values snapped to 0.01 precision.
- **Run Exports**: JSON with full state, CSV summary, clipboard text. Exported to `res://runs/` with timestamp filenames.

## Workflows
- **Testing Changes**: Run game in Godot editor, observe system behavior in lab mode. Export runs via "Export Run" button, analyze with `python analyze_runs.py`.
- **Adding Upgrades**: Follow pattern in upgrade handlers (e.g., `_on_UpgradeClickButton_pressed`): check cost, deduct money, modify variable, scale cost, increment `structural_upgrades`, add lap marker, call `update_ui()`.
- **UI Updates**: All labels updated in `update_ui()`. Use `snapped(value, 0.01)` for display. Formula text built dynamically based on unlocks.
- **Mathematical Extensions**: New terms should integrate into `get_delta_total()`, `get_contribution_breakdown()`, and symbolic formula display.

## Conventions
- Variables prefixed by component: `click_*`, `auto_*`, `trueque_*`, `cognitive_*`.
- Constants in ALL_CAPS with descriptive names (e.g., `AUTO_MULTIPLIER_GAIN := 1.06`).
- Functions layered: economic (get_*_power), analysis (get_dominant_term), UI (build_*_text).
- Time formatted as MM:SS, money rounded, deltas snapped.
- Structural upgrades affect `n` parameter, influencing persistence via `pow(K_PERSISTENCE, (1.0 - 1.0 / n))`.

## Dependencies
- Godot 4.5+ for game engine.
- Python 3+ for analysis scripts (uses pathlib, json, re).
- No external libraries; pure GDScript and standard Python.

## Validation
After changes, run game and verify:
- Formula displays correctly with unlocks.
- Dominance transitions logged.
- Exported runs parseable by Python scripts.
- Persistence converges smoothly without overshoot.