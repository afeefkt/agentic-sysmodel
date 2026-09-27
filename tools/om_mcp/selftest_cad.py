"""Self-test for the CAD -> Modelica tools (cad_body_parameters, cad_import_shape).

Run from WSL:  cd tools/om_mcp && uv run python selftest_cad.py
"""

import json
import struct
from pathlib import Path

import numpy as np

import server

fails = 0


def check(name, cond, info=""):
    global fails
    fails += not cond
    print(f"{'PASS' if cond else 'FAIL'}  {name:<42} {info}")


work = server.BUILD_ROOT / "selftest_cad"
work.mkdir(parents=True, exist_ok=True)
REMAP = {"x": "-y", "y": "x", "z": "z"}          # CAD bar along +x -> model arm along -y

# 1) mass properties: ServoArm arm as exported by FreeCAD (CAD frame, SI)
props = {
    "bodies": {"Arm": {"mass": 0.24164283197364925,
                       "com": [0.15075821691899943, 0.015, 0.005],
                       "inertia_com": [[2.0233261594341686e-05, 0, 0],
                                       [0, 0.0017996349555665632, 0],
                                       [0, 0, 0.0018158408366280108]]}},
    "joints": {"armPivot": {"point": [0.015, 0.015, 0.005]},
               "tip": {"point": [0.300, 0.015, 0.005]}}}
pjson = work / "mass_properties.json"
pjson.write_text(json.dumps(props))
p = server.cad_body_parameters(str(pjson), "Arm", "armPivot", REMAP, next_joint="tip")
check("inertia remapped I_11 (= CAD I_yy)", abs(p["I_11"] - 1.7996349555665632e-3) < 1e-9, p["I_11"])
check("inertia remapped I_22 (= CAD I_xx)", abs(p["I_22"] - 2.0233261594341686e-5) < 1e-9, p["I_22"])
check("I_33 unchanged", abs(p["I_33"] - 1.8158408366280108e-3) < 1e-9, p["I_33"])
check("r_CM = {0, -0.13576, 0}", np.allclose(p["r_CM"], [0, -0.13575821691899943, 0], atol=1e-8), p["r_CM"])
check("r to tip = {0, -0.285, 0}", np.allclose(p["r"], [0, -0.285, 0], atol=1e-9), p["r"])
try:
    server.cad_body_parameters(str(pjson), "Arm", "armPivot", {"x": "y", "y": "y", "z": "z"})
    check("rejects improper axes_map", False)
except ValueError:
    check("rejects improper axes_map", True)

# 2) geometry: binary STL box 100 x 50 x 20 mm, corner at origin
def box_triangles(L, W, H):
    v = np.array([[x, y, z] for x in (0, L) for y in (0, W) for z in (0, H)], float)
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return [(v[a], v[b], v[c]) for a, b, c, d in faces] + \
           [(v[a], v[c], v[d]) for a, b, c, d in faces]


tris = box_triangles(100, 50, 20)
stl = work / "Box_binary.stl"
with open(stl, "wb") as f:
    f.write(b"binary test box".ljust(80, b"\0"))
    f.write(struct.pack("<I", len(tris)))
    for t in tris:
        f.write(struct.pack("<12fH", 0, 0, 0, *t[0], *t[1], *t[2], 0))

pkg = work / "CadTest"
pkg.mkdir(exist_ok=True)
res = server.cad_import_shape(str(stl), str(pkg), "Box", [0, 25, 10], REMAP)
out = server.PROJECT_ROOT / res["file"]
check("output is ASCII STL", out.read_text().startswith("solid Box"), res["file"])
check("URI", res["uri"] == "modelica://CadTest/Resources/Shapes/Box.stl", res["uri"])
check("bbox rotated + scaled to metres",
      np.allclose(res["bbox_min_m"], [-0.025, -0.1, -0.01]) and
      np.allclose(res["bbox_max_m"], [0.025, 0.0, 0.01]),
      f"{res['bbox_min_m']} .. {res['bbox_max_m']}")

# 3) the generated FixedShape compiles and simulates in a MultiBody model
(pkg / "package.mo").write_text(f"""package CadTest
  model M
    inner Modelica.Mechanics.MultiBody.World world
      annotation(Placement(transformation(extent = {{{{-60, -10}}, {{-40, 10}}}})));
    Modelica.Mechanics.MultiBody.Joints.Revolute rev(n = {{0, 0, 1}}, phi(start = 0.3, fixed = true))
      annotation(Placement(transformation(extent = {{{{-20, -10}}, {{0, 10}}}})));
    Modelica.Mechanics.MultiBody.Parts.BodyShape body(r = {{0, -0.1, 0}}, r_CM = {{0, -0.05, 0}}, m = 0.27, animation = false)
      annotation(Placement(transformation(extent = {{{{20, -10}}, {{40, 10}}}})));
    {res["fixed_shape_declaration"].split("  //")[0]}
      annotation(Placement(transformation(extent = {{{{20, 20}}, {{40, 40}}}})));
  equation
    connect(world.frame_b, rev.frame_a) annotation(Line(points = {{{{-40, 0}}, {{-20, 0}}}}));
    connect(rev.frame_b, body.frame_a) annotation(Line(points = {{{{0, 0}}, {{20, 0}}}}));
    connect(rev.frame_b, boxShape.frame_a) annotation(Line(points = {{{{0, 0}}, {{10, 0}}, {{10, 30}}, {{20, 30}}}}));
  end M;
end CadTest;
""")
chk = server.check(str(pkg / "package.mo"), "CadTest.M")
check("model with FixedShape: check", chk["ok"], chk.get("diagnostics", "")[:120])
sim = server.simulate(str(pkg / "package.mo"), "CadTest.M", stop_time=1.0, tag="cad")
check("model with FixedShape: simulate", sim["ok"], sim.get("diagnostics", "")[:120])

print("\nALL PASS" if fails == 0 else f"\n{fails} FAILED")
raise SystemExit(1 if fails else 0)
