"""Self-test for search_library / list_examples / get_class_source /
diagram_check / describe_class inherited parameters.

Run from WSL:  cd tools/om_mcp && uv run python selftest_library.py
(first run builds the MSL index, ~1-2 min, cached in .om_build/msl_index.json)
"""

import time
from pathlib import Path

import server

fails = 0


def check(name, cond, info=""):
    global fails
    fails += not cond
    print(f"{'PASS' if cond else 'FAIL'}  {name}  {info}")


t = time.time()
res = server.search_library("permanent magnet synchronous machine", limit=10)["results"]
print(f"(index + search took {time.time() - t:.1f}s)")
names = [r["name"] for r in res]
check("search finds SM_PermanentMagnet", any(n.endswith("SM_PermanentMagnet") for n in names),
      names[:5])
res = server.search_library("prismatic joint")["results"]
check("search finds Prismatic joint",
      any(r["name"] == "Modelica.Mechanics.MultiBody.Joints.Prismatic" for r in res),
      [r["name"] for r in res[:3]])
res = server.search_library("limited PID anti windup")["results"]
check("search finds LimPID", any(r["name"].endswith("Continuous.LimPID") for r in res),
      [r["name"] for r in res[:3]])

ex = server.list_examples("Modelica.Electrical.Machines.Examples.SynchronousMachines")["examples"]
check("list_examples machines", len(ex) > 3, [e["name"].rsplit(".", 1)[-1] for e in ex[:6]])

src = server.get_class_source("Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum")
check("get_class_source has Placement", "Placement(" in src["source"])

desc = server.describe_class(
    "Modelica.Magnetic.FundamentalWave.BasicMachines.SynchronousMachines.SM_PermanentMagnet")
inh = [p for ps in desc["inherited_parameters"].values() for p in ps]
check("describe_class shows inherited m", "m" in inh, list(desc["inherited_parameters"])[:3])

# Fixture: MSL components wired with connect() but without Placement annotations
# (the failure mode seen in agent-generated models: simulates, invisible in OMEdit)
unplaced = Path(server.BUILD_ROOT / "UnplacedPendulum.mo")
unplaced.parent.mkdir(parents=True, exist_ok=True)
unplaced.write_text("""
model UnplacedPendulum
  inner Modelica.Mechanics.MultiBody.World world;
  Modelica.Mechanics.MultiBody.Joints.Revolute rev(n = {0, 0, 1});
  Modelica.Mechanics.MultiBody.Parts.Body body(m = 1, r_CM = {0.5, 0, 0});
equation
  connect(world.frame_b, rev.frame_a);
  connect(rev.frame_b, body.frame_a);
end UnplacedPendulum;
""")
bad = server.diagram_check(str(unplaced), "UnplacedPendulum")
check("diagram_check flags unplaced model", not bad["ok"] and len(bad["missing_placement"]) == 3,
      f"missing={bad['missing_placement']}")

copy = Path(server.BUILD_ROOT / "PendulumCopy.mo")
copy.write_text(src["source"].replace("model Pendulum", "model PendulumCopy", 1)
                .replace("end Pendulum;", "end PendulumCopy;"))
good = server.diagram_check(str(copy), "PendulumCopy")
check("diagram_check passes MSL example", good["ok"],
      f"components={good['components']} connects={good['connect_count']} issues={good['issues']}")

print("\nALL PASS" if fails == 0 else f"\n{fails} FAILED")
raise SystemExit(1 if fails else 0)
