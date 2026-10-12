import os
import re

lib_dir = os.path.join("client", "lib")

hint_regex = re.compile(r"hintText:\s*['\"]([^'\"]{3,})['\"]")
tooltip_regex = re.compile(r"tooltip:\s*['\"]([^'\"]{3,})['\"]")
helper_regex = re.compile(r"helperText:\s*['\"]([^'\"]{3,})['\"]")

findings = []

for root, _, files in os.walk(lib_dir):
    for file in files:
        if not file.endswith(".dart") or file.startswith("app_localizations"):
            continue
        path = os.path.join(root, file)
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        for idx, line in enumerate(lines, 1):
            clean = line.strip()
            if clean.startswith("//"):
                continue
            for reg, kind in [(hint_regex, "hintText"), (tooltip_regex, "tooltip"), (helper_regex, "helperText")]:
                m = reg.search(line)
                if m:
                    val = m.group(1).strip()
                    if re.search(r"[a-zA-ZÀ-ÿ]", val) and not val.startswith("$"):
                        findings.append((file, idx, kind, val, clean))

by_file = {}
for f, l, kind, val, line in findings:
    by_file.setdefault(f, []).append((l, kind, val, line))

print(f"Total occurrences of hint/tooltip/helper literals: {len(findings)} across {len(by_file)} files")
for f, items in sorted(by_file.items()):
    print(f"\n=== {f} ({len(items)} occurrences) ===")
    for l, kind, val, line in items:
        print(f"  Line {l} [{kind}]: \"{val}\"")
