#!/usr/bin/env python3
"""
analyze_telemetry.py — Dashboard interactivo de telemetría para AntiIDLE
Genera gráficos Plotly con tooltips, heatmap de correlaciones y dashboard HTML completo.
"""

import argparse
import csv
import html
import json
import os
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean, median

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

DEFAULT_RUNS_DIR = (
    Path(os.environ.get("APPDATA", ""))
    / "Godot"
    / "app_userdata"
    / "AntiIDLE"
    / "telemetry"
    / "runs"
)
DEFAULT_OUTPUT_DIR = Path(__file__).parent / "analysis_output"

# Colores por ruta (consistentes en todos los gráficos)
ROUTE_COLORS = {
    "HOMEOSTASIS": "#26a269",
    "ALLOSTASIS": "#1c71d8",
    "HOMEORHESIS": "#9141ac",
    "ESPORULACION": "#e5a50a",
    "ESPORULACIÓN": "#e5a50a",
    "PARASITISMO": "#c01c28",
    "HIPERASIMILACION": "#ff7800",
    "HIPERASIMILACIÓN": "#ff7800",
    "SIMBIOSIS": "#33dd88",
    "DEPREDADOR": "#cc3322",
    "METABOLISMO OSCURO": "#8844aa",
    "SINGULARIDAD": "#44ddff",
    "RED_MICELIAL": "#88dd33",
}

# ============================================================================
# CARGA DE DATOS
# ============================================================================

def load_all_runs(runs_dir: Path) -> list[dict]:
    runs = []
    for path in sorted(runs_dir.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            data["_file"] = path.name
            runs.append(data)
        except Exception as exc:
            print(f"Warning: could not read {path}: {exc}")
    return runs


def to_float(value, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def to_int(value, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def seconds_to_label(seconds: float | None) -> str:
    if seconds is None:
        return "-"
    seconds = max(0, int(round(seconds)))
    minutes, sec = divmod(seconds, 60)
    hours, minutes = divmod(minutes, 60)
    if hours:
        return f"{hours:d}:{minutes:02d}:{sec:02d}"
    return f"{minutes:d}:{sec:02d}"


def event_time(events: list[dict], event_type: str) -> float | None:
    for event in events:
        if event.get("type") == event_type:
            return to_float(event.get("time"))
    return None


def summarize_run(run: dict) -> dict:
    summary = run.get("run_summary", {})
    meta = run.get("meta", {})
    events = list(run.get("events", []))
    metrics = list(run.get("metrics_series", []))

    run_time = to_float(summary.get("run_time"))
    pl = to_int(summary.get("pl_gained"))
    route_efficiency = (pl / (run_time / 60.0)) if run_time > 0 else 0.0

    upgrade_counts = Counter(
        event.get("upgrade_id", "")
        for event in events
        if event.get("type") == "upgrade_bought"
    )
    upgrade_counts.pop("", None)

    epsilon_values = [to_float(point.get("epsilon")) for point in metrics]
    omega_values = [to_float(point.get("omega")) for point in metrics]

    return {
        "file": run.get("_file", ""),
        "route": str(summary.get("final_route", "")),
        "pl": pl,
        "run_time_seconds": run_time,
        "pl_per_min": route_efficiency,
        "epsilon_peak": to_float(summary.get("epsilon_peak")),
        "time_to_first_epsilon_high": event_time(events, "first_epsilon_high"),
        "time_to_first_mutation": event_time(events, "mutation_activated"),
        "max_mu": to_float(summary.get("max_mu")),
        "max_delta_per_sec": to_float(summary.get("max_delta_per_sec")),
        "upgrade_count": sum(upgrade_counts.values()),
        "mutations": ", ".join(summary.get("mutations_activated", [])),
        "version": str(meta.get("game_version", "unknown")),
        "epsilon_avg_sampled": mean(epsilon_values) if epsilon_values else 0.0,
        "omega_min_sampled": min(omega_values) if omega_values else 0.0,
    }


def build_dataframe(rows: list[dict]) -> pd.DataFrame:
    return pd.DataFrame(rows)


# ============================================================================
# GRÁFICOS PLOTLY (interactivos con tooltips)
# ============================================================================

def create_scatter_epsilon_vs_pl(df: pd.DataFrame) -> go.Figure:
    """Gráfico de dispersión ε_peak vs PL (con tooltips y línea de tendencia)"""
    fig = px.scatter(
        df,
        x="epsilon_peak",
        y="pl",
        color="route",
        color_discrete_map=ROUTE_COLORS,
        hover_data=["file", "pl_per_min", "run_time_seconds", "max_mu"],
        title="ε_peak vs PL ganados",
        labels={
            "epsilon_peak": "ε_peak (estrés máximo)",
            "pl": "PL ganados",
            "route": "Ruta final"
        },
        trendline="ols",
        trendline_color_override="red",
    )
    fig.update_traces(marker=dict(size=12, opacity=0.7, line=dict(width=1, color="black")))
    fig.update_layout(
        template="plotly_dark",
        hovermode="closest",
        legend=dict(font=dict(size=10))
    )
    return fig


def create_boxplot_pl_by_route(df: pd.DataFrame) -> go.Figure:
    """Boxplot de PL por ruta"""
    fig = px.box(
        df,
        x="route",
        y="pl",
        color="route",
        color_discrete_map=ROUTE_COLORS,
        title="Distribución de PL por ruta",
        labels={"route": "Ruta final", "pl": "PL ganados"},
        points="all",
    )
    fig.update_layout(
        template="plotly_dark",
        xaxis_tickangle=-45,
        showlegend=False,
    )
    return fig


def create_bar_efficiency(df: pd.DataFrame) -> go.Figure:
    """Barras de eficiencia (PL/min) por ruta"""
    eff_by_route = df.groupby("route")["pl_per_min"].agg(["mean", "std", "count"]).reset_index()
    eff_by_route = eff_by_route.sort_values("mean", ascending=False)
    
    fig = go.Figure()
    fig.add_trace(go.Bar(
        x=eff_by_route["route"],
        y=eff_by_route["mean"],
        error_y=dict(type="data", array=eff_by_route["std"], visible=True),
        marker_color=[ROUTE_COLORS.get(r, "#64748b") for r in eff_by_route["route"]],
        text=[f"n={int(c)}" for c in eff_by_route["count"]],
        textposition="outside",
        name="PL/min",
    ))
    fig.update_layout(
        title="Eficiencia por ruta (PL/minuto)",
        xaxis_title="Ruta final",
        yaxis_title="PL / minuto",
        template="plotly_dark",
        xaxis_tickangle=-45,
    )
    return fig


def create_scatter_mu_vs_pl(df: pd.DataFrame) -> go.Figure:
    """μ máximo vs PL"""
    fig = px.scatter(
        df,
        x="max_mu",
        y="pl",
        color="route",
        color_discrete_map=ROUTE_COLORS,
        hover_data=["file", "pl_per_min", "epsilon_peak"],
        title="μ máximo vs PL ganados",
        labels={"max_mu": "μ (capital cognitivo máximo)", "pl": "PL ganados"},
        trendline="ols",
    )
    fig.update_traces(marker=dict(size=12, opacity=0.7))
    fig.update_layout(template="plotly_dark")
    return fig


def create_duration_histogram(df: pd.DataFrame) -> go.Figure:
    """Histograma de duración de runs"""
    fig = px.histogram(
        df,
        x="run_time_seconds",
        color="route",
        color_discrete_map=ROUTE_COLORS,
        nbins=20,
        title="Distribución de duración de runs",
        labels={"run_time_seconds": "Duración (segundos)", "count": "Número de runs"},
        marginal="box",
    )
    fig.update_layout(template="plotly_dark")
    return fig


def create_epsilon_boxplot_by_route(df: pd.DataFrame) -> go.Figure:
    """Boxplot de ε_peak por ruta"""
    fig = px.box(
        df,
        x="route",
        y="epsilon_peak",
        color="route",
        color_discrete_map=ROUTE_COLORS,
        title="ε_peak por ruta (estrés máximo alcanzado)",
        labels={"route": "Ruta final", "epsilon_peak": "ε_peak"},
        points="all",
    )
    fig.add_hline(y=0.5, line_dash="dash", line_color="orange", annotation_text="Umbral alto (0.5)")
    fig.add_hline(y=0.25, line_dash="dash", line_color="yellow", annotation_text="Umbral medio (0.25)")
    fig.update_layout(template="plotly_dark", xaxis_tickangle=-45, showlegend=False)
    return fig


RADAR_AXES = ["Eficiencia", "PL mediano", "Consistencia", "Velocidad", "Escalado μ", "Seguridad"]


def compute_radar_stats(df: pd.DataFrame) -> dict:
    """Computa stats por ruta para el radar: 6 ejes, valores raw y normalizados."""
    routes = list(df["route"].unique())
    raw: dict[str, dict] = {}

    for route in routes:
        rdf = df[df["route"] == route]

        eficiencia = rdf["pl_per_min"].mean()
        pl_mediano = float(rdf["pl"].median())

        pl_mean = rdf["pl"].mean()
        pl_std = rdf["pl"].std() if len(rdf) > 1 else 0.0
        consistencia = max(0.0, 1.0 - (pl_std / pl_mean)) if pl_mean > 0 else 0.0

        mutation_times = rdf["time_to_first_mutation"].dropna()
        mt_mean = mutation_times.mean() if len(mutation_times) > 0 else 0.0
        velocidad_raw = (1.0 / mt_mean) if mt_mean > 0 else 0.0

        escalado_mu = rdf["max_mu"].mean()
        seguridad = max(0.0, 1.0 - rdf["epsilon_peak"].mean())

        raw[route] = {
            "Eficiencia": eficiencia,
            "PL mediano": pl_mediano,
            "Consistencia": consistencia,
            "Velocidad": velocidad_raw,
            "Escalado μ": escalado_mu,
            "Seguridad": seguridad,
        }

    # Normalizar por eje entre todas las rutas
    normalized: dict[str, dict] = {r: {} for r in routes}
    for axis in RADAR_AXES:
        max_val = max((raw[r][axis] for r in routes), default=1.0)
        max_val = max_val if max_val > 0 else 1.0
        for route in routes:
            normalized[route][axis] = raw[route][axis] / max_val

    return {"axes": RADAR_AXES, "raw": raw, "normalized": normalized, "routes": routes}


def create_radar_top3(stats: dict) -> go.Figure:
    """Radar: Top 3 rutas por eficiencia resaltadas, resto como líneas tenues."""
    AXES = stats["axes"]
    raw = stats["raw"]
    normalized = stats["normalized"]
    routes = stats["routes"]

    top3 = sorted(routes, key=lambda r: raw[r]["Eficiencia"], reverse=True)[:3]
    axes_closed = AXES + [AXES[0]]

    fig = go.Figure()

    # Fondo: rutas no-top3 como líneas sin fill
    for route in routes:
        if route in top3:
            continue
        vals = [normalized[route][ax] for ax in AXES] + [normalized[route][AXES[0]]]
        color = ROUTE_COLORS.get(route, "#64748b")
        fig.add_trace(go.Scatterpolar(
            r=vals, theta=axes_closed,
            fill="none", name=route,
            line=dict(color=color, width=1),
            opacity=0.22, showlegend=True,
        ))

    # Top 3: fill + hover con valor absoluto
    for route in top3:
        vals = [normalized[route][ax] for ax in AXES] + [normalized[route][AXES[0]]]
        color = ROUTE_COLORS.get(route, "#64748b")
        hover = [
            f"<b>{ax}</b><br>Norm: {normalized[route][ax]:.2f}<br>Absoluto: {raw[route][ax]:.3f}"
            for ax in AXES
        ] + [f"<b>{AXES[0]}</b><br>Norm: {normalized[route][AXES[0]]:.2f}<br>Absoluto: {raw[route][AXES[0]]:.3f}"]
        fig.add_trace(go.Scatterpolar(
            r=vals, theta=axes_closed,
            fill="toself", name=f"⭐ {route}",
            line=dict(color=color, width=2.5),
            fillcolor=color, opacity=0.45,
            text=hover, hovertemplate="%{text}<extra></extra>",
        ))

    fig.update_layout(
        polar=dict(
            radialaxis=dict(visible=True, range=[0, 1], tickfont=dict(size=9)),
            angularaxis=dict(tickfont=dict(size=12)),
        ),
        title="Perfil de rutas — Top 3 por eficiencia (⭐) vs resto",
        template="plotly_dark",
        legend=dict(font=dict(size=10)),
    )
    return fig


def build_radar_comparator_html(stats: dict) -> str:
    """HTML+JS para comparar dos rutas head-to-head en un radar interactivo."""
    AXES = stats["axes"]
    raw = stats["raw"]
    normalized = stats["normalized"]
    routes = sorted(stats["routes"])

    route_data = {
        r: {
            "normalized": [normalized[r][ax] for ax in AXES],
            "raw": {ax: round(raw[r][ax], 4) for ax in AXES},
            "color": ROUTE_COLORS.get(r, "#64748b"),
        }
        for r in routes
    }

    axes_json = json.dumps(AXES, ensure_ascii=False)
    data_json = json.dumps(route_data, ensure_ascii=False)

    second = routes[1] if len(routes) > 1 else routes[0] if routes else ""
    opts_a = "".join(f'<option value="{r}">{r}</option>' for r in routes)
    opts_b = "".join(
        f'<option value="{r}" {"selected" if r == second else ""}>{r}</option>'
        for r in routes
    )

    return f"""
<div style="margin-bottom:18px; display:flex; align-items:center; gap:16px; flex-wrap:wrap;">
    <label style="color:#aaa;">Ruta A:</label>
    <select id="routeA" style="background:#1a1a2e;color:#ffcc44;border:1px solid #ffcc44;padding:6px 14px;border-radius:6px;font-size:14px;">{opts_a}</select>
    <span style="color:#555; font-size:1.4em;">vs</span>
    <label style="color:#aaa;">Ruta B:</label>
    <select id="routeB" style="background:#1a1a2e;color:#88aaff;border:1px solid #88aaff;padding:6px 14px;border-radius:6px;font-size:14px;">{opts_b}</select>
</div>
<div id="radar-comparator" style="height:440px;"></div>
<script>
(function(){{
    var AXES={axes_json};
    var DATA={data_json};
    function buildTrace(route,opacity){{
        var d=DATA[route];
        var vals=d.normalized.concat([d.normalized[0]]);
        var theta=AXES.concat([AXES[0]]);
        var hover=AXES.map(function(ax,i){{
            return '<b>'+ax+'</b><br>Norm: '+d.normalized[i].toFixed(2)+'<br>Absoluto: '+d.raw[ax].toFixed(3);
        }}).concat(['']);
        return{{type:'scatterpolar',r:vals,theta:theta,fill:'toself',name:route,
            line:{{color:d.color,width:2.5}},fillcolor:d.color,opacity:opacity,
            text:hover,hovertemplate:'%{{text}}<extra></extra>'}};
    }}
    var layout={{
        polar:{{
            radialaxis:{{visible:true,range:[0,1],tickfont:{{size:9}},color:'#aaa'}},
            angularaxis:{{tickfont:{{size:12}},color:'#ccc'}},
            bgcolor:'#111118'
        }},
        paper_bgcolor:'#111118',plot_bgcolor:'#111118',
        font:{{color:'#e0e0e0'}},
        legend:{{font:{{size:11}}}},
        margin:{{t:30,b:20,l:50,r:50}}
    }};
    function update(){{
        var rA=document.getElementById('routeA').value;
        var rB=document.getElementById('routeB').value;
        Plotly.react('radar-comparator',[buildTrace(rA,0.5),buildTrace(rB,0.35)],layout);
    }}
    document.getElementById('routeA').addEventListener('change',update);
    document.getElementById('routeB').addEventListener('change',update);
    update();
}})();
</script>"""


def create_evolution_overlay(df: pd.DataFrame, runs: list[dict]) -> go.Figure:
    """Evolución de ε y μ superpuestas (todas las runs normalizadas)"""
    fig = make_subplots(specs=[[{"secondary_y": True}]])
    
    for run in runs:
        metrics = run.get("metrics_series", [])
        if not metrics:
            continue
        times = [to_float(m.get("time", 0)) for m in metrics]
        eps_series = [to_float(m.get("epsilon", 0)) for m in metrics]
        mu_series = [to_float(m.get("mu", 1)) for m in metrics]
        
        if times and times[-1] > 0:
            times_pct = [t / times[-1] * 100 for t in times]
            route = run.get("run_summary", {}).get("final_route", "?")
            color = ROUTE_COLORS.get(route, "#64748b")
            
            fig.add_trace(
                go.Scatter(x=times_pct, y=eps_series, mode="lines", 
                          line=dict(width=1, color=color, dash="solid"),
                          opacity=0.4, name=f"{route} (ε)", showlegend=False),
                secondary_y=False,
            )
            fig.add_trace(
                go.Scatter(x=times_pct, y=mu_series, mode="lines",
                          line=dict(width=1, color=color, dash="dot"),
                          opacity=0.3, name=f"{route} (μ)", showlegend=False),
                secondary_y=True,
            )
    
    fig.update_layout(
        title="Evolución de ε y μ durante la run (todas las runs)",
        xaxis_title="Progreso de la run (%)",
        template="plotly_dark",
        hovermode="closest",
    )
    fig.update_yaxes(title_text="ε (estrés)", secondary_y=False, color="#e5a50a")
    fig.update_yaxes(title_text="μ (capital cognitivo)", secondary_y=True, color="#1c71d8")
    return fig


# ============================================================================
# HEATMAP DE CORRELACIONES
# ============================================================================

def create_correlation_heatmap(df: pd.DataFrame, output_dir: Path) -> None:
    """Genera heatmap de correlaciones entre métricas clave"""
    # Seleccionar columnas numéricas relevantes
    corr_cols = ["pl", "pl_per_min", "epsilon_peak", "max_mu", "max_delta_per_sec", 
                 "run_time_seconds", "upgrade_count", "epsilon_avg_sampled", "omega_min_sampled"]
    
    # Filtrar columnas existentes
    available_cols = [c for c in corr_cols if c in df.columns]
    corr_matrix = df[available_cols].corr()
    
    # Renombrar para mejor legibilidad
    rename_map = {
        "pl": "PL",
        "pl_per_min": "PL/min",
        "epsilon_peak": "ε_peak",
        "max_mu": "μ máximo",
        "max_delta_per_sec": "Δ$/s pico",
        "run_time_seconds": "Duración (s)",
        "upgrade_count": "# Upgrades",
        "epsilon_avg_sampled": "ε promedio",
        "omega_min_sampled": "Ω mínimo",
    }
    corr_matrix = corr_matrix.rename(index=rename_map, columns=rename_map)
    
    # Crear heatmap con matplotlib (más control)
    fig, ax = plt.subplots(figsize=(10, 8))
    im = ax.imshow(corr_matrix.values, cmap="RdBu_r", vmin=-1, vmax=1, aspect="auto")
    
    # Añadir valores numéricos en cada celda
    for i in range(len(corr_matrix.columns)):
        for j in range(len(corr_matrix.columns)):
            text = ax.text(j, i, f"{corr_matrix.values[i, j]:.2f}",
                          ha="center", va="center", color="white" if abs(corr_matrix.values[i, j]) > 0.5 else "black",
                          fontsize=9)
    
    ax.set_xticks(range(len(corr_matrix.columns)))
    ax.set_yticks(range(len(corr_matrix.columns)))
    ax.set_xticklabels(corr_matrix.columns, rotation=45, ha="right", fontsize=10)
    ax.set_yticklabels(corr_matrix.columns, fontsize=10)
    ax.set_title("Matriz de correlaciones entre métricas", fontsize=14, pad=20)
    
    plt.colorbar(im, ax=ax, label="Correlación")
    plt.tight_layout()
    plt.savefig(output_dir / "correlation_heatmap.png", dpi=150, bbox_inches="tight")
    plt.close()
    
    # También guardar versión HTML interactiva con Plotly
    if len(corr_matrix.columns) > 1:
        fig_plotly = go.Figure(data=go.Heatmap(
            z=corr_matrix.values,
            x=corr_matrix.columns,
            y=corr_matrix.columns,
            colorscale="RdBu",
            zmin=-1,
            zmax=1,
            text=corr_matrix.values.round(2),
            texttemplate="%{text}",
            textfont={"size": 10},
            hoverongaps=False,
        ))
        fig_plotly.update_layout(
            title="Matriz de correlaciones",
            width=600,
            height=600,
            template="plotly_dark",
            xaxis_tickangle=-45,
        )
        fig_plotly.write_html(output_dir / "correlation_heatmap_interactive.html")


# ============================================================================
# ANÁLISIS DE UPGRADES Y MUTACIONES
# ============================================================================

_MUT_COLORS = ["#9141ac", "#ff7800", "#1c71d8", "#26a269", "#e5a50a", "#c01c28", "#ff2244", "#44ffcc"]


def extract_upgrade_stats(runs: list[dict], df: pd.DataFrame) -> dict:
    """Estadísticas por upgrade_id: adopción, nivel máx, primer tiempo de compra, impacto en PL."""
    upgrade_data: dict[str, dict] = {}

    for run in runs:
        events = run.get("events", [])
        summary = run.get("run_summary", {})
        route = str(summary.get("final_route", ""))
        pl = to_int(summary.get("pl_gained"))

        seen: dict[str, dict] = {}
        for ev in events:
            if ev.get("type") != "upgrade_bought":
                continue
            uid = ev.get("upgrade_id", "")
            if not uid:
                continue
            lvl = to_int(ev.get("new_level", 1))
            t = to_float(ev.get("time", 0))
            if uid not in seen:
                seen[uid] = {"max_level": lvl, "first_time": t}
            else:
                seen[uid]["max_level"] = max(seen[uid]["max_level"], lvl)

        for uid, info in seen.items():
            if uid not in upgrade_data:
                upgrade_data[uid] = {"max_levels": [], "first_times": [], "routes": [], "pls": []}
            upgrade_data[uid]["max_levels"].append(info["max_level"])
            upgrade_data[uid]["first_times"].append(info["first_time"])
            upgrade_data[uid]["routes"].append(route)
            upgrade_data[uid]["pls"].append(pl)

    total_runs = len(runs)

    route_run_counts: dict[str, int] = {}
    for run in runs:
        r = str(run.get("run_summary", {}).get("final_route", ""))
        route_run_counts[r] = route_run_counts.get(r, 0) + 1

    adoption, avg_max_level, first_time_stats, pl_with, pl_without, route_adoption = {}, {}, {}, {}, {}, {}

    for uid, data in upgrade_data.items():
        n = len(data["first_times"])
        adoption[uid] = n / total_runs if total_runs > 0 else 0.0
        avg_max_level[uid] = float(np.mean(data["max_levels"])) if data["max_levels"] else 0.0

        ft = np.array(sorted(data["first_times"]))
        first_time_stats[uid] = {
            "median": float(np.median(ft)),
            "p25": float(np.percentile(ft, 25)),
            "p75": float(np.percentile(ft, 75)),
        }

        pl_with[uid] = float(np.mean(data["pls"])) if data["pls"] else 0.0

        pls_without = [
            to_int(run.get("run_summary", {}).get("pl_gained"))
            for run in runs
            if uid not in {ev.get("upgrade_id") for ev in run.get("events", []) if ev.get("type") == "upgrade_bought"}
        ]
        pl_without[uid] = float(np.mean(pls_without)) if pls_without else float("nan")

        route_bought: dict[str, int] = {}
        for run in runs:
            r = str(run.get("run_summary", {}).get("final_route", ""))
            bought = {ev.get("upgrade_id") for ev in run.get("events", []) if ev.get("type") == "upgrade_bought"}
            if uid in bought:
                route_bought[r] = route_bought.get(r, 0) + 1
        route_adoption[uid] = {
            r: route_bought.get(r, 0) / cnt
            for r, cnt in route_run_counts.items() if cnt > 0
        }

    return {
        "all_upgrade_ids": sorted(upgrade_data.keys()),
        "total_runs": total_runs,
        "adoption": adoption,
        "avg_max_level": avg_max_level,
        "first_time_stats": first_time_stats,
        "pl_with": pl_with,
        "pl_without": pl_without,
        "route_adoption": route_adoption,
        "route_run_counts": route_run_counts,
        "all_routes": list(route_run_counts.keys()),
    }


def extract_mutation_stats(runs: list[dict], df: pd.DataFrame) -> dict:
    """Estadísticas por mutation_id: tasa de activación, PL, ε_peak, timing."""
    mutation_data: dict[str, dict] = {}

    for run in runs:
        events = run.get("events", [])
        summary = run.get("run_summary", {})
        pl = to_int(summary.get("pl_gained"))
        eps_peak = to_float(summary.get("epsilon_peak"))
        run_time = to_float(summary.get("run_time"))
        route = str(summary.get("final_route", ""))

        for ev in events:
            if ev.get("type") != "mutation_activated":
                continue
            mid = ev.get("mutation_id", "")
            if not mid:
                continue
            t = to_float(ev.get("time", 0))
            time_pct = (t / run_time * 100.0) if run_time > 0 else 0.0

            if mid not in mutation_data:
                mutation_data[mid] = {"pls": [], "eps_peaks": [], "timing_pct": [], "routes": [], "count": 0}
            mutation_data[mid]["pls"].append(pl)
            mutation_data[mid]["eps_peaks"].append(eps_peak)
            mutation_data[mid]["timing_pct"].append(time_pct)
            mutation_data[mid]["routes"].append(route)
            mutation_data[mid]["count"] += 1

    total_runs = len(runs)
    pls_no_mut = [
        to_int(run.get("run_summary", {}).get("pl_gained"))
        for run in runs if not run.get("run_summary", {}).get("mutations_activated")
    ]
    eps_no_mut = [
        to_float(run.get("run_summary", {}).get("epsilon_peak"))
        for run in runs if not run.get("run_summary", {}).get("mutations_activated")
    ]

    return {
        "all_mutation_ids": sorted(mutation_data.keys()),
        "total_runs": total_runs,
        "mutation_data": mutation_data,
        "activation_rate": {
            mid: data["count"] / total_runs for mid, data in mutation_data.items()
        },
        "pls_no_mutation": pls_no_mut,
        "eps_no_mutation": eps_no_mut,
    }


def create_upgrade_adoption_bar(stats: dict) -> go.Figure:
    """Barra: % de runs que compraron cada upgrade + nivel máximo promedio."""
    uids = sorted(stats["all_upgrade_ids"], key=lambda u: -stats["adoption"][u])
    adoptions = [stats["adoption"][u] * 100 for u in uids]
    avg_lvls = [stats["avg_max_level"][u] for u in uids]
    n_runs = stats["total_runs"]

    colors = [
        f"rgba(100,180,255,{0.35 + stats['adoption'][u] * 0.65})" for u in uids
    ]

    fig = go.Figure(go.Bar(
        x=uids, y=adoptions,
        marker_color=colors,
        text=[f"{a:.0f}%  lvl {l:.1f}" for a, l in zip(adoptions, avg_lvls)],
        textposition="outside",
        customdata=[[stats["pl_with"].get(u, 0), stats["avg_max_level"][u],
                     int(stats["adoption"][u] * n_runs)] for u in uids],
        hovertemplate=(
            "<b>%{x}</b><br>"
            "Adopcion: %{y:.1f}% (%{customdata[2]} runs)<br>"
            "Nivel max promedio: %{customdata[1]:.1f}<br>"
            "PL medio (con): %{customdata[0]:.2f}<extra></extra>"
        ),
    ))
    fig.update_layout(
        title="Adopcion de upgrades (% de runs donde se compro al menos una vez)",
        xaxis_title="Upgrade",
        yaxis_title="Runs (%)",
        yaxis_range=[0, 118],
        template="plotly_dark",
        xaxis_tickangle=-35,
    )
    return fig


def create_upgrade_build_order(stats: dict) -> go.Figure:
    """Timeline horizontal: cuándo se compra cada upgrade por primera vez (mediana ± IQR)."""
    uids = sorted(
        stats["all_upgrade_ids"],
        key=lambda u: stats["first_time_stats"][u]["median"]
    )
    medians = [stats["first_time_stats"][u]["median"] for u in uids]
    p25s = [stats["first_time_stats"][u]["p25"] for u in uids]
    p75s = [stats["first_time_stats"][u]["p75"] for u in uids]
    adoptions = [stats["adoption"][u] for u in uids]

    fig = go.Figure()

    # IQR como barra de rango
    fig.add_trace(go.Bar(
        x=[p75s[i] - p25s[i] for i in range(len(uids))],
        y=uids,
        base=p25s,
        orientation="h",
        marker_color="rgba(100,180,255,0.25)",
        name="IQR (25-75%)",
        hovertemplate="<b>%{y}</b><br>IQR: %{base:.0f}s - %{customdata:.0f}s<extra></extra>",
        customdata=p75s,
    ))

    # Mediana como punto
    fig.add_trace(go.Scatter(
        x=medians, y=uids,
        mode="markers",
        marker=dict(
            size=14,
            color=[a * 100 for a in adoptions],
            colorscale="Blues",
            cmin=0, cmax=100,
            showscale=True,
            colorbar=dict(title="Adopcion %", x=1.02),
            line=dict(width=1.5, color="white"),
        ),
        text=[f"Mediana: {m:.0f}s | IQR: {p:.0f}s-{q:.0f}s | Adopcion: {a*100:.0f}%"
              for m, p, q, a in zip(medians, p25s, p75s, adoptions)],
        hovertemplate="<b>%{y}</b><br>%{text}<extra></extra>",
        name="Primera compra (mediana)",
    ))

    fig.update_layout(
        title="Orden de build tipico (primer purchase: mediana +- IQR)",
        xaxis_title="Tiempo de primera compra (segundos)",
        yaxis_title="Upgrade",
        template="plotly_dark",
        height=max(380, len(uids) * 42),
        legend=dict(orientation="h", y=-0.15),
    )
    return fig


def create_upgrade_pl_delta(stats: dict) -> go.Figure:
    """Barras: diferencia de PL promedio en runs con vs. sin cada upgrade."""
    pairs = []
    for uid in stats["all_upgrade_ids"]:
        pw = stats["pl_with"].get(uid, 0)
        pwo = stats["pl_without"].get(uid, float("nan"))
        if np.isnan(pwo):
            continue  # 100% adoption — imposible calcular "sin"
        pairs.append((uid, pw - pwo, pw, pwo))

    if not pairs:
        fig = go.Figure()
        fig.add_annotation(text="Todos los upgrades tienen 100% de adopcion.", showarrow=False, font=dict(size=13))
        fig.update_layout(template="plotly_dark")
        return fig

    pairs.sort(key=lambda x: -x[1])
    uids = [p[0] for p in pairs]
    deltas = [p[1] for p in pairs]
    pws = [p[2] for p in pairs]
    pwos = [p[3] for p in pairs]

    colors = ["#26a269" if d >= 0 else "#c01c28" for d in deltas]

    fig = go.Figure(go.Bar(
        x=uids, y=deltas,
        marker_color=colors,
        text=[f"+{d:.2f}" if d >= 0 else f"{d:.2f}" for d in deltas],
        textposition="outside",
        customdata=list(zip(pws, pwos)),
        hovertemplate=(
            "<b>%{x}</b><br>"
            "PL con upgrade: %{customdata[0]:.2f}<br>"
            "PL sin upgrade: %{customdata[1]:.2f}<br>"
            "Delta: %{y:+.2f}<extra></extra>"
        ),
    ))
    fig.add_hline(y=0, line_dash="dash", line_color="gray")
    fig.update_layout(
        title="Impacto de upgrades en PL (media con - media sin)",
        xaxis_title="Upgrade",
        yaxis_title="Delta PL",
        template="plotly_dark",
        xaxis_tickangle=-35,
    )
    return fig


def create_upgrade_route_heatmap(stats: dict) -> go.Figure:
    """Heatmap upgrade x ruta: % de runs de esa ruta que compraron el upgrade."""
    uids = sorted(stats["all_upgrade_ids"], key=lambda u: -stats["adoption"][u])
    routes = sorted(stats["all_routes"])

    z = [
        [stats["route_adoption"].get(uid, {}).get(r, 0.0) * 100 for r in routes]
        for uid in uids
    ]
    route_labels = [f"{r} (n={stats['route_run_counts'].get(r,0)})" for r in routes]

    fig = go.Figure(go.Heatmap(
        z=z, x=route_labels, y=uids,
        colorscale="Blues", zmin=0, zmax=100,
        text=[[f"{v:.0f}%" for v in row] for row in z],
        texttemplate="%{text}",
        textfont={"size": 10},
        hovertemplate="<b>%{y}</b> en <b>%{x}</b><br>Adopcion: %{z:.0f}%<extra></extra>",
    ))
    fig.update_layout(
        title="Adopcion de upgrades por ruta (% de runs de esa ruta que lo compraron)",
        xaxis_title="Ruta final",
        yaxis_title="Upgrade",
        template="plotly_dark",
        height=max(400, len(uids) * 36),
        xaxis_tickangle=-30,
    )
    return fig


def create_mutation_overview(mut_stats: dict) -> go.Figure:
    """3 subplots: tasa de activacion, PL medio, ε_peak medio — con vs sin mutacion."""
    mids = mut_stats["all_mutation_ids"]
    total = mut_stats["total_runs"]

    if not mids:
        fig = go.Figure()
        fig.add_annotation(text="No hay mutaciones registradas aun.", showarrow=False, font=dict(size=14))
        fig.update_layout(template="plotly_dark")
        return fig

    rates = [mut_stats["activation_rate"][m] * 100 for m in mids]
    pl_with = [float(np.mean(mut_stats["mutation_data"][m]["pls"])) if mut_stats["mutation_data"][m]["pls"] else 0 for m in mids]
    eps_with = [float(np.mean(mut_stats["mutation_data"][m]["eps_peaks"])) if mut_stats["mutation_data"][m]["eps_peaks"] else 0 for m in mids]
    counts = [mut_stats["mutation_data"][m]["count"] for m in mids]
    pl_none = float(np.mean(mut_stats["pls_no_mutation"])) if mut_stats["pls_no_mutation"] else 0.0
    eps_none = float(np.mean(mut_stats["eps_no_mutation"])) if mut_stats["eps_no_mutation"] else 0.0
    bar_colors = [_MUT_COLORS[i % len(_MUT_COLORS)] for i in range(len(mids))]

    fig = make_subplots(
        rows=1, cols=3,
        subplot_titles=("Activacion (%)", "PL medio (linea = sin mutacion)", "e_peak medio (linea = sin mutacion)"),
        horizontal_spacing=0.1,
    )

    fig.add_trace(go.Bar(
        x=mids, y=rates, marker_color=bar_colors, showlegend=False,
        text=[f"{r:.0f}%  n={c}" for r, c in zip(rates, counts)],
        textposition="outside",
        hovertemplate="<b>%{x}</b><br>%{y:.1f}% de runs<extra></extra>",
    ), row=1, col=1)

    fig.add_trace(go.Bar(
        x=mids, y=pl_with, marker_color=bar_colors, showlegend=False,
        text=[f"{p:.2f}" for p in pl_with], textposition="outside",
        hovertemplate="<b>%{x}</b><br>PL medio: %{y:.2f}<extra></extra>",
    ), row=1, col=2)
    fig.add_hline(y=pl_none, line_dash="dash", line_color="#ffcc44",
                  annotation_text=f"Sin: {pl_none:.1f}", row=1, col=2)

    fig.add_trace(go.Bar(
        x=mids, y=eps_with, marker_color=bar_colors, showlegend=False,
        text=[f"{e:.2f}" for e in eps_with], textposition="outside",
        hovertemplate="<b>%{x}</b><br>e_peak medio: %{y:.3f}<extra></extra>",
    ), row=1, col=3)
    fig.add_hline(y=eps_none, line_dash="dash", line_color="#ffcc44",
                  annotation_text=f"Sin: {eps_none:.2f}", row=1, col=3)

    fig.update_layout(
        title="Analisis de mutaciones — activacion, impacto en PL y estres",
        template="plotly_dark",
        height=440,
    )
    return fig


def create_mutation_timing(mut_stats: dict) -> go.Figure:
    """Scatter: en qué % del tiempo de run se activa cada mutacion. Tamaño = PL."""
    mids = mut_stats["all_mutation_ids"]

    if not mids:
        fig = go.Figure()
        fig.add_annotation(text="No hay mutaciones registradas aun.", showarrow=False)
        fig.update_layout(template="plotly_dark")
        return fig

    fig = go.Figure()
    for i, mid in enumerate(mids):
        timings = mut_stats["mutation_data"][mid]["timing_pct"]
        pls = mut_stats["mutation_data"][mid]["pls"]
        color = _MUT_COLORS[i % len(_MUT_COLORS)]
        sizes = [max(10, p * 4 + 10) for p in pls]

        fig.add_trace(go.Scatter(
            x=timings, y=[mid] * len(timings),
            mode="markers",
            marker=dict(size=sizes, color=color, opacity=0.75, line=dict(width=1, color="white")),
            text=[f"PL: {p}" for p in pls],
            hovertemplate=f"<b>{mid}</b><br>Momento: %{{x:.1f}}%<br>%{{text}}<extra></extra>",
            name=mid,
        ))

    fig.add_vline(x=50, line_dash="dot", line_color="rgba(255,255,255,0.2)",
                  annotation_text="50%")
    fig.update_layout(
        title="Momento de activacion de mutaciones (% del tiempo total de run, tamano = PL)",
        xaxis_title="Momento en la run (%)",
        xaxis_range=[-3, 105],
        yaxis_title="Mutacion",
        template="plotly_dark",
    )
    return fig


# ============================================================================
# CURVAS DE ACUMULACIÓN POR RUTA
# ============================================================================

def _hex_rgba(hex_color: str, alpha: float) -> str:
    h = hex_color.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return f"rgba({r},{g},{b},{alpha})"


def create_accumulation_curves(runs: list[dict]) -> go.Figure:
    """Curvas de acumulacion promedio por ruta (mediana + banda IQR 25-75).
    4 subplots: epsilon, mu, dinero, biomasa. Tiempo normalizado 0-100%."""
    GRID = np.linspace(0, 100, 41)
    METRICS = [
        ("epsilon",  "e (estres)",           "#e5a50a"),
        ("mu",       "u (capital cognitivo)", "#1c71d8"),
        ("money",    "Dinero",                "#26a269"),
        ("biomasa",  "Biomasa",               "#9141ac"),
    ]

    route_series: dict[str, dict[str, list]] = {}

    for run in runs:
        metrics = run.get("metrics_series", [])
        if len(metrics) < 2:
            continue
        summary = run.get("run_summary", {})
        route = str(summary.get("final_route", ""))
        run_time = to_float(summary.get("run_time"))
        if run_time <= 0:
            continue

        times_pct = [to_float(m.get("time", 0)) / run_time * 100.0 for m in metrics]

        if route not in route_series:
            route_series[route] = {mid: [] for mid, _, _ in METRICS}

        for mid, _, _ in METRICS:
            values = [to_float(m.get(mid, 0)) for m in metrics]
            route_series[route][mid].append(np.interp(GRID, times_pct, values))

    fig = make_subplots(
        rows=2, cols=2,
        subplot_titles=[m[1] for m in METRICS],
        vertical_spacing=0.14,
        horizontal_spacing=0.08,
    )
    positions = [(1, 1), (1, 2), (2, 1), (2, 2)]

    shown_in_legend: set[str] = set()

    for idx, (mid, label, _) in enumerate(METRICS):
        row, col = positions[idx]
        for route, series_dict in route_series.items():
            series = series_dict.get(mid, [])
            if not series:
                continue
            arr = np.array(series)
            median_line = np.median(arr, axis=0)
            color = ROUTE_COLORS.get(route, "#64748b")
            show_legend = route not in shown_in_legend

            if len(series) > 1:
                p25 = np.percentile(arr, 25, axis=0)
                p75 = np.percentile(arr, 75, axis=0)
                fig.add_trace(go.Scatter(
                    x=np.concatenate([GRID, GRID[::-1]]),
                    y=np.concatenate([p75, p25[::-1]]),
                    fill="toself",
                    fillcolor=_hex_rgba(color, 0.15),
                    line=dict(width=0),
                    showlegend=False,
                    hoverinfo="skip",
                    legendgroup=route,
                ), row=row, col=col)

            fig.add_trace(go.Scatter(
                x=GRID, y=median_line,
                mode="lines",
                line=dict(color=color, width=2),
                name=route,
                legendgroup=route,
                showlegend=show_legend,
                hovertemplate=f"<b>{route}</b><br>Progreso: %{{x:.0f}}%<br>{label}: %{{y:.4f}}<extra></extra>",
            ), row=row, col=col)

            if show_legend:
                shown_in_legend.add(route)

    fig.update_layout(
        title="Curvas de acumulacion por ruta (mediana + banda IQR)",
        template="plotly_dark",
        height=680,
        legend=dict(font=dict(size=10), orientation="h", y=-0.06),
    )
    for i in range(1, 5):
        fig.update_xaxes(title_text="Progreso (%)", row=positions[i-1][0], col=positions[i-1][1])
    return fig


# ============================================================================
# RUN DETECTIVE
# ============================================================================

def build_run_detective_html(runs: list[dict]) -> str:
    """HTML+JS para inspeccionar una run individual con chart de metricas y tabla de eventos."""
    run_data: dict[str, dict] = {}

    EVENT_TYPES = {"upgrade_bought", "mutation_activated", "first_epsilon_high",
                   "achievement_unlocked", "run_close"}

    for run in runs:
        fname = run.get("_file", "")
        summary = run.get("run_summary", {})
        metrics = run.get("metrics_series", [])
        events = [
            {
                "type": ev.get("type"),
                "time": round(to_float(ev.get("time")), 2),
                "id": ev.get("upgrade_id") or ev.get("mutation_id") or ev.get("achievement_id") or "",
                "level": ev.get("new_level"),
            }
            for ev in run.get("events", [])
            if ev.get("type") in EVENT_TYPES
        ]
        route = str(summary.get("final_route", ""))
        run_data[fname] = {
            "route": route,
            "color": ROUTE_COLORS.get(route, "#64748b"),
            "pl": to_int(summary.get("pl_gained")),
            "run_time": round(to_float(summary.get("run_time")), 1),
            "epsilon_peak": round(to_float(summary.get("epsilon_peak")), 4),
            "max_mu": round(to_float(summary.get("max_mu")), 4),
            "metrics": [
                {
                    "t": round(to_float(m.get("time")), 1),
                    "e": round(to_float(m.get("epsilon")), 4),
                    "mu": round(to_float(m.get("mu")), 4),
                    "money": round(to_float(m.get("money")), 1),
                    "biomasa": round(to_float(m.get("biomasa")), 3),
                }
                for m in metrics
            ],
            "events": events,
        }

    run_files = sorted(run_data.keys())
    if not run_files:
        return "<p style='color:#aaa'>No hay runs disponibles.</p>"

    options_html = "".join(f'<option value="{f}">{f}</option>' for f in run_files)
    data_json = json.dumps(run_data, ensure_ascii=False)

    return f"""
<div id="detective-summary" style="
    background:#1a1a2e; border:1px solid #444; border-radius:8px;
    padding:12px 20px; margin-bottom:14px; font-size:15px; color:#e0e0e0;">
    Selecciona una run para inspeccionarla.
</div>

<div style="margin-bottom:14px; display:flex; align-items:center; gap:14px; flex-wrap:wrap;">
    <label style="color:#aaa; font-size:14px;">Run:</label>
    <select id="detective-select" style="
        background:#1a1a2e; color:#ffcc44; border:1px solid #ffcc44;
        padding:6px 14px; border-radius:6px; font-size:14px; max-width:420px;">
        {options_html}
    </select>
</div>

<div id="detective-chart" style="height:380px; margin-bottom:16px;"></div>
<div id="detective-resources" style="height:260px; margin-bottom:16px;"></div>

<div style="overflow-x:auto; max-height:340px; overflow-y:auto;">
    <table style="width:100%; border-collapse:collapse; background:#111118; border-radius:8px; overflow:hidden; font-size:13px;">
        <thead>
            <tr>
                <th style="padding:8px 12px; text-align:left; background:#1a1a2e; color:#ffcc44; position:sticky; top:0;">Tiempo</th>
                <th style="padding:8px 12px; text-align:left; background:#1a1a2e; color:#ffcc44; position:sticky; top:0;">Tipo</th>
                <th style="padding:8px 12px; text-align:left; background:#1a1a2e; color:#ffcc44; position:sticky; top:0;">ID / Detalle</th>
                <th style="padding:8px 12px; text-align:left; background:#1a1a2e; color:#ffcc44; position:sticky; top:0;">Nivel</th>
            </tr>
        </thead>
        <tbody id="detective-events"></tbody>
    </table>
</div>

<script>
(function(){{
var DATA = {data_json};
var ETYPE_COLORS = {{
    upgrade_bought: "#64748b",
    mutation_activated: "#ff7800",
    first_epsilon_high: "#e5a50a",
    achievement_unlocked: "#ffdd55",
    run_close: "#26a269"
}};
var ETYPE_LABELS = {{
    upgrade_bought: "Upgrade",
    mutation_activated: "Mutacion",
    first_epsilon_high: "e alta",
    achievement_unlocked: "Logro",
    run_close: "Fin de run"
}};

function fmt(secs) {{
    var m = Math.floor(secs / 60);
    var s = Math.floor(secs % 60);
    return m + ":" + String(s).padStart(2, "0");
}}

function buildShapes(events) {{
    var shapes = [], anns = [];
    events.forEach(function(ev) {{
        if (ev.type === "mutation_activated") {{
            shapes.push({{type:"line", x0:ev.time, x1:ev.time, y0:0, y1:1,
                yref:"paper", line:{{color:"#ff7800", width:2, dash:"dot"}}}});
            anns.push({{x:ev.time, y:0.98, yref:"paper", text:ev.id,
                showarrow:false, font:{{color:"#ff7800", size:10}}, xanchor:"left"}});
        }} else if (ev.type === "first_epsilon_high") {{
            shapes.push({{type:"line", x0:ev.time, x1:ev.time, y0:0, y1:1,
                yref:"paper", line:{{color:"#e5a50a", width:1.5, dash:"dash"}}}});
            anns.push({{x:ev.time, y:0.88, yref:"paper", text:"e alta",
                showarrow:false, font:{{color:"#e5a50a", size:10}}, xanchor:"left"}});
        }}
    }});
    return {{shapes:shapes, annotations:anns}};
}}

var BASE_LAYOUT = {{
    paper_bgcolor:"#111118", plot_bgcolor:"#111118",
    font:{{color:"#e0e0e0"}},
    margin:{{t:30, b:40, l:60, r:60}},
    hovermode:"x unified",
    legend:{{font:{{size:11}}, orientation:"h"}},
}};

function update(fname) {{
    var d = DATA[fname];
    if (!d) return;

    var times = d.metrics.map(function(m){{return m.t;}});
    var minTime = times[0] || 0;
    var maxTime = d.run_time;

    // --- Chart 1: epsilon + mu ---
    var traces1 = [
        {{x:times, y:d.metrics.map(function(m){{return m.e;}}),
          name:"e (estres)", type:"scatter", mode:"lines",
          line:{{color:"#e5a50a", width:2.5}}, yaxis:"y"}},
        {{x:times, y:d.metrics.map(function(m){{return m.mu;}}),
          name:"u (cap. cognitivo)", type:"scatter", mode:"lines",
          line:{{color:"#64aaff", width:2.5}}, yaxis:"y2"}},
    ];
    var sa = buildShapes(d.events);
    Plotly.react("detective-chart", traces1, Object.assign({{}}, BASE_LAYOUT, {{
        shapes: sa.shapes, annotations: sa.annotations,
        xaxis:{{title:"Tiempo (s)", range:[minTime, maxTime]}},
        yaxis:{{title:"e (estres)", titlefont:{{color:"#e5a50a"}}, tickfont:{{color:"#e5a50a"}}}},
        yaxis2:{{title:"u", titlefont:{{color:"#64aaff"}}, tickfont:{{color:"#64aaff"}},
                 overlaying:"y", side:"right"}},
    }}));

    // --- Chart 2: money + biomasa ---
    var traces2 = [
        {{x:times, y:d.metrics.map(function(m){{return m.money;}}),
          name:"Dinero", type:"scatter", mode:"lines",
          line:{{color:"#26a269", width:2}}, yaxis:"y"}},
        {{x:times, y:d.metrics.map(function(m){{return m.biomasa;}}),
          name:"Biomasa", type:"scatter", mode:"lines",
          line:{{color:"#9141ac", width:2}}, yaxis:"y2"}},
    ];
    Plotly.react("detective-resources", traces2, Object.assign({{}}, BASE_LAYOUT, {{
        shapes: sa.shapes,
        xaxis:{{title:"Tiempo (s)", range:[minTime, maxTime]}},
        yaxis:{{title:"Dinero", titlefont:{{color:"#26a269"}}, tickfont:{{color:"#26a269"}}}},
        yaxis2:{{title:"Biomasa", titlefont:{{color:"#9141ac"}}, tickfont:{{color:"#9141ac"}},
                 overlaying:"y", side:"right"}},
    }}));

    // --- Summary ---
    var dur = fmt(d.run_time);
    document.getElementById("detective-summary").innerHTML =
        "<b style='color:" + d.color + "'>" + d.route + "</b>" +
        " &nbsp;|&nbsp; PL: <b>" + d.pl + "</b>" +
        " &nbsp;|&nbsp; e_peak: <b>" + d.epsilon_peak + "</b>" +
        " &nbsp;|&nbsp; u_max: <b>" + d.max_mu + "</b>" +
        " &nbsp;|&nbsp; Duracion: <b>" + dur + "</b>" +
        " &nbsp;|&nbsp; <span style='color:#aaa; font-size:12px;'>" + fname + "</span>";

    // --- Event table ---
    var tbody = document.getElementById("detective-events");
    tbody.innerHTML = "";
    d.events.forEach(function(ev) {{
        var c = ETYPE_COLORS[ev.type] || "#aaa";
        var lbl = ETYPE_LABELS[ev.type] || ev.type;
        var detail = ev.id || "";
        var level = ev.level ? "Nv" + ev.level : "";
        tbody.innerHTML +=
            "<tr style='border-bottom:1px solid #1e1e2e;'>" +
            "<td style='padding:5px 12px; color:" + c + ";'>" + fmt(ev.time) + "</td>" +
            "<td style='padding:5px 12px; color:" + c + ";'>" + lbl + "</td>" +
            "<td style='padding:5px 12px;'>" + detail + "</td>" +
            "<td style='padding:5px 12px; color:#888;'>" + level + "</td>" +
            "</tr>";
    }});
}}

document.getElementById("detective-select").addEventListener("change", function(){{
    update(this.value);
}});
update(run_files[0]);

var run_files = {json.dumps(run_files)};
// init
update(run_files[0]);
document.getElementById("detective-select").value = run_files[0];
}})();
</script>"""


# ============================================================================
# DASHBOARD HTML
# ============================================================================

def build_dashboard_html(df: pd.DataFrame, runs: list[dict]) -> str:
    """Genera el dashboard HTML con los gráficos interactivos"""
    
    # Estadísticas básicas
    total_runs = len(df)
    avg_pl = df["pl"].mean()
    avg_eps = df["epsilon_peak"].mean()
    best_route = df.groupby("route")["pl_per_min"].mean().idxmax() if not df.empty else "-"
    
    cards_html = f"""
    <div class="stats-grid">
        <div class="stat-card"><div class="stat-num">{total_runs}</div><div class="stat-label">Total runs</div></div>
        <div class="stat-card"><div class="stat-num">{avg_pl:.1f}</div><div class="stat-label">PL promedio</div></div>
        <div class="stat-card"><div class="stat-num">{avg_eps:.2f}</div><div class="stat-label">ε_peak promedio</div></div>
        <div class="stat-card"><div class="stat-num">{best_route}</div><div class="stat-label">Ruta más eficiente</div></div>
    </div>
    """
    
    # Generar gráficos Plotly como HTML
    scatter_plot = create_scatter_epsilon_vs_pl(df).to_html(full_html=False, include_plotlyjs="cdn")
    boxplot_pl = create_boxplot_pl_by_route(df).to_html(full_html=False, include_plotlyjs=False)
    bar_eff = create_bar_efficiency(df).to_html(full_html=False, include_plotlyjs=False)
    scatter_mu = create_scatter_mu_vs_pl(df).to_html(full_html=False, include_plotlyjs=False)
    hist_duration = create_duration_histogram(df).to_html(full_html=False, include_plotlyjs=False)
    eps_boxplot = create_epsilon_boxplot_by_route(df).to_html(full_html=False, include_plotlyjs=False)
    radar_stats = compute_radar_stats(df)
    radar_top3 = create_radar_top3(radar_stats).to_html(full_html=False, include_plotlyjs=False)
    radar_comparator = build_radar_comparator_html(radar_stats)
    evolution = create_evolution_overlay(df, runs).to_html(full_html=False, include_plotlyjs=False)

    accum_curves = create_accumulation_curves(runs).to_html(full_html=False, include_plotlyjs=False)
    run_detective = build_run_detective_html(runs)

    upgrade_stats = extract_upgrade_stats(runs, df)
    mut_stats = extract_mutation_stats(runs, df)
    upg_adoption = create_upgrade_adoption_bar(upgrade_stats).to_html(full_html=False, include_plotlyjs=False)
    upg_build_order = create_upgrade_build_order(upgrade_stats).to_html(full_html=False, include_plotlyjs=False)
    upg_pl_delta = create_upgrade_pl_delta(upgrade_stats).to_html(full_html=False, include_plotlyjs=False)
    upg_route_heatmap = create_upgrade_route_heatmap(upgrade_stats).to_html(full_html=False, include_plotlyjs=False)
    mut_overview = create_mutation_overview(mut_stats).to_html(full_html=False, include_plotlyjs=False)
    mut_timing = create_mutation_timing(mut_stats).to_html(full_html=False, include_plotlyjs=False)

    # Tabla HTML simple
    table_rows = ""
    for _, row in df.iterrows():
        table_rows += f"""
        <tr>
            <td>{html.escape(row['file'])}</td>
            <td style="color:{ROUTE_COLORS.get(row['route'], '#64748b')}">{html.escape(row['route'])}</td>
            <td>{int(row['pl'])}</td>
            <td>{seconds_to_label(row['run_time_seconds'])}</td>
            <td>{row['pl_per_min']:.2f}</td>
            <td>{row['epsilon_peak']:.3f}</td>
            <td>{row['max_mu']:.3f}</td>
            <td>{int(row['max_delta_per_sec'])}</td>
        </tr>
        """
    
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AntiIDLE - Telemetry Dashboard</title>
    <script src="https://cdn.plot.ly/plotly-3.1.0.min.js" charset="utf-8"></script>
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0a0a0f;
            color: #e0e0e0;
            padding: 20px;
        }}
        .container {{ max-width: 1400px; margin: 0 auto; }}
        h1 {{ color: #ffcc44; margin-bottom: 10px; }}
        h2 {{ color: #88aaff; margin: 30px 0 15px 0; border-bottom: 1px solid #333; padding-bottom: 8px; }}
        h3 {{ color: #aaa; margin: 20px 0 10px 0; }}
        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }}
        .stat-card {{
            background: linear-gradient(135deg, #1a1a2e, #16213e);
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            border: 1px solid #ffcc44;
        }}
        .stat-num {{
            font-size: 2.2em;
            font-weight: bold;
            color: #ffcc44;
        }}
        .stat-label {{
            font-size: 0.85em;
            color: #aaa;
            margin-top: 5px;
        }}
        .plot-card {{
            background: #111118;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 25px;
            border: 1px solid #2a2a35;
        }}
        .two-columns {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
            gap: 20px;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            background: #111118;
            border-radius: 8px;
            overflow: hidden;
        }}
        th, td {{
            padding: 10px 12px;
            text-align: left;
            border-bottom: 1px solid #2a2a35;
        }}
        th {{
            background: #1a1a2e;
            color: #ffcc44;
            font-weight: 600;
        }}
        tr:hover {{ background: #1a1a2e; }}
        .footer {{
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #666;
            font-size: 0.8em;
            border-top: 1px solid #2a2a35;
        }}
    </style>
</head>
<body>
<div class="container">
    <h1>🍄 AntiIDLE - Telemetry Dashboard</h1>
    <p>Dashboard interactivo para análisis de balance y rendimiento</p>
    
    {cards_html}
    
    <h2>📈 Análisis de PL y eficiencia</h2>
    <div class="two-columns">
        <div class="plot-card">{scatter_plot}</div>
        <div class="plot-card">{boxplot_pl}</div>
    </div>
    <div class="two-columns">
        <div class="plot-card">{bar_eff}</div>
        <div class="plot-card">{scatter_mu}</div>
    </div>
    
    <h2>📊 Análisis de estrés (ε) y capital cognitivo (μ)</h2>
    <div class="two-columns">
        <div class="plot-card">{eps_boxplot}</div>
        <div class="plot-card">{hist_duration}</div>
    </div>
    <div class="plot-card">{evolution}</div>
    
    <h2>🎯 Perfil de rutas</h2>
    <div class="plot-card">{radar_top3}</div>
    <h3 style="color:#aaa; margin: 20px 0 10px 0;">Comparador 1v1</h3>
    <div class="plot-card">{radar_comparator}</div>

    <h2>📈 Curvas de acumulación por ruta</h2>
    <div class="plot-card">{accum_curves}</div>

    <h2>🔍 Run Detective</h2>
    <div class="plot-card">{run_detective}</div>

    <h2>🔧 Análisis de Upgrades</h2>
    <div class="plot-card">{upg_adoption}</div>
    <div class="two-columns">
        <div class="plot-card">{upg_build_order}</div>
        <div class="plot-card">{upg_pl_delta}</div>
    </div>
    <div class="plot-card">{upg_route_heatmap}</div>

    <h2>🧬 Análisis de Mutaciones</h2>
    <div class="plot-card">{mut_overview}</div>
    <div class="plot-card">{mut_timing}</div>

    <h2>📋 Tabla de runs</h2>
    <div style="overflow-x: auto;">
        <table>
            <thead>
                <tr><th>Archivo</th><th>Ruta</th><th>PL</th><th>Duración</th><th>PL/min</th><th>ε_peak</th><th>μ max</th><th>Δ$/s max</th></tr>
            </thead>
            <tbody>{table_rows}</tbody>
        </table>
    </div>
    
    <div class="footer">
        Generado con Plotly | <a href="correlation_heatmap_interactive.html" style="color:#88aaff;">Ver heatmap de correlaciones interactivo</a> | 
        <a href="correlation_heatmap.png" style="color:#88aaff;">Versión PNG</a>
    </div>
</div>
</body>
</html>"""


# ============================================================================
# MAIN
# ============================================================================

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Analyze local AntiIDLE telemetry runs.")
    parser.add_argument("runs_dir", nargs="?", type=Path, default=DEFAULT_RUNS_DIR,
                        help="Folder containing telemetry run JSON files.")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT_DIR,
                        help="Output folder for analysis files.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    runs_dir = args.runs_dir
    output_dir = args.output
    
    if not runs_dir.exists():
        print(f"Telemetry folder does not exist: {runs_dir}")
        return 1
    
    runs = load_all_runs(runs_dir)
    rows = [summarize_run(run) for run in runs]
    df = build_dataframe(rows)
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Guardar CSV
    df.to_csv(output_dir / "telemetry_runs.csv", index=False)
    
    # Generar heatmap de correlaciones
    create_correlation_heatmap(df, output_dir)
    
    # Generar dashboard HTML
    dashboard_html = build_dashboard_html(df, runs)
    (output_dir / "telemetry_dashboard.html").write_text(dashboard_html, encoding="utf-8")
    
    print(f"[OK] Analisis completado. {len(runs)} runs procesadas.")
    print(f"[>]  Output: {output_dir.absolute()}")
    print(f"[>]  Abre:   {output_dir / 'telemetry_dashboard.html'}")
    
    return 0


if __name__ == "__main__":
    raise SystemExit(main())