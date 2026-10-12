"""Resume los JSON de run_benchmark.ps1: mediana de las repeticiones por configuracion.

CPU ms/s = logic_hz*logic + ui_hz*ui + clicks_por_s*click (frecuencias reales de cada plataforma).
Uso: python tools/sim/bench_analyze.py <OutDir>   (escribe <OutDir>/summary.json)
"""
import json, glob, os, sys, statistics as st
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
d = sys.argv[1]
runs = {}
for f in glob.glob(os.path.join(d, "*.json")):
    if os.path.basename(f) == "summary.json":
        continue
    b, rest = os.path.basename(f)[:-5].split("_", 1)
    cfg, rep = rest.rsplit("_r", 1)
    r = json.load(open(f, encoding='utf-8'))
    if isinstance(r, list):
        r = r[0]
    runs.setdefault((b, cfg), []).append(r)

def metrics(r):
    p = r["perf"]; c = r["config"]; o = r["outcome"]
    dt = c["frame_dt"]; ui_hz = 1.0 / (c["cadence_frames"]["ui"] * dt); logic_hz = 1.0 / (c["cadence_frames"]["logic"] * dt)
    cps = o["clicks"] / max(o["t_end"], 1e-6)
    lg, ui, ck = p["logic_tick"]["mean_us"], p["ui_tick"]["mean_us"], p["click"]["mean_us"]
    cpu = (logic_hz * lg + ui_hz * ui + cps * ck) / 1000.0
    eco = p.get("economy_us_per_call", {})
    m = p.get("memory", {})
    return {
        "logic_us": lg, "logic_p95": p["logic_tick"]["p95_us"], "ui_us": ui, "ui_p95": p["ui_tick"]["p95_us"], "click_us": ck,
        "cpu_ms_s": cpu, "cpu_pct": cpu / 10.0, "update_ui_us": p.get("update_ui_us", 0.0),
        "click_power_us": eco.get("get_click_power_us", 0.0), "passive_us": eco.get("get_passive_total_us", 0.0),
        "breakdown_us": eco.get("get_contribution_breakdown_us", 0.0),
        "sim_x": p["sim_speed_x"], "mem_mb": m.get("static_mb", 0.0), "mem_max_mb": m.get("static_max_mb", 0.0),
        "objects": m.get("objects", 0), "nodes": m.get("nodes", 0), "orphans": m.get("orphan_nodes", 0),
        "ach_clock": r["achievement_clock"]["ratio"], "ui_hz": ui_hz, "cps": cps, "t_end": o["t_end"],
        "breakdown_parts": p.get("ui_breakdown_us", {}),
    }

out = {}
cfgs = sorted({k[1] for k in runs})
for cfg in cfgs:
    out[cfg] = {}
    for b in ("before", "after"):
        ms = [metrics(r) for r in runs.get((b, cfg), [])]
        if not ms:
            continue
        agg = {}
        for k in ms[0]:
            if k == "breakdown_parts":
                parts = {}
                for name in ms[0][k]:
                    vals = [m[k].get(name) for m in ms if m[k].get(name) is not None]
                    parts[name] = st.median(vals)
                agg[k] = parts
            else:
                agg[k] = st.median([m[k] for m in ms])
        agg["n"] = len(ms)
        agg["cpu_spread"] = [round(min(m["cpu_ms_s"] for m in ms), 1), round(max(m["cpu_ms_s"] for m in ms), 1)]
        out[cfg][b] = agg
json.dump(out, open(os.path.join(d, "summary.json"), "w", encoding='utf-8'), indent=1, ensure_ascii=False)
keys = ["cpu_ms_s", "logic_us", "ui_us", "click_us", "update_ui_us", "click_power_us", "passive_us", "sim_x", "mem_mb", "objects", "nodes", "ach_clock"]
for cfg in cfgs:
    print("==", cfg, {b: out[cfg][b]["n"] for b in out[cfg]}, "spread", {b: out[cfg][b]["cpu_spread"] for b in out[cfg]})
    for k in keys:
        b = out[cfg].get("before", {}).get(k); a = out[cfg].get("after", {}).get(k)
        if b is None or a is None:
            continue
        ch = (a - b) / b * 100 if b else 0
        print(f"   {k:16} {b:10.2f} -> {a:10.2f}  ({ch:+.0f}%)")
