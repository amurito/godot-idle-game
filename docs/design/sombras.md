# Sombras (A → anti-A)

> Spec para revisión del autor (2026-10-17). Completa la fila de Sombras de la grilla de involución
> (`involucion_transmutaciones.md` §4 y §6) y suma dos ideas del autor: una rama **procariota** y una con
> **lore matemático**. Estructura por T decidida: las Sombras se abren en **T4** (Ayuno incluido).
> Los números son una primera propuesta: se calibran con bot (proponer → simular → ajustar).

---

## 1. Reglas de la familia

- **Llave** permanente en el Banco Genético (sin toggle), 20 PL, tras cerrar la ruta base.
- **Disparador espejo, de CONDUCTA**: la Sombra entra sola cuando jugás *lo opuesto* de la base. No hay botón.
  Lección de Ayuno: el espejo *literal* de los números era inalcanzable (el "activo %" no mide si clickeás);
  el espejo tiene que medir **qué hace el jugador**, con un **aviso de 10 s** que lo deja evitar.
- **Recompensa = un sistema o visibilidad nueva**, nunca sólo ×N. Es el contraste con la Transmutación,
  que da poder.
- **Fracaso → vuelve a la base** (misma regla que las transmutaciones, 2026-10-17).
- **Las rutas de segundo nivel también pueden tener Sombra** (decisión 2026-10-17): Procariota es la Sombra
  de Endosimbiosis, que es un cruce.

## 2. La grilla

| Base | Sombra | Verbo | Sistema nuevo | Estado |
|---|---|---|---|---|
| Hiperasimilación | **Ayuno Primordial** | renunciar a clickear | Silencio | ✅ |
| Homeostasis | **Inestabilidad Consciente** | observar | OBSERVAR: leer la propia ecuación (lore matemático) | ✅ (§9) |
| Endosimbiosis | **Procariota** | dividirse | población por fisión binaria + plásmidos | ✅ (§10) |
| Simbiosis | **Antibiosis** *(ex Autarquía)* | competir | rivales + antibióticos con resistencia | spec |
| Parasitismo | **Autosuficiencia** | cultivar | mejoras hechas con biomasa, sin mercado | spec |
| Red Micelial | **Hifa Pionera** *(ex Núcleo Aislado)* | explorar | mapa del sustrato, avance sin ramificar | spec |

Orden sugerido: **Inestabilidad Consciente** primero (engancha con los 3 legados de conocimiento del Banco
que hoy no hacen nada: le dan sentido), después **Procariota**, **Antibiosis**, **Autosuficiencia** y
**Hifa Pionera**.

---

## 3. INESTABILIDAD CONSCIENTE — anti-Homeostasis · lore matemático

> El hongo deja de reducir ε y empieza a **medirlo**. Descubre que es una ecuación, y que mirarla la cambia.

**Lore.** El juego ya muestra su matemática: ε, Ω, μ y `∫$ = [clicks · a · b · cₙ …] · μ · Λ`. Esta
Sombra la convierte en el juego mismo. Referencias para textos y Codex:
- **Lyapunov**: Homeostasis es *estabilidad de Lyapunov* (toda perturbación vuelve al equilibrio). Su opuesto
  es un **exponente de Lyapunov positivo**: perturbaciones que crecen (caos).
- **Efecto del observador / Heisenberg**: medir una variable la perturba.
- Final: **Q.E.D.** — el hongo demuestra el teorema de su propia existencia.

**Espejo.** Homeostasis es mantener ε en banda baja. Inestabilidad: **ε ≥ 0.60 sostenido 60 s sin entrar
en Hiperasimilación** (con Contabilidad ≥ 1, para que no sea el caos del principio de la run). Aviso 10 s antes.

**Mecánica — OBSERVAR.**
- Los coeficientes de la fórmula aparecen **ocultos** (`a = ?`, `b = ?`, `μ = ?`, …). **[Q] OBSERVAR** revela
  uno, pero **mirar perturba**: cada observación suma ε (+0.15). Con ε > 1.2 la ecuación se rompe (fracaso).
- **Lemas**: el panel propone lemas sobre la ecuación que el jugador tiene que *demostrar* jugando, por
  ejemplo "μ · Λ ≥ 3 durante 30 s" o "el término pasivo supera al click con ε > 0.8". Para saber qué mover
  hay que haber observado los coeficientes de ese lema. Un lema demostrado deja el coeficiente **fijo y
  visible** el resto de la run.
- **[W] Integrar**: gasta plata para bajar ε 0.2 (cooldown 30 s). Es la única forma de recuperarse de
  observar demasiado.
- **Sello — Q.E.D.**: 5 lemas demostrados.
- **Fracaso**: ε > 1.2 durante 10 s (la ecuación diverge) → cierra como HOMEOSTASIS.

**Recompensa (visibilidad, nunca ×N).** Los 3 legados de conocimiento del Banco que hoy no hacen nada pasan
a ser la recompensa (o se habilitan al sellar):
- **Observatorio Genómico** (`unlock_hidden_achievements`): muestra los logros ocultos.
- **Análisis de Tensión** (`show_epsilon_detail`): desglose de ε en vivo (activo / pasivo / complejidad).
- **Predictor Estructural** (`warn_epsilon_threshold`): avisa antes de cruzar los umbrales de ε de cada mutación.
- Más un legado propio, **Lema de Lyapunov**: la fórmula del núcleo muestra los valores reales de todos los
  coeficientes en todas las runs.

---

## 4. PROCARIOTA — anti-Endosimbiosis

> Endosimbiosis es el nacimiento de la célula eucariota. Procariota es deshacerlo: el hongo expulsa sus
> orgánulos y vuelve a ser lo que fue antes de ser hongo.

**Espejo.** Endosimbiosis es *incorporar*. Procariota es *no incorporar*: con la llave, si aparece **ENGULLIR**
y dejás pasar la ventana sin engullir, el hongo expulsa sus orgánulos y entra a Procariota (por omisión, como Ayuno).

**Mecánica — dividirse.**
- **Fisión binaria**: una población **N** que se duplica cada `t_div` (20 s) hasta una **capacidad K** (curva
  logística: cerca de K crece cada vez más lento). El ingreso es proporcional a N.
- **[Q] Cosechar**: convierte la mitad de N en plata. Cosechar temprano corta el crecimiento; esperar mucho
  satura en K. La decisión es *cuándo*.
- **Quorum sensing**: con N ≥ 80 % de K se habilita **[W] Quorum**, una ráfaga coordinada (×3 todo el ingreso,
  10 s) que gasta el quorum (N baja a 40 %).
- **Plásmidos** (transferencia horizontal de genes; el Banco Genético ya se llama "Plásmidos"): **[E]** apaga
  un legado tuyo y prende otro de los que tenés apagados, durante 60 s. Una procariota no tiene herencia fija.
- **Sello**: 10 quorums.
- **Fracaso**: N llega a 0 por cosechar de más (**extinción**) → cierra como SIMBIOSIS (la base de la run).

**Recompensa.** Legado **Plásmido**: en todas las runs, una vez por run, podés intercambiar un legado
activo por uno apagado. Es un sistema nuevo para el Banco.

**Cruce futuro.** LUCA (último ancestro común universal) como contenido de la secreta **El Origen** /
Jardín Primigenio: involucionar hasta antes de la división bacterias / arqueas / eucariotas.

---

## 5. ANTIBIOSIS — anti-Simbiosis *(rename de Autarquía)*

> La antibiosis es lo contrario de la simbiosis: organismos que se dañan. Los hongos la inventaron:
> la penicilina sale de un hongo (*Penicillium*, Fleming 1928).

**Espejo.** Simbiosis es cooperar con orden (Ω ≥ 0.40, Contabilidad). Antibiosis: **hifas ≥ 5 con Ω < 0.25
sostenido 60 s** (colonia grande en competencia). *A calibrar.*

**Mecánica — competir.**
- Cada 30 s aparece una **colonia rival** que roba un % del ingreso hasta que la eliminás.
- Tres antibióticos: **[Q]**, **[W]**, **[E]** (β-lactámico, macrólido, tetraciclina). Cada uno mata al rival en
  unos segundos, pero **repetir el mismo antibiótico genera resistencia**: cada uso lo vuelve menos efectivo
  contra los rivales siguientes. Hay que rotar.
- **Visibilidad**: el panel muestra la resistencia de cada rival a cada antibiótico.
- **Sello**: eliminar 15 rivales.
- **Fracaso**: 3 rivales vivos a la vez → la competencia te desplaza → cierra como SIMBIOSIS.

**Recompensa.** Legado **Penicilina**: en todas las runs, la corrosión del Parasitismo y la ventana del
Depredador muestran su progreso exacto (visibilidad). A definir.

---

## 6. AUTOSUFICIENCIA — anti-Parasitismo

> Parasitismo es depender del sistema y drenarlo. Autosuficiencia es no depender de nada.

**Espejo.** Parasitismo entra por inactividad con biomasa. Autosuficiencia: **no comprar ninguna mejora
durante 90 s teniendo plata para comprar** (renunciar al mercado), con biomasa ≥ 5.

**Mecánica — cultivar.**
- No se pueden comprar mejoras con plata. En su lugar, **[Q] Cultivar** un nivel de una mejora con **biomasa**:
  tarda (30 s por nivel) y hay un solo cultivo a la vez.
- La plata se acumula sin uso. **[W] Fermentar** convierte plata en biomasa a mala tasa (la puerta de salida
  del mercado).
- **Sello**: 12 niveles cultivados.
- **Fracaso**: comprar una mejora con plata (romper la autosuficiencia) → cierra como PARASITISMO.

**Recompensa.** Legado **Despensa Propia**: en todas las runs, la primera mejora de cada tipo se puede cultivar
con biomasa en vez de comprarla.

---

## 7. HIFA PIONERA — anti-Red Micelial *(rename de Núcleo Aislado)*

> La Red se expande en todas direcciones. La Hifa Pionera es una sola punta que avanza sin ramificar.

**Espejo.** Red Micelial es tener muchas hifas conectadas. Hifa Pionera: **biomasa ≥ 8 con hifas < 3 durante
60 s** (crecer sin ramificar). *A calibrar.*

**Mecánica — explorar.**
- Un **mapa del sustrato** 1D: la punta avanza sola (energía por segundo). Cada tanto hay una **bifurcación**
  y elegís izquierda o derecha.
- **[Q] Sondear** revela qué hay en las dos ramas próximas (bolsillos de nutrientes, roca, toxinas), y cuesta energía.
- Bolsillos = ráfagas de ingreso; roca = frena; toxinas = pierde energía.
- **Sello**: recorrer 1000 m del sustrato.
- **Fracaso**: energía 0 (la punta muere) → final propio **HIFA EXTRAVIADA** (decisión 2026-10-18, ver §8).

**Recompensa.** Legado **Mapa del Sustrato**: en todas las runs, el panel de genoma muestra las condiciones
de la próxima mutación latente antes de que estés cerca (visibilidad).

---

## 8. Decisiones del autor (2026-10-18)

1. **Renombres aprobados**: Autarquía → **Antibiosis**, Núcleo Aislado → **Hifa Pionera**.
2. **Inestabilidad Consciente**: los 3 legados de conocimiento **pasan a ser su recompensa** (dejan de
   comprarse en el Banco; quien ya los tenía los conserva).
3. **Procariota**: la extinción cierra como **SIMBIOSIS**.
4. **Hifa Pionera**: su fracaso tiene **final propio** (como Micelio Fragmentado). Nombre propuesto:
   **HIFA EXTRAVIADA**, con un legado menor de consuelo.
5. **Orden**: se arranca por **Inestabilidad Consciente**.

## 9. Inestabilidad Consciente — implementada (2026-10-18) ✅

Concreta §3 (`InestabilidadLogic.gd`, estado `inest_*` en EvoManager, constantes `INEST_*` en Balance).
Calibrada con bot; los números de abajo son los finales.

- **Llave** `sombra_inestabilidad` (20 PL, se revela en T3 y se desbloquea tras cerrar HOMEOSTASIS).
- **Espejo**: con la llave, sin ninguna mutación base activa, **habiendo tenido Homeostasis elegible en la run**
  (su botón habilitado o su gen latente: tuviste el equilibrio al alcance y lo soltaste) y Contabilidad ≥ 1:
  **45 s acumulados con ε ≥ 0.45** → entra (con ε por debajo el acumulado baja a la mitad de velocidad, no se
  reinicia; el panel de ε muestra «Inestabilidad: ε ≥ 0.45 · 23/45 s»). Aviso con cuenta regresiva 10 s antes.
  - Feedback del autor (18/10): 0.50 sostenido 60 s seguidos era muy difícil (ε oscila con cada click).
  - Calibración: con 0.60 el bot visual se quedaba oscilando en 0.51–0.60 sin entrar (el borde de lo que se
    alcanza clickeando). 0.50 sigue lejos de las bandas de Homeostasis (≤ 0.25) y Simbiosis (≤ 0.45).
  - Calibración: "Homeostasis latente" casi nunca se veía (el gen salta de dormido a activo), por eso se mide
    también "Homeostasis elegible" (`RunManager.is_homeostasis_candidate()`).
- **Perturbación P**: se suma al objetivo de ε (StructuralModel), así que ε sube suave hacia natural + P.
  Negar Homeostasis también apaga los pisos de Ω (omega_min y legados de Alostasis/Homeorresis).
- **[Q] OBSERVAR** (cooldown 6 s): P += 0.20 y revela el próximo lema (5, en orden fijo).
- **Lo observado sigue perturbando**: cada lema revelado y sin demostrar suma +0.002/s a P. Observar de más da
  opciones pero acelera la deriva.
- **[W] INTEGRAR** (cooldown 20 s, cuesta 10 s de ingreso): P −= 0.25 (puede quedar negativa, hasta −0.30).
- **Lemas** (el progreso sube mientras se cumple y baja a la mitad de velocidad si no):
  1. **a — Impulso**: ≥ 3 clicks/s (media móvil) durante 40 s.
  2. **ε — Lyapunov**: 0.90 ≤ ε ≤ 1.10 durante 60 s.
  3. **d — Inercia**: sin clickear (≥ 3 s), con ε ≥ 0.60, durante 40 s. Sin clicks ε ≈ P + pasivo: pide ≥ 3
     observaciones. (Con 0.80 era imposible: 5 observaciones dan P = 0.75 como máximo.)
  4. **n — Estructura**: comprar 5 mejoras estructurales desde que se reveló.
  5. **Ω — Elasticidad**: Ω vuelve a ×1.75 su mínimo desde que se reveló, durante 30 s (estirarse y
     recuperarse: bajar ε integrando sin que converja). Era "Ω ≤ 0.30" (trivial: entrar ya lo cumple) y después
     "Ω ≥ 0.40" (con muchas mejoras pedía ε < 0.35 = zona de convergencia).
- **Teoremas**: cada lema demostrado da ingreso ×1.10 acumulado (×1.50 con 5) y deja su coeficiente visible
  (la fórmula del núcleo muestra `a = ? ε = ? d = ? n = ? Ω = ?` durante la ruta).
- **Sello — Q.E.D.**: 5 lemas → botón SELLAR (+9 PL; NG+: elegancia = 8 − integraciones, tope 8).
- **Fracaso** (los dos cierran como **HOMEOSTASIS**):
  - **diverge**: ε > 1.20 durante 10 s;
  - **converge**: ε < 0.35 durante 60 s (el AFK vuelve solo al equilibrio: no hay run trabada).
- **Recompensa**: Observatorio Genómico (los logros secretos se ven en el panel), Análisis de Tensión (desglose
  de ε en el panel de ε), Predictor Estructural (próximo umbral de ε en el panel y aviso a 0.05) y
  **Lema de Lyapunov** (la fórmula del núcleo muestra a, b, d y e en todas las runs). Los 3 de conocimiento ya no
  se compran (costo 0, se otorgan al sellar; quien los tenía los conserva).
- **Logros**: Q.E.D. (ANCESTRAL, sellar) · Principio de Incertidumbre (FRUTO: los 5 lemas a la vista sin haber
  demostrado ninguno) · **Demostración Elegante** (MYTHIC: sellar con ≤ 5 integraciones).

**Bot (escenarios `t3_inest_*`, `a3_inest_elegante`, controles `t3_*_key`):**

| Escenario | Resultado |
|---|---|
| `t3_inest_player` (observa de a 2, integra con ε > 1.08, guarda plata para integrar) | Q.E.D. a 746 s (~6 min de ruta) · 6 integraciones (no saca el MYTHIC) |
| `a3_inest_elegante` (de a 1 lema, junta plata para la estructura) | Q.E.D. a 731 s · 5 integraciones → MYTHIC |
| `t3_inest_greedy` (observa todo, clickea sin mirar ε) | diverge en ~25 s → HOMEOSTASIS |
| `t3_inest_afk` (entra y se va) | converge a los 60 s → HOMEOSTASIS |
| `t3_homeo_key` / `t3_hiper_key` / `t3_simbiosis_key` | con la llave juegan su ruta normal: ninguno entra a la Sombra |

## 10. Procariota — implementada (2026-10-18) ✅

`ProcariotaLogic.gd`, estado `proc_*` en EvoManager, constantes `PROC_*` en Balance. Concreta §4.

- **Llave** `sombra_procariota` (20 PL, se revela en T3 y se desbloquea tras sellar ENDOSIMBIOSIS).
- **Espejo**: con la llave, si aparece **ENGULLIR** y dejás pasar la ventana sin engullir, el hongo expulsa sus
  orgánulos. Al abrirse la ventana un aviso lo anuncia. Reemplaza a la Simbiosis de la run (efectos, sello y
  cierres).
- **Colonia** N de 0 a 100: crecimiento logístico (se duplica cada 20 s lejos de la capacidad). El ingreso escala
  ×0.3 (vacía) → ×2.0 (llena).
- **Toxinas** (en lugar de un AFK eterno): desde el 90 % se acumulan +1/s (−0.5/s por debajo); a 30, **lisis**:
  la colonia queda al 25 %.
- **[W] Quorum** desde el 80 %: ráfaga × (1 + 4·N/K) 10 s y la colonia queda al 40 %. Esperar más cerca de K
  rinde más pero roza la lisis.
- **[Q] Cosechar**: la mitad de la colonia → plata (una colonia llena = 30 s de ingreso). Con N < 2 la extingue.
- **[E] Plásmido** (−20 % de la colonia, cooldown 10 s): resistencia (toxinas ×0.5) → virulencia (quorum +2·N/K)
  → metabólico (crecimiento ×1.5).
  - **Cambio respecto de §4**: la spec pedía "apagar un legado y prender otro 60 s", pero los legados ya se
    prenden y apagan gratis en el Banco en cualquier momento: no aportaba nada. El plásmido pasa a ser un gen
    de la colonia, dentro de la run.
- **Sello**: 8 quorums → PROCARIOTA (+9 PL; NG+: el mejor quorum, tope 8).
- **Fracaso** (→ SIMBIOSIS): 3 lisis o extinguir la colonia cosechando.
- **Recompensa** (también cambia respecto de §4, por lo mismo): **Legado Plásmido** — el panel de Buffs activos
  muestra la *expresión génica*: cuánto multiplica cada legado y buff cósmico tu click y tu pasivo, en vivo.
- **Logros**: Fisión Binaria (ANCESTRAL, sellar) · Conjugación (FRUTO: los 3 plásmidos en una run) ·
  **Quorum Absoluto** (MYTHIC: todos los quorums con la colonia ≥ 95 %).

**Bot (escenarios `t3_proc_*`, `a3_proc_absoluto`, control `t3_endo_key_engulf`):**

| Escenario | Resultado |
|---|---|
| `t3_proc_player` (quorum al 80 %, virulencia) | entra a 347 s · sella a 838 s (8 min de ruta) · sin lisis |
| `a3_proc_absoluto` (quorum al 96 %, resistencia) | sella a 1238 s → MYTHIC |
| `t3_proc_afk` | 3 lisis → SIMBIOSIS a 757 s |
| `t3_proc_harvest` (cosecha sin parar) | extinción → SIMBIOSIS |
| `t3_endo_key_engulf` (con la llave, engulle) | Endosimbiosis normal: la Sombra no entra |
