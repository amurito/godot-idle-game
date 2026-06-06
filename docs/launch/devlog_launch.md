# Devlogs — HYPHAE: genesis

> Repositorio de devlogs para itch.io. El primero (lanzamiento) abre el archivo;
> los nuevos se agregan **arriba** del #1, en orden cronológico inverso (el más reciente primero).

## Normas para todos los devlogs

1. **Misterio que cautiva.** Tono diegético — el sistema/organismo le habla al jugador.
   Insinuar, no explicar. Generar curiosidad, no resolverla.
2. **Sin spoilers de mecánicas.** Teasear *nombres y sensaciones*, nunca números, fórmulas
   ni condiciones exactas. El descubrimiento in-game es lo más valioso del juego.
3. **Sin fechas, sin promesas duras** (lineamiento del launch plan). "Pronto" diegético;
   nunca "la semana que viene" ni features comprometidas con calendario.
4. **Honesto, no hype vacío.** La audiencia de r/incremental es alérgica al clickbait barato.
   El misterio vende; la exageración quema credibilidad.
5. **Bilingüe ES/EN siempre.** Las dos versiones, mismo contenido.
6. **CTA agradecido.** Invitar feedback de forma corta y genuina; las esporas escuchan.

---

## Devlog #2 — v1.0.1 — El micelio ya no espera

> **Estado:** PUBLICADO (r/incremental_games, 06/06/2026). v1.0.1.0 en itch.io.
> **Título publicado (sobrio):**
> *"El micelio ya no espera — v1.0.1"* / *"The mycelium doesn't wait anymore — v1.0.1"*
> **Alternativa clickbait:**
> *"Cinco formas de morir siendo hongo"* / *"Five ways to die as a fungus"*

### VERSIÓN ES

**El micelio ya no espera**

Hace unas semanas prometí dos cosas: que el ESCLEROCIO OSCURO estaba casi listo, y que el organismo no había terminado de mostrarse.

Ambas eran ciertas.

🌑 **ESCLEROCIO OSCURO** ya está en el juego. Algunos hongos, sabiendo que el colapso es inevitable, no esperan a morir: se encapsulan. Endurecen su micelio en una cápsula de dormancia, y algo de esa bioquímica que nunca debió existir *pasa al ciclo siguiente*. Si ya llegaste hasta ahí, sabés de qué hablo. Si no: la puerta sigue siendo el Metabolismo Oscuro.

Pero el cambio que realmente transformó el juego en esta versión fue otro.

La **Red Micelial** siempre fue la rama silenciosa. Extendés. Esperás. El sistema hace su trabajo. Era suficiente.

En la v1.0.1, la red decidió dejar de esperar.

Donde antes había una sola forma de terminar esa rama, ahora hay **cinco**. Cinco paths. Cinco organismos distintos dentro de la misma mutación. Cada uno tiene su propia forma de morir — o de sobrevivir, según cómo lo veas.

Algunos requieren que empujés activamente. Otros te dan recursos finitos y esperan que los administrés. Uno te pide que sostengás un equilibrio en cuatro dimensiones al mismo tiempo. Y el último... tiene su propia inteligencia. Pero acotada. No confiés demasiado.

El organismo no cambia las reglas sin razón. Algo en el micelio aprendió a exigir más.

**Y en el lore que todavía no tiene forma jugable:**

Autólisis. Necrosis. Un protocolo donde Ω llega a cero. Una única ruta que el sistema clasifica como *"final feliz"* — y no está claro si eso es una promesa o una advertencia.

*¿Ya exploraste los cinco paths de la Red? ¿Cuál te resultó más brutal? Las esporas escuchan.*

---

### VERSIÓN EN

**The mycelium doesn't wait anymore**

A few weeks ago I promised two things: that Dark Sclerotium was almost ready, and that the organism hadn't finished showing itself.

Both were true.

🌑 **Dark Sclerotium** is now in the game. Some fungi, knowing collapse is inevitable, don't wait to die: they encapsulate. They harden their mycelium into a dormant capsule — and something of that biochemistry that was never supposed to exist *carries into the next cycle*. If you've gotten that far, you know what I mean. If not: the door is still Dark Metabolism.

But the change that truly transformed the game in this version was something else.

The **Mycelial Network** was always the quiet branch. You spread. You wait. The system does its work. It was enough.

In v1.0.1, the network decided to stop waiting.

Where there used to be one way to end that branch, there are now **five**. Five paths. Five distinct organisms within the same mutation. Each has its own way of dying — or surviving, depending on how you see it.

Some require you to push actively. Others give you finite resources and expect you to manage them. One asks you to hold a balance across four dimensions simultaneously. And the last one... has its own intelligence. But limited. Don't trust it too much.

The organism doesn't change the rules without reason. Something in the mycelium learned to demand more.

**And in lore that has no playable form yet:**

Autolysis. Necrosis. A protocol where Ω reaches zero. A single route the system classifies as a *"happy ending"* — and it's unclear whether that's a promise or a warning.

*Already explored all five Network paths? Which one hit hardest? The spores are listening.*

---

## Devlog #1 — Lanzamiento (v1.0.0.10)

### VERSIÓN ES

**HYPHAE: genesis — v1.0.0.10 "génesis" ya está disponible**

Después de varios meses de desarrollo, hoy publico la primera versión pública de **HYPHAE: genesis** — un idle/incremental donde gestionás un organismo fúngico en evolución.

### Qué es el juego

Empezás con un solo recurso (dinero/energía) y un hongo que observa el entorno. Con el tiempo desbloqueás mejoras, y el sistema empieza a mostrar sus capas: el estrés estructural (ε) que sube con la actividad, la estabilidad (Ω) que lo contrarresta, y las mutaciones que cambian las reglas del loop.

No es solo "comprá mejoras y esperá". Cada mutación activa una máquina de estados que abre rutas distintas. Simbiosis juega con la cooperación; Metabolismo Oscuro bloquea los upgrades convencionales y te fuerza a sobrevivir de otra forma; Depredador te da un timer de implosión que tenés que gestionar activamente. Tras trascender el ciclo, se abren tres rutas más que reescriben el juego desde cero: Vacío Hambriento (×100 producción a cambio de tus buffs), Carnaval de Mutaciones (rotación automática cada 60s), Reencarnación Heredada (arrancás fuerte pero pagás deuda kármica).

### Por qué tardó

Originalmente se llamaba "AntiIDLE" y era un prototipo mucho más simple. Fue creciendo en capas: el modelo de ε/Ω, el prestige doble (Banco Genético + Banco Cósmico), las rutas NG+, el export web con Godot 4 (audio, emojis, canvas scaling — cada uno fue su propio mini-proyecto), el panel de accesibilidad, el sistema de slots, y finalmente el rename y el pulido final.

La v1.0.0.10 consolida todo eso en algo que se puede jugar de principio a fin de manera coherente.

### Lo que viene

El roadmap tiene contenido, pero para la v1.1 me interesa especialmente iterar en base a feedback: ¿qué ruta confunde más al jugador nuevo? ¿Qué mechanic se siente incompleta? El plan a mediano plazo es expandir el endgame para jugadores que ya trascendieron varias veces, con rutas más complejas gateadas por progresión real.

Si llegás a jugar y tenés algo para decir — bienvenido sea el feedback, sea en los comentarios o por mail.

**Link:** [itch.io]
**Plataformas:** Navegador (Chrome, Firefox, Edge) · Windows .exe
**Precio:** Gratis

---

### VERSIÓN EN

**HYPHAE: genesis — v1.0.0.10 "génesis" is out**

After several months of development, I'm releasing the first public version of **HYPHAE: genesis** — an idle/incremental where you manage an evolving fungal organism.

### What the game is

You start with a single resource and a fungus observing its environment. Over time you unlock upgrades, and the system reveals its layers: structural stress (ε) that builds with activity, stability (Ω) that counteracts it, and mutations that change the rules of the loop.

It's not just "buy upgrades and wait." Each mutation activates a state machine that opens distinct routes. Symbiosis plays with cooperation; Dark Metabolism locks conventional upgrades and forces you to survive differently; Predator gives you an implosion timer you have to actively manage. After transcending the cycle, three more routes open that rewrite the game from scratch: Hungry Void (×100 production in exchange for your buffs), Carnival of Mutations (auto-rotation every 60s), and Inherited Reincarnation (strong start, but you pay karmic debt on every purchase).

### Why it took a while

It started as a much simpler prototype called "AntiIDLE." It grew in layers: the ε/Ω structural model, the dual prestige system (Genetic Bank + Cosmic Bank), NG+ routes, Godot 4 web export (audio routing, emoji rendering, canvas scaling — each its own mini-project), an accessibility panel, a slot system, and finally the rename and final polish.

v1.0.0.10 consolidates all of that into something playable from start to finish in a coherent way.

### What's next

The roadmap has content, but for v1.1 I'm most interested in iterating based on feedback: which route confuses new players most? Which mechanic feels incomplete? The medium-term plan is to expand the endgame for players who've already transcended several times, with more complex routes gated by real progression.

If you play it and have something to say — feedback is very welcome, in the comments or by email.

**Link:** [itch.io]
**Platforms:** Browser (Chrome, Firefox, Edge) · Windows .exe
**Price:** Free
