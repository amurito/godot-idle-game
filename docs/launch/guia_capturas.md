# Guía de capturas — assets de lanzamiento

Para HYPHAE: genesis en itch.io. Plan general en memoria `launch_plan_hyphae_genesis.md`.

## Setup de captura (hacer una vez)

- **Capturá desde un build release** (export Windows o el web de onrender), **no del editor** — así no aparece el `DebugPanel` (barra Input/2D/3D/●) ni el tag `(DEBUG)` en la ventana.
- **Fullscreen 1920×1080.** Si capturás ventaneado, fijate que sea 16:9 limpio.
- **Fuente accesibilidad en Normal** (no 115/130%) para que la densidad de info se vea como el diseño base.
- **Capturá cada toma en ES y EN** (toggle en Settings). itch.io permite varias imágenes; al menos el hero y 1-2 más conviene tenerlas en ambos idiomas.
- Naming sugerido: `hyphae_01_hero_es.png`, `hyphae_01_hero_en.png`, etc.

---

## Las 6 screenshots

### 1. HERO — reactor en producción (cover + primera screenshot)
- **Estado:** run activa, reactor en estado lindo (producción normal con gradiente/bloom, NO el rojo plano de Dark Metabolism). Header con chips activos (click×, pas×, Ω, PL×) y $/s visible.
- **Encuadre:** reactor centrado-izquierda + header arriba. Que se vea el número de producción grande saltando.
- **Para el cover 630×500:** recortá alrededor del reactor + un par de chips. Es la imagen que más se ve, que sea la más vistosa.
- **Variante:** sacá una con reactor 2D y otra con 3D (toggle en Settings) y elegimos.

### 2. PROFUNDIDAD — sistema en pleno (estilo tu captura, pero limpia)
- **Estado:** Dark Metabolism o una ruta avanzada activa, con la **fórmula Λ** visible (modo Lab, tecla L), genoma, efectos mutacionales y el **log de eventos** a la derecha.
- **Por qué:** vende la complejidad real del juego. Es tu captura actual recapturada sin debug.
- **Encuadre:** pantalla completa, que se lea la fórmula y los logros (59/71).

### 3. BIFURCACIÓN — panel de mutaciones
- **Estado:** momento de elegir mutación, con el panel "Genoma Fúngico + Próxima Mutación" abierto y una ruta en bifurcación.
- **Encuadre:** centrado en el panel de rutas/mutaciones con sus íconos temáticos.

### 4. BANCO GENÉTICO — prestige
- **Estado:** Banco Genético abierto, con buffs comprados (★ visibles) y Puntos de Legado.
- **Por qué:** muestra la capa de prestige permanente.

### 5. ÁRBOL DE EVOLUCIONES (HTML → PNG) ✦
- **No es captura del juego.** Abrí `docs/arbol_evoluciones.html` en Chrome/Firefox a ≥1100px de ancho y sacá un **full-page screenshot**:
  - Chrome: DevTools (F12) → Ctrl+Shift+P → "Capture full size screenshot".
  - Firefox: clic derecho → "Tomar captura de pantalla" → "Guardar la página completa".
- Esperá ~1s a que el JS dibuje las líneas SVG antes de capturar.
- Ya tiene branding actualizado + leyenda de familias. Es el asset que mejor comunica la profundidad de un vistazo.

### 6. LOGRO LEGENDARIO — toast
- **Estado:** disparar un logro tier legendario para capturar el toast "★ LOGRO LEGENDARIO" en pantalla.
- Timing: el toast dura ~4.5s antes del fade. Capturá apenas aparece.

---

## GIF principal (3–6 seg, <5MB, loop limpio)

**Guion:** el bucle core en 4 beats, ~5 segundos:
1. (0–1s) Click manual → el número de producción salta sobre el reactor.
2. (1–2s) $/s sube en el header.
3. (2–3s) Primera compra de upgrade → el botón se actualiza, producción escala.
4. (3–5s) El contador acelera solo (pasivo) → reactor pulsa más fuerte.

**Tips:**
- Grabá a 1280×720 para mantener el peso bajo; recortá a la zona reactor+header+upgrades.
- Loop seamless: que el último frame conecte con el primero (volvé a un estado visual similar al inicio).
- Herramientas: ScreenToGif (Windows) para grabar+optimizar, o grabás mp4 y convertís con gifski/ezgif. Apuntá <5MB (itch.io).

**GIF secundario (opcional):** animación de trascendencia + reset visual (el overlay de primera trascendencia con su mensaje).

---

## Checklist de pre-captura

- [ ] Build release (sin DebugPanel ni "(DEBUG)")
- [ ] Ventana 1920×1080
- [ ] Probada en ES y EN
- [ ] Reactor en estado vistoso para el hero (no rojo plano)
- [ ] Árbol HTML exportado a PNG (con líneas dibujadas)
- [ ] GIF <5MB, loop limpio
