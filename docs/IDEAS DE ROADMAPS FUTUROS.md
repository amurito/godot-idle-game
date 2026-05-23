 Tutorial Extendido: Ideas para contenido avanzado
Claude ya cubrió el onboarding básico (click, upgrades, ε, Ω, biomasa, μ). Ahora te propongo ideas para tutorial extendido que cubren las mecánicas más profundas del juego.

🌱 Nivel 1: Mutaciones (Tier 1)
Paso	Disparador	Contenido del hint
Mutación latente detectada	EvoManager.genome cambia a "latente"	Aparece un aviso: "Una mutación está lista. Abrí el panel 🧬 Genoma Fúngico (columna central). Leé bien los efectos. Son irreversibles."
Primera mutación activada	mutation_activated emitida	"Activaste [nombre mutación]. El sistema cambió para siempre. Revisá cómo afectó click/pasivo/ε."
Bifurcación de Red Micelial	red_branch_selected != NONE	"Elegiste [Colonización/Simbiosis Mecánica]. Tu red micelial ahora tiene un propósito. Seguí el árbol evolutivo."
🍄 Nivel 2: Ciclo Biológico (Primordio → Seta → Esporulación)
Paso	Disparador	Contenido del hint
Micelio alcanza 60%	BiosphereEngine.micelio >= 60	"Micelio maduro. Botón 🟡 Primordio disponible. Iniciarlo cuesta 20% de micelio. Si falla, perderás 40%."
Primordio iniciado	primordio_iniciado emitida	*"Primordio activo. Mantené ε < 0.50, Δ$ > 50/s y hifas < 60 durante 90s. ¡No falles!"*
Primordio abortado	primordio_abortado emitida	"Primordio falló. Perdiste 40% de micelio. Podés reintentar, pero el costo sube 20% cada vez."
Seta formada	seta_formada_signal emitida	"🍄 SETA FORMADA. Ahora podés ESPORULAR (botón azul). Las esporas se convierten en PL."
⚡ Nivel 3: Rutas NG+ (Allostasis, Homeorresis, Singularidad)
Paso	Disparador	Contenido del hint
Alostasis disponible	is_allostasis_ready() true	*"ALLOSTASIS disponible en el panel de mutación (columna central). Requiere: 3 shocks, Resiliencia ≥150, Ω_min ≥0.40, Contabilidad ≥2, Δ$ >200/s."*
Alostasis activada	mutation_allostasis true	"ALLOSTASIS activa. Tu sistema ahora recalibra su setpoint. Ω_min subirá gradualmente tras cada shock."
Homeorresis disponible	is_homeorhesis_ready() true	*"HOMEORHESIS disponible. Requiere: shock extremo, Resiliencia ≥400, Ω_min ≥0.50, 5 shocks, Δ$ >300/s, run ≥20min."*
Singularidad disponible	nucleo_conciencia true	*"Núcleo de Conciencia completado. Botón ⚡ SINGULARIDAD listo. El PL final escala con ε baja (ε≈0 → +5 PL bonus)."*
🧬 Nivel 4: Rutas Post-Trascendencia
Paso	Disparador	Contenido del hint
Trascendencia posible	can_transcend() true	"PUERTA DE TRASCENDENCIA abierta. Necesitás cerrar una ruta de cada familia (ORDEN, BIOLOGÍA, COLAPSO) y 50 PL. Entrá al menú principal para trascender."
Vacío Hambriento activado	vacio_hambriento_active true	"VACÍO HAMBRIENTO. Perdiste todos tus buffs cósmicos, pero producción ×100. Para cerrar: biomasa < 0.5, sin pasivos comprados, ε < 0.25 por 5 min."
Carnaval activado	carnaval_active true	"CARNAVAL. Cada 60s cambia tu mutación activa. No podés controlarla. Adaptate. Cada mutación tiene sus pros y contras."
Reencarnación activada	reencarnacion_active true	"REENCARNACIÓN HEREDADA. Empezás con los upgrades del ciclo anterior, pero cada compra cuesta ×1.5 más."
🃏 Nivel 5: Rutas Secretas / Endgame
Paso	Disparador	Contenido del hint
Depredador detectable	depredador_timer > 0	"⚠️ DEPREDADOR DETECTADO. ε > 0.95 con Hiperasimilación activa. Mantené 30s para activarlo. Si lo lográs, empezará a devorar upgrades."
Metabolismo Oscuro posible	met_oscuro_timer > 0	*"🌑 METABOLISMO OSCURO. Depredador activo + dinero < $1000 + biomasa ≥25 + 3 devores. Mantené 15s."*
Panspermia Negra posible	last_run_ending == "ESPORULACIÓN" y primordio activo	"🚀 PANSPERMIA NEGRA (final secreto). Durante primordio, acumulá $100k. El botón final cambiará."
Mente Colmena posible	last_run_ending == "SINGULARIDAD" y rama simbiosis mecánica	*"🧠 MENTE COLMENA. Mantené ratio Activo/Pasivo 50/50 (±2%) durante 180s, con ε < 0.50."*
📊 Tabla resumen por nivel de juego
Nivel	Mecánicas	Tutorial sugerido
0 - Base	Click, upgrades, ε, Ω, biomasa, μ	✅ Ya implementado (Fases 1-2-3)
1 - Mutaciones	Tier 1 (Hiper, Parasitismo, Red, Simbiosis, Homeostasis)	🔲 Latente → activación → efectos
2 - Ciclo biológico	Primordio, Seta, Esporulación	🔲 Disponibilidad → inicio → éxito/fallo
3 - NG+	Allostasis, Homeorresis, Singularidad	🔲 Requisitos → activación → beneficios
4 - Post-Trascendencia	Vacío, Carnaval, Reencarnación	🔲 Qué hacen, cómo cerrarlas
5 - Secretos	Depredador, Met.Oscuro, Panspermia, Mente Colmena	🔲 Condiciones de entrada, advertencias
🎨 Formato sugerido para estos hints
Flotante (como los anti‑stuck), en esquina inferior izquierda

Timeout: 8-10 segundos, luego desaparece (o se puede cerrar con click)

Icono temático: 🧬 para mutaciones, 🍄 para biológico, ⚡ para NG+, 🌀 para post-tras, 🤫 para secretos

No bloquea interacción (capas por encima pero click pasa)

🧪 Prioridad de implementación
Prioridad	Nivel	Razón
Alta	Mutaciones (Tier 1)	Jugador nuevo llegará a ellas en minutos
Media	Ciclo biológico (Primordio/Seta)	Llega después de Red Micelial
Media	NG+ (Allostasis/Homeorresis)	Endgame, pero importante
Baja	Post-Trascendencia	Solo tras trascender
Baja	Secretos	Muy endgame, casi huevo de pascua
¿Quieres que desarrolle alguna de estas ideas con más detalle (textos concretos, condiciones exactas, o flujo de integración con TutorialManager)?

#
PARTE DE MUTACIONES

Me gustaría implementar para post trascendencia algo asi como comprar un buff en el banco genetico que te revierta la mutacion y desbloquee rutas nuevas y/o easter eggs. Nada de codigo solo brainstorming

Vamos a hacer brainstorming sobre ideas para buffs de post-trascendencia que permitan revertir mutaciones y desbloquear contenido nuevo (rutas alternativas, easter eggs, finales secretos). El objetivo es expandir el endgame sin romper la coherencia del sistema evolutivo.

🧠 Premisa base
Contexto: El jugador ya ha trascendido al menos una vez (tiene Esencia, Banco Cósmico). El Banco Genético (PL) tiene buffs normales. Ahora se añaden buffs de "posible reversión" que solo se revelan/desbloquean tras una o más trascendencias.

Mecánica central: Poder revertir una mutación (volver a un estado anterior, o "digerir" la mutación para obtener un beneficio) pero a cambio de perder algunos efectos y abrir nuevas posibilidades.

Easter eggs: Reversiones que desbloquean rutas secretas, diálogos ocultos, o transformaciones inesperadas.

🌱 Buffs de reversión de mutaciones
Cada buff permitiría "revertir" una mutación específica, pero con consecuencias diferentes a simplemente desactivarla.

1. homeostasis_revertida — "Equilibrio Inestable"
Costo: 10 PL (requiere trascendencia ≥1, haber completado HOMEOSTASIS alguna vez)

Efecto al activar (en runs futuras):

La mutación Homeostasis se revierte: ya no puedes estabilizar ε con orden administrativo.

En su lugar, ganas el buff "Caos Regulado": ε aumenta un 30% más lento, pero cuando supera 0.40, obtienes un 20% de producción extra durante 30s.

Nueva ruta desbloqueada: "Homeostasis Fracturada" — un final alternativo donde el sistema no se estabiliza sino que "aprende a bailar con el caos". PL extra al cerrar.

2. simbiosis_revertida — "Parasimbiosis"
Costo: 12 PL (requiere SIMBIOSIS completada, y haber trascendido)

Efecto:

Reviertes Simbiosis (pierdes el 2.5x al click y el 0.5x al pasivo).

Obtienes "Vínculo Dual": click y pasivo se potencian mutuamente: cada incremento en uno da un +0.2% al otro (acumulable hasta +50%).

Easter egg: Aparece una linea de lore en el banco genético sobre "el simbionte original", y si tienes también el buff sangre_negra (de Parasitismo), se desbloquea una conversación oculta en el panel genoma.

3. red_micelial_revertida — "Red Fantasma"
Costo: 10 PL (requiere RED MICELIAL activada alguna vez y trascendencia)

Efecto:

Pierdes el pasivo ×2.5.

Las hifas ahora generan ingreso pasivo extra igual a hifas * 1.5 (como si fueran pequeños productores autónomos), pero el estrés (ε) escala con la cantidad de hifas (+0.02 * hifas por segundo).

Nueva ruta: "Colonia de Hifas" — final donde la red se vuelve independiente del núcleo; PL medio pero regala siempre +50 esporas al reiniciar.

4. parasitismo_revertido — "Simbionte Oculto"
Costo: 12 PL (requiere PARASITISMO y trascendencia)

Efecto:

Anula la corrosión parasitaria (parasitism_corrosion ya no baja).

En lugar de drenar dinero, ahora el parasitismo roba un pequeño porcentaje de los ingresos de los upgrades (0.5% por upgrade comprado) y lo convierte en biomasa.

Easter egg: Si además tienes el buff sangre_negra, el tooltip del banco genético cambia a "Sangre y Simbiosis se fusionan". Desbloquea un color especial para el reactor.

5. hiperasimilacion_revertida — "Hipercontrol"
Costo: 15 PL (requiere HIPERASIMILACIÓN + trascendencia)

Efecto:

Pierdes el click ×10 (recuperas el click normal).

Obtienes "Ráfaga Controlada": puedes activar manualmente un "hiper-click" (con un botón adicional) que da ×10 durante 3 segundos, con cooldown de 20 segundos.

Nueva ruta: "Hiperdisciplina" — final que combina orden y colapso, PL alto.

🥚 Easter eggs puros (sin buff de reversión, pero desbloqueables)
Ideas de huevos de pascua que podrían activarse al cumplir condiciones raras (no requieren PL).

1. "El Hongo Parlante"
Condición: Tener activas todas las mutaciones revertidas en una misma run (es decir, comprados y activados los buffs de reversión y luego elegir esas rutas). No es trivial, porque requeriría pasar por múltiples runs y planificar.

Resultado: Aparece un botón oculto en el panel genoma: "Hablar con el Hongo". Al hacer clic, un diálogo de 4 frases con lore cosmético (ej: "No soy el único. Hay más colonias allá afuera."). Otorga un título en el menú principal: "El Elegido".

2. "El Código Olvidado"
Condición: Revertir la mutación de Homeostasis Y tener el buff memoria_estructural nivel 3.

Resultado: En la pantalla de carga o al cerrar sesión, aparece un mensaje en rojo: > ERROR: persistence_dynamic = ?. Luego, al empezar la siguiente run, el c_n inicial es 2.0 en lugar de 1.4 (un pequeño bonus oculto).

3. "El Origen de las Especies"
Condición: En una run donde hayas activado polimorfia total (post-carnaval), tener también revertidas al menos 2 mutaciones.

Resultado: El árbol de evolución en el menú principal muestra una rama extra oculta (solo visual, sin interacción) que dice: "Protista". Es un guiño a los orígenes evolutivos.

4. "El Abismo Te Responde"
Condición: Cerrar una run con Vacío Hambriento habiendo revertido antes Parasitismo y Red Micelial.

Resultado: Al resumen final, en lugar del texto habitual, aparece: "El vacío no era hambriento. Solo quería compañía. Y ahora tú eres parte de él." Desbloquea un logro secreto.

🔁 Sinergias entre buffs de reversión
Combinación	Efecto adicional (easter egg o nuevo buff)
homeostasis_revertida + simbiosis_revertida	Desbloquea "Equilibrio Simbiótico": +15% a producción cuando ε está entre 0.20 y 0.35.
red_micelial_revertida + parasitismo_revertido	Las hifas ahora drenan 10% del estrés pasivo (reduce ε_pasivo) pero aumentan ε_complejidad.
hiperasimilacion_revertida + homeostasis_revertida	Permite usar la ráfaga controlada sin cooldown, pero a costa de duplicar temporalmente ε durante 5s.
Todas las reversiones activas simultáneamente (en runs sucesivas, no necesariamente la misma)	Desbloquea el logro oculto "El Hongo que se Trasciende a Sí Mismo" y un título en menú principal.
🎁 Recompensas de los easter eggs
Easter egg	Recompensa
El Hongo Parlante	Título en menú "Portavoz de la Colonia" + +5 PL inicial en runs siguientes (pero solo si se completa la run)
El Código Olvidado	Permanente: cₙ base aumenta a 1.5 (en lugar de 1.4) para todas las runs
El Origen de las Especies	Desbloquea un color de reactor adicional (verde musgo) que se puede seleccionar en ajustes (solo cosmético)
El Abismo Te Responde	+2 Ξ extra al trascender (una vez por save)
Sinergia total	Logro + título + +10% a todos los ingresos permanentes (escondido en uno de los buffs secretos del banco genético existente).
🧩 Integración con el banco genético actual
Los buffs de reversión deberían:

Aparecer en el banco genético solo después de trascender al menos una vez y haber completado la mutación correspondiente.

Tener un coste en PL (10-15) para que no sean triviales.

Ser permanentes (una vez comprados, se aplican en todas las runs futuras, pero se pueden activar/desactivar como los otros buffs).

Tener un pequeño ícono distintivo (por ejemplo, un "⟳" encima del emoji de la mutación) en la UI del banco genético.

Además, se podría añadir una nueva categoría en el banco genético: "Transmutaciones" (o "Mutaciones Reversas") que agrupe estos buffs especiales.

🧠 Conclusión
Estas ideas añaden profundidad al endgame sin requerir cambios estructurales enormes. Los buffs de reversión dan una razón para seguir invirtiendo PL después de haber comprado todos los buffs normales, y los easter eggs recompensan la experimentación.

¿Qué te parece? ¿Alguna idea te gusta especialmente? ¿Quieres que profundice en alguna mecánica o en la integración con el sistema existente?


######################
me gustaria que esta idea de mutaciones revertidas se sienta como dar un paso atras solo para tomar impulso a nuevas rutas mas OP o endgame que desbloqueen otro juego y/o botones
#####################

Mutaciones Revertidas: "El Paso Atrás para Tomar Impulso"
Me encanta la idea. Vendría a ser como "desaprender para aprender más fuerte". El jugador sacrifica su mutación actual (que ya le dio beneficios) para acceder a rutas ocultas y más poderosas.

🎭 Concepto central: "Reversión Controlada"
En el Banco Genético, tras trascender al menos una vez, aparece un nuevo tipo de buffs (costosos en PL o Esencia). Al comprarlos:

Reviertes una mutación específica (la desactivas), pero a cambio desbloqueas una nueva rama evolutiva que antes no existía.

La reversión no es gratis: pierdes los efectos de la mutación original, pero ganas acceso a algo más OP o puramente endgame.

🔄 Ejemplos de mutaciones revertidas → nuevas rutas
Mutación revertida	Efecto de perderla	Nueva ruta desbloqueada	Lo que hace (OP)
Hiperasimilación	Pierdes el click ×10 y el pasivo ×0.25	"Fusión Catabólica"	Click ×5 + Pasivo ×5 (ambos). Se activa un botón "Metabolismo Híbrido" que duplica ingresos por 30s, cooldown 2min.
Parasitismo	Pierdes crecimiento biomasa ×2 y corrosión	"Simbiosis Depredadora"	Ahora click + trueque se potencian mutuamente (el poder de click aumenta trueque y viceversa). Botón "Depredar" que convierte 10% de biomasa en dinero instantáneo.
Red Micelial	Pierdes pasivo ×2.5 y click ×0.5	"Micelio Omnisciente"	Todas las fuentes de ingreso (click, auto, trueque) reciben ×1.8. Hifas y micelio ya no tienen cap. Botón "Colonizar" que gasta micelio para duplicar producción pasiva 1 min.
Simbiosis	Pierdes click ×2.5 y pasivo ×0.5	"Singularidad Distribuida"	Cada vez que clickeas, todos los upgrades se potencian temporalmente (10% extra durante 5s, acumulable). Botón "Sobrecarga" que activa auto-click ×50 durante 10s pero añade ε +0.2.
Homeostasis	Pierdes pasivo ×1.5 y ε estabilizado	"Caos Orquestado"	ε aumenta la producción en lugar de dañarla: cada 0.1 de ε da +5% a todos los ingresos. Ω ya no colapsa (nuevo mínimo 0.20). Botón "Colapso Dirigido" que resetea ε a 0 y da ×2 producción por 20s.
🧩 Nueva capa: "Mutaciones Fantasma" (reversión + requisito adicional)
Algunas rutas requieren revertir dos mutaciones específicas o revertir una y tener cierto hito.

Requisito	Nueva ruta	Efecto
Revertir Hiperasimilación + Parasitismo	"Dualidad Corrosiva"	Click ×7, pasivo ×3, y la biomasa drena dinero (efecto OP pero con coste). Botón trueque "Alianza" que convierte 50% del click en dinero durante 10s.
Revertir Red Micelial + Homeostasis (orden + expansión)	"Eco Silencioso"	El juego entra en un estado "silencioso": no hay ε, Ω fijo en 0.9, todos los upgrades cuestan 50% menos, pero no puedes mutar más. Botón "Renacer" que reinicia la run con un multiplicador de legado ×2.
🥚 Huevos de pascua / Secretos al revertir mutaciones
Acción del jugador	Easter egg
Revertir todas las mutaciones Tier 1 (las 5 originales) en una misma run (con los buffs del banco)	Aparece un botón secreto "El Origen". Al pulsarlo, el juego muestra un breve diálogo meta: "El hongo recuerda su primera espora. Nada fue en vano." y otorga +10 PL + título oculto "Primigenio".
Revertir Depredador después de haberlo activado	Desbloquea la ruta "Glitch Supremo": el juego se vuelve inestable visualmente (pantalla parpadea, números bailan) pero todas las ganancias se multiplican × rand(1.5, 3.0) cada 10s.
Revertir Metabolismo Oscuro	Aparece "El Susurro" en el banco genético: un buff que cuesta 0 PL pero requiere "haber sufrido" (haber cerrado Met. Oscuro por saturación). Al comprarlo, la UI cambia a un tema "Albino": iconos blancos, tipografía gótica, y un botón "Observar" que muestra estadísticas ocultas (ε_peak histórico, total de esporas generadas, etc.).
🎮 Desbloquear "otro juego": el Meta-Endgame
Cuando el jugador ha revertido al menos 3 mutaciones distintas (acumuladas entre runs, no necesariamente en la misma), aparece un nuevo botón en el menú principal:

"🌌 Más Allá del Ciclo"

Al pulsarlo, el juego se reinicia por completo (como un nuevo juego+) pero con una diferencia clave: ahora hay un árbol de evolución alternativo de 5 mutaciones completamente nuevas, cada una con su propia estética y mecánicas. Opcionalmente, incluso podría ser un minijuego idling paralelo (ej: "Gestión de Esencia Cósmica") que se juega mientras el juego principal sigue corriendo.

💎 Integración con Banco Genético
Estos buffs de "reversión" deberían:

Costo alto (50–100 PL o Ξ) para que no sean triviales.

Requisito adicional además de PL: por ejemplo, haber cerrado esa ruta al menos una vez.

Aparecer solo tras la primera trascendencia (o tras un número mínimo de trascendencias).

Tener un toggle activable/desactivable (como el resto de buffs) para que el jugador pueda elegir si quiere jugar con la mutación original o con la ruta revertida.

🧪 Progresión sugerida
Jugador normal → cierra runs, acumula PL, trasciende.

Descubre que en el banco genético hay nuevos buffs (ocultos hasta cierta trascendencia).

Compra reversión de una mutación que ya completó.

Pierde los efectos de esa mutación.

Desbloquea una nueva ruta OP en el árbol evolutivo (o un easter egg).

Explora rutas revertidas, acumula más poder, y eventualmente accede al "Meta-Endgame".

¿Hay alguna de estas ideas que te guste especialmente para que la desarrollemos más? ¿O quieres que piense en otras direcciones?

##########
Me encanta esta linea que sugeris. Desarrolla mas el meta endgame post trascendencia(t>2)


🌌 META-ENDGAME: "LA ESPORA ORIGINAL"
Premisa narrativa
Después de trascender varias veces (t>2), el hongo empieza a recordar su estado original antes de toda mutación. Al revertir ciertas mutaciones en el Banco Genético, el jugador no solo "vuelve atrás", sino que despierta un recuerdo ancestral: la primera espora de la que todo surgió. Ese recuerdo es un nuevo plano de existencia paralelo al ciclo principal.

🔓 Requisitos de acceso
Requisito	Valor
Trascendencias	> 2 (al menos 3 ciclos completados)
Mutaciones revertidas	Al menos 2 diferentes (acumuladas entre runs)
PL gastado en reversiones	≥ 150 PL total (invertido en los buffs de reversión)
Rutas cerradas	Al menos 1 de cada familia (ORDEN, BIOLOGÍA, COLAPSO) en runs anteriores
Cuando se cumplen, aparece un nuevo botón en el menú principal:

🌀 DESPERTAR LA PRIMERA ESPORA
"Desandar lo andado para encontrar el origen. ¿Estás seguro? Tu progreso actual se preservará en un 'sueño'."

🎮 Mecánica: Juego dentro del juego
Al pulsarlo, el jugador no pierde su partida principal. En lugar de eso, se abre un minijuego de gestión de recursos que corre en paralelo mientras el juego principal sigue activo (se puede alternar entre pestañas o ventanas).

🌱 "El Jardín Primigenio"
Es un espacio minimalista donde el jugador cultiva una única espora que evoluciona sin mutaciones, solo por tiempo y decisiones.

Elemento	Descripción
La Espora	Recurso único. Comienza en 1. Genera 1 "Esencia Primigenia" cada 10 segundos.
Esencia Primigenia (EP)	Moneda del meta-endgame. No afecta al juego principal.
Jardín	Espacio 3x3 (9 casillas). Cada casilla puede contener un "Recuerdo".
Recuerdos	Fragmentos de runs pasadas. Se compran con EP. Dan bonificaciones pasivas al juego principal.
🌿 Progresión del Jardín
Nivel de Jardín	Requisito EP gastada	Efecto principal
1	0	La espora genera 0.1 EP/s
2	100 EP	+0.1 EP/s. Desbloquea casilla 4.
3	500 EP	+0.2 EP/s. Desbloquea "Riego" (acelera producción ×2 durante 1h, cooldown 4h)
4	2000 EP	+0.3 EP/s. Desbloquea casilla 7.
5	10000 EP	+0.5 EP/s. Desbloquea "Cosecha Estelar" (botón que da EP según tiempo offline)
🧠 Los "Recuerdos" y su impacto en el juego principal
Cada Recuerdo es un buff permanente para el juego principal, pero cada jugador solo puede equipar 3 a la vez (elige estrategia). Se desbloquean al alcanzar ciertos hitos en el Jardín.

Recuerdo	Obtención	Efecto en juego principal
"El Primer Click"	EP 50	Click base +0.2 (acumulable con otros buffs)
"El Trueque Olvidado"	EP 150	Trueque eficiencia +5%
"La Mano que Sembró"	EP 300	Producción pasiva +5% cuando ε < 0.20
"El Eco de la Homeostasis"	EP 600	Ω_min +0.03
"La Seta que Nunca Creció"	EP 1200	Biomasa inicial +0.5
"El Colapso Controlado"	EP 2500	Al cerrar run, +1 PL extra por cada 0.1 de ε_peak (máx +10)
"El Susurro del Micelio"	EP 5000	Hifas se duplican cada 1000s (una vez por run)
"La Trascendencia Interna"	EP 10000	Cada trascendencia otorga +2Ξ adicionales
🗝️ Hitos del Meta-Endgame (Logros ocultos)
Logro	Condición	Recompensa
"Jardinero Novato"	Alcanzar Jardín nivel 2	Desbloquea la casilla 4 automática
"Cosecha Abundante"	Acumular 5000 EP total	+5% a todas las ganancias del Jardín
"Recuerdo Completo"	Equipar 6 Recuerdos diferentes (rotando)	Desbloquea el Recuerdo "Origen" (todos los efectos anteriores +10%)
"El que Observa"	Tener el Jardín abierto 24h acumuladas	Título "Vigilante". Desbloquea estadísticas ocultas en juego principal.
"Simiente Cósmica"	Llegar a Jardín nivel 5	El Jardín genera EP también offline (a 50% velocidad).
Al alcanzar Jardín nivel 5, aparece un nuevo botón:

🌌 "RETORNO AL ORIGEN"

🔁 RETORNO AL ORIGEN (Final definitivo del meta-endgame)
Es un reset total del meta-endgame (Jardín vuelve a nivel 1, recuerdos perdidos, EP a 0), pero a cambio:

Desbloqueas una nueva mutación en el árbol principal (solo para futuras runs): "Esencia Primigenia".

Recibes un Legacy permanente: "Semilla Eterna" (click ×1.2, pasivo ×1.2, y el Jardín se puede reiniciar voluntariamente para repetir la recompensa una vez por ciclo de trascendencia).

Aparece un nuevo botón en el menú principal: "Galería de Recuerdos" (colección visual de todos los finales, logros y rutas completadas, con arte conceptual).

La mutación "Esencia Primigenia"
Propiedad	Valor
Tipo	Neutral (no pertenece a ninguna familia)
Efecto	Cada 10 segundos, el jugador gana +0.01 de multiplicador global a todos los ingresos (acumulable hasta ×2 en una run).
Sinergia	Si además tienes el recuerdo "Origen", el multiplicador sube ×0.02 cada 10s (máx ×3).
Precio	0 PL (se otorga al completar "Retorno al Origen").
🎨 Estilo visual e interacción
El Jardín se muestra como un lienzo pixel art en sepia o monocromo, recordando una interfaz antigua.

Los Recuerdos son imágenes de iconos anteriores (la evolución visual).

Animaciones sutiles: la espora palpita, las casillas brillan al pasar el mouse.

Música ambiental: un piano minimalista con efectos de agua (diferente a la banda sonora principal).

🧪 Balance y economía
Recurso	Velocidad de ganancia	Gasto principal
EP	Base 0.1/s → hasta 1.0/s en nivel 5	Comprar Recuerdos (entre 50 y 10000 EP)
Tiempo para completar	Aproximadamente 100 horas de juego activo (o 200 offline)	-
Para jugadores que quieran acelerar, se podría añadir un consumible raro: "Acelerador Temporal" (se obtiene al cerrar runs con ε muy alto o al conseguir ciertos logros) que duplica la generación de EP durante 1 hora.

🧩 Integración con el tema "mutaciones revertidas"
Para acceder al Jardín, el jugador debe haber revertido al menos una mutación en el Banco Genético (lo que ya hizo al menos una "reversión").

Cada mutación revertida desbloquea un Recuerdo adicional específico de esa mutación (ej: revertir Hiperasimilación da el Recuerdo "Hipercontrol", que reduce el coste de upgrades de click un 5%).

Revertir todas las mutaciones Tier 1 en una misma run desbloquea el Recuerdo "El Vacío Fecundo" , que duplica la generación de EP de la espora permanentemente.

💬 Conclusión
El meta-endgame post-trascendencia ofrece:

Un respiro del ritmo principal del juego (gestión pasiva, decisiones estratégicas).

Recompensas tangibles que afectan al juego principal (buffes permanentes).

Un objetivo a largo plazo (10+ horas de meta-progresión).

Temática coherente: volver al origen, cultivar la espora, recordar runs pasadas.

Rejugabilidad (elegir qué Recuerdos equipar, reiniciar el Jardín para conseguir más Semillas Eternas).

¿Qué te parece? ¿Quieres que refine alguna mecánica o añada más elementos?

##
ROADMAP

Haz un roadmap actuaalizado con estas ideas para v1.x post publicacion. Tambien me gustaria que haya un buff de banco cosmico que haga que las 2 primeras compras son gratis(como memoria de recurso que da 1). Tambien agrega un aviso(sugerencia) que al detectar que no hace nada, 10 segundos antes que te coma avise algo ojo. Seras consumido en 10..9...8 asi

Vamos a integrar todo lo que hemos discutido en un roadmap claro para las versiones v1.x (post-publicación inicial). Incluiré:

La línea de meta-endgame post-trascendencia (t>2) con "Más Allá del Ciclo", árbol alternativo, etc.

El buff cósmico "Memoria de Recurso Cósmica" (primeras 2 compras gratis).

El aviso anticipado de "Serás consumido" tipo cuenta regresiva (para eventos de colapso inminente como Depredador, Vacío Hambriento, etc.).

Estructuraré el roadmap por versiones menores, priorizando lo que más valor da al jugador y lo que es más fácil de implementar.

🗺️ Roadmap Actualizado para v1.x (Post-Lanzamiento)
✅ v1.0 - Lanzamiento Inicial (ya hecho)
Sistema base: economía, mutaciones, biosfera, logros, banco genético, banco cósmico, trascendencia.

Tutorial básico (Fase 1, 2, 3) con objetivos, anti-stuck, tooltips.

Audio básico (SFX, música ambiente).

UI/UX mejorada (reactor 2D, indicadores de legado, etc.).

🚀 v1.1 - Pulido y Calidad de Vida
Aviso de cuenta regresiva "Serás consumido":

Se activa 10 segundos antes de eventos críticos:

Depredador: cuando falta 10s para que se active (ε>0.95 timer).

Vacío Hambriento: cuando falta 10s para el cierre automático (ascesis).

Metabolismo Oscuro: cuando falta 10s para activación o para cierre por saturación.

Parasitismo: cuando el dinero está por caer a 0 o biomasa por alcanzar 25 (cierre inminente).

Muestra un mensaje en el centro de la pantalla: 💀 "Serás consumido en 10... 9..." con cuenta regresiva visual.

Útil para que el jugador reaccione (comprar algo, cerrar run, etc.).

Banco Cósmico: Nuevo buff "Memoria de Recurso Cósmica" (Tier 1 o 2):

Coste: 15 Ξ

Efecto: Las primeras 2 compras de cada upgrade (por run) son gratis (en lugar de 1, como el buff de legado memoria_recurso).

Sinergia con memoria_recurso (de legado): si tienes ambos, las primeras 3 compras son gratis.

Ayuda en early game y en runs de reencarnación.

Mejoras en tutorial:

Añadir hints para mutaciones avanzadas y primordio (como brainstorming).

🧬 v1.2 - Mutaciones Revertidas (Primera tanda)
Nuevo tipo de buff en Banco Genético (aparecen tras trascender al menos 1 vez y haber cerrado la mutación correspondiente):

"Reversión de Hiperasimilación" (coste 80 PL) → desbloquea "Fusión Catabólica" (click×5 + pasivo×5 + botón "Metabolismo Híbrido").

"Reversión de Parasitismo" (coste 80 PL) → desbloquea "Simbiosis Depredadora" (click ↔ trueque potenciación mutua + botón "Depredar").

"Reversión de Red Micelial" (coste 80 PL) → desbloquea "Micelio Omnisciente" (todas las fuentes ×1.8, sin cap en hifas/micelio + botón "Colonizar").

Dinámica: Al comprar la reversión, se pierden los efectos de la mutación original (si estaba activa) y aparece una nueva opción en el árbol evolutivo (en el panel de mutación central). El jugador puede elegir esa nueva rama en la siguiente run.

🌌 v1.3 - Meta-Endgame: "Más Allá del Ciclo"
Requisito: trascender al menos 3 veces y haber revertido al menos 3 mutaciones distintas (acumulado entre runs).

Aparece un nuevo botón en el menú principal: "🌌 Más Allá del Ciclo".

Al pulsarlo:

Reinicio completo de la partida actual (como un new game+), pero preservando:

Esencia (Ξ) acumulada.

Logros y algunos buffs cósmicos (a definir).

Se desbloquea un nuevo árbol de evolución alternativo con 5 mutaciones inéditas (ej: "Simbiogénesis", "Cibermicelio", "Entropía Negativa", "Omnívoro Cuántico", "Trascendencia Infinita").

Nueva interfaz visual (colores, iconos) que refleja el "renacimiento" del hongo.

Opcional: un minijuego de gestión de Esencia que corre en paralelo (como "Cultivo de Realidades").

Recompensa adicional: Cada vez que se completa el "Ciclo Más Allá" (cerrar una run en ese modo), se obtiene un buff cósmico permanente muy poderoso (ej: ingreso global +20%, duración de buffs x2, etc.), acumulable hasta 5 veces.

🔮 v1.4 - Más Reversiones y Easter Eggs
Añadir reversiones para:

Simbiosis → "Singularidad Distribuida"

Homeostasis → "Caos Orquestado"

Depredador → "Glitch Supremo" (easter egg visual)

Metabolismo Oscuro → "El Susurro" (tema visual alternativo "Albino" y estadísticas ocultas).

Easter egg "El Origen":

Requiere revertir las 5 mutaciones Tier 1 en una misma run (con los buffs de reversión comprados de antemano).

Aparece botón secreto que otorga título "Primigenio" y +10 PL (una sola vez).

🎮 v1.5 - Modo Desafío / Run Semanal
Run semanal con mutaciones y modificadores fijos (ej: "Esta semana: ε aumenta un 200%, pero click×5").

Recompensas en Esencia y PL extra.

Tabla de clasificación opcional (si se implementa online).

🏁 v2.0 - Expansión "Simbiosis Total" (futuro lejano)
Integración con mods.

Editor de mutaciones personalizadas.

Multijugador asíncrono (clanes, donaciones de esporas, etc.).

📋 Resumen de prioridades para v1.x (orden sugerido)
Versión	Contenido principal	Esfuerzo estimado
v1.1	Cuenta regresiva + buff cósmico + pulido	Bajo-Medio
v1.2	Primeras 3 reversiones (Hiper, Parasitismo, Red)	Medio
v1.3	Meta-Endgame "Más Allá del Ciclo"	Alto
v1.4	Resto de reversiones + easter eggs	Medio
v1.5	Modo Desafío semanal	Medio-Alto
¿Quieres que profundice en algún aspecto concreto (diseño de la cuenta regresiva, detalles del nuevo árbol alternativo, o cómo implementar la persistencia del "Más Allá del Ciclo")?


##############################################################################################
Extende ese roadmpa en el tiempo y versiones. Futuros features



#############################################################################################


 Roadmap Actualizado v1.x — Post-publicación
Basado en tus ideas (mutaciones revertidas, meta-endgame, buffs cósmicos extendidos, advertencia anti‑consumo) más las funcionalidades ya planeadas. Las versiones son estimadas (pueden variar según feedback de jugadores).

🧩 Leyenda de hitos
Ícono	Significado
✅	Implementado (Fase 0 – lanzamiento inicial)
🔜	Prioridad alta (primeras semanas)
🟡	Prioridad media (siguientes meses)
⚪	Prioridad baja / nice‑to‑have
🌌	Meta‑endgame (post‑trascendencia 2+)
🚀 v1.0 – Lanzamiento Base (✅ ya implementado)
Juego estable (economía, mutaciones, biosfera, logros, legado, trascendencia)

Tutorial Fase 1 (welcome, highlight, primeros pasos)

Panel de atajos "?", objetivos, hints anti‑stuck

AudioManager (opcional, puede venir en hotfix)

🔜 v1.1 – Pulido inicial (primer mes)
Feature	Descripción	Estado
Anti‑consumo countdown	Cuando el sistema detecte que estás a punto de ser "devorado" (ej: depredador, colapso por estrés), mostrar cuenta atrás en grande 10…9…8… con sonido de amenaza.	🔜
Buff cósmico: Primeros pasos	Nuevo buff en Banco Cósmico (Ξ coste). Las 2 primeras compras de upgrades en cada run son gratis (similar a memoria_recurso pero con 2 usos y cósmico).	🔜
Sugerencia contextual avanzada	Si el jugador no realiza ninguna acción (click/compra) durante 50s, aparece un mensaje: "¿Atascado? Prueba L (lab), Banco Genético o Guardar/Salir." A los 60s, inicia countdown 10s antes de aplicar un "pequeño empujón" (ej: regalar $10).	🔜
Mejoras en tooltips	Añadir tooltip para μ (capital cognitivo) en el panel de fórmula (ya está). Extender a otros indicadores si faltan.	🔜
🟡 v1.2 – Mutaciones revertidas (primer trimestre)
Feature	Descripción	Estado
Buff de reversión en Banco Genético	Nuevos buffs (coste 50‑100 PL) que al comprarlos desactivan permanentemente una mutación específica (Tier 1) y desbloquean una rama alternativa oculta. Primera tanda: una por cada mutación original (5 en total). Aparecen tras primera trascendencia.	🟡
Rutas OP básicas	Ejemplo: revertir Hiperasimilación → "Fusión Catabólica" (click ×5 + pasivo ×5, botón "Metabolismo Híbrido"). Implementar al menos 2 rutas en esta versión.	🟡
Easter egg visual	Al revertir la primera mutación, aparece un pequeño mensaje y un efecto visual (pantalla parpadea, color especial).	🟡
Ajuste de balances	Las rutas revertidas deben ser potentes pero con algún coste o condición (ej: ε aumenta más rápido).	🟡
🟡 v1.3 – Ciclo biológico extendido
Feature	Descripción	Estado
Nuevas rutas revertidas	Completar las 5 mutaciones originales + añadir reversión para Depredador y Metabolismo Oscuro (secretos).	🟡
Meta‑logro "Arquitecto de la Reversión"	Desbloquear todas las rutas revertidas (7) → título + +20 PL + icono especial en perfil.	🟡
Interfaz de selección de ruta revertida	En la pantalla de mutación (cuando hay varias disponibles), mostrar claramente cuál es la ruta revertida (icono dorado, tooltip especial).	🟡
🌌 v1.4 – Meta‑endgame (post‑trascendencia 2+)
Esta es la capa que mencionaste: "desbloquee otro juego y/o botones".

Feature	Descripción	Estado
Puerta de Trascendencia Avanzada	Cuando el jugador ha trascendido al menos 2 veces y ha completado al menos 3 rutas revertidas (acumulativo entre runs), aparece un nuevo botón en el menú principal: "🌌 Más Allá del Ciclo".	🌌
Árbol de mutaciones alternativo	Al entrar, el juego se reinicia (como un NG++) pero con un conjunto de 5 mutaciones completamente nuevas (nombres, efectos, condiciones distintas). La UI cambia de color (ej: tema "Albino" o "Espectral").	🌌
Minijuego idling paralelo	Opcional: mientras juegas la partida normal, un segundo panel (mini‑ventana) muestra una "Gestión de Esencia Cósmica" que genera recursos extra pasivamente y se puede mejorar con puntos de trascendencia.	🌌
Logros específicos de meta‑endgame	"Primera mutación alternativa", "Completar run en modo albino", etc.	🌌
⚪ v1.5 – Pulido final y contenido extra (segundo trimestre)
Feature	Descripción	Estado
Nuevos buffs cósmicos	Añadir al menos 3 más (ej: "Reversión rápida" – reduce el coste de los buffs de reversión en un 20%; "Legado persistente" – al trascender, conservas 1 de las rutas revertidas activa).	⚪
Easter eggs ocultos	Combinaciones raras de reversiones producen diálogos o botones secretos (ej: revertir Hiperasimilación y Parasitismo juntos → una línea de texto: "El sistema se retuerce...").	⚪
Mejoras en la UI de objetivos	El panel "Obj." ahora también muestra el progreso hacia el meta‑endgame.	⚪
Sistema de notificaciones	Para eventos importantes (reversión desbloqueada, meta‑endgame disponible).	⚪
📅 Línea de tiempo estimada
Versión	Tiempo estimado (post‑lanzamiento)	Contenido principal
v1.0	Día 0	Base estable + tutorial Fase 1‑3
v1.1	Semana 1‑2	Countdown anti‑consumo, buff cósmico, sugerencias mejoradas
v1.2	Mes 1	Mutaciones revertidas (primeras 2‑3 rutas)
v1.3	Mes 2‑3	Resto de reversiones + logros asociados
v1.4	Mes 3‑4	Meta‑endgame (nuevo árbol y minijuego paralelo)
v1.5	Mes 4‑6	Buffs cósmicos extra, easter eggs, pulido final
🔁 Iteración continua: Entre versiones mayores se lanzarán hotfixes y pequeños parches de balance.

🧪 Notas sobre el countdown anti‑consumo
Propuesta concreta para v1.1:

Detectar condiciones de "consumo inminente" (ej: en Depredador, cuando quedan <5 upgrades por devorar; o en Metabolismo Oscuro, cuando biomasa >95; o en Parasitismo, cuando dinero <500 y biomasa >12).

Mostrar en el centro de la pantalla (o cerca del reactor) un texto grande y parpadeante:
"⚠️ SERÁS CONSUMIDO EN 10… 9… 8…"
También un sonido de advertencia (tic‑tac acelerado).

Si el jugador realiza alguna acción que lo salve (comprar upgrade, click, cerrar run manualmente), el countdown se cancela.

Si llega a 0, se ejecuta el evento de consumo y se muestra un mensaje de "Game Over" (que reinicia la run o cierra el juego, según diseño).

¿Quieres que profundice en algún punto concreto (por ejemplo, cómo implementar el countdown técnicamente o los requisitos exactos de las rutas revertidas)?


#######################################
Que te imaginas entonces +v.1.6
#######################################


🌌 v1.6 – Expansión Cósmica (tercer trimestre)
Superado el meta‑endgame básico, el juego se abre a una escala cósmica propiamente dicha.

Feature	Descripción
Multijugador asíncrono – "Clanes Fúngicos"	Los jugadores pueden crear o unirse a clanes (hasta 10 miembros). Cada clan tiene un micelio colectivo que crece con las acciones de todos (clicks, compras, trascendencias). Bonificaciones globales según nivel del clan.
Eventos estacionales	Rotación mensual de mutaciones especiales (ej: "Mutación Invernal" congelamiento de ε, "Mutación Primaveral" reproducción acelerada de biomasa). Recompensas exclusivas (iconos, títulos, PL).
Ranking global (opcional)	Tabla de líderes por PL total, tiempo de run más largo, mayor μ alcanzado, etc. Solo para quienes acepten compartir datos.
Tienda cósmica extendida	Nuevos buffs cósmicos (Ξ) que afectan al clan: ej "Simbiósis del Clan" – cada miembro aporta +2% a tus ingresos pasivos.
🧬 v1.7 – Editor de Mutaciones (poder de la comunidad)
Los jugadores más creativos pueden diseñar sus propias mutaciones y compartirlas.

Feature	Descripción
Editor de mutaciones	Interfaz visual para crear condiciones (ε > X, biomasa > Y, clicks acumulados, etc.) y efectos (click ×Z, pasivo ×W, +ε o -ε, etc.). Las mutaciones se guardan como archivos .tres que pueden compartirse.
Galería de la comunidad	Dentro del juego, los jugadores pueden explorar mutaciones creadas por otros, votarlas y usarlas (con un límite de 2 activas simultáneamente, además de las del juego base).
Mutación del mes	La más votada se integra como mutación oficial temporal (con recompensa para su creador).
🔄 v1.8 – "Trascendencia Cósmica" (prestige definitivo)
Un nuevo tipo de reinicio que va más allá de la trascendencia normal.

Feature	Descripción
Trascendencia Cósmica	Requiere: haber trascendido al menos 5 veces y completado el meta‑endgame (v1.4). Al activarla, TODO se resetea (PL, buffs, rutas completadas, incluso el árbol de mutaciones alternativo) a cambio de Esencia Pura (un nuevo recurso dorado).
Esencia Pura	Se gasta en mutaciones primordiales (efectos globales que persisten entre todas las runs futuras, ej: "Ingresos base ×1.10 permanente"). Son caras y muy poderosas.
Desafíos de Pureza	Modo opcional en el que juegas sin ningún buff de banco genético ni cósmico, pero las ganancias de PL/Ξ son ×2. Desbloquea logros únicos.
🎮 v1.9 – Integración con plataformas (Twitch / Discord)
Para streamers y comunidades.

Feature	Descripción
Modo Twitch	Los espectadores pueden votar por "mutaciones del caos" que afectan al streamer (ej: "+0.5 ε ahora" o "duplica biomasa durante 30s"). El streamer obtiene recompensas por interactuar.
Bot de Discord	Muestra estadísticas en tiempo real (dinero, ε, mutación activa), permite comandos como /hifas o /run_time.
Logros vinculados a comunidad	"Tener 10 espectadores activos en modo Twitch", "Unirte a un clan con miembros de 3 países distintos".
🌱 v2.0 – "Fungi Forever" (versión definitiva)
Cierre del desarrollo activo, pero con mantenimiento.

Feature	Descripción
Balance final	Ajuste de números basado en datos agregados de todos los jugadores.
Modo offline progresivo	Para móviles/web, el juego sigue generando recursos hasta 8 horas sin abrirlo (con un tope diario).
Galería de arte desbloqueable	Ilustraciones de cada mutación, hongos, lore, conseguibles al completar ciertos hitos.
Exportar/importar partida con código	Compartir runs completas con amigos.
Fin de actualizaciones masivas	Se anuncian ciclos de mantenimiento (compatibilidad con navegadores, corrección de bugs críticos).
🧪 Ideas extra (para expansiones opcionales)
Área	Posibilidad
Sonido dinámico	La música y SFX cambian según ε (más caótico cuanto más alto) y según mutación activa (tema propio). Requiere assets adicionales.
Modo oscuro / temas	Tema "Nocturno" (fondo negro, textos claros) y "Albino" (blanco, texto oscuro) desbloqueables con logros.
Narrativa / Lore	Diario del sistema: fragmentos de texto que aparecen al completar ciertas rutas, contando la historia del hongo desde su origen.
Logros por tiempo real	"Jugar 100 días diferentes", "Acumular 1 año de tiempo de juego".
📅 Resumen de versiones largas
Versión	Nombre	Contenido principal
v1.0	Lanzamiento	Base estable + tutorial
v1.1	Ajustes iniciales	Countdown anti‑consumo, buff cósmico
v1.2	Reversiones I	Primeras 2-3 rutas revertidas
v1.3	Reversiones II	Resto de reversiones + logros
v1.4	Meta‑endgame	Nuevo árbol alternativo + minijuego
v1.5	Pulido	Buffs cósmicos extra, easter eggs
v1.6	Cósmico social	Clanes, rankings, eventos estacionales
v1.7	Editor de mutaciones	Mutaciones creadas por la comunidad
v1.8	Trascendencia Cósmica	Prestige definitivo, Esencia Pura
v1.9	Modo streamer	Integración Twitch/Discord
v2.0	Fungi Forever	Versión estable definitiva
¿Quieres que profundice en alguna de estas versiones (por ejemplo, v1.6 clanes o v1.7 editor de mutaciones) con detalles de implementación?

#################
v1.7 editor de mutaciones
#########################

 v1.7 – Editor de Mutaciones (Diseño conceptual)
Esta versión convierte a los jugadores en diseñadores de mutaciones. La idea es que compartan sus creaciones y enriquezcan el ecosistema del juego sin necesidad de que los desarrolladores codifiquen cada nueva mutación.

🎨 Interfaz del editor
Acceso:
Botón "🧬 Editor de Mutaciones" en el menú principal (solo visible tras completar al menos una trascendencia, o tras v1.4). También se puede acceder desde el Banco Genético.

Diseño:
┌─────────────────────────────────────────────────────────────┐
│  🧬 Editor de Mutaciones                     [Guardar] [Salir] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Nombre:      [ Campo de texto ]                           │
│  Descripción: [ Área de texto ]                            │
│  Icono:       [🎲] [🖌️] [📁]  (seleccionar emoji o subir PNG)│
│                                                             │
│  ┌───────────── CONDICIONES ─────────────┐                 │
│  │ + Añadir condición                     │                 │
│  │ ┌───────────────────────────────────┐ │                 │
│  │ │ ε_runtime  >  0.40            [🗑] │ │                 │
│  │ │ Click %     >  80             [🗑] │ │                 │
│  │ │ Biomasa      >  4.0           [🗑] │ │                 │
│  │ │ Contabilidad == 0             [🗑] │ │                 │
│  │ │ Tiempo run   >  180 s         [🗑] │ │                 │
│  │ └───────────────────────────────────┘ │                 │
│  └────────────────────────────────────────┘                 │
│                                                             │
│  ┌───────────── EFECTOS ───────────────┐                   │
│  │ + Añadir efecto                      │                   │
│  │ ┌───────────────────────────────────┐ │                 │
│  │ │ Click × 10.0                  [🗑] │ │                 │
│  │ │ Pasivo × 0.25                 [🗑] │ │                 │
│  │ └───────────────────────────────────┘ │                 │
│  └────────────────────────────────────────┘                 │
│                                                             │
│  ⚠️ Coste de publicación: 25 PL / 5 Ξ                      │
│  [ Publicar en la Galería ]                                │
└─────────────────────────────────────────────────────────────┘

 Bloques de condiciones (disponibles)
Categoría	Condiciones posibles
Tiempo	run_time > X, run_time < X
Dinero	money > X, total_money_generated > X
Ingresos	delta_per_sec > X, click_power > X, passive_total > X
Estrés / Flexibilidad	epsilon_runtime > X, epsilon_peak > X, omega > X, omega_min > X
Biomasa / Hifas	biomasa > X, hifas > X, micelio > X
Mutaciones activas	mutation_homeostasis == true, mutation_red_micelial == true, etc.
Upgrades	nivel de accounting > X, nivel de cognitive > X, etc.
Genoma	genome.hiperasimilacion == "latente", genome.red_micelial == "activo", etc.
Logros	achievement_unlocked("id") == true
Variables booleanas	carnaval_active, vacio_hambriento_active, etc.
Los valores X son ajustables por el jugador (con límites predefinidos para evitar desbalance extremo, ej: ε_runtime no puede superar 2.0 en condición).

⚡ Bloques de efectos (disponibles)
Categoría	Efectos posibles (con rango ajustable)
Multiplicadores	click_power *= X, passive_total *= X, money_gain_rate *= X (0.1 ≤ X ≤ 10)
Aditivos	epsilon_runtime += X, biomasa += X, money += X (con límites)
Modificadores de estado	mutation_hyperassimilation = true, omega_min = max(omega_min, X), etc.
Efectos temporales	buff_timer(id, duración) (ej: "click ×2 durante 30s", "ε no aumenta durante 60s")
Botones especiales	Añadir un botón adicional en la UI que dispare un efecto bajo demanda (cooldown configurable).
📤 Publicación y galería
Coste de publicación:
25 PL o 5 Ξ (para incentivar el uso de ambos sistemas). El coste se reintegra si la mutación es aprobada/mod destacada.

Flujo:

El jugador diseña la mutación.

Paga el coste y la envía a la galería.

La mutación queda pendiente de revisión automática (se comprueba que no tenga valores imposibles).

Aparece en la galería con etiquetas (ej: "Desequilibrada", "Creativa", "Rara").

Interacción con mutaciones de otros:

Cada jugador puede tener activas hasta 2 mutaciones de la galería a la vez (además de las del juego base y las revertidas).

Posibilidad de votar 👍/👎.

Las más votadas del mes se destacan y su creador recibe un bonus (PL, Ξ o título especial).

⚖️ Balance automático (opcional, según diseño)
Para evitar creaciones absurdas, el juego puede calcular un índice de poder:

power_score = sum(efectos) / (sum(condiciones) + 1)

Si el power_score excede un umbral (ej: 2.0), la mutación se marca como "Desequilibrada" y muestra una advertencia antes de publicarse. Los jugadores pueden filtrar por equilibrio en la galería.

🧪 Ejemplo de mutación creada por editor
"Furia Meteórica"

Condiciones: ε_runtime > 0.70, click_power > 100, biomasa > 10

Efectos: click_power × 3.0, epsilon_runtime += 0.2

Botón adicional: "Meteorito" – consume 10 de biomasa para dar un click ×5 instantáneo (cooldown 30s).

Icono: ☄️

El jugador la publica, otros la votan, y si se vuelve popular aparece en rotación mensual.

💎 Integración con el lore
Las mutaciones de la galería se explican dentro del juego como "esporas mutantes provenientes de otros sistemas" o "legados de otros hongos viajeros".

El editor lleva un contador de mutaciones creadas y descargadas, con logros asociados: "Primera mutación publicada", "Tu mutación fue usada por 100 jugadores", "Editor legendario".

🔧 Requerimientos técnicos para implementar
Área	Necesidad
Serialización	Guardar mutaciones como recursos .tres o .json. Incluir metadatos (autor, fecha, votos, ID).
Validación	Función que recorre condiciones/efectos y comprueba rangos válidos.
Ejecución	Al activar una mutación (en EvoManager), evaluar condiciones y aplicar efectos; los efectos temporales y botones necesitan un sistema de buffs.
Galería	Servidor (o almacenamiento local simulado) para compartir mutaciones. En una primera versión offline, podrían ser solo locales o vía archivos compartidos manualmente.
UI dinámica	Generar los bloques de condiciones/efectos a partir de una lista de definiciones en código.
🧪 Primera iteración (simplificada)
Para v1.7 inicial, se puede lanzar una versión local:

El editor solo guarda mutaciones localmente (no hay galería online).

El jugador puede cargar mutaciones de otros compartiendo archivos .tres.

Sin sistema de votos ni destacados.

En parches posteriores (v1.7.1, v1.7.2) se añade la galería centralizada si el juego tiene suficiente comunidad.

¿Quieres que profundice en cómo implementar técnicamente el editor (estructura de datos, sistema de evaluación de condiciones, UI dinámica) o prefieres seguir con la planificación de otras versiones?

#################
que te imaginas para hacer tipo leaderboards o speedruns y builds, en que v entraria?
####################


Leaderboards, Speedruns y Builds – ¿En qué versión?
Estas funcionalidades encajan perfectamente en v1.6 – Expansión Cósmica (clanes, rankings, eventos estacionales). De hecho, se complementan: los clanes fomentan la cooperación, mientras que los rankings y speedruns fomentan la competición individual.

📊 Leaderboards (Tablas de clasificación)
Categoría	Métrica	¿Reset periódico?	Notas
PL total	Puntos de Legado acumulados (histórico)	No	Refleja progresión total del jugador
Ξ total	Esencia acumulada (histórica)	No	Prestigio cósmico
Run más larga	Tiempo de sesión (segundos) en una sola run	No	Resistencia / idle extremo
μ máximo alcanzado	Pico de capital cognitivo	No	Indica eficiencia en builds cognitivas
ε_peak más alto	Mayor estrés estructural alcanzado	No	Para builds de riesgo/colapso
Mayor Δ$/s	Pico de metabolismo	No	Builds de producción masiva
Mutaciones distintas completadas	Número de rutas finales únicas	No	Completismo
Velocidad (speedrun)	Tiempo real desde inicio de run hasta cerrarla	Sí (semanal/mensual)	Competencia activa
Eventos estacionales	Puntos en evento actual	Sí (cada evento)	Rotación mensual
⏱️ Speedruns (categorías)
Se pueden definir varias categorías de speedrun, cada una con su propia tabla.

Categoría	Objetivo	Tiempo típico estimado
Any% (run rápida)	Cerrar la primera run posible (cualquier final)	5-15 minutos
Homeostasis%	Cerrar específicamente la ruta HOMEOSTASIS	20-40 minutos
Red Micelial%	Cerrar ESPORULACIÓN o SINGULARIDAD	30-60 minutos
Parasitismo%	Cerrar PARASITISMO	40-90 minutos
Trascendencia%	Alcanzar primera trascendencia (desde run nueva)	2-5 horas
100% (completista)	Cerrar todas las rutas únicas (en runs separadas)	Muchas horas (meta)
Características del modo speedrun:

Un botón "Iniciar Speedrun" en el menú principal que:

Resetea el juego a estado fresco (opcional, o usa el save actual).

Inicia un cronómetro en pantalla.

Al cerrar la run, detiene el crono y pregunta si guardar tiempo.

Los tiempos se envían a la tabla de clasificación (con verificación anti-trampas básica: hash del estado, detección de debug mode, etc.).

Categorías desbloqueables: no todas están disponibles al principio (ej: Parasitismo% solo tras haber completado esa ruta al menos una vez).

🏗️ Builds (compartir configuraciones)
Un build es una combinación de:

Mutaciones activas (hasta 1 o 2, según estado del juego).

Buffs del Banco Genético activados.

Buffs del Banco Cósmico (si los hay).

Estilo de juego recomendado (activo / pasivo / equilibrio).

Funcionalidades:

Característica	Descripción
Guardar build actual	Un botón "💾 Guardar Build" que captura la configuración actual (qué mutaciones están activas, qué buffs legacy/cósmicos están encendidos).
Compartir build	Genera un código corto (ej: BUILD-ABC123) o un archivo .json. Otros jugadores pueden importarlo.
Cargar build	Aplica automáticamente los buffs (si el jugador los tiene desbloqueados) y sugiere la mutación a activar.
Builds destacados	En la galería (v1.7) se puede tener una sección de builds populares, con enlace directo a la configuración.
Builds por objetivo	"Build para speedrun Any%", "Build para alcanzar μ alto", etc. Los jugadores etiquetan sus builds.

 Relación con otras versiones
Feature	Depende de	Versión sugerida
Leaderboards (estáticas)	Sistema de cuentas (o ID local)	v1.6
Leaderboards (speedrun)	Sistema de verificación de tiempos	v1.6
Speedrun mode	Nuevo estado de juego "speedrun"	v1.6
Builds (guardar/cargar)	API de serialización de configuración	v1.6
Builds (compartir con código)	Almacenamiento en servidor local o nube	v1.6 o v1.7
Builds en galería	Integración con editor de mutaciones	v1.7
📅 Ajuste en el roadmap
Versión	Contenido principal	Añadido
v1.6	Clanes, eventos estacionales, leaderboards estáticas y de speedrun, modo speedrun, sistema de builds	✅
v1.7	Editor de mutaciones, galería, builds en la galería	✅
🧩 Nota sobre verificación anti-trampas
Para leaderboards y speedruns sería importante (aunque opcional en una primera versión) implementar:

Al iniciar un speedrun, se deshabilita el modo debug y se registra un hash de la configuración inicial.

Durante la run, se toman snapshots periódicas para detectar desviaciones (ej: si se activa una mutación que no debería).

Al finalizar, se envía el tiempo + el log de eventos + hash final.

En la tabla, los tiempos sospechosos pueden ser marcados manualmente por moderadores o la comunidad.

Sin embargo, para un juego indie, se puede empezar con un sistema de confianza (el jugador declara su tiempo) y añadir verificación más tarde si hay demanda o problemas de trampas.

¿Quieres que elabore más detalles sobre cómo implementar técnicamente el modo speedrun o los leaderboards?

##############
que otras mejoras se te ocurren a futuro?
###############

Otras mejoras futuras (brainstorming abierto)
Más allá de v1.6–v1.7, se me ocurren muchas direcciones interesantes. Aquí van, agrupadas por áreas:

🧩 Progresión alternativa y meta‑progresión
Idea	Descripción
Prestige de clanes	El clan puede "trascender" colectivamente, reiniciando su nivel pero dando bonificaciones permanentes (ej: +5% de producción base para todos los miembros).
Árbol de habilidades de Esencia Pura (v1.8)	En lugar de comprar buffs sueltos, la Esencia Pura se invierte en un árbol de habilidades con ramas (ej: "Economía", "Biología", "Caos") y nodos que se desbloquean en cadena.
Desafíos diarios / semanales	Objetivos rotativos (ej: "Llegar a ε > 0.80 sin morir", "Generar $1M solo con trueque"). Recompensas: PL, Ξ, o moneda exclusiva para cosmeticos.
Roguelite mode	Run con modificadores aleatorios (ej: "Los upgrades cuestan el doble", "El click no da dinero, solo reduce ε"). Al cerrar, obtienes puntos para comprar ventajas para la próxima run.
🎨 Personalización y estética
Idea	Descripción
Temas visuales desbloqueables	Fondo de pantalla, colores de UI, fuente, skins para el reactor. Se consiguen con logros, eventos, o comprando con PL/Ξ.
Avatar de perfil	Cada jugador tiene un pequeño icono (hongo, espora, mutación) que muestra en rankings, clanes, etc. Desbloqueable por hitos.
Animaciones de reactor personalizables	Efectos de partículas alternativos, formas del núcleo, estelas. Se pueden comprar o encontrar en cofres de eventos.
Música dinámica por mutación	Cada mutación (o ruta revertida) tiene su propio tema musical. El jugador puede elegir cuál suena en cada run (si las tiene desbloqueadas).
🎲 Nuevas mecánicas de juego
Idea	Descripción
Mutaciones híbridas (combinaciones)	Si tienes dos mutaciones activas (gracias a algún buff especial), puedes fusionarlas en una tercera mutación híbrida con efectos mezclados. Ej: Hiperasimilación + Homeostasis → "Ruptura Estable": click ×5, pasivo ×0.75, ε se mantiene bajo.
Riesgo / recompensa temporales	Aparece un evento emergente: "Tormenta cósmica. ¿Aceptas? (+5 ε ahora, pero ×2 producción por 30s)". El jugador decide en pocos segundos.
Misiones de mutación	Cada mutación (una vez activada) te pide completar un objetivo secundario (ej: "Alcanza ε > 0.70 con Hiperasimilación activa"). Si lo logras, obtienes un bonus permanente pequeño (+2% a esa mutación en futuras runs).
Comercio entre jugadores (clanes)	Los miembros del clan pueden intercambiar recursos (PL, Ξ, esporas) a una tasa de conversión desfavorable (ej: 1000 PL → 1 Ξ). Activa economía interna.
🌐 Integración y comunidad
Idea	Descripción
Tournaments (torneos)	Eventos semanales donde los jugadores compiten en una categoría específica (ej: "máximo μ en 1 hora"). Los mejores reciben premios exclusivos.
Compartir runs como "replays"	Un jugador puede exportar una run completa (eventos, acciones) como archivo. Otros pueden "reproducirla" para ver cómo se hizo (útil para speedruns o aprender builds).
API pública	Permitir que aplicaciones externas (discord bots, webs) consulten datos básicos del jugador (rankings, build actual).
Modo espectador en clanes	Ver en tiempo real la partida de un compañero de clan, con retardo de unos segundos. Ideal para aprender o apoyar.
🧪 Experimentación y ciencia ciudadana
Idea	Descripción
Modo sandbox	Acceso a todas las mutaciones, recursos infinitos, sin persistencia. Para testear builds o aprender mecánicas. Se desbloquea tras cierta progresión.
Telemetría anónima (opt‑in)	El juego puede enviar datos de uso (sin datos personales) para que el desarrollador vea qué mutaciones son más populares, dónde abandonan los jugadores, etc. A cambio, los participantes reciben pequeño bonus.
Parches experimentales	Canales beta donde los jugadores pueden probar nuevas mutaciones o balances antes de lanzarlos oficialmente, y dar feedback.
🃏 Easter eggs y humor
Idea	Descripción
Consola secreta (tipo "Konami code")	Secuencia de teclas (↑↑↓↓←→←→BA) que desbloquea un reactor con forma de ñoqui o un mensaje de los desarrolladores.
Referencias a la cultura del idle	Al alcanzar ciertos hitos, aparecen diálogos meta: "¿Sabías que en otro juego incremental esto daría ×10 más?"
Modo "Pato de goma"	Un pato de goma flota en el reactor. No hace nada, pero puedes hacer clic y suena un "cuac". Desbloqueable con un logro oculto.
Carta de los desarrolladores	Un objeto coleccionable que aparece aleatoriamente al cerrar runs, conteniendo un mensaje personal, anécdotas del desarrollo o chistes.
📱 Plataformas adicionales
Idea	Descripción
Aplicación móvil nativa	Versión para iOS/Android con misma cuenta, notificaciones push, modo offline.
Progresión cruzada (cross‑save)	Guardar partida en la nube (login con Google/Discord) para continuar en cualquier dispositivo.
Integración con Google Play Games / Game Center	Logros, leaderboards, guardado en la nube.
Versión para Steam (Greenlight)	Con logros de Steam, cartas coleccionables, emojis, fondos de pantalla.
🧠 Calidad de vida (QoL) avanzada
Idea	Descripción
Deshacer compra (5s)	Un botón que aparece tras comprar un upgrade por error, permite revertir la compra si no ha pasado mucho tiempo.
Planificador de builds (offline)	Interfaz donde puedes simular combinaciones de mutaciones y buffs sin tener que jugar, mostrando resultados teóricos (Δ$/s, ε esperado, etc.).
Historial de runs con gráficos	Al cerrar una run, se guarda una gráfica temporal de ε, Ω, biomasa, dinero. Puedes comparar runs entre sí.
Marcadores (bookmarks)	Guardar momentos específicos de una run (ej: justo antes de trascender) para volver a ellos más tarde.
Atajos de teclado configurables	El jugador puede reasignar las teclas (1‑9, L, F1, F2, etc.) a su gusto.
📅 ¿Qué versión para cada cosa?
Área	Versión sugerida	Prioridad
Personalización (temas, avatares)	v1.6	🟡 Media
Música dinámica por mutación	v1.7	⚪ Baja
Nuevas mecánicas (híbridas, eventos emergentes)	v1.8	🌌 Meta
Torneos / API pública	v1.9	🌌 Meta
Modo sandbox / telemetría	v1.6 – v1.7	🟡 Media
Easter eggs	Cualquier versión	⚪ Baja
Móvil / Steam	v2.0 o posterior	⚪ Baja