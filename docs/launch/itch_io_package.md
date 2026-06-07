# Paquete de publicación itch.io — HYPHAE: genesis

Todo listo para copiar/pegar al crear la página. Versión: v1.0.0.10 "génesis".

---

## 1. Título y tagline

- **Título del proyecto:** `HYPHAE: genesis`
- **Tagline / short description** (campo "Short description or tagline", ~140 chars):
  - **ES:** `Idle de evolución fúngica: generá energía, sobreviví al estrés estructural y trascendé el ciclo para desbloquear rutas de mutación únicas.`
  - **EN:** `A fungal-evolution idle: generate energy, survive structural stress, and transcend the cycle to unlock unique mutation routes.`

---

## 2. Descripción larga (campo principal de la página)

> itch.io permite formato rico. Pegá la versión ES y EN una debajo de la otra (es bilingüe el juego). Los `**` son negritas; ajustá con el editor visual de itch si hace falta.

### Intro "cómo jugar" (pegar ARRIBA de todo, antes del pitch)

**ES:**
```
▶ Cómo se juega
Clickeá el reactor para generar energía y comprá mejoras para automatizar la producción.
A medida que crecés, el estrés estructural (ε) sube: mantenelo bajo control con mejoras
estructurales o el sistema colapsa. Cuando estés listo, trascendé el ciclo para reiniciar
con buffs permanentes y desbloquear rutas de mutación que cambian las reglas del juego.

Una partida hasta la primera trascendencia toma ~15-20 min. Después, la cosa se pone rara.

🖱 Controles: Mouse para clickear y comprar · teclas 1-9 compra rápida · B biosfera · L modo lab.
```

**EN:**
```
▶ How to play
Click the reactor to generate energy and buy upgrades to automate production.
As you grow, structural stress (ε) rises: keep it in check with structural upgrades or the
system collapses. When you're ready, transcend the cycle to restart with permanent buffs and
unlock mutation routes that change the rules of the game.

A run to your first transcendence takes ~15-20 min. After that, things get weird.

🖱 Controls: Mouse to click and buy · keys 1-9 for quick buy · B biosphere · L lab mode.
```

### ES

```
HYPHAE: genesis es un idle/incremental donde gestionás un organismo en evolución.
Generá energía, sobreviví al estrés estructural (ε) y trascendé el ciclo biótico
para desbloquear rutas de mutación que reescriben el loop.

No es solo "comprar mejoras y esperar": cada ruta cambia cómo se juega.

✦ 10 mutaciones con máquina de estados — cada decisión transforma el loop
✦ Prestige multi-capa: Banco Genético (Puntos de Legado) + Banco Cósmico (Esencia)
✦ Métricas estructurales reales (ε estrés, Ω estabilidad) que reflejan el sistema
✦ Finales y rutas distintas: Homeostasis, Simbiosis, Metabolismo Oscuro, Singularidad…
✦ Rutas post-trascendencia que cambian las reglas: Vacío Hambriento, Carnaval, Reencarnación
✦ Reactor visual 2D/3D con zoom
✦ Bilingüe ES/EN · Guardado export/import (.json)

Optimizado para PC (escritorio/laptop). Mobile en el roadmap.
Gratis. Se juega en el navegador o se descarga para Windows.
```

### EN

```
HYPHAE: genesis is an idle/incremental where you manage an evolving organism.
Generate energy, survive structural stress (ε), and transcend the biotic cycle
to unlock mutation routes that rewrite the loop.

It's not just "buy upgrades and wait": each route changes how you play.

✦ 10 mutations driven by a state machine — every choice reshapes the loop
✦ Multi-layer prestige: Genetic Bank (Legacy Points) + Cosmic Bank (Essence)
✦ Real structural metrics (ε stress, Ω stability) reflecting the system state
✦ Distinct endings & routes: Homeostasis, Symbiosis, Dark Metabolism, Singularity…
✦ Post-transcendence routes that change the rules: Hungry Void, Carnival, Reincarnation
✦ Visual 2D/3D reactor with zoom
✦ Bilingual EN/ES · Save export/import (.json)

Optimized for desktop/laptop PC. Mobile on the roadmap.
Free. Play in the browser or download for Windows.
```

---

## 3. Tags (máx 10 en itch.io)

```
idle, incremental, clicker, simulation, evolution, biology, godot, prestige, singleplayer, atmospheric
```
(Alternativas si querés rotar: `dark`, `experimental`, `numbers`, `management`.)

---

## 4. Metadatos de la página

| Campo | Valor |
|---|---|
| Kind of project | **HTML** (para que el juego se juegue embebido) |
| Pricing | **No payments / Free** (opcional: activar "donations" con monto sugerido) |
| Uploads | 1) build web (.zip exportado) marcado **"This file will be played in the browser"** · 2) `HYPHAE-genesis-v1.0.0.10-win.zip` (el .exe + pck) marcado para Windows |
| Embed options | **Manually set size: 1280 × 720** · ✅ Mobile friendly **OFF** (desktop-first) · ✅ **Fullscreen button** ON · ✅ "Enable scrollbars" OFF · "Automatically start on page load" a gusto (recomendado OFF para que el audio web arranque con el primer click) |
| Genre | Simulation |
| Tools/Engine | Godot |
| Inputs | Mouse, Keyboard |
| Average session | A few minutes / Long (idle) |
| Languages | Spanish, English |
| Accessibility | Configurable colors, High-contrast, Reduce-motion, Font scaling (mencionarlo: tenés un panel de accesibilidad real) |

> Nota embed: el viewport base es 1600×900 con stretch `canvas_items/expand`, así que el embed 16:9 escala bien. El **botón de fullscreen** es clave para que en pantallas chicas el jugador pueda agrandar.

---

## 5. Assets a subir

| Asset | Archivo | Uso |
|---|---|---|
| Cover 630×500 | `Pictures/Screenshots/hyphae_cover_v3_630x500.png` | Imagen de portada |
| Screenshot — bifurcación | `…003526.png` (panel MUTACIÓN DETECTADA) | Screenshot 1 |
| Screenshot — banco genético | `…003603.png` | Screenshot 2 |
| Screenshot — trascendencia/menú | `…004625.png` | Screenshot 3 |
| Screenshot — SIMBIOSIS (juego completo) | `…002530.png` | Screenshot 4 |
| Screenshot — árbol de evoluciones | `docs/arbol_evoluciones.png` | Screenshot 5 |
| (opcional) GIF principal | a grabar (ScreenToGif, <5MB) | Animación destacada |

---

## 6. Checklist de subida (Día 0)

- [ ] Re-export final del build web + correr `fix_web_export.ps1`
- [ ] Re-export del .exe Windows (zip con .exe + .pck)
- [ ] Crear proyecto en itch.io · Kind = HTML · Free
- [ ] Subir build web (.zip) → marcar "played in the browser" · subir .exe (.zip) para Windows
- [ ] Embed 1280×720 · fullscreen ON · mobile OFF
- [ ] Pegar tagline + descripción (ES + EN)
- [ ] Cargar cover + 5 screenshots (+ GIF si está)
- [ ] Tags
- [ ] Probar el embed en Chrome, Firefox y Edge
- [ ] Test en incógnito/caché limpia (primer jugador) — que el audio arranque al primer click
- [ ] Publicar (visibility: Public)

---

## 7. Drafts de Reddit

### r/incremental_games (post principal — Día 0, viernes/sábado UTC tarde)

**Título:**
```
HYPHAE: genesis — an idle with 10 mutation FSMs, multi-layer prestige & structural-stress mechanics [browser/free]
```

Hi all! I released HYPHAE: genesis a week ago — a free idle/incremental built in Godot 4, just updated to v1.0.1.
You manage an evolving fungal organism: generate energy, keep structural stress (ε) and stability (Ω) in check, and transcend the cycle to unlock mutation routes that actually change how the loop plays — not just bigger numbers.
- 10 mutations driven by a state machine; each reshapes the run
- Multi-layer prestige (Genetic Bank + Cosmic Bank)
- Distinct endings (Symbiosis, Dark Metabolism, Singularity…) + 3 post-transcendence routes that rewrite the rules (Hungry Void, Carnival of Mutations, Reincarnation)
- v1.0.1: Dark Sclerotium (dark endgame extension) + Mycelial Network rework — one mutation, now five distinct ways to end the run
- Bilingual EN/ES, accessibility options, save slots
Browser + Windows, free: [https://amurito.itch.io/hyphae-genesis]
First incremental I've shipped — feedback very welcome, especially on early pacing and which routes land best. Thanks for taking a look!

*(Reemplazá `[LINK itch.io]`. Insertá el GIF en el cuerpo. Leé las reglas del sub antes de postear — algunos exigen tag de plataforma.)*

### r/godot (cross-post — Día +2, ángulo técnico)

**Título:**
```
HYPHAE: genesis — idle game in Godot 4: 2D/3D reactor, mutation FSMs, Twemoji web fix [free]
```

**Cuerpo:**
```
Released my Godot 4 idle game HYPHAE: genesis (browser + Windows, free).

A few Godot-specific things that were fun/painful:
- 2D/3D reactor toggle (SubViewport sync, dynamic camera)
- Web (HTML5) export: getting color emojis to render via a Twemoji-PNG system,
  and fixing audio bus routing for Chrome
- Architecture split into singleton "managers" (run, economy, upgrades, legacy, saves)

Link + screenshots: [LINK itch.io]
Happy to answer anything about the implementation.
```

---

## 8. Reglas de oro (recordatorio del plan)
- No hotfix en caliente el día 0 — esperá 24h, juntá feedback, fix consolidado.
- Respondé TODO comentario, corto y agradecido. No pidas upvotes.
- Espaciá los subs: r/incremental_games día 0, r/godot día +2, r/WebGames día +5.
- Sé honesto con "desktop-first, mobile en roadmap".
