# HYPHAE: genesis

> *An idle/incremental game about structural stress, mutation, and transcendence.*

**[Play in browser (itch.io)](https://amurito.itch.io/hyphae-genesis)** &nbsp;·&nbsp; **[Latest release](https://github.com/amurito/godot-idle-game/releases/latest)**

---

## What is this?

HYPHAE: genesis is a free idle/incremental game where you manage an evolving organism under structural pressure. Generate energy, survive **structural stress (ε)**, and transcend the biotic cycle to unlock unique mutation routes.

Each transcendence unlocks more depth — the game changes qualitatively, not just numerically.

---

## Features

- **10 mutations with FSM** — Homeostasis, Allostasis, Homeorhesis, Mycelial Network, Symbiosis, Parasitism, Hyperassimilation, Sporulation, Predator, Dark Metabolism. Each changes the loop, not just the numbers.
- **Structural metrics** — ε (epsilon) and Ω (omega) reflect your system's real state. Manage stress or collapse.
- **Multi-layer prestige** — Genetic Bank (41 permanent buffs) + Cosmic Bank (11 items) + NG+ routes with qualitative differences
- **Biosphere** — hyphae / biomass / nutrients / mycelium bars that feed back into your economy
- **71 achievements** across Mythic / Ancestral / Rare / Common tiers
- **Visual reactor** — 2D animated core with particle system + optional 3D SubViewport mode
- **Save export/import** — full `.json` save portability between desktop and browser
- **Bilingual** — ES / EN with live locale switch in Settings
- **Accessibility** — font scale (85–130%), reduce motion, high contrast, colorblind modes (Deuteranopia, Protanopia, Tritanopia)

---

## How to play

### Browser (recommended)

Play directly at **[amurito.itch.io/hyphae-genesis](https://amurito.itch.io/hyphae-genesis)** — no install needed.

> Optimized for desktop/laptop PC. Mouse + keyboard. Mobile is not currently supported.

### Windows (.exe)

Download the latest `.zip` from the [releases page](https://github.com/amurito/godot-idle-game/releases/latest) and run `HYPHAE genesis.exe` directly — no installer.

---

## Build from source

**Requirements:** [Godot 4.5](https://godotengine.org/download) (GL Compatibility renderer)

```bash
git clone https://github.com/amurito/godot-idle-game.git
cd godot-idle-game
# Open project.godot in the Godot 4.5 editor
```

### Web export

```bash
# 1. Export from Godot editor → builds/web/  (preset "Web")
# 2. Run post-export patch (required):
fix_web_export.bat
# 3. Serve builds/web/ with any static server, e.g.:
#    python -m http.server 8080 --directory builds/web
```

The `.bat` patches `index.html` for correct canvas resize policy and injects the audio unlock JS required by browsers. See `fix_web_export.ps1` for implementation details.

### Desktop export

Export directly from the Godot editor → `builds/win/`. No post-processing needed.

---

## Project structure

```
idleantigravity/
├── main.gd                   # Scene orchestrator (~1550 LOC)
├── main.tscn                 # Main game scene
├── MainMenu.gd / .tscn       # Menus, prestige UI, save slots
│
├── Balance.gd                # All balance constants (autoload #1)
├── RunManager.gd             # Run lifecycle — start, tick, close
├── EconomyManager.gd         # Production, costs, economy ticks
├── UpgradeManager.gd         # Upgrade definitions + purchase state
├── LegacyManager.gd          # Prestige / legacy between runs
├── SaveManager.gd            # Serialize / deserialize + migration
├── SlotManager.gd            # Multiple save slots (3 slots)
├── AchievementManager.gd     # 71 achievements, 4 tiers
├── EvoManager.gd             # Mutation FSM (10 mutations)
├── BiosphereEngine.gd        # Hyphae / biomass / nutrient simulation
├── StructuralModel.gd        # ε and Ω structural model
├── UIManager.gd              # UI refresh, formula, lab mode
├── AudioManager.gd           # SFX pool, music, web audio unlock
├── LocaleManager.gd          # i18n ES/EN
├── AccessibilityManager.gd   # Font scale, contrast, reactor mode
├── TutorialManager.gd        # Tutorial + milestone toasts
├── LogManager.gd             # Run history (FIFO cap)
│
├── EmojiToRichText.gd        # Twemoji PNG system for web export
├── ReactorVisual.gd          # 2D animated reactor (particles + ADD blend)
├── version.gd                # Version string (computed property)
│
├── emoji/                    # Twemoji PNGs (55 files, 72×72)
├── builds/web/               # HTML5 export output
├── builds/win/               # Windows export output
├── fix_web_export.bat        # Web post-export patch entry point
├── fix_web_export.ps1        # Web post-export patch logic
└── docs/                     # Design docs, roadmaps
```

---

## Architecture notes

**Autoload order** — defined in `project.godot`, order matters:
`Balance → SaveManager → SlotManager → LegacyManager → RunManager → EconomyManager → UpgradeManager → StructuralModel → EvoManager → BiosphereEngine → AchievementManager → LogManager → UIManager → AudioManager → LocaleManager → AccessibilityManager → TutorialManager`

**`main.gd` is a scene orchestrator** — logic lives in managers. Never put systems in main.

**Web emoji rendering** via `EmojiToRichText`:
- `rich(text)` — for RichTextLabel (replaces emoji with `[img]` Twemoji PNGs)
- `strip(text)` — for Label/Button (replaces with ASCII equivalents)
- `set_icon_texture(rect, emoji)` — for TextureRect icons
- Only active on `OS.get_name() == "Web"`; desktop pass-through

**Audio** — buses defined statically in `default_bus_layout.tres`. Never create buses at runtime (breaks web audio routing).

**Save migrations** — new persistent fields always go through `SaveManager.serialize/deserialize`. Use `data.get("field", default)` for backward compat.

---

## Roadmap

| Version | Content | Status |
|---------|---------|--------|
| v1.0.0 "Génesis" | First stable release | ✅ 2026-05-15 |
| v1.0.0.10 "génesis" | Web audio fix, Twemoji complete, compact UI, full EN i18n, rename to HYPHAE: genesis | ✅ 2026-05-26 |
| v1.1 (planned) | AI Observer, mobile-friendly layouts | Roadmap |

---

## Credits

**Design & Development:** Nicolás Maure  
**Engine:** [Godot 4.5](https://godotengine.org) — GL Compatibility renderer  
**Emoji:** [Twemoji](https://twemoji.twitter.com/) by Twitter, Inc. — [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

---

## License

Source code is available for reference. Not licensed for redistribution or commercial use without permission.  
Game content (art, audio, design, balance): © 2026 Nicolás Maure — All rights reserved.
