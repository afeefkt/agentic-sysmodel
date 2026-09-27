---
name: skill-authoring
description: Use when asked to create, improve or tune an agent skill (SKILL.md), especially when distilling knowledge from documents in knowledge/ (e.g. Modelica/OpenModelica tutorials) or when recording a recurring agent mistake.
---

# How to create and tune skills in this repo

## Location and format
- `.opencode/skills/<skill-name>/SKILL.md`. The folder name must equal `name`: lowercase letters and digits with single hyphens.
- Frontmatter needs `name` and `description`. The **description is the trigger**: write it as "Use when …" and list the concrete situations and keywords.
- Keep SKILL.md under ~150 lines. Put longer material in `reference.md` next to it and say in SKILL.md when to read it.

## Distilling from documents (knowledge/*.txt)
1. The source PDFs are converted to text in `knowledge/` (gitignored, since they're copyrighted and must not be committed or copied verbatim).
2. Read only the chapter that's relevant. Extract:
   - rules and conventions (checklist form)
   - common mistakes (a symptom → fix table)
   - **short** code patterns, **rewritten** in your own words and names
3. **Verify every snippet** with `openmodelica_check` (put it in a scratch model under `.om_build/scratch/`). Snippets that don't compile never go into a skill.
4. Cite the source at the bottom (`Source: Fritzson, Modelica Tutorial 2025, ch. X`), with no long quotes.

## Source licenses (what may go into the repo)
| Source | License | Allowed |
|---|---|---|
| Modelica Standard Library docs (`knowledge/msl/`) | BSD-3-Clause | quote and adapt, with attribution |
| OpenModelica User's Guide (`knowledge/web/omug-*`) | CC BY 4.0 | quote and adapt, with attribution |
| Modelica Language Spec (`knowledge/web/spec-*`) | free distribution with notice | quote with the notice. Summarize in your own words |
| Modelica by Example (Tiller) | CC BY-NC-ND | **cite and link only**, no copied or adapted text |
| Fritzson tutorial PDFs, other books | copyrighted | **cite only**, keep extracts private in `knowledge/` |

Rebuild the knowledge base: `python3 tools/knowledge/fetch_web_docs.py` and `uv run --directory tools/om_mcp python ../knowledge/build_msl_knowledge.py`.

## Tuning loop (skills are living checklists)
- Whenever an agent makes a mistake that the skill should have prevented, add **one line** to the right table or checklist: the symptom, the cause, the fix.
- Measure: run the same task 3 times with the skill and 3 times without it (turn it off with `"skill": false` in the agent's tools), and compare pass counts and attempts. Keep the changes that help. Delete lines that never trigger.
- Keep the skills focused: one topic each. Split a skill once it reaches ~150 lines.
