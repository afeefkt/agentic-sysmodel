"""Build knowledge/msl/*.md from the installed Modelica Standard Library.

Per domain: the library's own User's Guide text, a component catalog
(non-partial models/blocks/connectors with their descriptions) and the list of
example models. Source: Modelica Standard Library 4.1.0, BSD-3-Clause,
(c) Modelica Association - version-matched to what omc simulates.

Run from WSL (repo root):
  uv run --directory tools/om_mcp python ../knowledge/build_msl_knowledge.py
"""

from __future__ import annotations

import html
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "om_mcp"))
import server  # noqa: E402  (reuses the MCP server's omc session + index)

OUT = server.PROJECT_ROOT / "knowledge" / "msl"
DOMAINS = {
    "General": "Modelica.UsersGuide",
    "MultiBody": "Modelica.Mechanics.MultiBody",
    "Rotational": "Modelica.Mechanics.Rotational",
    "Translational": "Modelica.Mechanics.Translational",
    "ElectricalAnalog": "Modelica.Electrical.Analog",
    "Machines": "Modelica.Electrical.Machines",
    "PowerConverters": "Modelica.Electrical.PowerConverters",
    "Polyphase": "Modelica.Electrical.Polyphase",
    "FundamentalWave": "Modelica.Magnetic.FundamentalWave",
    "Blocks": "Modelica.Blocks",
    "StateGraph": "Modelica.StateGraph",
    "Clocked": "Modelica.Clocked",
    "HeatTransfer": "Modelica.Thermal.HeatTransfer",
    "Fluid": "Modelica.Fluid",
}
SKIP = (".Icons.", ".Internal.", ".Obsolete", ".BaseClasses.", ".Examples.",
        ".UsersGuide", ".Types.", ".Utilities.Internal")
DOC_CHARS = 25000


def html_to_text(s: str) -> str:
    s = re.sub(r"(?is)<(script|style).*?</\1>", "", s)
    s = re.sub(r"(?i)<br\s*/?>", "\n", s)
    s = re.sub(r"(?i)</?(p|div|tr|table|blockquote)[^>]*>", "\n", s)
    s = re.sub(r"(?i)<li[^>]*>", "\n- ", s)
    s = re.sub(r"(?i)<h(\d)[^>]*>", lambda m: "\n" + "#" * (int(m.group(1)) + 2) + " ", s)
    s = re.sub(r"(?i)</h\d>", "\n", s)
    s = re.sub(r"(?i)</?(code|pre)[^>]*>", "`", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)
    s = re.sub(r"[ \t]+", " ", s)
    return re.sub(r"\n\s*\n\s*\n+", "\n\n", s).strip()


def doc_of(name: str) -> str:
    om = server._om()
    val, _ = om._safe_send(f"getDocumentationAnnotation({name})")
    om._drain_diagnostics()
    if isinstance(val, (list, tuple)) and val and val[0]:
        return html_to_text(str(val[0]))
    return ""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    index = server._index()
    for domain, pkg in DOMAINS.items():
        pre = pkg + "."
        in_pkg = [c for c in index if c["name"] == pkg or c["name"].startswith(pre)]
        guides = [c["name"] for c in in_pkg if ".UsersGuide" in c["name"] + "."]
        if domain == "General":
            guides = [c["name"] for c in index if c["name"].startswith("Modelica.UsersGuide")]
        lines = [f"# MSL knowledge: {domain} (`{pkg}`)",
                 "",
                 "Source: Modelica Standard Library 4.1.0 (BSD-3-Clause, (c) Modelica Association),",
                 "extracted from the installed library by tools/knowledge/build_msl_knowledge.py.",
                 "Use `openmodelica_describe_class` / `get_class_source` for full details.", ""]

        lines += ["## Package overview", "", doc_of(pkg)[:6000] or "(no overview)", ""]

        if guides:
            lines += ["## User's Guide", ""]
            budget = DOC_CHARS
            for g in guides:
                text = doc_of(g)
                if not text or budget <= 0:
                    continue
                text = text[:budget]
                budget -= len(text)
                lines += [f"### {g}", "", text, ""]

        if domain != "General":
            comps = [c for c in in_pkg if not c["partial"]
                     and c["kind"] in ("model", "block", "connector")
                     and not any(s in c["name"] + "." for s in SKIP)]
            lines += ["## Component catalog (non-partial, excluding examples/internals)", "",
                      "| class | kind | description |", "|---|---|---|"]
            lines += [f"| `{c['name'][len(pre):]}` | {c['kind']} | {c['comment']} |" for c in comps]
            exs = [c for c in in_pkg if ".Examples." in c["name"] + "."
                   and c["kind"] == "model" and not c["partial"]]
            lines += ["", "## Example models (copy structure + layout via get_class_source)", ""]
            lines += [f"- `{c['name']}`: {c['comment']}" for c in exs]

        path = OUT / f"{domain}.md"
        path.write_text("\n".join(lines) + "\n")
        print(f"{path.relative_to(server.PROJECT_ROOT)}: {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
