"""OpenModelica MCP server for agentic-sysmodel.

Exposes compile / simulate / read / verify / describe tools to opencode agents.
Built on omagent (BSD-3-Clause, https://github.com/MasoudMiM/omagent) for the
omc session wrapper, diagnostics parsing, result loading and verifiers.

Paths passed by agents may be relative to the project root (agentic-sysmodel/).
"""

from __future__ import annotations

import html
import os
import re
from pathlib import Path
from typing import Any, Optional

from mcp.server.mcpserver import MCPServer
from omagent import (OMSession, expect_bounds, expect_final, expect_value_at,
                     load_result, summarize_for_llm)

import analysis
import library
import cad

PROJECT_ROOT = Path(os.environ.get(
    "SYSMODEL_ROOT", Path(__file__).resolve().parents[2])).resolve()
BUILD_ROOT = PROJECT_ROOT / ".om_build"

mcp = MCPServer("openmodelica")
_session: Optional[OMSession] = None


def _om() -> OMSession:
    """One long-lived omc session; MSL is loaded once (it takes seconds)."""
    global _session
    if _session is None:
        _session = OMSession()
        msl = _session.load_msl()
        if not msl.success:
            raise RuntimeError("could not load Modelica Standard Library: "
                               + summarize_for_llm(msl.diagnostics))
    return _session


def _abs(path: str) -> Path:
    p = Path(path)
    return (p if p.is_absolute() else PROJECT_ROOT / p).resolve()


def _load(file: str) -> tuple[bool, str]:
    path = _abs(file)
    if not path.exists():
        return False, f"file not found: {path}"
    res = _om().load_file(path.as_posix())
    return res.success, summarize_for_llm(res.diagnostics)


def _cd(dir_: Path) -> None:
    dir_.mkdir(parents=True, exist_ok=True)
    _om()._send(f'cd("{dir_.as_posix()}")')


@mcp.tool()
def check(file: str, model: str) -> dict:
    """Load a .mo file (or package.mo) and run checkModel on `model`
    (fully qualified, e.g. 'LandingGear.Kinematics'). Returns ok, the
    equation/variable count summary and compact diagnostics."""
    ok, diag = _load(file)
    if not ok:
        return {"ok": False, "stage": "load", "diagnostics": diag}
    res = _om().check_model(model)
    return {"ok": res.success, "stage": "check",
            "summary": str(res.value)[:1500],
            "diagnostics": summarize_for_llm(res.diagnostics)}


@mcp.tool()
def simulate(file: str, model: str, stop_time: float = 1.0,
             number_of_intervals: int = 500, tolerance: float = 1e-6,
             overrides: Optional[dict[str, float]] = None,
             tag: str = "run") -> dict:
    """Compile and simulate `model`. `overrides` sets parameter values at
    run time (e.g. {"actuator.boreDiameter": 0.05}) without editing the .mo.
    `tag` names the run (e.g. 'nominal', 'cold_fluid') so parallel cases keep
    separate result files. Returns ok, result_file (absolute) and diagnostics."""
    ok, diag = _load(file)
    if not ok:
        return {"ok": False, "stage": "load", "diagnostics": diag}
    safe_tag = re.sub(r"[^A-Za-z0-9_]+", "_", tag)
    _cd(BUILD_ROOT / model.replace(".", "_") / safe_tag)
    opts: dict[str, Any] = dict(stopTime=stop_time,
                                numberOfIntervals=number_of_intervals,
                                tolerance=tolerance)
    if overrides:
        opts["simflags"] = "-override=" + ",".join(
            f"{k}={v}" for k, v in overrides.items())
    res = _om().simulate(model, **opts)
    result_file = ""
    messages = ""
    if isinstance(res.value, dict):
        result_file = str(res.value.get("resultFile", ""))
        messages = str(res.value.get("messages", ""))[-1500:]
    return {"ok": res.success, "stage": "simulate", "result_file": result_file,
            "overrides": overrides or {}, "messages": messages,
            "diagnostics": summarize_for_llm(res.diagnostics)}


@mcp.tool()
def list_variables(result_file: str, contains: str = "", limit: int = 200) -> dict:
    """List variable names in a result file, optionally filtered by substring."""
    names = [n for n in load_result(str(_abs(result_file))).names()
             if contains.lower() in n.lower()]
    return {"count": len(names), "names": names[:limit]}


@mcp.tool()
def read_results(result_file: str, variables: list[str],
                 at_times: Optional[list[float]] = None) -> dict:
    """Summarize trajectories: min, max, final, time of min/max, and optional
    interpolated values at given times. Use this instead of reading raw files."""
    r = load_result(str(_abs(result_file)))
    out: dict[str, Any] = {}
    for var in variables:
        try:
            times, vals = r.series(var)
        except KeyError as exc:
            out[var] = {"error": str(exc)[:300]}
            continue
        i_min = min(range(len(vals)), key=vals.__getitem__)
        i_max = max(range(len(vals)), key=vals.__getitem__)
        entry = {"min": vals[i_min], "t_min": times[i_min],
                 "max": vals[i_max], "t_max": times[i_max],
                 "final": vals[-1], "t_final": times[-1]}
        if at_times:
            entry["at"] = {str(t): r.at(var, t) for t in at_times}
        out[var] = entry
    return out


@mcp.tool()
def time_to_reach(result_file: str, variable: str, threshold: float,
                  direction: str = "rising") -> dict:
    """First time `variable` crosses `threshold` ('rising' or 'falling').
    Typical use: retraction time = time for gear angle to reach its up-lock."""
    times, vals = load_result(str(_abs(result_file))).series(variable)
    for t0, t1, v0, v1 in zip(times, times[1:], vals, vals[1:]):
        crossed = (v0 < threshold <= v1) if direction == "rising" else \
                  (v0 > threshold >= v1)
        if crossed:
            t = t0 if v1 == v0 else t0 + (threshold - v0) * (t1 - t0) / (v1 - v0)
            return {"reached": True, "time": t}
    return {"reached": False, "final_value": vals[-1], "t_final": times[-1]}


@mcp.tool()
def verify(result_file: str, checks: list[dict]) -> dict:
    """Evaluate requirement checks against one result file. Each check:
    {"req_id": "REQ-02", "type": "bounds", "var": "p_A", "lo": 0, "hi": 21e6, "after": 0}
    {"req_id": "REQ-01", "type": "final",  "var": "phi", "expected": 1.57, "rtol": 0.01}
    {"req_id": "REQ-03", "type": "value_at", "var": "x", "t": 2.0, "expected": 0.22, "atol": 1e-3}
    Returns PASS/FAIL per req_id with the evidence string."""
    sim_like = type("Sim", (), {"value": {"resultFile": str(_abs(result_file))}})()
    results = []
    for c in checks:
        kind = c.get("type")
        if kind == "bounds":
            v = expect_bounds(c["var"], lo=c.get("lo", float("-inf")),
                              hi=c.get("hi", float("inf")),
                              after=c.get("after", float("-inf")))
        elif kind == "final":
            v = expect_final(c["var"], c["expected"], atol=c.get("atol", 1e-6),
                             rtol=c.get("rtol", 1e-3))
        elif kind == "value_at":
            v = expect_value_at(c["var"], t=c["t"], expected=c["expected"],
                                atol=c.get("atol", 1e-6), rtol=c.get("rtol", 1e-3))
        else:
            results.append({"req_id": c.get("req_id"), "status": "ERROR",
                            "evidence": f"unknown check type {kind!r}"})
            continue
        complaint = v(sim_like)
        results.append({"req_id": c.get("req_id"),
                        "status": "PASS" if complaint is None else "FAIL",
                        "evidence": complaint or f"{kind} check on {c['var']} satisfied"})
    return {"all_pass": all(r["status"] == "PASS" for r in results),
            "results": results}


def _strip_html(s: str, limit: int) -> str:
    text = html.unescape(re.sub(r"<[^>]+>", " ", s))
    return re.sub(r"\s+", " ", text).strip()[:limit]


@mcp.tool()
def describe_class(name: str, doc_chars: int = 1500) -> dict:
    """Look up a Modelica class (e.g. 'Modelica.Mechanics.MultiBody.Joints.Revolute'):
    comment, parameters, components/connectors and a documentation excerpt.
    Use this BEFORE instantiating any MSL component to avoid invented names."""
    om = _om()
    out: dict[str, Any] = {"name": name}
    for key, expr in [("comment", f"getClassComment({name})"),
                      ("restriction", f"getClassRestriction({name})"),
                      ("parameters", f"getParameterNames({name})"),
                      ("components", f"getComponents({name})"),
                      ("children", f"getClassNames({name})")]:
        val, _ = om._safe_send(expr)
        om._drain_diagnostics()
        if key == "components" and isinstance(val, (list, tuple)):
            # (type, name, comment, ...) tuples -> compact strings
            val = [f"{c[0]} {c[1]}  // {c[2]}" for c in val
                   if isinstance(c, (list, tuple)) and len(c) >= 3][:80]
        out[key] = val
    val, _ = om._safe_send(f"getDocumentationAnnotation({name})")
    om._drain_diagnostics()
    if isinstance(val, (list, tuple)) and val:
        out["documentation"] = _strip_html(str(val[0]), doc_chars)
    out["inherited_parameters"] = _inherited_parameters(name)
    return out


def _inherited_parameters(name: str, depth: int = 0) -> dict[str, list]:
    """Parameters declared in base classes (e.g. the phase count `m` of a
    machine), grouped by the base class that declares them."""
    if depth > 5:
        return {}
    om = _om()
    bases, _ = om._safe_send(f"getInheritedClasses({name})")
    om._drain_diagnostics()
    found: dict[str, list] = {}
    for b in bases or []:
        b = str(b)
        params, _ = om._safe_send(f"getParameterNames({b})")
        om._drain_diagnostics()
        if params:
            found[b] = list(params)
        found.update(_inherited_parameters(b, depth + 1))
    return found


# ------------------------------------------------------ library discovery --
_index_cache: Optional[list] = None


def _index() -> list:
    global _index_cache
    if _index_cache is None:
        _index_cache = library.build_index(_om(), "Modelica",
                                           BUILD_ROOT / "msl_index.json")
    return _index_cache


@mcp.tool()
def search_library(query: str, limit: int = 25, include_partial: bool = False) -> dict:
    """Find Modelica Standard Library classes by words in their name AND
    description, e.g. "permanent magnet synchronous machine", "hydraulic
    cylinder", "PID anti windup", "prismatic joint". ALWAYS search before
    writing a custom component. First call builds an index (~1 min)."""
    return {"results": library.search(_index(), query, limit, include_partial)}


@mcp.tool()
def list_examples(package: str, limit: int = 60) -> dict:
    """List ready-made example models under an MSL package (e.g.
    'Modelica.Electrical.Machines', 'Modelica.Mechanics.MultiBody').
    Open the closest one with get_class_source and copy its structure."""
    return {"examples": library.examples(_index(), package, limit)}


@mcp.tool()
def get_class_source(name: str, max_chars: int = 12000) -> dict:
    """Modelica source of a library class INCLUDING its Placement/Line
    annotations. Use it to copy the component structure and diagram layout
    of an MSL example into your own model."""
    om = _om()
    try:
        # raw Modelica string literal; OMPython's parser over-unescapes
        # nested quotes (e.g. inside Documentation HTML)
        raw = str(om._omc.sendExpression(f"list({name})", parsed=False) or "")
    except Exception as exc:  # pragma: no cover
        return {"name": name, "error": str(exc)[:500]}
    om._drain_diagnostics()
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"'):
        raw = raw[1:-1]
    src = re.sub(r'\\(["\\])', r"\1", raw)
    return {"name": name, "truncated": len(src) > max_chars,
            "source": src[:max_chars]}


@mcp.tool()
def diagram_check(file: str, model: str) -> dict:
    """Quality gate for a component-based model: every component has a
    Placement (visible in the OMEdit diagram), wiring uses connect(), and MSL
    components are preferred over custom ones. Must return ok=true before a
    model is considered done."""
    ok, diag = _load(file)
    if not ok:
        return {"ok": False, "stage": "load", "diagnostics": diag}
    return library.diagram_report(_om(), model, set())


# ------------------------------------------------ measurement / plot / export --
def _results(result_files: dict[str, str]) -> dict[str, Any]:
    return {tag: load_result(str(_abs(p))) for tag, p in result_files.items()}


@mcp.tool()
def measure(result_file: str, variable: str, metrics: Optional[list[str]] = None,
            t_start: Optional[float] = None, t_end: Optional[float] = None,
            setpoint: Optional[float] = None, band: float = 0.02) -> dict:
    """Exact metrics on one variable. metrics from: min, max, mean, rms, final,
    integral, max_rate, rise_time (10-90 %), overshoot_pct, settling_time
    (within `band` of the step size), steady_state_error (needs setpoint),
    peak_time. Step metrics use the value at t_start as the initial value and
    `setpoint` (or the final value) as the reference; times are relative to
    t_start. Omit metrics for all of them."""
    times, vals = load_result(str(_abs(result_file))).series(variable)
    return analysis.signal_metrics(times, vals, metrics, t_start, t_end,
                                   setpoint, band)


@mcp.tool()
def compare_cases(result_files: dict[str, str], variables: list[str],
                  metrics: Optional[list[str]] = None,
                  t_start: Optional[float] = None, t_end: Optional[float] = None,
                  setpoint: Optional[float] = None) -> dict:
    """Same metrics for several cases, e.g. result_files={"nominal": "...mat",
    "cold_fluid": "...mat"}. Returns a nested dict and a ready markdown table."""
    metrics = metrics or ["min", "max", "final"]
    cases = _results(result_files)
    table = {var: {tag: analysis.signal_metrics(*res.series(var), metrics,
                                                t_start, t_end, setpoint)
                   for tag, res in cases.items()}
             for var in variables}
    return {"table": table, "markdown": analysis.markdown_table(table, metrics)}


@mcp.tool()
def export_data(result_files: dict[str, str], variables: list[str], out_path: str,
                format: str = "csv", resample_dt: Optional[float] = None) -> dict:
    """Export trajectories to CSV (one file per case) or Excel (.xlsx: one
    sheet per case + 'summary' sheet). out_path is relative to the repo, e.g.
    'Example/<Project>/Results/data/retraction'. resample_dt gives a uniform
    time grid (recommended for Excel)."""
    written = analysis.export_cases(_results(result_files), variables,
                                    _abs(out_path), format, resample_dt)
    return {"files": [str(Path(w).relative_to(PROJECT_ROOT)) for w in written]}


@mcp.tool()
def plot(result_files: dict[str, str], variables: list[str], out_path: str,
         title: str = "", x: str = "time", subplots: bool = True,
         reference_lines: Optional[list[dict]] = None) -> dict:
    """Plot variables to a PNG (for humans/reports; you cannot see it).
    Cases are overlaid; one subplot per variable. reference_lines:
    [{"y": 21e6, "label": "REQ-02 limit", "var": "actuator.p_A"}] ('var'
    optional = all subplots). out_path relative to repo, e.g.
    'Example/<Project>/Results/plots/pressure'."""
    png = analysis.plot_cases(_results(result_files), variables, _abs(out_path),
                              title, x, subplots, reference_lines)
    return {"png": str(Path(png).relative_to(PROJECT_ROOT))}


# ------------------------------------------------------------ control tools --
@mcp.tool()
def linearize(file: str, model: str, t_lin: float = 0.0,
              overrides: Optional[dict[str, float]] = None,
              tag: str = "lin") -> dict:
    """Linearize `model` at time t_lin (simulates up to t_lin first). The model
    must declare top-level `input` and `output` variables; they become u and y.
    Returns state/input/output names, poles, and A,B,C,D (matrices only if
    n_states <= 12), plus `lin_file` to pass to frequency_analysis."""
    ok, diag = _load(file)
    if not ok:
        return {"ok": False, "stage": "load", "diagnostics": diag}
    safe_tag = re.sub(r"[^A-Za-z0-9_]+", "_", tag)
    work = BUILD_ROOT / model.replace(".", "_") / f"linearize_{safe_tag}"
    _cd(work)
    lin_mo = work / "linearized_model.mo"
    if lin_mo.exists():
        lin_mo.unlink()
    simflags = ""
    if overrides:
        simflags = ', simflags="-override=' + ",".join(
            f"{k}={v}" for k, v in overrides.items()) + '"'
    om = _om()
    val, exc = om._safe_send(f"linearize({model}, stopTime={t_lin}{simflags})")
    diags = exc + om._drain_diagnostics()
    if not lin_mo.exists():
        msg = str(val.get("messages", ""))[-1500:] if isinstance(val, dict) else str(val)[:1500]
        return {"ok": False, "stage": "linearize", "messages": msg,
                "diagnostics": summarize_for_llm(diags)}
    lin = analysis.parse_linearized_model(lin_mo)
    lin["model"], lin["t_lin"], lin["overrides"] = model, t_lin, overrides or {}
    lin_file = analysis.save_json(lin, work / "linearization.json")
    import numpy as np
    A = np.array(lin["A"], float).reshape(lin["n_states"], lin["n_states"])
    poles = np.linalg.eigvals(A) if A.size else []
    out = {k: lin[k] for k in ("n_states", "n_inputs", "n_outputs",
                               "states", "inputs", "outputs")}
    out.update(ok=True, lin_file=str(Path(lin_file).relative_to(PROJECT_ROOT)),
               poles=[[float(p.real), float(p.imag)] for p in poles])
    if lin["n_states"] <= 12:
        out.update({k: lin[k] for k in "ABCD"})
    return out


@mcp.tool()
def frequency_analysis(lin_file: str, input: str, output: str,
                       bode_out_path: Optional[str] = None) -> dict:
    """From a linearize() result: poles, stability, DC gain, gain/phase
    crossover, gain margin, phase margin, bandwidth for input -> output.
    Margins are only meaningful if that path is the OPEN-LOOP loop gain
    (loop cut: input = controller error or actuator command, output = the
    fed-back measurement, sign convention: negative feedback)."""
    import json
    lin = json.loads(_abs(lin_file).read_text())
    res = analysis.frequency_analysis(
        lin, input, output,
        bode_path=_abs(bode_out_path) if bode_out_path else None)
    if "bode_png" in res:
        res["bode_png"] = str(Path(res["bode_png"]).relative_to(PROJECT_ROOT))
    return res


# --------------------------------------------------------- CAD -> Modelica --
@mcp.tool()
def cad_body_parameters(mass_properties_json: str, body: str, pivot_joint: str,
                        axes_map: dict[str, str],
                        next_joint: Optional[str] = None) -> dict:
    """Exact BodyShape/Body parameters from CAD/mass_properties.json, expressed
    in the Modelica body frame (frame_a at `pivot_joint`). axes_map says where
    each CAD axis points in the model, e.g. {"x": "-y", "y": "x", "z": "z"}
    (CAD bar along +x, model arm hanging along -y, pivot axis z). Returns m,
    r_CM, I_11..I_32 (rotated), r (to next_joint) and a ready modifier string.
    ALWAYS use this instead of converting CAD numbers by hand."""
    return cad.body_parameters_from_file(
        _abs(mass_properties_json), body=body, pivot_joint=pivot_joint,
        axes_map=axes_map, next_joint=next_joint)


@mcp.tool()
def cad_import_shape(stl_path: str, package_dir: str, body: str,
                     pivot: list[float], axes_map: dict[str, str],
                     scale: float = 0.001) -> dict:
    """Bring a CAD STL (binary or ASCII, CAD frame, usually mm) into the model
    for OMEdit 3D animation: shifts by -pivot (same units as the STL), rotates
    with axes_map (same as cad_body_parameters), scales to metres and writes
    an ASCII STL to <package_dir>/Resources/Shapes/<body>.stl. Returns the
    modelica:// URI and a FixedShape declaration to connect to the body's
    frame_a. Geometry is visual only; physics uses cad_body_parameters."""
    res = cad.import_shape(_abs(stl_path), _abs(package_dir), body, pivot,
                           axes_map, scale)
    res["file"] = str(Path(res["file"]).relative_to(PROJECT_ROOT))
    return res


if __name__ == "__main__":
    mcp.run()
