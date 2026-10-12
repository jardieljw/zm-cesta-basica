import os
import re

lib_dir = os.path.join("client", "lib")

text_regex = re.compile(r"Text\(\s*['\"]([^'\"]{3,})['\"]")
title_regex = re.compile(r"title:\s*['\"]([^'\"]{3,})['\"]")
label_regex = re.compile(r"labelText:\s*['\"]([^'\"]{3,})['\"]")
snack_regex = re.compile(r"SnackBar\(\s*content:\s*Text\(\s*['\"]([^'\"]{3,})['\"]")

findings = []

for root, _, files in os.walk(lib_dir):
    for file in files:
        if not file.endswith(".dart"):
            continue
        if file.startswith("app_localizations"):
            continue
        path = os.path.join(root, file)
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        for idx, line in enumerate(lines, 1):
            clean = line.strip()
            if clean.startswith("//"):
                continue
            for reg, kind in [(text_regex, "Text"), (title_regex, "title"), (label_regex, "labelText"), (snack_regex, "SnackBar")]:
                m = reg.search(line)
                if m:
                    val = m.group(1).strip()
                    if re.search(r"[a-zA-ZÀ-ÿ]", val) and not val.startswith("$") and not val.startswith("http") and val not in ["id", "sku", "kg", "un", "cx", "fd", "lt", "pct", "N/A", "OK"]:
                        findings.append((file, idx, kind, val, clean))

by_file = {}
for f, l, kind, val, line in findings:
    by_file.setdefault(f, []).append((l, kind, val, line))

print(f"Total occurrences: {len(findings)} across {len(by_file)} files in client/lib")
for f, items in sorted(by_file.items()):
    print(f"\n=== {f} ({len(items)} occurrences) ===")
    for l, kind, val, line in items:
        print(f"  Line {l} [{kind}]: \"{val}\"")
