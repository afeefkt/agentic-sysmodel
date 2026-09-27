"""Download openly licensed Modelica/OpenModelica docs into knowledge/web/*.md.

Only sources whose license allows copying:
- OpenModelica User's Guide: CC BY 4.0 (c) Open Source Modelica Consortium
- Modelica Language Specification 3.6: free distribution with the copyright
  notice retained (c) Modelica Association

NOT downloaded (license does not allow derivatives/copies; cite only):
- "Modelica by Example" (M. Tiller, CC BY-NC-ND): https://mbe.modelica.university/
- P. Fritzson tutorial PDFs (copyrighted): keep your own local extracts private.

Run (WSL or Windows, stdlib only):  python tools/knowledge/fetch_web_docs.py
"""

from __future__ import annotations

import html
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "knowledge" / "web"

OMUG = "https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/"
SPEC = "https://specification.modelica.org/maint/3.6/"
SOURCES = {
    # name: (url, license notice)
    "omug-omedit": (OMUG + "omedit.html", "OpenModelica User's Guide, CC BY 4.0, (c) OSMC"),
    "omug-solving": (OMUG + "solving.html", "OpenModelica User's Guide, CC BY 4.0, (c) OSMC"),
    "omug-scripting-api": (OMUG + "scripting_api.html", "OpenModelica User's Guide, CC BY 4.0, (c) OSMC"),
    "omug-simulation-flags": (OMUG + "simulationflags.html", "OpenModelica User's Guide, CC BY 4.0, (c) OSMC"),
    "omug-plotting": (OMUG + "plotting.html", "OpenModelica User's Guide, CC BY 4.0, (c) OSMC"),
    "omug-ompython": (OMUG + "ompython.html", "OpenModelica User's Guide, CC BY 4.0, (c) OSMC"),
    "omug-faq": (OMUG + "faq.html", "OpenModelica User's Guide, CC BY 4.0, (c) OSMC"),
    "spec-annotations": (SPEC + "annotations.html", "Modelica Language Specification 3.6, (c) Modelica Association, freely distributable with this notice"),
    "spec-connectors": (SPEC + "connectors-and-connections.html", "Modelica Language Specification 3.6, (c) Modelica Association, freely distributable with this notice"),
    "spec-equations": (SPEC + "equations.html", "Modelica Language Specification 3.6, (c) Modelica Association, freely distributable with this notice"),
    "spec-classes": (SPEC + "class-predefined-types-and-declarations.html", "Modelica Language Specification 3.6, (c) Modelica Association, freely distributable with this notice"),
    "spec-inheritance": (SPEC + "inheritance-modification-and-redeclaration.html", "Modelica Language Specification 3.6, (c) Modelica Association, freely distributable with this notice"),
}


def html_to_md(s: str) -> str:
    m = re.search(r'(?is)<div[^>]*(role="main"|class="ltx_page_main"|class="body")[^>]*>(.*)', s)
    s = m.group(2) if m else s
    s = re.sub(r"(?is)<(script|style|nav|footer|header)[^>]*>.*?</\1>", "", s)
    s = re.sub(r"(?i)<br\s*/?>", "\n", s)
    s = re.sub(r"(?i)<h(\d)[^>]*>", lambda m: "\n\n" + "#" * int(m.group(1)) + " ", s)
    s = re.sub(r"(?i)</h\d>", "\n", s)
    s = re.sub(r"(?i)<li[^>]*>", "\n- ", s)
    s = re.sub(r"(?is)<pre[^>]*>(.*?)</pre>", lambda m: "\n```\n" + re.sub(r"<[^>]+>", "", m.group(1)) + "\n```\n", s)
    s = re.sub(r"(?i)</?(p|div|tr|table|dl|dt|dd|blockquote|section)[^>]*>", "\n", s)
    s = re.sub(r"(?i)</?code[^>]*>", "`", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)
    s = re.sub(r"[ \t]+", " ", s)
    return re.sub(r"\n\s*\n\s*\n+", "\n\n", s).strip()


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    failed = 0
    for name, (url, notice) in SOURCES.items():
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "agentic-sysmodel-docs/0.1"})
            raw = urllib.request.urlopen(req, timeout=60).read().decode("utf-8", "replace")
        except Exception as exc:
            print(f"FAIL {name}: {exc}")
            failed += 1
            continue
        body = html_to_md(raw)
        (OUT / f"{name}.md").write_text(
            f"<!-- Source: {url}\n     License: {notice} -->\n\n{body}\n", encoding="utf-8")
        print(f"ok   {name}: {len(body) // 1024} KB")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
