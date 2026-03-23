import os
import re
import json
from pathlib import Path

RUNS_DIR = Path("runs")

TIME_RE = re.compile(r"^(\d{2}):(\d{2})")
TRUEQUE_EVENT_RE = re.compile(r"Desbloqueado e", re.IGNORECASE)
DELTA_RE = re.compile(r"([-+]?\d+\.?\d*)")

def parse_mmss_to_seconds(ts):
    m, s = map(int, ts.split(":"))
    return m * 60 + s

def extract_first_trueque_time(lap_text):
    """
    Busca la primera línea del estilo:
    05:08 → Desbloqueado e (Trueque)
    """
    for line in lap_text.splitlines():
        if TRUEQUE_EVENT_RE.search(line):
            m = TIME_RE.match(line.strip())
            if m:
                return parse_mmss_to_seconds(m.group(0))
    return None

def extract_delta_numeric(delta_text):
    """
    Ej: 'Δ$ estimado / s = +114.21' -> 114.21
    """
    m = DELTA_RE.search(delta_text)
    return float(m.group(1)) if m else None

def load_runs():
    runs = []
    for file in RUNS_DIR.glob("*.json"):
        with open(file, "r", encoding="utf-8") as f:
            data = json.load(f)

        run = {
            "file": file.name,
            "fecha": data.get("fecha"),
            "hora": data.get("hora"),
            "tiempo_sesion": data.get("tiempo_sesion"),
            "lap_markers": data.get("lap_markers", ""),
            "delta_text": data.get("delta_total_s", ""),
            "dominio": data.get("dominio"),
        }

        run["time_to_trueque_s"] = extract_first_trueque_time(run["lap_markers"])
        run["delta_final"] = extract_delta_numeric(run["delta_text"])
        run["reached_delta_100"] = (
            run["delta_final"] is not None and run["delta_final"] >= 100
        )

        runs.append(run)

    return runs

def print_trueque_ranking(runs):
    print("\n🏁 RANKING — Tiempo hasta desbloquear Trueque (e)\n")

    # filtra solo runs que lo alcanzaron
    valid = [r for r in runs if r["time_to_trueque_s"] is not None]
    valid.sort(key=lambda r: r["time_to_trueque_s"])

    if not valid:
        print("No hay runs con desbloqueo de Trueque registrado aún.\n")
        return

    for i, r in enumerate(valid, 1):
        mm = int(r["time_to_trueque_s"] // 60)
        ss = int(r["time_to_trueque_s"] % 60)

        print(
            f"{i:02d}) {mm:02d}:{ss:02d}  "
            f"{r['fecha']} {r['hora']}  "
            f"{r['file']}  "
            f"(Δ$≥100={'sí' if r['reached_delta_100'] else 'no'})"
        )

def print_delta_summary(runs):
    print("\n📈 ESTADO — Runs que alcanzaron Δ$ ≥ 100\n")

    reached = [r for r in runs if r["reached_delta_100"]]
    for r in reached:
        print(f"- {r['fecha']} {r['hora']}  {r['file']}  Δ$={r['delta_final']}")

    if not reached:
        print("Ninguna run superó Δ$=100 todavía.")

def main():
    if not RUNS_DIR.exists():
        print("No existe la carpeta /runs — exportá una run primero.")
        return

    runs = load_runs()

    print(f"\n🧪 Runs analizadas: {len(runs)}")
    print_trueque_ranking(runs)
    print_delta_summary(runs)
    print("\n✔ Listo — análisis básico generado.\n")

if __name__ == "__main__":
    main()