"""Smoke test for the OpenModelica MCP tools without an LLM.

Run from WSL:  cd tools/om_mcp && uv run python selftest.py
Writes a tiny pendulum model, checks, simulates, reads and verifies it.
"""

import math
import tempfile
from pathlib import Path

import server

MODEL = """
model SelfTestPendulum
  parameter Real L = 1.0 "length [m]";
  parameter Real g = 9.81;
  Real phi(start = 0.1, fixed = true) "angle [rad]";
  Real w(start = 0, fixed = true);
equation
  der(phi) = w;
  der(w) = -g / L * sin(phi);
end SelfTestPendulum;
"""

mo = Path(tempfile.gettempdir()) / "SelfTestPendulum.mo"
mo.write_text(MODEL)

fails = 0


def check(name, cond, info=""):
    global fails
    fails += not cond
    print(f"{'PASS' if cond else 'FAIL'}  {name:<34} {info}")


check("check model", server.check(str(mo), "SelfTestPendulum")["ok"])
sim = server.simulate(str(mo), "SelfTestPendulum", stop_time=4.0,
                      overrides={"L": 2.0}, tag="selftest")
check("simulate with override", sim["ok"], sim["result_file"])
phi = server.read_results(sim["result_file"], ["phi"])["phi"]
half_period = math.pi * math.sqrt(2.0 / 9.81)       # L overridden to 2 m
check("override took effect (t_min=T/2)", abs(phi["t_min"] - half_period) < 0.02,
      f"t_min={phi['t_min']:.3f} expected={half_period:.3f}")
ver = server.verify(sim["result_file"], [
    {"req_id": "T-01", "type": "bounds", "var": "phi", "lo": -0.11, "hi": 0.11}])
check("verify bounds", ver["all_pass"])
params = server.describe_class("Modelica.Mechanics.MultiBody.Joints.Revolute")["parameters"]
check("describe_class", "useAxisFlange" in (params or ()), params)

print("\nALL PASS" if fails == 0 else f"\n{fails} FAILED")
raise SystemExit(1 if fails else 0)
