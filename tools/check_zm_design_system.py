#!/usr/bin/env python3
"""Verify ZM canonical visual contracts and prevent NEW page-local styling.

This is a differential textual gate, NOT an AST linter or visual certification.
Existing technical debt is inventoried; it is not falsely treated as fixed.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DS = ROOT / "docs/design_system"
REFERENCE = ROOT / "docs/referencias_frontend/rodada-acabamento-2026-10-16/acabamento-integrado-zm.html"
EXPECTED_SHA = "774f5bbce0ccbc8048818a2daa24531804619551432113795a00a6dbe4eaf53f"
RULES = [
    ("typography", re.compile(r"\bTextStyle\s*\(")),
    ("color_palette", re.compile(r"\bColors\.\w+|\bColor\s*\(\s*0x[0-9a-fA-F]+")),
    ("geometry", re.compile(r"\bBorderRadius\.(?:circular|only)\s*\(")),
    ("input_style", re.compile(r"\bInputDecoration\s*\(")),
    ("datepicker", re.compile(r"\bshowDatePicker\s*\(")),
    ("date_range_picker", re.compile(r"\bshowDateRangePicker\s*\(")),
    ("independent_page_shell", re.compile(r"\b(?:Scaffold|AppBar)\s*\(")),
    ("raw_icon_family", re.compile(r"\bIcons\.\w+")),
    ("raw_filter_control", re.compile(r"\b(?:FilterChip|ChoiceChip|InputChip|ExpansionTile|SegmentedButton)\s*(?:<[^>]*>)?\s*\(")),
    ("raw_input_control", re.compile(r"\b(?:TextField|TextFormField|DropdownButtonFormField)\s*(?:<[^>]*>)?\s*\(")),
    ("local_spacing", re.compile(r"\bEdgeInsets\.(?:all|only|symmetric|fromLTRB)\s*\(")),
    ("literal_font_size", re.compile(r"\bfontSize\s*:\s*\d+(?:\.\d+)?\b")),
]
STATUS = {"confirmed_user", "reference_observed", "pending", "rejected_as_binding"}

def issue(msg: str) -> None:
    raise ValueError(msg)

def read_json(name: str) -> dict:
    return json.loads((DS / name).read_text(encoding="utf-8"))

def validate_contract() -> dict:
    if not REFERENCE.is_file():
        issue("FE-052 missing")
    digest = hashlib.sha256(REFERENCE.read_bytes()).hexdigest()
    if digest != EXPECTED_SHA:
        issue("FE-052 changed: do not silently move the reference")
    data = {name: read_json(name) for name in
            ("tokens.json", "components.json", "page_patterns.json", "views.json", "exceptions.json")}
    ts = data["tokens.json"]["tokens"]
    cs = data["components.json"]["components"]
    ps = data["page_patterns.json"]["patterns"]
    vs = data["views.json"]["views"]
    for name, objects in (("tokens", ts), ("components", cs), ("patterns", ps)):
        ids = [item["id"] for item in objects]
        if len(ids) != len(set(ids)):
            issue(f"Duplicated {name} IDs")
    if any(t["status"] not in STATUS for t in ts):
        issue("Unknown status in tokens")
    known_tokens = {t["id"]: t for t in ts}
    expected_confirmed = {
        "color.accent.seed": "#2866AE",
        "space.form.group": 20,
        "radius.field": 24,
        "radius.panel": 32,
    }
    for key, expected in expected_confirmed.items():
        val = known_tokens.get(key)
        if not val or val["status"] != "confirmed_user" or val["value"] != expected:
            issue(f"Confirmed source mismatch: {key}")
    if len(vs) != 38 or len({v["file"] for v in vs}) != 38:
        issue("Expected 38 unique views from backup inventory")
    actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / "client/lib/views").glob("*.dart")}
    inventoried = {v["file"] for v in vs}
    if actual != inventoried:
        issue("Views inventory drift: missing " + repr(sorted(actual-inventoried))
              + "; stale " + repr(sorted(inventoried-actual)))
    for c in cs:
        for source in c["sourcePaths"]:
            if not (ROOT / source).is_file():
                issue(f"Component source missing: {c['id']}: {source}")
    components = {c["id"] for c in cs}
    for p in ps:
        if not set(p["componentIds"]) <= components:
            issue(f"Unknown component in page pattern {p['id']}")
    for ex in data["exceptions.json"]["exceptions"]:
        if not re.fullmatch(r"EX-\d{3,}", ex["id"]) or not ex.get("reason") or not ex.get("path"):
            issue(f"Unjustified exception {ex}")
    return {"tokens": len(ts), "components": len(cs), "patterns": len(ps), "views": len(vs), "reference_sha256": digest}

def detect_added(line: str, exceptions: set[str]) -> list[str]:
    if "zm-design-exception:" in line:
        ids = re.findall(r"zm-design-exception:\s*(EX-\d+)", line)
        if ids and all(i in exceptions for i in ids):
            return []
    return [name for name, rule in RULES if rule.search(line)]

def changed_violations(base: str) -> list[str]:
    cmd = ["git", "diff", "--no-ext-diff", "--unified=0", base, "HEAD",
           "--", "client/lib/views", "client/lib/widgets"]
    diff = subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)
    if diff.returncode != 0:
        issue("Cannot compare with " + base + ": " + diff.stderr.strip())
    allowed = read_json("exceptions.json")["exceptions"]
    # Explicitly documented exemptions need file-specific scope.
    exemptions = {e["id"]: e["path"] for e in allowed}
    issues: list[str] = []
    filename = ""
    current_line = 0
    for raw in diff.stdout.splitlines():
        if raw.startswith("+++ b/"):
            filename = raw[6:]
            continue
        match = re.match(r"@@ .* \+(\d+)(?:,\d+)? @@", raw)
        if match:
            current_line = int(match.group(1)) - 1
            continue
        if raw.startswith("+") and not raw.startswith("+++"):
            current_line += 1
            if not filename.startswith("client/lib/views/") or not filename.endswith(".dart"):
                continue
            line = raw[1:]
            if line.lstrip().startswith(("//", "///", "*", "/*")):
                continue
            file_exceptions = {key for key, path in exemptions.items() if path == filename}
            # Exception marker must be on SAME new line and registered to that exact path.
            for kind in detect_added(line, file_exceptions):
                issues.append(f"{filename}:{current_line}: NEW page-local {kind}; use a shared ZM component/token")
        elif raw.startswith(" ") and not raw.startswith("++"):
            current_line += 1
    return issues

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check-changed", action="store_true")
    parser.add_argument("--base", default="origin/backup")
    args = parser.parse_args()
    try:
        report = validate_contract()
        print("ZM contract VALID:", json.dumps(report, ensure_ascii=False))
        if args.check_changed:
            issues = changed_violations(args.base)
            if issues:
                for i in issues:
                    print("ZM DESIGN VIOLATION:", i)
                return 2
            print("ZM design diff: no newly introduced page-local styles detected")
        print("NOTICE: text guard is limited; visual and interaction validation remain separate")
        return 0
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print("ZM DESIGN CONTRACT ERROR:", exc, file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
