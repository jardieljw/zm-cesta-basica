import json
import re

with open("client/lib/l10n/app_pt.arb", "r", encoding="utf-8") as f:
    arb = json.load(f)

print(f"Total keys: {len([k for k in arb.keys() if not k.startswith('@')])}")

def search_text(term):
    results = {}
    term_l = term.lower()
    for k, v in arb.items():
        if k.startswith("@"):
            continue
        if term_l in str(v).lower():
            results[k] = v
    return results

terms = ["tentar novamente", "alterar", "imprimir", "período", "mês", "ano", "exportad", "baixad", "frete", "aluguel", "energia", "outros", "dinheiro", "pix", "transferência"]
for t in terms:
    res = search_text(t)
    print(f"--- Term: '{t}' (found {len(res)}) ---")
    for k, v in list(res.items())[:5]:
        print(f"  {k}: {v}")
