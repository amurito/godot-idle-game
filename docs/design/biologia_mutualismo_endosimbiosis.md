# Biología: Mutualismo → Holobionte y Endosimbiosis

> Spec para revisión del autor (2026-10-16). Llena el hueco de la franja Biología del árbol
> (`docs/roadmaps/pendientes_2026-10.md` A1). Se desbloquea en **T1** (estructura por T decidida el
> 2026-10-16). Los números son la primera propuesta: se calibran con bot antes de darlos por buenos
> (lección de R3: proponer → simular → ajustar).

---

## 1. Dónde estamos

| Ruta | Cómo entra | Qué hace | Cómo cierra | PL |
|---|---|---|---|---|
| **Simbiosis** | contabilidad ≥ 1, hifas ≥ 5, Ω ≥ 0.40 con click dominante | click ×2.5, pasivo ×0.5 | botón SELLAR a los 60 s, o solo tras 300 s en banda (ε 0.12–0.55, Ω > 0.30) | 4 |
| **Parasitismo** | 120 s sin clickear con biomasa > 3 (o Masa Crítica / estancamiento) | pasivo ×1.2, corrosión y drenaje de plata | biomasa ≥ 25, o bancarrota, o colapso de Ω (vive 13–20 s) | 2 |

Las dos terminan en la columna 1. Parasitismo sólo sirve de puerta al Depredador (`last_run`);
Simbiosis no lleva a nada. Ya existen dos pistas de que el juego "quería" un cruce: el legado
**Simbiosis Agresiva** (cerrar las dos → ×1.15 híbrido) y las transmutaciones Coro / Huésped (T3).

## 2. Principio: un verbo nuevo por ruta

Verbos ya usados, para no repetir:

| Verbo | Ruta |
|---|---|
| clickear sin parar | Hiperasimilación |
| mantener ε en banda | Homeostasis y sus tiers |
| empujar / regar / cargar | Red Micelial (colonización, primordio, panspermia) |
| ráfaga + sumidero | Fusión |
| clickear a tiempo | Coro |
| asignar recursos a nodos | Micelio Omnisciente |
| mantener el hambre en banda | Huésped Soberano |
| no clickear | Ayuno |

Propuesta:

| Ruta | Verbo | En una frase |
|---|---|---|
| **Mutualismo** | **negociar** | el socio te hace ofertas; aceptás o rechazás, y la cuenta tiene que quedar pareja |
| **Holobionte** | **sostener un ecosistema** | cuatro socios piden estilos de juego que se contradicen; los tenés que mantener vivos a la vez |
| **Endosimbiosis** | **dosificar** | le vas sacando genes al parásito que tragaste: ni tan rápido que te rechace, ni tan lento que se escape |

## 3. El árbol de Biología

```
            ┌── Simbiosis ──► Mutualismo ──► Holobionte        (tiers en la misma run, como el Orden)
Biología ───┤        ▲
            │        │ (engullir)
            └── Parasitismo ───► Endosimbiosis                  (cruce: last_run Parasitismo + Simbiosis)
```

- **Simbiosis → Mutualismo → Holobionte**: tiers dentro de la misma run, como Homeostasis → Allostasis →
  Homeorresis. Cada tier tiene su botón de sello; seguir de largo es la apuesta.
- **Endosimbiosis**: cruce, con la misma puerta que el Depredador. Si la run anterior cerró en Parasitismo y
  esta entra a Simbiosis, el parásito vuelve y la célula puede **tragárselo**.
- Más adelante: **Redención de la Biología** (después de Holobionte / Endosimbiosis), y las Sombras
  Autarquía (anti-Simbiosis) y Autosuficiencia (anti-Parasitismo) en T4.

---

## 4. MUTUALISMO — negociar

> Lore: la micorriza. El hongo le da fósforo a la raíz; la raíz le paga con azúcar. Si uno toma de más,
> el otro corta el trato.

### 4.1 Entrada
- T ≥ 1, Simbiosis activa y run ≥ 60 s (cuando aparece hoy el botón SELLAR SIMBIOSIS).
- El primer socio, la **Raíz**, propone el pacto con un botón **ACEPTAR PACTO** junto al de sellar
  Simbiosis. Aceptar = entrar a Mutualismo. Desde ahí se apaga el auto-cierre de Simbiosis a los 300 s.
- Con la llave de Coro (T3): el botón [T] sólo aparece mientras no aceptaste el pacto. Aceptarlo
  descarta la transmutación en esa run, y transmutar descarta el Mutualismo (son excluyentes, igual que hoy).

### 4.2 Las ofertas
Cada **25 s** el socio hace una oferta; hay **10 s** para decidir con dos botones,
**[A] Aceptar** y **[R] Rechazar** (con teclas). Todo se mide en **segundos de ingreso**, así no
depende de la escala de la run.

| Oferta | Si aceptás | Reciprocidad R | Confianza |
|---|---|---|---|
| **Intercambio** | das 15 s de ingreso; recibís ×1.5 al ingreso durante 30 s | 0 | +1 |
| **Préstamo** | recibís 20 s de ingreso ya; a los 40 s el socio cobra 25 s. Si no tenés la plata: incumplimiento | −20, después +25 | +1 si pagás, −3 si no |
| **Auxilio** (el socio está en sequía) | das 20 s sin nada a cambio; a los 60 s te devuelve 30 s ("gratitud") | +20, después −30 | +2 |
| **Tentación** | tomás 40 s de su reserva, gratis | −40 | −4 |

- **Reciprocidad R** = lo que diste menos lo que recibiste, en segundos de ingreso. **Banda justa: |R| ≤ 30.**
- Rechazar no cuesta nada, salvo **3 rechazos seguidos**: el socio se ofende (−1 de confianza).
  Rechazar la Tentación no cuenta como rechazo.
- Mezcla de ofertas: 40 % Intercambio, 25 % Préstamo, 20 % Auxilio, 15 % Tentación. Nunca dos
  Tentaciones seguidas.

### 4.3 Sello y fracasos
- **SELLAR MUTUALISMO** (+6 PL): confianza ≥ 6 y |R| ≤ 30 en el momento de sellar.
- **Abusaste** (R ≤ −60): el socio te deja y la run **cierra como PARASITISMO**, con el texto "el socio se
  volvió presa". Es un puente con la otra mitad de la Biología: la avaricia te convierte en parásito.
- **Te explotaron** (R ≥ +60): el socio se lleva más de lo que da y la run cierra como **SIMBIOSIS**
  (4 PL, sin bonus NG+).
- Duración esperada: sello de Mutualismo hacia los **6–8 min** (≈ 12–16 ofertas).

### 4.3b Implementado (B1, 2026-10-16) · `MutualismoLogic.gd`
Cambios contra la propuesta, por calibración con bot:
- **Pago parcial**: si no te alcanza, das lo que tengas; el retorno del Intercambio y la gratitud del Auxilio
  (1.5× lo dado) se calculan sobre lo pagado de verdad. Exigir el monto entero dejaba afuera a quien gasta
  todo en mejoras (la mitad de las ofertas quedaban inaceptables).
- **Sello con confianza 8** (no 6): con 6 se sellaba en ~3 min de pacto.
- Ofertas en secuencia fija (sin RNG): Intercambio, Préstamo, Intercambio, Auxilio, Tentación, … (como los antojos de Huésped).
- Teclas [A] / [R]. El pacto bloquea el botón [T] de Coro (excluyentes).

| Perfil (`tests/sim/Scenarios.gd`) | Resultado | Tiempo en Mutualismo |
|---|---|---|
| `t1_mutualismo_fair` (rechaza Tentaciones, cuida \|R\|) | MUTUALISMO a 640 s | 5.7 min |
| `t1_mutualismo_naive` (acepta todo menos Tentación) | MUTUALISMO a 790 s, roza la ruptura (R −60) | 8.2 min |
| `t1_mutualismo_greedy` (acepta todo) | rompe → PARASITISMO a 475 s | 3 min |

Pendiente para B4: legado Micorriza y logros.

### 4.4 Por qué no es Huésped otra vez
Huésped es un medidor que baja solo y se mantiene en banda. Acá no hay nada que se mueva solo:
cada oferta es una **decisión discreta** con costo ahora y retorno después. La tensión es leer el
tipo de oferta y la plata que vas a tener cuando el socio cobre.

---

## 5. HOLOBIONTE — sostener un ecosistema

> Lore: ningún organismo es uno solo. El holobionte es el hongo más todo lo que vive en él.

### 5.1 Entrada
Desde Mutualismo con confianza ≥ 6. En vez de sellar, la Raíz **presenta a sus socios**: van
apareciendo tres socios nuevos, cada uno con su oferta de entrada (una cada 45 s). Al aceptar los tres
(4 socios contando la Raíz) empieza el Holobionte. Las ofertas de §4.2 siguen corriendo, más espaciadas
(cada 40 s).

### 5.2 Los cuatro socios
Cada socio tiene **salud 0–100**. Mientras su necesidad se cumple, cura +1/s; mientras no, pierde −2/s.
Las necesidades **se contradicen a propósito**:

| Socio | Necesita | Da mientras está vivo |
|---|---|---|
| **Raíz** (planta) | pasivo ≥ 50 % del ingreso total | pasivo ×1.5 |
| **Bacteria** (fijadora) | ≥ 1 click/s de promedio en los últimos 10 s | click ×1.5 |
| **Alga** (fotobionte) | ε ≤ 0.30 (luz estable) | Ω +0.10 |
| **Levadura** | comprar una mejora cada 60 s (que circule la plata) | mejoras −10 % |

- Raíz contra Bacteria: el pasivo tiene que ganar, pero hay que seguir clickeando.
- Bacteria contra Alga: clickear sube ε.
- Levadura contra todos: gastar frena el pasivo que pide la Raíz.

Un socio que llega a 0 **muere**: perdés su bonus y 3 de confianza, y lo podés volver a sumar con su
oferta de entrada a los 60 s.

### 5.3 Sello
- **SELLAR HOLOBIONTE** (+8 PL): los **4 socios con salud ≥ 70 durante 90 s seguidos**. Se muestra
  como una barra de "coherencia" (el mínimo de las cuatro saludes).
- Duración esperada: **14–18 min** en total.

### 5.3b Implementado (B2, 2026-10-16) · `HolobionteLogic.gd`
Cambios contra la propuesta, por calibración con bot:
- **Raíz: pasivo ≥ 1/3** (no 50 %): Simbiosis deja el ingreso ~75 % activo; comprando sólo pasivo el bot llega a ~37 %.
- **Gratitud del Auxilio**: en la reciprocidad salda lo dado (el 0.5× extra es premio). Contarla entera hacía
  derivar R −10 por ciclo y en runs largas terminaba en traición sin que el jugador hiciera nada malo.
- **Colapso**: 5 muertes desarman el ecosistema → la run cierra como MUTUALISMO (sin esto quien no atiende quedaba trabado).
- Los socios llegan como ofertas del sistema de Mutualismo ("Nuevo socio: X", [A] para sumarlo); las ofertas de la Raíz siguen cada 40 s.
- Entrada: PRESENTAR SOCIOS aparece cuando el pacto es sellable (confianza 8, |R| ≤ 30) y T ≥ 2.

| Perfil | Resultado |
|---|---|
| `t2_holobionte_care` (compra pasivo si la Raíz lo pide, clickea medido según ε) | HOLOBIONTE a 1197 s (entra a 640: ~9 min de ecosistema; la Raíz muere 2 veces al principio) |
| `t2_holobionte_careless` (compra lo más barato, 4 cps) | el Alga muere en loop → colapso → MUTUALISMO a 1335 s |

### 5.4 Panel
Cuatro mini barras con el ícono de cada socio y su necesidad en una línea ("Bacteria: 0.6/1 cps ▼").
El núcleo late con un color por socio en rotación; un socio en peligro parpadea.

---

## 6. ENDOSIMBIOSIS — dosificar (cruce Parasitismo × Simbiosis)

> Lore: hace dos mil millones de años una célula se tragó una bacteria y no la pudo digerir. La
> bacteria se quedó. Hoy se llama mitocondria.

### 6.1 Entrada
- T ≥ 1, `last_run == PARASITISMO` (o Huésped Soberano) y la run actual **entra a Simbiosis**.
- A los 30 s de Simbiosis aparece el parásito de la run anterior, con un botón **ENGULLIR** que dura
  20 s. Si lo apretás entrás a Endosimbiosis; si no, seguís en Simbiosis normal (y en T1+, con Mutualismo
  disponible). Endosimbiosis y Mutualismo son excluyentes en la run.
- Alternativa (ver §9.3): que entre sola si te quedás AFK durante Simbiosis, porque el parásito llega
  como siempre pero la célula lo traga. Es más orgánico, pero cuesta descubrirlo y se dispara sin querer.

### 6.2 Dos economías
- **Núcleo**: tu plata, como siempre. Sigue la Simbiosis (click ×2.5, pasivo ×0.5).
- **Endosimbionte**: produce **ATP**, una moneda propia. ATP/s = 10 % de tu pasivo × (autonomía / 100).
  Cuanto más libre está, más produce. También drena un poco de plata (un parasitismo suave: 25 % del drenaje
  normal).
- Botón **[F] Alimentar**: convierte un 5 % de la plata en ATP (para cuando la autonomía ya es baja y el ATP
  no alcanza). Es la frontera entre las dos economías.

### 6.3 Los genes
El endosimbionte tiene **6 genes**. **Transferir** uno cuesta ATP (escala ×1.6 por gen) y te da
su función para el resto de la run:

| # | Gen | Efecto al transferirlo |
|---|---|---|
| 1 | Respiración | pasivo ×1.5 (compensa el ×0.5 de Simbiosis) |
| 2 | Membrana | se apaga el drenaje de plata del endosimbionte |
| 3 | Replicación | click ×1.5 |
| 4 | Señalización | Ω +0.10 |
| 5 | Metabolismo | mejoras −15 % |
| 6 | **Genoma** | requiere los otros 5: el endosimbionte pasa a **orgánulo** → se habilita el sello |

### 6.4 La tensión: rechazo contra escape
Dos medidores opuestos:
- **Rechazo** (0–100): cada transferencia suma +25 y baja −1/s. **Al llegar a 100, la célula lo expulsa** y la
  run cierra como **PARASITISMO**. No podés transferir más rápido que uno cada ~25 s sostenido.
- **Autonomía** (empieza en 60): sube +0.5/s y cada transferencia la baja −20. **Al llegar a 100, se escapa**:
  se activa Parasitismo pleno (drenaje y corrosión de verdad, y cierra como Parasitismo). Tampoco podés
  transferir más lento que uno cada ~40 s.

La ventana de ritmo queda entre ~25 y ~40 s por gen. Además, cada gen baja la autonomía y con ella el
ATP, así que los últimos genes cuestan más y entran más lento: hay que meter **[F] Alimentar** en el momento justo.
- **SELLAR ENDOSIMBIOSIS** (+8 PL): los 6 genes transferidos. Duración esperada **10–13 min**.

### 6.5 Por qué no es Coro
Coro es reflejo (±0.20 s sobre un metrónomo). Acá el ritmo es de decisiones cada medio minuto, con dos
riesgos opuestos a la vista y una segunda moneda que administrar.

---

## 7. Recompensas

### 7.1 PL y NG+
| Ruta | PL base | NG cap |
|---|---|---|
| Simbiosis | 4 (igual) | 6 |
| Mutualismo | 6 | 6 |
| Holobionte | 8 | 8 |
| Endosimbiosis | 8 | 8 |

(Referencia: Allostasis 4, Homeorresis 8, transmutaciones 9.)

### 7.2 Legados (Banco Genético, familia Biología)
Siguen la regla de los legados de ruta: tienen que servir también **fuera** de la Biología.

| Legado | Se gana | Efecto (propuesta) |
|---|---|---|
| **Micorriza** | sellar Mutualismo | +10 % pasivo en todas las runs |
| **Microbioma** | sellar Holobionte | shocks de Homeostasis y corrosión parasitaria −25 % |
| **Mitocondria** | sellar Endosimbiosis | +15 % click y pasivo mientras ε < 0.30 |

**Simbiosis Agresiva** (híbrido ×1.15 al cerrar las dos) queda como precursora de la Endosimbiosis. Su texto
puede insinuarla ("dos rutas contrarias dejan un híbrido…").

### 7.3 Logros (3 por ruta, 1 MYTHIC)
| Ruta | Logro | Condición |
|---|---|---|
| Mutualismo | Comercio Justo | sellar con \|R\| ≤ 5 |
| Mutualismo | Buen Pagador | pagar 5 préstamos en una run |
| Mutualismo | **Sin Tentación** (MYTHIC) | sellar habiendo rechazado todas las Tentaciones y sin incumplir |
| Holobionte | Ecosistema | sellar Holobionte |
| Holobionte | Todos a Bordo | tener los 4 socios ≥ 90 de salud a la vez |
| Holobionte | **Nadie Muere** (MYTHIC) | sellar sin que muera ningún socio |
| Endosimbiosis | Mitocondria | sellar Endosimbiosis |
| Endosimbiosis | Contrarreloj | transferir los 6 genes en < 4 min desde ENGULLIR |
| Endosimbiosis | **Huésped Perfecto** (MYTHIC) | sellar sin que el rechazo pase de 50 |

### 7.4 Colores (medidos contra la paleta 2026-10-16, todos con ΔE ≥ 20)
Gama Biología naranja → rosa:

| Ruta | Color | Vecino más cercano |
|---|---|---|
| Mutualismo | `#ffc2a8` durazno | Seta (21.5) |
| Holobionte | `#e8578f` frambuesa | Simbiosis (23.2) |
| Endosimbiosis | `#ff9a5c` mandarina (mitad naranja de parásito, mitad rosa de socio) | Seta (24.3) |

Sellados = el color vivo apagado (fallback actual de `get_reactor_color()`), salvo que haga falta uno propio.

---

## 8. Plan de implementación

| Paso | Qué | Archivos principales |
|---|---|---|
| B1 | **Mutualismo**: `MutualismoLogic.gd` (ofertas, R, confianza), botones A/R, panel, entrada desde Simbiosis, sellos y fracasos | MutualismoLogic (nuevo), EvoManager, RunManager.check_symbiosis_final, NGPlusButtonManager, UITextBuilders, Balance, SaveSchema |
| B2 | **Holobionte**: 4 socios con salud, coherencia, sello | MutualismoLogic (o HolobionteLogic), IncomeModifiers |
| B3 | **Endosimbiosis**: `EndosimbiosisLogic.gd` (ATP, genes, rechazo/autonomía), ENGULLIR, [F] | EndosimbiosisLogic (nuevo), EvoManager, IncomeModifiers, EconomyManager |
| B4 | Legados, logros, Codex ES/EN, colores, PL/NG caps, gating T1 | LegacyDefs, AchievementDefs, CodexDefs, LocaleManager, UIManager, Balance |
| B5 | Bot: perfiles `bio_mutualismo`, `bio_holobionte`, `bio_endosimbiosis` (+ MYTHIC), goldens de trayectoria | tests/sim/*, run_golden.ps1 |

Cada paso con CI verde antes del siguiente. Calibración con bot igual que R3–R6 (con/sin el recurso
clave, MYTHIC no lo saca el bot normal).

---

## 9. Decisiones del autor (2026-10-16)

1. **Mutualismo = negociar ofertas** ✅.
2. Abusar del socio (R ≤ −60) **cierra como PARASITISMO** ✅.
3. Entrada a Endosimbiosis con el **botón ENGULLIR** (`last_run` Parasitismo o Huésped) ✅.
4. Holobionte con **4 socios** (Raíz, Bacteria, Alga, Levadura) ✅.
5. Gating: **Mutualismo en T1; Holobionte y Endosimbiosis en T2** (junto al árbol oscuro) ✅.
6. **Simbiosis Agresiva queda como está** ✅.

---

## Nota al margen (auditoría de legados)
`LegacyDefs.resonancia_simbionte` tiene la clave `"effect"` **duplicada** (`simbiosis_click_biomasa_scale`
y `start_biomasa`): en un Dictionary gana la segunda. El efecto real se lee por id en
`IncomeModifiers.gd:204`, así que hoy funciona, pero el def miente. Entra en el reordenamiento del Banco
Genético (B2 de pendientes).
