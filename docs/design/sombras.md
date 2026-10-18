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
| Homeostasis | **Inestabilidad Consciente** | observar | OBSERVAR: leer la propia ecuación (lore matemático) | spec |
| Endosimbiosis | **Procariota** | dividirse | población por fisión binaria + plásmidos | spec (nueva) |
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
- **Fracaso**: energía 0 (la punta muere) → cierra como ESPORULACIÓN / Red (a definir, ver §8).

**Recompensa.** Legado **Mapa del Sustrato**: en todas las runs, el panel de genoma muestra las condiciones
de la próxima mutación latente antes de que estés cerca (visibilidad).

---

## 8. Preguntas para el autor

1. **Renombres**: Autarquía → **Antibiosis** y Núcleo Aislado → **Hifa Pionera**. ¿Sí?
2. **Inestabilidad Consciente**: ¿los 3 legados de conocimiento del Banco pasan a ser su recompensa
   (dejan de comprarse), o siguen en el Banco y la Sombra suma solo el Lema de Lyapunov?
3. **Procariota**: su fracaso (extinción), ¿cierra como Simbiosis (la base de la run) o como Parasitismo?
4. **Hifa Pionera**: Red Micelial no tiene un final propio. ¿Su fracaso cierra como Esporulación o le
   damos un final de fracaso propio, como Micelio Fragmentado?
5. **Orden**: ¿arrancamos por Inestabilidad Consciente?
