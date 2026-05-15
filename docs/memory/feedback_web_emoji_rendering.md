---
name: Web emoji rendering — solución completa para export HTML5
description: Sistema EmojiToRichText con Twemoji PNGs locales + BMP_SYMBOLS para web export de Godot 4. Patrones de uso y lista de caracteres problemáticos.
type: feedback
originSessionId: 466eb176-ee39-4659-bfa2-d26cf1a91cd7
---
## Sistema EmojiToRichText (res://EmojiToRichText.gd — autoload)

Godot 4 web export usa un subset de Noto Sans que NO cubre:
- Geometric Shapes (U+25A0-U+25FF): ▲▼▶●■□▪▫
- Arrows (U+2190-U+21FF): →↑↓
- Box Drawings (U+2500-U+257F): ─═──
- Block Elements (U+2580-U+259F): █▓░
- Misc Symbols (U+2600-U+26FF): ☠☣⚖ (sin FE0F), ★✦◈
- Enclosed Alphanumerics (U+2460-U+24FF): ①②...
- Subscripts/Superscripts (U+2070-U+209F): ₀ₙⁿ

Solución implementada en `EmojiToRichText.gd`:
- `EMOJI_TO_FILE`: dict emoji → codepoint PNG local en `res://emoji/`
- `BMP_SYMBOLS`: dict símbolo BMP → sustituto ASCII
- `rich(text)`: para RichTextLabel — reemplaza emoji con `[img=16]res://emoji/XXXX.png[/img]` y BMP symbols con ASCII. Solo actúa en web.
- `strip(text)`: para Label/Button — elimina emoji (→ "") y reemplaza BMP symbols. Solo actúa en web.

**Why:** Godot web WASM no soporta fuentes color (CBDT/COLRv1). El subset de Noto Sans incluido no cubre los bloques Unicode listados. Desktop funciona por fallback del OS.

## Reglas de uso

### Para RichTextLabel con BBCode:
```gdscript
label.clear()
label.append_text(EmojiToRichText.rich(texto_con_bbcode))
```
NUNCA usar `label.text = texto` directamente si el texto tiene emoji o BMP symbols.

### Para Label / Button:
```gdscript
label.text = EmojiToRichText.strip("texto con emoji o ▼▶")
```

### Textos hardcodeados en .tscn:
- Labels con emoji: dejar `text = ""` y asignar en código via `strip()`
- Labels que necesitan mostrar emoji como imagen: convertir a RichTextLabel + asignar via `rich()`
- Buttons con emoji: asignar en `_ready()` o cuando se actualiza via `strip()`

## Archivos modificados en la sesión v0.9.11 web fix

- `EmojiToRichText.gd`: EMOJI_TO_FILE (55 PNGs) + BMP_SYMBOLS (▲▼▶●→✓✗★✦◈═─█▓░ c₀ cₙ fⁿ)
- `main.gd`: formula_label, sys_active_passive_label, sys_breakdown_label, click_stats_label, institution_panel_label, epsilon_sticky_label, Desc labels del EvoChoicePanel — todos via rich()/strip()
- `UIManager.gd`: toggle buttons via strip(); tier headers `-- Tier X --` (era `── Tier X ──`)
- `MainMenu.gd`: achievements_label via rich(); nav badges, trascendencia UI, rutas buttons via strip()
- `LegacyManager.gd/MainMenu.gd`: gate_status Label via strip()
- `UpgradeButton.gd`: ✓ ADQUIRIDO via strip()
- `main.tscn`: MoneyIcon `$`, toggle buttons ASCII, c₀→c0, `→`→`->`, Icon labels vaciados

## Patrones frecuentes a revisar en código nuevo

1. Cualquier `label.text = "..."` con emoji o ▲▼●→ en un Label/Button: wrappear con `strip()`
2. Cualquier `rich_label.text = "..."` con esos chars en un RichTextLabel: cambiar a `clear()` + `append_text(rich(...))`
3. Textos de escena (.tscn) con emoji en Labels: vaciar y asignar en código
4. Strings de lapso (`add_lap(...)`) que contengan BMP symbols: van a LapLogLabel via `rich()` automáticamente
5. `⚠` SIN variation selector FE0F (U+26A0 solo) no matchea `"⚠️"` en EMOJI_TO_FILE — reemplazar directamente con `[!]` en el string

## Descarga de PNGs Twemoji

Script: `download_emoji.ps1` en raíz del proyecto.
CDN: `https://cdnjs.cloudflare.com/ajax/libs/twemoji/14.0.2/72x72/`
Los emoji con variation selector FE0F (☠️=2620-fe0f) → bajar versión base (2620.png).
Carpeta destino: `res://emoji/` = `C:\Users\nicol\Desktop\idleantigravity\emoji\`
