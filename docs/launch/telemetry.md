Prompt para implementar Sistema de Telemetría Anónima (Godot + Python)
A continuación tienes un prompt completo y autocontenido que puedes copiar y pegar directamente a la IA que desarrolle (Claude, ChatGPT, etc.). Contiene todos los requisitos, la estructura de archivos, el código listo para usar y las instrucciones de integración.

# Sistema de Telemetría Anónima para Juego Incremental (Godot 4 + Python)

Necesito implementar un sistema opcional de recolección de datos anónimos para un juego incremental. El sistema tiene dos partes: una en Godot (guarda eventos en JSON) y otra en Python (analiza esos JSON y genera gráficos/estadísticas).

## Contexto del juego
- El juego se llama “Fungi”, es un idle con mecánicas de economía, mutaciones, biosfera, estrés (ε), flexibilidad (Ω), legados y trascendencias.
- Ya existe un `main.gd` con grupos de autoloads, sistema de logros, etc.
- La telemetría será **opt‑in** (el jugador debe aceptar) y **anónima** (sin IP, email, ni datos personales).

---

## Parte 1 – Godot: TelemetryManager (autoload)

### 1. Configuración y persistencia
- Crear `TelemetryManager.gd` como autoload.
- Guardar la preferencia del jugador en `user://telemetry_settings.cfg` o un JSON simple (por ejemplo `{"enabled": false}`).
- Por defecto, la telemetría está **desactivada** hasta que el jugador la active.

### 2. Opción en la UI de ajustes
- Añadir un `CheckBox` con texto: *“Enviar datos anónimos de uso (ayuda a mejorar el juego)”*.
- Conectar `toggled` a `TelemetryManager.set_enabled(value)`.
- Esta opción debe estar accesible tanto en el menú principal como dentro de la partida (en el mismo panel de ajustes donde se controla el sonido).

### 3. Funcionamiento interno
- Cuando `set_enabled(true)`:
  - Generar un `session_id` único y persistente (almacenarlo en `user://telemetry_id.txt`). Usar algo como `"PLAYER_" + str(randi())` o un UUID simple.
  - Iniciar un timer para guardar eventos acumulados (cada 10 eventos o cada 60 segundos).
- Cuando `set_enabled(false)`:
  - Vaciar la cola pendiente y detener el timer.

### 4. Eventos a registrar (trackear)
Registrar cada evento en una cola (`event_queue`). Cada evento debe incluir al menos:
- `event` (string)
- `timestamp` (Unix time)
- `session_id`
- Datos específicos del evento (según tabla).

#### Eventos obligatorios:

| Evento | Momento | Datos extra |
|--------|---------|--------------|
| `session_start` | Al activar la telemetría (o al iniciar el juego si ya estaba activa) | `game_version` (de `ProjectSettings`) |
| `session_end` | Al cerrar el juego o desactivar telemetría | `duration_seconds` (tiempo de sesión) |
| `run_start` | Cuando `main.gd` termina `_ready()` y la partida está cargada | - |
| `run_close` | Dentro de `RunManager.close_run()` | `final_route`, `run_time`, `pl_gained` |
| `mutation_activated` | Dentro de `EvoManager.activate_mutation()` | `mutation_id` |
| `upgrade_bought` | Dentro de `UpgradeManager.buy()` (solo cuando la compra fue exitosa) | `upgrade_id`, `new_level` |
| `achievement_unlocked` | Cuando `AchievementManager.unlock()` emite la señal | `achievement_id` |
| `trascendencia` | Dentro de `LegacyManager.transcend()` | `trascendencia_count_new` |
| `first_epsilon_high` (solo una vez por run) | La primera vez que `StructuralModel.epsilon_runtime > 0.65` | `epsilon_value` |

### 5. Métricas periódicas (series temporales)
- Cada 30 segundos de juego real (no de simulación) guardar una “muestra” en un array `metrics_series` dentro de la misma run.
- Cada muestra debe contener:
  - `time` (segundos desde inicio de la run)
  - `epsilon`, `omega`, `money`, `biomasa`, `mu` (si está disponible)

### 6. Guardado en disco
- Cuando se cierra una run (normalmente en `run_close`), se escribe un archivo JSON independiente en `user://telemetry/runs/run_YYYYMMDD_HHMMSS.json`.
- El nombre del archivo debe incluir la fecha/hora para evitar colisiones.
- La estructura completa del JSON será:

```json
{
  "meta": {
    "game_version": "v1.2.3",
    "session_id": "PLAYER_123456",
    "timestamp_start": 1700000000,
    "timestamp_end": 1700003600,
    "platform": "HTML5"  // o "Windows", "Linux"
  },
  "run_summary": {
    "final_route": "HOMEOSTASIS",
    "pl_gained": 3,
    "epsilon_peak": 0.45,
    "max_mu": 1.8,
    "max_delta_per_sec": 3500.0,
    "mutations_activated": ["homeostasis"],
    "trascendencia_count": 2
  },
  "events": [
    {"time": 5, "type": "upgrade_bought", "upgrade_id": "click", "level": 1}
  ],
  "metrics_series": [
    {"time": 0, "epsilon": 0.0, "omega": 1.0, "money": 0, "biomasa": 0, "mu": 1.0}
  ]
}

7. Consideraciones de rendimiento
Usar call_deferred para escrituras en disco.

No bloquear el hilo principal.

Si hay muchas partidas, rotar archivos (guardar solo las últimas 100 runs, opcional).

Parte 2 – Python: Analizador y generador de gráficos
Crear un script analyze_telemetry.py que:

Lea todos los archivos JSON de una carpeta (ejemplo: ./telemetry_data/).

Genere al menos los siguientes gráficos (PNG) y estadísticas (archivo de texto).

2.1 Gráficos requeridos
Popularidad de rutas finales (gráfico de barras)

Dispersión ε_peak vs PL ganados (con colores por ruta)

Evolución de ε, Ω, dinero para una run concreta (línea temporal)

Mapa de calor: mutación activada → ruta final

Histograma de duración de runs (minutos)

Boxplot de PL por ruta (cada ruta es una categoría)

2.2 Estadísticas a mostrar en estadisticas.txt
Número total de runs analizadas.

Ruta más popular y su porcentaje.

ε_peak promedio, mediana.

PL medio por run.

μ máximo global.

Correlación entre ε_peak y PL (coeficiente de Pearson).

2.3 Uso de bibliotecas
pandas, matplotlib, seaborn, numpy, json, pathlib.

2.4 Estructura de salida
El script debe crear una carpeta analysis_output/ con:

Todos los gráficos en PNG.

Un archivo estadisticas.txt.

(Opcional) un archivo heatmap_transitions.png.

2.5 Ejemplo de entrada esperada
El script debe asumir que los JSON tienen exactamente la estructura definida en la Parte 1. Si falta algún campo opcional (por ejemplo metrics_series), debe manejarlo sin errores.

Código a entregar
3.1 Archivo TelemetryManager.gd (completo, listo para copiar)
Incluye:

_ready(), set_enabled(), track_event(), _flush_queue(), _save_run_json().

Manejo de temporizadores.

Generación de session_id persistente.

Conexión con las señales del juego (se deben conectar en main.gd como se indica en las instrucciones de integración).

3.2 Archivo analyze_telemetry.py (completo, con puntos de entrada y comentarios)
Functions: load_all_runs(), plot_route_popularity(), plot_epsilon_vs_pl(), etc.

Ejecución principal con if __name__ == "__main__".

3.3 Instrucciones de integración para el desarrollador (texto plano)
Dónde colocar cada archivo en el proyecto Godot.

Cómo añadir el TelemetryManager a los autoloads (en project.godot).

Qué líneas añadir en main.gd y RunManager.gd, EvoManager.gd, etc. para llamar a track_event.

Cómo añadir el checkbox en la UI de ajustes (tanto en MainMenu.tscn como en main.tscn).

Cómo exportar los datos de telemetría desde el juego (opcional: botón "Exportar telemetría" que comprima todos los JSON en un ZIP).

Requisitos adicionales (opcionales pero deseables)
Si OS.get_name() == "HTML5", la telemetría debe pedir confirmación expresa del usuario (navegador) si es posible, o simplemente confiar en la opción interna (más sencillo: usar la misma opción interna).

Los archivos JSON deben ser legibles por humanos (indentados) para facilitar depuración.

El script de Python debe ser ejecutable con python analyze_telemetry.py sin argumentos (asume la carpeta ./telemetry_data/).