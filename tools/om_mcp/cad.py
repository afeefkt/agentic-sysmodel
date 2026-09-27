"""Deterministic CAD -> Modelica helpers (no LLM arithmetic).

- body_parameters: mass properties from CAD/mass_properties.json (CAD frame,
  SI) -> BodyShape/Body parameters in the Modelica body frame (frame_a at the
  pivot), with an explicit axis remap validated as a proper rotation.
- import_shape: binary or ASCII STL (CAD frame, usually mm) -> ASCII STL in the
  Modelica frame and metres under <Package>/Resources/Shapes, referenced by a
  modelica:// URI for OMEdit's 3D animation (which needs ASCII STL).

Modelica MultiBody does not derive inertia from geometry: the shape file is
visual only; mass properties are parameters computed in CAD (FreeCAD).
"""

from __future__ import annotations

import json
import re
import struct
from pathlib import Path
from typing import Optional

import numpy as np

_AXES = {"x": 0, "y": 1, "z": 2}


# ---------------------------------------------------------------- rotation --
def rotation_from_axes_map(axes_map: dict[str, str]) -> np.ndarray:
    """{"x": "-y", "y": "x", "z": "z"} means: CAD x-axis points along model -y,
    CAD y along model +x, CAD z along model +z. Returns R with v_model = R v_cad."""
    R = np.zeros((3, 3))
    for cad_ax, model_ax in axes_map.items():
        m = re.fullmatch(r"\s*([+-]?)\s*([xyz])\s*", str(model_ax).lower())
        if cad_ax.lower() not in _AXES or not m:
            raise ValueError(f"bad axes_map entry {cad_ax!r}: {model_ax!r} "
                             "(use e.g. {'x': '-y', 'y': 'x', 'z': 'z'})")
        sign = -1.0 if m.group(1) == "-" else 1.0
        R[_AXES[m.group(2)], _AXES[cad_ax.lower()]] = sign
    if not np.allclose(R @ R.T, np.eye(3)) or not np.isclose(np.linalg.det(R), 1.0):
        raise ValueError(f"axes_map {axes_map} is not a proper rotation "
                         "(each model axis exactly once, right-handed, det=+1)")
    return R


# --------------------------------------------------------- mass properties --
def body_parameters(props: dict, body: str, pivot_joint: str,
                    axes_map: dict[str, str],
                    next_joint: Optional[str] = None) -> dict:
    R = rotation_from_axes_map(axes_map)
    b = props["bodies"][body]
    pivot = np.array(props["joints"][pivot_joint]["point"], float)
    com = np.array(b["com"], float)
    I = R @ np.array(b["inertia_com"], float) @ R.T
    I = 0.5 * (I + I.T)                                   # clean round-off asymmetry
    I[np.abs(I) < 1e-15] = 0.0
    r_cm = R @ (com - pivot)
    out = {
        "body": body, "frame_a_at": pivot_joint, "axes_map": axes_map,
        "rotation_matrix": R.astype(int).tolist(),
        "m": float(b["mass"]),
        "r_CM": [round(float(v), 9) for v in r_cm],
        "I_11": float(I[0, 0]), "I_22": float(I[1, 1]), "I_33": float(I[2, 2]),
        "I_21": float(I[1, 0]), "I_31": float(I[2, 0]), "I_32": float(I[2, 1]),
        "inertia_about_pivot_axis_z": float(I[2, 2] + b["mass"] * (r_cm[0] ** 2 + r_cm[1] ** 2)),
    }
    if next_joint:
        nxt = np.array(props["joints"][next_joint]["point"], float)
        out["r"] = [round(float(v), 9) for v in R @ (nxt - pivot)]
    p = out
    args = [f"m = {p['m']:.7g}", "r_CM = {%s}" % ", ".join(f"{v:.7g}" for v in p["r_CM"])]
    if "r" in p:
        args.insert(0, "r = {%s}" % ", ".join(f"{v:.7g}" for v in p["r"]))
    args += [f"{k} = {p[k]:.7g}" for k in ("I_11", "I_22", "I_33", "I_21", "I_31", "I_32")]
    out["modelica_modifier"] = "(" + ", ".join(args) + ")"
    return out


def body_parameters_from_file(path: Path, **kw) -> dict:
    return body_parameters(json.loads(path.read_text()), **kw)


# --------------------------------------------------------------------- STL --
def read_stl(path: Path) -> np.ndarray:
    """Return triangles as array (n, 3, 3). Handles binary and ASCII STL."""
    data = path.read_bytes()
    if len(data) >= 84:
        n = struct.unpack_from("<I", data, 80)[0]
        if 84 + 50 * n == len(data):                       # binary layout matches
            tri = np.empty((n, 3, 3))
            for i in range(n):
                vals = struct.unpack_from("<12f", data, 84 + 50 * i)
                tri[i] = np.array(vals[3:12]).reshape(3, 3)
            return tri
    text = data.decode("ascii", "replace")
    verts = [list(map(float, m.groups())) for m in
             re.finditer(r"vertex\s+(\S+)\s+(\S+)\s+(\S+)", text)]
    if not verts or len(verts) % 3:
        raise ValueError(f"{path}: not a readable STL (binary or ASCII)")
    return np.array(verts, float).reshape(-1, 3, 3)


def write_ascii_stl(tri: np.ndarray, path: Path, name: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"solid {name}"]
    for t in tri:
        nrm = np.cross(t[1] - t[0], t[2] - t[0])
        ln = np.linalg.norm(nrm)
        nrm = nrm / ln if ln > 0 else nrm
        lines.append(f"  facet normal {nrm[0]:.6e} {nrm[1]:.6e} {nrm[2]:.6e}")
        lines.append("    outer loop")
        for v in t:
            lines.append(f"      vertex {v[0]:.6e} {v[1]:.6e} {v[2]:.6e}")
        lines.append("    endloop")
        lines.append("  endfacet")
    lines.append(f"endsolid {name}")
    path.write_text("\n".join(lines) + "\n", encoding="ascii")


def import_shape(stl_path: Path, package_dir: Path, body: str,
                 pivot: list[float], axes_map: dict[str, str],
                 scale: float = 1e-3) -> dict:
    """pivot is in the STL's own units (usually mm, CAD frame)."""
    R = rotation_from_axes_map(axes_map)
    tri = read_stl(stl_path)
    pts = (tri.reshape(-1, 3) - np.asarray(pivot, float)) @ R.T * scale
    tri_m = pts.reshape(-1, 3, 3)
    pkg = package_dir.name
    out_rel = Path("Resources") / "Shapes" / f"{body}.stl"
    write_ascii_stl(tri_m, package_dir / out_rel, body)
    uri = f"modelica://{pkg}/{out_rel.as_posix()}"
    lo, hi = pts.min(axis=0), pts.max(axis=0)
    snippet = (
        f"Modelica.Mechanics.MultiBody.Visualizers.FixedShape {body[0].lower() + body[1:]}Shape(\n"
        f"  shapeType = \"{uri}\",\n"
        f"  r_shape = {{0, 0, 0}}, lengthDirection = {{1, 0, 0}}, widthDirection = {{0, 1, 0}},\n"
        f"  length = 1, width = 1, height = 1,\n"
        f"  color = {{180, 180, 190}})  // connect frame_a to the body's frame_a (pivot)")
    return {"uri": uri, "file": str(package_dir / out_rel), "triangles": int(len(tri_m)),
            "bbox_min_m": [round(float(v), 6) for v in lo],
            "bbox_max_m": [round(float(v), 6) for v in hi],
            "fixed_shape_declaration": snippet,
            "note": "Visual only. Mass properties come from cad_body_parameters. "
                    "Set animation=false on the BodyShape to hide its default cylinder."}
