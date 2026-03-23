Lo que sigue es un documento de arquitectura del DLC FÚNGICO + compendio matemático + plan mínimo implementable.

Nada de divague. Esto es el “README interno” del sistema.

🍄 IDLE v0.8 — DLC Fúngico
Arquitectura del Sistema Vivo

Este DLC agrega una segunda ley de la termodinámica al modelo económico.

Tu juego ya tiene:

producción

estructura

eficiencia

fricción (ε)

Pero no tenía:

un sistema que absorba entropía

Eso es la biosfera.

1️⃣ Qué es cada variable (definición física)
Variable	Significado real
ε_runtime	Estrés estructural del sistema económico
nutrients	Entropía económica capturada
biomass	Capacidad del sistema para absorber estrés
micelio	Biomasa estructurada (memoria biológica)
μ	Capacidad cognitiva (organización)
κμ	Rigidez productiva ajustada por μ
ω	Flexibilidad macro del sistema
2️⃣ Ciclo termodinámico completo

La economía produce estrés
La biosfera lo metaboliza

Econom
ı
ˊ
a
→
𝜀
→
Nutrientes
→
Biomasa
→
𝜀
efectivo
Econom
ı
ˊ
a→ε→Nutrientes→Biomasa→ε
efectivo
	​


Formalmente:

Nutrientes
𝑑
𝑁
𝑑
𝑡
=
𝑘
𝑛
⋅
𝜀
𝑟
𝑢
𝑛
𝑡
𝑖
𝑚
𝑒
dt
dN
	​

=k
n
	​

⋅ε
runtime
	​


(ya lo implementaste)

Biomasa
𝑑
𝐵
𝑑
𝑡
=
𝑘
𝑏
⋅
𝑁
⋅
𝜇
dt
dB
	​

=k
b
	​

⋅N⋅μ

Crecimiento regulado por cognición.

Consumo de nutrientes
𝑁
←
𝑁
−
𝑑
𝐵
𝑑
𝑡
N←N−
dt
dB
	​

3️⃣ Biomasa como amortiguador de crisis

Biomasa reduce el estrés efectivo:

𝜀
𝑒
𝑓
𝑒
𝑐
𝑡
𝑖
𝑣
𝑜
=
𝜀
1
+
𝐵
ε
efectivo
	​

=
1+B
ε
	​


Eso no elimina crisis,
las vuelve digeribles.

4️⃣ Biomasa como booster económico

La biomasa no aumenta dinero directamente.
Modula eficiencia.

Definimos:

𝛽
(
𝐵
)
=
1
+
log
⁡
(
1
+
𝐵
)
β(B)=1+log(1+B)

Y afecta:

Variable	Efecto
md	md · β(B)
me	me · β(B)
so	so · (1 + 0.5β)
μ	μ · (1 + 0.3β)

Esto es exactamente lo que vos intuías:

biomasa → flujos
micelio → estructura

5️⃣ Micelio (Tier 2 del DLC)

Micelio es biomasa cristalizada:

𝑀
=
𝐵
M=
B
	​


Micelio:

nunca decrece

afecta estructura

no depende de nutrientes

Efectos:

𝜇
𝑒
𝑓
𝑒
𝑐
𝑡
𝑖
𝑣
𝑜
=
𝜇
⋅
(
1
+
0.1
𝑀
)
μ
efectivo
	​

=μ⋅(1+0.1M)
𝜅
𝜇
=
𝑘
⋅
(
1
+
𝛼
(
𝜇
𝑒
𝑓
𝑒
𝑐
𝑡
𝑖
𝑣
𝑜
−
1
)
)
κ
μ
	​

=k⋅(1+α(μ
efectivo
	​

−1))

Esto vuelve al DLC parte del corazón del modelo.

6️⃣ Metabolismo (indicador de crisis)

Para que el jugador vea lo invisible:

Metabolismo
=
𝐵
Δ
$
Metabolismo=
Δ$
B
	​


Estados:

M	Estado
>0.12	Estable
0.06–0.12	Forzado
0.03–0.06	Agotado
<0.03	Crítico

No es un “evento”.
Es una condición física.

7️⃣ Por qué esto es brillante (no marketing, física)

Antes:

más producción = mejor

Ahora:

más producción sin biomasa = colapso

Esto crea un sistema que:

se acelera

se sobrecarga

necesita amortiguadores

se vuelve complejo

Es un capitalismo termodinámico.