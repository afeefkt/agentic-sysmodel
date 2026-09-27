"""Library discovery and diagram-quality helpers (need a live OMSession).

- build_index / search / examples: find MSL classes by name AND description,
  so agents reuse existing components instead of writing custom equations.
- diagram_report: checks that a model is a real component diagram
  (MSL instances wired with connect(), every component placed).
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

_BUILTIN = {"Real", "Integer", "Boolean", "String"}
_DIAGRAM_KINDS = {"model", "block", "connector", "expandable connector", "class"}
_NOISE = (".Icons.", ".Internal.", ".Obsolete", ".UsersGuide", ".BaseClasses.",
          ".Interfaces.Partial", ".Utilities.Internal")


def _send(om, expr: str) -> Any:
    val, _ = om._safe_send(expr)
    om._drain_diagnostics()
    return val


def _top_level_items(raw: str) -> list[str]:
    """Split omc's '{{a}, {b}, ...}' raw output into its top-level items.
    (OMPython's typed parser fails on Placement(...) records.)"""
    raw = raw.strip()
    if raw.startswith("{") and raw.endswith("}"):
        raw = raw[1:-1]
    items, depth, cur, in_str = [], 0, [], False
    for ch in raw:
        if ch == '"':
            in_str = not in_str
        if not in_str:
            if ch in "{(":
                depth += 1
            elif ch in "})":
                depth -= 1
            elif ch == "," and depth == 0:
                items.append("".join(cur).strip())
                cur = []
                continue
        cur.append(ch)
    if "".join(cur).strip():
        items.append("".join(cur).strip())
    return items


def _component_annotations(om, model: str) -> list[str]:
    try:
        raw = om._omc.sendExpression(f"getComponentAnnotations({model})", parsed=False)
    except Exception:
        return []
    om._drain_diagnostics()
    return _top_level_items(str(raw))


# ------------------------------------------------------------------- index --
def build_index(om, root: str, cache: Path) -> list[dict]:
    if cache.exists():
        return json.loads(cache.read_text())
    names = _send(om, f"getClassNames({root}, recursive=true)") or []
    index = []
    for n in names:
        n = str(n)
        kind = str(_send(om, f"getClassRestriction({n})") or "").strip('"')
        if kind in ("function", "type", "operator", "operator record",
                    "operator function", ""):
            continue                                   # not diagram material
        comment = str(_send(om, f"getClassComment({n})") or "").strip('"')
        partial = bool(_send(om, f"isPartial({n})"))
        index.append({"name": n, "kind": kind, "comment": comment,
                      "partial": partial})
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_text(json.dumps(index))
    return index


def search(index: list[dict], query: str, limit: int = 25,
           include_partial: bool = False) -> list[dict]:
    words = [w for w in re.split(r"\W+", query.lower()) if w]
    scored = []
    for c in index:
        if c["partial"] and not include_partial:
            continue
        name, comment = c["name"].lower(), c["comment"].lower()
        short = name.rsplit(".", 1)[-1]
        s = 0.0
        hits = 0
        for w in words:
            h = False
            if w in short:
                s += 3; h = True
            elif w in name:
                s += 1.5; h = True
            if w in comment:
                s += 1; h = True
            hits += h
        if hits == 0:
            continue
        s += 2.0 * hits / len(words)                     # prefer matching all words
        if any(x.lower() in name for x in _NOISE):
            s -= 2.5
        if ".examples." in name:
            s -= 0.5                                     # components first, examples via list_examples
        scored.append((s, c))
    scored.sort(key=lambda t: -t[0])
    return [dict(c, score=round(s, 2)) for s, c in scored[:limit]]


def examples(index: list[dict], package: str, limit: int = 60) -> list[dict]:
    pre = package.rstrip(".") + "."
    out = [c for c in index
           if c["name"].startswith(pre) and ".Examples." in c["name"] + "."
           and c["kind"] == "model" and not c["partial"]]
    return out[:limit]


# ----------------------------------------------------------- diagram check --
def diagram_report(om, model: str, index_names: set[str]) -> dict:
    comps = _send(om, f"getComponents({model})") or []
    anns = _component_annotations(om, model)
    n_conn = int(_send(om, f"getConnectionCount({model})") or 0)
    n_eq = int(_send(om, f"getEquationItemsCount({model})") or 0)

    kind_cache: dict[str, str] = {}
    instances, missing, custom, msl = [], [], [], []
    for i, c in enumerate(comps):
        if not isinstance(c, (list, tuple)) or len(c) < 9:
            continue
        ctype, cname, variability = str(c[0]), str(c[1]), str(c[8])
        if ctype in _BUILTIN or variability in ("parameter", "constant"):
            continue
        if ctype not in kind_cache:
            kind_cache[ctype] = str(_send(om, f"getClassRestriction({ctype})") or "").strip('"')
        if kind_cache[ctype] not in _DIAGRAM_KINDS:
            continue                                     # SI types, records, ...
        instances.append(cname)
        ann = anns[i] if i < len(anns) else ()
        if "Placement" not in str(ann):
            missing.append(cname)
        (msl if ctype.startswith("Modelica.") else custom).append(f"{cname}: {ctype}")

    plain_eq = max(0, n_eq - n_conn)
    issues = []
    if missing:
        issues.append(f"{len(missing)} component(s) without Placement annotation "
                      f"(invisible in OMEdit diagram): {missing[:15]}")
    if instances and n_conn == 0:
        issues.append("components exist but there are no connect() statements "
                      "(wired by equations instead of connections)")
    if plain_eq > n_conn and instances:
        issues.append(f"{plain_eq} plain equations vs {n_conn} connect(): "
                      "top-level wiring should use connect() between connectors")
    if instances and len(custom) > len(msl):
        issues.append(f"more custom ({len(custom)}) than MSL ({len(msl)}) component "
                      "instances; check search_library/list_examples for existing components")
    return {"ok": not missing and not (instances and n_conn == 0),
            "model": model, "components": len(instances),
            "msl_components": msl, "custom_components": custom,
            "missing_placement": missing, "connect_count": n_conn,
            "plain_equation_count": plain_eq, "issues": issues}
