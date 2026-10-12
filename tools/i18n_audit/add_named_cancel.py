import json

arb_path = "client/lib/l10n/app_pt.arb"
with open(arb_path, "r", encoding="utf-8") as f:
    arb = json.load(f)

arb["payableConfirmCancelObligationNamed"] = "Tem certeza que deseja cancelar a obrigação \"{description}\"?"
arb["@payableConfirmCancelObligationNamed"] = {
    "description": "Confirmação de cancelamento de obrigação com nome",
    "placeholders": {"description": {"type": "String"}}
}

with open(arb_path, "w", encoding="utf-8") as f:
    json.dump(arb, f, ensure_ascii=False, indent=2)

print("Updated app_pt.arb successfully.")
