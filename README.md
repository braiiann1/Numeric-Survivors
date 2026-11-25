# 🧮 Numeric Survivors — un bullet heaven en el que las armas son errores de coma flotante

> **¿Y si cada arma de un survivor-like fuera un error numérico real?**
> Proyectiles que se desvían porque el ángulo se redondea. Un acumulador que se traga las sumas pequeñas. Partículas que se desvanecen por underflow. Explosiones que duplican su daño hasta desbordar. Un haz que nace de restar dos números casi iguales. Zonas donde el daño es literalmente `NaN`.

**Numeric Survivors** es un *bullet heaven* de 10 minutos hecho en **Godot 4.3**: te mueves, las armas disparan solas, subes de nivel y eliges mejoras. La diferencia es que **cada mecánica está construida a partir de una fórmula**, no de un nombre bonito. Aunque se le ponga otro nombre al arma, su comportamiento sigue dando a entender qué fenómeno numérico representa. 🎯

---

## 🎮 Cómo se juega

| Acción | Tecla |
|---|---|
| Moverte | `WASD` / flechas |
| Pausa | `Esc` / `P` |
| Volver al menú | `M` |
| Reiniciar al terminar | `R` |
| Elegir mejora | `Enter` / clic / `1` · `2` · `3` |

- 🕹️ **Objetivo:** sobrevivir **600 s** (10 minutos). Si llegas a 0 de vida, reinicia (skill issue).
- 🔫 **Armas automáticas:** no apuntas ni disparas. Tú solo esquivas y vas decidiendo tu build.
- 🧠 **Build:** llevas hasta **6 armas**, cada una con **8 niveles** (1–7 mejoras, 8 evolución).
- 💎 **XP:** los enemigos sueltan gemas que se te acercan solas. Al subir de nivel el juego se pausa y eliges **1 de 3 cartas**. Un **orbe grande** (2 % en enemigos comunes, garantizado en élites y jefes) vale **8×** y tiene más radio de atracción.
- 👑 **Élites cada 20 s** y **jefe a los 90 s**, después cada 120 s.

---

## 📈 Progresión: la curva de XP también es una fórmula

La XP necesaria para pasar del nivel `L` al `L+1` es:

```text
necesaria(L) = 5 + 6 · (L − 1) = 6L − 1
```

| Nivel | 1→2 | 2→3 | 3→4 | 4→5 | 5→6 | 6→7 | 7→8 | 8→9 |
|---|---|---|---|---|---|---|---|---|
| XP | 5 | 11 | 17 | 23 | 29 | 35 | 41 | 47 |

La XP acumulada para alcanzar el nivel `n` se puede cerrar en una sola expresión:

```text
XP_total(n) = (n − 1) · (3n − 1)
```

Al nivel 8 hacen falta **161 XP**. La curva es lineal y no exponencial a propósito, pues la partida dura 10 minutos y quieres que la build arranque pronto🚀

Podria pensar en una curva exponencial para un futuro modo dificil😅

### 🃏 Cartas de nivel

Cada subida de nivel ofrece 3 cartas de una bolsa con pesos:

```text
peso(estadística)   = 1
peso(nivel de arma) = 3
peso(arma nueva)    = 4
```

Mientras tengas **menos de 3 armas**, una carta de arma nueva está garantizada. Así ninguna partida se queda con una sola arma y el *buildcraft* empieza desde el minuto uno. 🎲

La pantalla de subida de nivel es una parada completa: fondo animado, tres cartas con **icono circular**, etiqueta (`NUEVA ARMA` / `SUBE NIVEL` / `EVOLUCIÓN`), descripción y progreso. Las cartas entran escalonadas y las evoluciones brillan con su **color propio**. Puedes elegir con clic, `Enter` o las teclas `1`, `2` y `3`. Al pie se ve el arsenal actual con sus iconos. 🃏✨

**Estadísticas mejorables:** potencia +15 %, cadencia +12 %, precisión +8 %, movilidad +12, vitalidad +20, magnetismo +25, +1 proyectil, +1 perforación, regeneración +0,4/s, blindaje +1.

---

## 👾 Enemigos: cuatro arquetipos y una curva de dificultad

| Enemigo | Vida | Velocidad | Daño | XP | Aparece | Peso |
|---|---:|---:|---:|---:|---|---:|
| 🐀 Rata | 8 | 55 | 5 | 1 | 0:00 | 3 |
| 🐇 Conejo | 6 | 95 | 4 | 1 | 0:00 | 3 |
| 🦇 Murciélago | 12 | 80 | 6 | 2 | 1:00 | 2 |
| 🐗 Jabalí | 30 | 45 | 10 | 3 | 2:30 | 1 |

Las figuras están **dibujadas por código** (soy muy malo con los diseños, la IA carreó esa parte) sin sprites: ojos, sombras, orejas, alas animadas y colmillos. 👀

El escalado con los minutos `m` transcurridos es multiplicativo:

```text
vida    = base · (1 + 0,65 · m)
daño    = base · (1 + 0,16 · m)
velocidad = base · (1 + 0,025 · m)
```

A los 10 minutos: **×7,5 de vida**, **×2,6 de daño** y **×1,25 de velocidad**.🔥🔥

### 🌊 Director de oleadas

```text
intervalo(t) = lerp(0,6 s → 0,16 s, t / 600)
tanda(t)     = 1 + floor(t / 150)
enjambre     = 6 + floor(t / 70)   (cada 30 s, en círculo)
tope         = 380 enemigos activos
```

Los enemigos aparecen en un **anillo alrededor del jugador** (nunca en el origen ni encima de ti) y entran caminando desde fuera de cámara. La dificultad no depende solo de la cantidad: también de que las tandas crecen y de que cada 30 s llega una oleada circular que te obliga a moverte. 🌀

---

## 👑 Élites y jefes

| | Vida | Daño | Velocidad | XP | Extra |
|---|---:|---:|---:|---:|---|
| ⭐ Élite | ×6 | ×1,4 | ×0,85 | ×5 | Aura dorada, barra propia, orbe grande garantizado |
| 💀 Jefe | ×60 | ×2,2 | ×0,55 | ×40 | Aura roja, barra en el HUD, embestida cada 6 s a ×2,3 de velocidad |

- El primer jefe llega a los **90 s**; después, uno cada **120 s** (máximo uno activo).
- El jefe se telegrafía con un anillo, sacudida de cámara y un aviso en pantalla.
- Al morir suelta **1 orbe grande + 6 gemas** repartidas en círculo.

---

## ⚔️ Las 6 armas, con sus matemáticas

El pollo del arroz con pollo 🐔🍗.  Cada arma tiene un fenómeno, una fórmula de daño, una progresión y una evolución. Los números que siguen son **sin mejoras de estadísticas** (potencia 1, cadencia 1, precisión 0), para que se puedan comparar entre sí.

### 1️⃣ Truncamiento y redondeo — *cuantización angular* 📐

**Fenómeno:** los reales se aproximan a números representables. El ángulo de disparo se cuantiza a una rejilla; el error es el residuo del redondeo.

```text
precisión_efectiva = 0,35 + 0,07 · (nivel − 1) + 0,3 · precisión
error_máximo       = 18° · (1 − precisión_efectiva)²
paso               = error_máximo
ángulo_disparado   = round(ángulo_ideal / paso) · paso
desvío             ≤ paso / 2
daño               = (5 + 1,5 · (nivel − 1)) · potencia
proyectiles        = 1 + floor((nivel − 1) / 3) + extra   (+1 al evolucionar)
cooldown           = max(0,18 ; (0,8 − 0,05 · (nivel − 1)) / cadencia)
```

| Nivel | Daño | Proyectiles | Cooldown | Precisión efectiva | Desvío máx. | DPS 1 objetivo |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 5 | 1 | 0,80 s | 0,35 | ±3,80° | 6,25 |
| 8 | 15,5 | 4 | 0,45 s | 0,84 | ±0,23° | 137,8 |

- El desvío depende del cuadrado del margen de error `(1 − precisión_efectiva)²`: cada punto de precisión se nota más cuanto más cerca estás de 1. 📐
- Con precisión 1,0 el desvío máximo baja a **±0,0009°**.
- 🧬 **Evolución — Doble Precisión:** +1 proyectil, perforación y error despreciable.

### 2️⃣ Absorción numérica — *suma que se traga lo pequeño* 🧲

**Fenómeno:** al sumar una cantidad pequeña a un acumulador grande, la pequeña puede no cambiar el resultado (pérdida por absorción).

```text
aporte    c = (1 + 0,45 · (nivel − 1)) · (1 + 0,15 · precisión)
epsilon   ε = A · max(0,02 ; 0,12 − 0,012 · nivel − 0,04 · precisión)
si c < ε  →  se pierde (lost += c)
si c ≥ ε  →  A += c
onda      = 1,1 · potencia · (A + lost si nivel ≥ 5)
radio     = 150 + 7 · nivel
liberación cada max(0,5 ; (2,2 − 0,12 · (nivel − 1)) / cadencia)
```

El acumulador se estanca en un **punto de equilibrio** cuando la liberación tarda lo suficiente:

```text
A* = c / ε_rel
```

| Nivel | Aporte | ε relativo | A al liberar | Onda | Radio | DPS (área) |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 1,00 | 0,108 | 9,26 | 10,2 | 157 | 4,6 |
| 8 | 4,15 | 0,024 | 40,3 | 44,3 | 206 | 32,6 |

- En los niveles 1–4, `lost` se descarta: todo lo absorbido se pierde. Al nivel 1 el equilibrio (9,26) llega antes de liberar, así que parte de las aportaciones desaparece. 📉
- En el nivel 8 las aportaciones por liberación (40,3) no llegan a `A*` (172,9), así que no se absorbe nada; el DPS converge a `7,857 · c = 32,6`. 📈
- A partir del nivel 5 se aplica **suma compensada (Kahan)**: `lost` se recupera al liberar, y el DPS pasa a ser proporcional a la cadencia. 🧮
- 🧬 **Evolución — Acumulador Compensado:** conserva todo, la onda crece sin pérdida.

### 3️⃣ Underflow — *decaimiento exponencial bajo el rango* 🫧

**Fenómeno:** una magnitud se hace tan pequeña que deja de ser representable y desaparece.

```text
magnitud(t) = e^(−λt)
λ           = max(0,22 ; 1,7 − 0,13 · (nivel − 1) − 0,35 · precisión)
daño golpe  = (4 + 1,2 · (nivel − 1)) · potencia · magnitud(t)
alcance     = (v / λ) · ln(1 / magnitud_mínima)
v           = 260 + 12 · nivel
vida        = 2 + 0,12 · nivel
```

| Nivel | Daño base | λ | Partículas | Alcance | Daño/partícula a 100 px | Intervalo |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 4,0 | 1,70 | 3 | 293 px | 2,14 | 1,35 s |
| 8 | 12,4 | 0,79 | 11 | 1.054 px (vida) | 9,93 | 0,86 s |

- El daño cae con la distancia siguiendo `D(d) = D₀ · e^(−(λ/v)·d)`. Es una exponencial negativa disfrazada de bala. 📉
- Al nivel 1 la partícula muere por magnitud mínima (0,16) a los ~300 px; al nivel 8 sobrevive a toda su vida y termina con magnitud 0,096. Ese es el “rango ampliado”.
- Abanico de 30° con jitter de ±0,03 rad; +1 perforación desde el nivel 5.
- 🧬 **Evolución — Lluvia Subnormal:** 11 partículas mínimas, 3 perforaciones y decaimiento lento.

### 4️⃣ Overflow — *duplicación hasta desbordar* 💥

**Fenómeno:** una magnitud crece hasta superar el máximo representable; al desbordar se reduce con `fmod`.

```text
carga₀ = 1
daño(n) = base · carga(n)
carga(n+1) = 2 · carga(n)
si carga(n+1) > cap:
    carga(n+1) = max(1 ; (2 · carga(n)) mod cap)
base   = 7 + 2,5 · (nivel − 1)
cap    = 4096 si evolucionada, si no (6 + 4 · (nivel − 1)) · (1 + 0,75 · precisión)
radio  = 85 + 8 · nivel (+45 evolucionada)
```

| Nivel | Base | Cap | Secuencia de cargas | Carga media (régimen) | Daño medio | DPS (área) |
|---|---:|---:|---|---:|---:|---:|
| 1 | 7 | 6 | 1 → 2 → 4 → 2 → 4 … | 3,0 | 21 | 8,75 |
| 8 | 24,5 | 4096 | 1, 2, 4 … 2048, 4096 → 1 | 630,1 | 15.437 | 12.864 |

- El cap del nivel 1 no es potencia de dos (6), así que el residuo `8 mod 6 = 2` crea un ciclo corto `2, 4`. 🎢
- Al evolucionar el cap es **4096 = 2¹²**, y `8192 mod 4096 = 0` se reajusta a 1: un ciclo limpio de **13 explosiones** cuya suma es `2¹³ − 1 = 8191`. La media por explosión es **630,1×** el daño base. 🤯
- Cada explosión golpea **todo** lo que esté en el radio (hasta 194 px al nivel 8), con empuje de 160.
- 🧬 **Evolución — Exponencial Escalada:** cap enorme, radio devastador y un residuo extra que también golpea.

### 5️⃣ Cancelación catastrófica — *restar números casi iguales* 🌗

**Fenómeno:** al restar dos cantidades muy próximas se pierden cifras significativas; el resultado queda dominado por el error de redondeo.

```text
bits       b = 8 + 1,5 · (nivel − 1) + 3 · precisión
error      = 1024 · 2^(−b)          (se redondea 1024 y 1023,5)
relación   R = clamp(0,5 / error ; 0,18 ; 0,85)   → 1,0 al evolucionar
daño haz   = (22 + 7 · (nivel − 1)) · R · potencia
ancho      = 16 + 3 · nivel (+10 evolucionada)
órbita     = 140 + 6 · nivel (+40 evolucionada)
intervalo  = max(0,16 ; 0,65 − 0,04 · (nivel − 1))
```

| Nivel | Bits | Error absoluto | R | Daño del haz | Ancho | Longitud | DPS por enemigo |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 8 | 4,00 | 0,18 | 3,96 | 19 | 292 | 6,1 |
| 8 | 18,5 | 0,00276 | 1,00 | 71,0 | 50 | 456 | 191,9 |

- Dos orbes opuestos orbitan al jugador y el **haz es el segmento que los une**: golpea a todos los enemigos a menos de `ancho` del segmento.
- La relación `R` se satura en 0,85 cuando `b ≥ 10,77`: a partir de ~11 bits, subir precisión ya no mejora la señal. Solo la **reformulación estable** de la evolución llega a 1,0. Es exactamente la lección de la cancelación catastrófica. 🎓
- 🧬 **Evolución — Diferencia Estable:** residuo exacto, haz limpio y más ancho.

### 6️⃣ NaN — *resultado no numérico* 🌀

**Fenómeno:** una operación inválida produce `NaN`, que se propaga y hace impredecible todo lo que toca.

```text
zonas      = 1 + floor((nivel − 1) / 3)   (+2 evolucionada)
radio      = 55 + 5 · nivel (+30 evolucionada)
daño/tick  = 3,5 + 1,1 · (nivel − 1)
control    c = clamp(0,35 + 0,07 · (nivel − 1) + 0,1 · precisión ; 0 ; 0,98)  → 1,0 al evolucionar
tick       = 0,3 s
```

Cada tick y cada enemigo hace una **tirada de validez**:

```text
si rand() > c:   daño = base · (6 con 50 %  |  0 con 50 %)
si rand() ≤ c:   daño = base · rand(0,8 ; 1,2)
slow = clamp(0,7 − 0,03 · nivel ; 0,4 ; 0,7) durante 0,5 s
```

El multiplicador esperado por tick es:

```text
E[mult] = c · 1 + (1 − c) · (0,5 · 6 + 0,5 · 0) = 3 − 2c
```

| Nivel | Zonas | Radio | Daño | Control | E[mult] | Daño/zona/enemigo |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 60 | 3,5 | 0,35 | 2,30 | 64,4 |
| 8 | 5 | 125 | 11,2 | 1,00 | 1,00 | 123,2 |

- Al nivel 1 el valor esperado es **2,3×** el daño base por tick, pero con muchísima varianza: puedes hacer 0 o 6×. 🎰
- Al evolucionar, `c = 1`: las zonas dejan de ser una lotería y pasan a ser daño determinista, amplio y ralentizador.
- 🧬 **Evolución — Dominio Definido:** control total y zonas gigantes.

---

## 📊 Resumen de potencia (nivel 1 → 8, sin mejoras)

| Arma | DPS aprox. Nv 1 | DPS aprox. Nv 8 | Tipo de daño |
|---|---:|---:|---|
| 📐 Truncamiento | 6,3 | 137,8 | Línea, multidisparo |
| 🧲 Absorción | 4,6 | 32,6 | Onda en área |
| 🫧 Underflow | ~6,5 (a 50 px) | ~114 (a 150 px) | Cono, decae con distancia |
| 💥 Overflow | 8,8 | 12.864 | Área enorme |
| 🌗 Cancelación | 6,1 | 191,9 | Segmento orbital |
| 🌀 NaN | 26,8 (por zona) | 37,3 (por zona) | Área + ralentización |

Los números altos de Overflow y Cancelación son intencionados: son armas de **área** con requisitos de posición (el jefe o la horda tienen que estar dentro del radio/haz) y su progresión es la recompensa de una build completa. El resto del juego escala en consecuencia: a los 10 minutos los enemigos tienen ×7,5 de vida. ⚖️

---

## 🎨 Presentación: música, CRT e iconos

### 🎵 Música de partida

- El tema principal 'dark fantasy demo' es hecho por mi en el FL suena **solo durante las partidas**, en bucle, a −14 dB. El menú principal queda en silencio. 🎶🐳


---

## 🔊 Sonido y efectos procedurales

- Todos los **efectos de sonido se sintetizan en runtime** con `AudioStreamWAV`: barridos de frecuencia, ruido y arpegios, con un pool de 16 reproductores y cooldowns por sonido. Disparos, impactos, muertes, élite, jefe, daño, recogida, subida de nivel, overflow, NaN, underflow, victoria y derrota. 🎧
- La **música** es el único asset de audio externo; los efectos no usan archivos.
- Los **FX son geometría dibujada por código**: estallidos, anillos, textos flotantes (`OVERFLOW`, `fmod`, `Σ`, `absorbido`, `residuo %`, `NaN`, `∞`, `→ 0`), trayectorias fantasma y estelas. ✨
- El **feedback de daño** combina viñeta roja, número flotante, sacudida de cámara y partículas.
- El HUD muestra vida, XP, nivel, tiempo, bajas, potencia, precisión, el arsenal con sus iconos y niveles, y una **barra de jefe** reactiva. 🧾

---

## 🛠️ Stack técnico

```text
Motor:        Godot 4.3 (GDScript)
Escenas:      main, main_menu, player, enemy, projectile, xp_gem, hud, level_up_menu
Armas:        una escena + un script por arma (clase base Weapon)
Datos:        EnemyData como Resource (.tres) para los 4 arquetipos
Shaders:      rejilla infinita, viñeta de daño, CRT y fondo del menú de nivel
Audio:        música darkfantasy.mp3 + efectos sintetizados en runtime
UI:           iconos circulares vectoriales y menú de nivel animado
Sprites:      ninguno en enemigos; todo es dibujo vectorial por código
```

### ▶️ Cómo ejecutarlo

```bash
# Abre el proyecto con Godot 4.3 y pulsa F5.
# O desde consola:
godot --path . res://scenes/main.tscn
```

La escena inicial es el menú (`scenes/main_menu.tscn`), con **JUGAR**, **CÓMO JUGAR** y **SALIR**.

---

## 🧭 Filosofía de diseño

> **Si le quitas el nombre al arma y solo ves su comportamiento, (y con un previo conocimiento en la asignatura🐳) deberías poder adivinar qué fenómeno numérico es.**

- La **precisión** no es un simple “+daño”: reduce errores concretos (desvío angular, bits de cancelación, decaimiento de underflow, control de NaN).
- **Subir precisión no arregla la cancelación catastrófica**: a partir de ~11 bits la relación señal/error se satura. La solución real es una **reformulación estable**, y esa es la evolución del arma.
- **Underflow, overflow y NaN** son fenómenos distintos y se juegan distinto: desaparecer, desbordar y volverse impredecible.
- La **suma compensada (Kahan)** no hace más daño por sí sola: hace que las aportaciones pequeñas **dejen de perderse**. El DPS sube porque el acumulador por fin conserva todo.

---

¿Qué arma te parece más rota? ¿Qué fenómeno numérico te gustaría ver como mecánica en futuras actualizaciones? Escucho Feedback. 👇

**Hecho con Godot 4.3, GDScript, mucho cráneo y mucho prompt.** ☕🧮
