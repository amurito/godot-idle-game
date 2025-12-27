IDLE — The Lab (v0.5.1)
The Lab es una versión experimental del proyecto IDLE cuyo objetivo no es aumentar el rendimiento del jugador, sino hacer visible la estructura matemática del sistema económico interno.

En lugar de ocultar fórmulas detrás de progreso incremental, esta versión expone:

los términos productivos del sistema
sus modificadores
la contribución marginal de cada componente
las unidades de medida
la dominancia del sistema en tiempo real
The Lab funciona como un laboratorio de incentivos: no busca balancear la experiencia de juego, sino permitir observar y estudiar el comportamiento del modelo.

🎯 Objetivo de la versión
Separar economía, análisis y UI — y convertir el juego en un entorno de experimentación matemática.

Esta versión introduce:

✔ modelo económico desacoplado de la interfaz
✔ análisis de términos dominantes
✔ representación simbólica de la fórmula
✔ descomposición del aporte de cada componente
✔ unidades explícitas por segundo
✔ comunicación transparente del sistema

El jugador no “progresa”. El jugador observa la evolución del sistema.

🧠 Estructura del modelo
El crecimiento del sistema se expresa como:

Δ$ = clicks × (a × b × c) + d × md + e × me

yaml Copiar código

Donde:

Símbolo	Componente
a	click base
b	multiplicador
c	persistencia
d	trabajo manual
md	ritmo de trabajo
e	trueque corregido
me	red de intercambio
📈 Unidades del sistema
Las magnitudes se expresan en:

Δ$ / s → tasa de crecimiento del sistema
d / s → trabajo manual efectivo
e / s → trueque corregido
Esto permite evaluar el rendimiento en términos energéticos del modelo
y no como números absolutos sin contexto.

📊 Lecturas mostradas en pantalla
La interfaz expone:

✔ Fórmula simbólica
(términos visibles según estén desbloqueados)

✔ Valores numéricos de cada parámetro
✔ Aporte marginal
• Click PUSH • Trabajo Manual / s • Trueque / s

shell Copiar código

✔ Término que domina el sistema
CLICK domina el sistema Trabajo Manual domina el sistema Trueque domina el sistema

yaml Copiar código

✔ Distribución porcentual de aporte
Incluyendo:

click
trabajo manual
trueque
Δ$ estimado / s
🔎 Filosofía de diseño
The Lab sigue 3 principios:

Transparencia > progresión oculta
Comprensión sistémica > optimización ciega
El jugador interpreta — no grindea
Este proyecto explora:

cómo emergen relaciones de poder entre términos productivos
cómo cambia el régimen del sistema con cada mejora
cuándo un término pasa a dominar al resto
qué significa “eficiencia” en una economía simulada
🧪 Qué observar mientras se juega
Al avanzar es esperable detectar:

✔ transición desde dominio de CLICK
✔ aparición progresiva de d × md
✔ cruce de fase cuando e × me comienza a escalar
✔ cambio real del comportamiento del sistema

The Lab no recompensa spam de upgrades.

El objetivo es:

leer, interpretar, comparar, entender.

🧭 Próximos pasos (Roadmap conceptual)
Las versiones futuras explorarán:

fⁿ como estructura autosimilar acotada
convergencia a atractores del sistema
elasticidad entre términos productivos
shock de incentivos
acoplamiento social entre agentes
The Lab no es el fin del juego
es la base teórica del juego futuro.

🏷 Versión
IDLE — The Lab v0.5.1 (stable)

yaml Copiar código

Esta build funciona como baseline oficial del modelo
para futuras iteraciones experimentales.

📜 Licencia & propósito
Este proyecto no está pensado como producto comercial, sino como experimento de diseño matemático y cognitivo.

Si algo en el sistema te dispara una idea, cuestionamiento o intuición nueva…

entonces cumplió su objetivo.
