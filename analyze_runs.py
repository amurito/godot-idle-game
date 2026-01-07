import json
from pathlib import Path

runs_dir = Path("runs")


# ================== UTILIDADES ==================

def load_runs():
    runs = []
    for f in sorted(runs_dir.glob("*.json")):
        try:
            data = json.loads(f.read_text(encoding="utf8"))
            data["file"] = f.name
            runs.append(data)
        except Exception as e:
            print(f"⚠ Error leyendo {f}: {e}")
    return runs


def sort_time(items):
    return sorted(items, key=lambda x: x[0])


# =============== RANKING TRUEQUE (v6.x) =================

def print_trueque_ranking(runs):
    ranking = []
    for r in runs:
        laps = r.get("laps", [])
        fname = r.get("file", "<??>")
        session = r.get("session_time", "?")

        t = None
        for lap in laps:
            if "Trueque" in lap.get("event", ""):
                t = lap.get("time")
                break

        if t:
            ranking.append((t, fname, session, r.get("delta_total_s","")))

    print("\n🏁 RANKING — Tiempo hasta desbloquear Trueque (e)")
    for i, r in enumerate(sort_time(ranking), 1):
        print(f"{i:02}) {r[0]}   {r[1]}   {r[2]}   ({r[3]})")


def print_delta_summary(runs):
    print("\n📊 ESTADO — Runs que alcanzaron Δ$ ≥ 100")

    for r in runs:
        d = r.get("delta_total_s","")
        if "Δ$" in d:
            print(f"— {r.get('session_time','?')}   {r['file']}   Δ$={d}")


# ========= NUEVOS RANKINGS ESTRUCTURALES =========

def analyze_structural_rankings(runs):
    tree_unlock_times = []
    click_dominance_times = []
    delta_100_times = []

    for run in runs:
        laps = run.get("laps", [])
        fname = run.get("file", "<?>")
        session = run.get("session_time", "?")

        # --- árbol completo ---
        unlocked = set()
        tree_time = None

        for lap in laps:
            ev = lap.get("event", "")

            if "Trabajo Manual" in ev: unlocked.add("d")
            if "Ritmo de Trabajo" in ev: unlocked.add("md")
            if "Especialización de Oficio" in ev: unlocked.add("so")
            if "Trueque" in ev: unlocked.add("e")
            if "Red de Intercambio" in ev: unlocked.add("me")

            if len(unlocked) == 5 and tree_time is None:
                tree_time = lap.get("time")

        if tree_time:
            tree_unlock_times.append((tree_time, fname, session))

        # --- dominio CLICK ---
        dom_time = None
        for lap in laps:
            if "CLICK domina el sistema" in lap.get("dominante",""):
                dom_time = lap.get("time")
                break

        if dom_time:
            click_dominance_times.append((dom_time, fname, session))

        # --- Δ$ ≥ 100 ---
        delta_text = run.get("delta_total_s","")
        if "Δ$" in delta_text:
            delta_100_times.append((session, fname, delta_text))

    print("\n🌳 RANKING — Árbol productivo completo")
    for i, r in enumerate(sort_time(tree_unlock_times), 1):
        print(f"{i:02}) {r[0]}   {r[1]}   (sesión {r[2]})")

    print("\n⚙ RANKING — Dominio CLICK del sistema")
    for i, r in enumerate(sort_time(click_dominance_times), 1):
        print(f"{i:02}) {r[0]}   {r[1]}   (sesión {r[2]})")

    print("\n📈 RANKING — Primer cruce Δ$ ≥ 100")
    for i, r in enumerate(sort_time(delta_100_times), 1):
        print(f"{i:02}) {r[0]}   {r[1]}   Δ$={r[2]}")
    


# ================= MAIN =================

def main():
    if not runs_dir.exists():
        print("No existe la carpeta /runs — exportá una run primero.")
        return

    runs = load_runs()

    print(f"\n🧪 Runs analizadas: {len(runs)}")

    print_trueque_ranking(runs)
    print_delta_summary(runs)

    analyze_structural_rankings(runs)

    print("\n✔ Listo — análisis generado.\n")


if __name__ == "__main__":
    main()
