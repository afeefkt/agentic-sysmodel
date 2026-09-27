"""Self-test for measure / compare / export / plot / linearize / frequency tools.

Run from WSL:  cd tools/om_mcp && uv run python selftest_control.py
Every check compares a tool result with an analytic value.
"""

import math
import tempfile
from pathlib import Path

import server

TMP = Path(tempfile.gettempdir())
OUT = ".om_build/selftest_control"           # relative to repo root

# Closed loop: P controller (Kp=4) on first-order plant K/(tau s + 1), K=1, tau=0.5,
# plus an independent 2nd-order system (zeta=0.3, wn=5) for overshoot.
CLOSED = """
model CL
  parameter Real Kp = 4, K = 1, tau = 0.5, zeta = 0.3, wn = 5;
  Real r = if time >= 0.1 then 1 else 0;
  Real y(start = 0, fixed = true);
  Real z(start = 0, fixed = true);
  Real zd(start = 0, fixed = true);
equation
  tau*der(y) = K*Kp*(r - y) - y;
  der(z) = zd;
  der(zd) = wn^2*(r - z) - 2*zeta*wn*zd;
end CL;
"""
# Open loop L(s) = Kp*K/(tau s + 1) with top-level input/output for linearize.
OPEN = """
model OL
  parameter Real Kp = 4, K = 1, tau = 0.5;
  input Real e;
  output Real ym;
  Real x(start = 0, fixed = true);
equation
  tau*der(x) = K*Kp*e - x;
  ym = x;
end OL;
"""

fails = 0


def check(name, got, exp, tol):
    global fails
    ok = got is not None and abs(got - exp) <= tol
    fails += not ok
    print(f"{'PASS' if ok else 'FAIL'}  {name:<32} got={got}  expected={exp:.4g} ±{tol}")


(TMP / "CL.mo").write_text(CLOSED)
(TMP / "OL.mo").write_text(OPEN)

sim = server.simulate(str(TMP / "CL.mo"), "CL", stop_time=3.0,
                      number_of_intervals=3000, tag="nominal")
assert sim["ok"], sim
rf = sim["result_file"]
sim2 = server.simulate(str(TMP / "CL.mo"), "CL", stop_time=3.0,
                       number_of_intervals=3000, overrides={"Kp": 9}, tag="high_gain")

# First order closed loop: final 0.8, tau_cl = 0.1 s
m = server.measure(rf, "y", ["final", "rise_time", "settling_time", "steady_state_error"],
                   t_start=0.1)
check("final value", m["final"], 0.8, 1e-3)
check("rise time 10-90 %", m["rise_time"], 0.1 * math.log(9), 5e-3)
check("settling time 2 %", m["settling_time"], 0.1 * math.log(50), 5e-3)
m_sp = server.measure(rf, "y", ["steady_state_error"], t_start=0.1, setpoint=1.0)
check("steady-state error", m_sp["steady_state_error"], 0.2, 1e-3)

# Second order overshoot
zeta = 0.3
m2 = server.measure(rf, "z", ["overshoot_pct", "peak_time"], t_start=0.1, setpoint=1.0)
check("overshoot %", m2["overshoot_pct"],
      100 * math.exp(-math.pi * zeta / math.sqrt(1 - zeta**2)), 0.2)
check("peak time", m2["peak_time"], math.pi / (5 * math.sqrt(1 - zeta**2)), 5e-3)

cmp = server.compare_cases({"nominal": rf, "high_gain": sim2["result_file"]}, ["y"],
                           ["final"])
check("compare: high-gain final", cmp["table"]["y"]["high_gain"]["final"], 0.9, 1e-3)
print(cmp["markdown"])

files = server.export_data({"nominal": rf, "high_gain": sim2["result_file"]},
                           ["r", "y", "z"], f"{OUT}/step", "xlsx", resample_dt=0.01)
print("xlsx :", files)
files = server.export_data({"nominal": rf}, ["r", "y"], f"{OUT}/step", "csv")
print("csv  :", files)
print("plot :", server.plot({"nominal": rf, "high_gain": sim2["result_file"]},
                            ["y", "z"], f"{OUT}/step",
                            title="self-test", reference_lines=[{"y": 1.0, "label": "setpoint"}]))

# Linearize open loop and check margins: |L|=1 at w = sqrt(15)/0.5
lin = server.linearize(str(TMP / "OL.mo"), "OL", tag="selftest")
assert lin["ok"], lin
print("lin  :", {k: lin[k] for k in ("states", "inputs", "outputs", "A", "B", "C", "D")})
check("pole", lin["poles"][0][0], -2.0, 1e-6)
fa = server.frequency_analysis(lin["lin_file"], "e", "ym", bode_out_path=f"{OUT}/bode")
wc = math.sqrt(15) / 0.5
check("gain crossover rad/s", fa["gain_crossover_rad_s"], wc, 0.02)
check("phase margin deg", fa["phase_margin_deg"], 180 - math.degrees(math.atan(0.5 * wc)), 0.2)
check("dc gain dB", fa["dc_gain_db"], 20 * math.log10(4), 0.05)
print("gain margin (expected None = infinite):", fa["gain_margin_db"], "| bode:", fa.get("bode_png"))

print("\nALL PASS" if fails == 0 else f"\n{fails} FAILED")
raise SystemExit(1 if fails else 0)
