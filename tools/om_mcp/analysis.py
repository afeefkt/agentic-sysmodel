"""Pure-Python analysis helpers for the OpenModelica MCP server.

Kept free of omc so they can be unit-tested on synthetic data:
signal metrics (step response + statistics), case comparison, CSV/XLSX
export, plotting, parsing of omc's linearized_model.mo and frequency analysis.
"""

from __future__ import annotations

import csv
import json
import math
import re
from pathlib import Path
from typing import Any, Optional

import numpy as np

ALL_METRICS = ["min", "max", "mean", "rms", "final", "integral", "max_rate",
               "rise_time", "overshoot_pct", "settling_time",
               "steady_state_error", "peak_time"]


# ------------------------------------------------------------------ metrics --
def _window(times, vals, t_start: Optional[float], t_end: Optional[float]):
    t = np.asarray(times, dtype=float)
    y = np.asarray(vals, dtype=float)
    mask = np.ones_like(t, dtype=bool)
    if t_start is not None:
        mask &= t >= t_start
    if t_end is not None:
        mask &= t <= t_end
    return t[mask], y[mask]


def _first_crossing(t, y, level: float, rising: bool) -> Optional[float]:
    for i in range(1, len(t)):
        a, b = y[i - 1], y[i]
        if (rising and a < level <= b) or (not rising and a > level >= b):
            if b == a:
                return float(t[i])
            return float(t[i - 1] + (level - a) * (t[i] - t[i - 1]) / (b - a))
    return None


def signal_metrics(times, vals, metrics: Optional[list[str]] = None,
                   t_start: Optional[float] = None, t_end: Optional[float] = None,
                   setpoint: Optional[float] = None, band: float = 0.02) -> dict:
    """Compute metrics on one trajectory.

    Step metrics use y0 = value at window start and ref = `setpoint` if given,
    else the final value. Times (rise/settling/peak) are relative to window start.
    """
    metrics = metrics or ALL_METRICS
    t, y = _window(times, vals, t_start, t_end)
    if len(t) < 2:
        return {"error": "fewer than 2 samples in the requested window"}
    t0, y0, yf = float(t[0]), float(y[0]), float(y[-1])
    ref = float(setpoint) if setpoint is not None else yf
    span = ref - y0
    rising = span >= 0
    out: dict[str, Any] = {}

    for m in metrics:
        if m == "min":
            out[m] = float(y.min())
        elif m == "max":
            out[m] = float(y.max())
        elif m == "final":
            out[m] = yf
        elif m == "mean":
            out[m] = float(np.trapezoid(y, t) / (t[-1] - t0)) if t[-1] > t0 else float(y.mean())
        elif m == "rms":
            out[m] = float(math.sqrt(np.trapezoid(y * y, t) / (t[-1] - t0))) if t[-1] > t0 else float(abs(y).mean())
        elif m == "integral":
            out[m] = float(np.trapezoid(y, t))
        elif m == "max_rate":
            dt = np.diff(t)
            ok = dt > 0                      # skip duplicated event time points
            out[m] = float(np.max(np.abs(np.diff(y)[ok] / dt[ok]))) if ok.any() else 0.0
        elif m == "steady_state_error":
            out[m] = (ref - yf) if setpoint is not None else None
        elif m in ("rise_time", "overshoot_pct", "settling_time", "peak_time"):
            if abs(span) < 1e-12:
                out[m] = None                # no step in this window
                continue
            if m == "rise_time":
                t10 = _first_crossing(t, y, y0 + 0.1 * span, rising)
                t90 = _first_crossing(t, y, y0 + 0.9 * span, rising)
                out[m] = (t90 - t10) if (t10 is not None and t90 is not None) else None
            elif m == "overshoot_pct":
                peak = y.max() if rising else y.min()
                out[m] = max(0.0, float((peak - ref) / span * 100.0))
            elif m == "peak_time":
                i = int(np.argmax(y) if rising else np.argmin(y))
                out[m] = float(t[i] - t0)
            elif m == "settling_time":
                tol = band * abs(span)
                outside = np.abs(y - ref) > tol
                if outside[-1]:
                    out[m] = None            # not settled within the window
                elif not outside.any():
                    out[m] = 0.0
                else:
                    last = int(np.where(outside)[0][-1])
                    out[m] = float(t[last + 1] - t0)
        else:
            out[m] = f"unknown metric (valid: {ALL_METRICS})"
    if any(k in metrics for k in ("rise_time", "overshoot_pct", "settling_time")):
        out["_reference"] = {"y0": y0, "ref": ref, "band": band, "t_window_start": t0}
    return out


def markdown_table(table: dict[str, dict[str, dict]], metrics: list[str]) -> str:
    """{var: {case: {metric: value}}} -> markdown table."""
    lines = ["| variable | case | " + " | ".join(metrics) + " |",
             "|---|---|" + "---|" * len(metrics)]
    for var, cases in table.items():
        for case, vals in cases.items():
            cells = []
            for m in metrics:
                v = vals.get(m)
                cells.append("—" if v is None else (f"{v:.4g}" if isinstance(v, float) else str(v)))
            lines.append(f"| {var} | {case} | " + " | ".join(cells) + " |")
    return "\n".join(lines)


# ------------------------------------------------------------------- export --
def _resample(times, vals, dt: Optional[float]):
    if not dt:
        return list(times), list(vals)
    t = np.asarray(times, dtype=float)
    # np.interp needs strictly increasing x: drop duplicated event points
    keep = np.concatenate(([True], np.diff(t) > 0))
    grid = np.arange(t[0], t[-1] + 0.5 * dt, dt)
    return grid.tolist(), np.interp(grid, t[keep], np.asarray(vals, float)[keep]).tolist()


def export_cases(cases: dict[str, Any], variables: list[str], out_path: Path,
                 fmt: str = "csv", resample_dt: Optional[float] = None) -> list[str]:
    """`cases` maps tag -> SimulationResult. Returns the written file paths."""
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tables: dict[str, tuple[list[str], list[list[float]]]] = {}
    for tag, res in cases.items():
        cols, header = [], ["time"]
        grid = None
        for var in variables:
            t, v = _resample(*res.series(var), resample_dt)
            grid = grid or t
            cols.append(v)
            header.append(var)
        rows = [[grid[i]] + [c[i] for c in cols] for i in range(len(grid))]
        tables[tag] = (header, rows)

    written: list[str] = []
    if fmt == "csv":
        for tag, (header, rows) in tables.items():
            p = out_path if len(tables) == 1 else \
                out_path.with_name(f"{out_path.stem}_{tag}{out_path.suffix or '.csv'}")
            p = p.with_suffix(".csv")
            with open(p, "w", newline="") as f:
                w = csv.writer(f)
                w.writerow(header)
                w.writerows(rows)
            written.append(str(p))
    elif fmt == "xlsx":
        from openpyxl import Workbook
        wb = Workbook()
        summary = wb.active
        summary.title = "summary"
        summary.append(["case", "variable", "min", "max", "final"])
        for tag, (header, rows) in tables.items():
            ws = wb.create_sheet(title=re.sub(r"[\[\]:*?/\\]", "_", tag)[:31])
            ws.append(header)
            for r in rows:
                ws.append(r)
            for j, var in enumerate(header[1:], start=1):
                col = [r[j] for r in rows]
                summary.append([tag, var, min(col), max(col), col[-1]])
        p = out_path.with_suffix(".xlsx")
        wb.save(p)
        written.append(str(p))
    else:
        raise ValueError("format must be 'csv' or 'xlsx'")
    return written


# --------------------------------------------------------------------- plot --
def plot_cases(cases: dict[str, Any], variables: list[str], out_path: Path,
               title: str = "", x: str = "time", subplots: bool = True,
               reference_lines: Optional[list[dict]] = None) -> str:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    n = len(variables) if subplots else 1
    fig, axes = plt.subplots(n, 1, figsize=(9, 2.6 * n + 0.6), sharex=True, squeeze=False)
    for k, var in enumerate(variables):
        ax = axes[k if subplots else 0][0]
        for tag, res in cases.items():
            _, yv = res.series(var)
            xv = res.series(x)[1] if x != "time" else res.series(var)[0]
            label = tag if subplots else f"{var} [{tag}]"
            ax.plot(xv, yv, label=label, linewidth=1.4)
        for ref in reference_lines or []:
            if ref.get("var") in (None, var):
                ax.axhline(ref["y"], linestyle="--", linewidth=1, color="k", alpha=0.6)
                ax.annotate(ref.get("label", ""), xy=(0.01, ref["y"]),
                            xycoords=("axes fraction", "data"), fontsize=8,
                            va="bottom")
        if subplots:
            ax.set_ylabel(var, fontsize=9)
        ax.grid(True, alpha=0.3)
        if len(cases) > 1 or not subplots:
            ax.legend(fontsize=8, loc="best")
    axes[-1][0].set_xlabel(x)
    if title:
        fig.suptitle(title)
    fig.tight_layout()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path.with_suffix(".png"), dpi=130)
    plt.close(fig)
    return str(out_path.with_suffix(".png"))


# ----------------------------------------------------------- linearization --
def _parse_matrix(text: str, name: str, rows: int, cols: int) -> list[list[float]]:
    if rows == 0 or cols == 0:
        return [[] for _ in range(rows)]
    m = re.search(rf"parameter Real {name}\[[^\]]*\]\s*=\s*(.*?);\s*\n\s*(?:parameter|Real|input|output|\n)",
                  text, re.S)
    if not m:
        raise ValueError(f"matrix {name} not found in linearized model")
    body = m.group(1).strip()
    if body.startswith("zeros"):
        return [[0.0] * cols for _ in range(rows)]
    body = body.strip().lstrip("[").rstrip("]")
    mat = [[float(v) for v in row.split(",")] for row in body.split(";")]
    if len(mat) != rows or any(len(r) != cols for r in mat):
        raise ValueError(f"matrix {name}: expected {rows}x{cols}")
    return mat


def parse_linearized_model(path: Path) -> dict:
    text = path.read_text()

    def dim(sym):
        return int(re.search(rf"parameter Integer {sym} = (\d+)", text).group(1))

    n, m, p = dim("n"), dim("m"), dim("p")
    names = {k: re.findall(rf"Real '{k}_([^']+)' = {k}\[\d+\]", text) for k in "xuy"}
    return {"n_states": n, "n_inputs": m, "n_outputs": p,
            "states": names["x"], "inputs": names["u"], "outputs": names["y"],
            "A": _parse_matrix(text, "A", n, n), "B": _parse_matrix(text, "B", n, m),
            "C": _parse_matrix(text, "C", p, n), "D": _parse_matrix(text, "D", p, m)}


# --------------------------------------------------------- frequency tools --
def _crossings(w, f, level):
    idx = np.where(np.diff(np.sign(f - level)) != 0)[0]
    out = []
    for i in idx:
        a, b = f[i] - level, f[i + 1] - level
        frac = a / (a - b) if a != b else 0.0
        out.append((i, float(np.exp(np.log(w[i]) + frac * (np.log(w[i + 1]) - np.log(w[i]))))))
    return out


def frequency_analysis(lin: dict, input_name: str, output_name: str,
                       n_points: int = 800, bode_path: Optional[Path] = None) -> dict:
    """SISO frequency analysis of the linearized model from input to output.
    Margins are only meaningful if this path is an OPEN-LOOP loop gain L(s)."""
    A = np.array(lin["A"], float).reshape(lin["n_states"], lin["n_states"])
    B = np.array(lin["B"], float).reshape(lin["n_states"], lin["n_inputs"])
    C = np.array(lin["C"], float).reshape(lin["n_outputs"], lin["n_states"])
    D = np.array(lin["D"], float).reshape(lin["n_outputs"], lin["n_inputs"])
    iu = lin["inputs"].index(input_name)
    iy = lin["outputs"].index(output_name)
    b, c, d = B[:, iu], C[iy, :], D[iy, iu]

    poles = np.linalg.eigvals(A) if A.size else np.array([])
    mags = np.abs(poles[np.abs(poles) > 1e-9])
    lo = max(mags.min() / 100, 1e-4) if mags.size else 1e-2
    hi = mags.max() * 100 if mags.size else 1e3
    w = np.logspace(np.log10(lo), np.log10(hi), n_points)
    I = np.eye(A.shape[0])
    G = np.array([c @ np.linalg.solve(1j * wi * I - A, b) + d for wi in w]) if A.size \
        else np.full(w.shape, d, dtype=complex)
    mag_db = 20 * np.log10(np.maximum(np.abs(G), 1e-300))
    phase = np.degrees(np.unwrap(np.angle(G)))

    res: dict[str, Any] = {
        "poles": [[float(p.real), float(p.imag)] for p in poles],
        "stable": bool(np.all(poles.real < 0)) if poles.size else True,
        "dc_gain_db": float(mag_db[0]),
        "w_range_rad_s": [float(w[0]), float(w[-1])],
    }
    gc = _crossings(w, mag_db, 0.0)
    if gc:
        i, wc = gc[0]
        res["gain_crossover_rad_s"] = wc
        res["phase_margin_deg"] = float(180.0 + np.interp(np.log(wc), np.log(w), phase))
    else:
        res["gain_crossover_rad_s"] = None
        res["phase_margin_deg"] = None       # |L| never crosses 0 dB in range
    pcs = []
    for k in range(-5, 5):
        pcs += _crossings(w, phase, -180.0 + 360.0 * k)
    if pcs:
        i, wp = min(pcs, key=lambda z: z[1])
        res["phase_crossover_rad_s"] = wp
        res["gain_margin_db"] = float(-np.interp(np.log(wp), np.log(w), mag_db))
    else:
        res["phase_crossover_rad_s"] = None
        res["gain_margin_db"] = None         # infinite within range
    bw = _crossings(w, mag_db, mag_db[0] - 3.0)
    res["bandwidth_rad_s"] = bw[0][1] if bw else None

    if bode_path is not None:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
        a1.semilogx(w, mag_db); a1.axhline(0, ls="--", c="k", lw=0.8)
        a1.set_ylabel("|G| [dB]"); a1.grid(True, which="both", alpha=0.3)
        a2.semilogx(w, phase); a2.axhline(-180, ls="--", c="k", lw=0.8)
        a2.set_ylabel("phase [deg]"); a2.set_xlabel("ω [rad/s]")
        a2.grid(True, which="both", alpha=0.3)
        fig.suptitle(f"Bode: {input_name} → {output_name}")
        fig.tight_layout()
        bode_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(bode_path.with_suffix(".png"), dpi=130)
        plt.close(fig)
        res["bode_png"] = str(bode_path.with_suffix(".png"))
    return res


def save_json(obj: dict, path: Path) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=1))
    return str(path)
