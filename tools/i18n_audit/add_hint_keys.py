import json

arb_path = "client/lib/l10n/app_pt.arb"
with open(arb_path, "r", encoding="utf-8") as f:
    arb = json.load(f)

hints_entries = {
    "tooltipPrintSelectPrinter": "Imprimir / Selecionar Impressora (Epson Wi-Fi)",
    "@tooltipPrintSelectPrinter": {"description": "Tooltip do botão de seleção de impressoras e Epson"},

    "tooltipShareSavePdf": "Compartilhar / Salvar PDF",
    "@tooltipShareSavePdf": {"description": "Tooltip para compartilhar ou salvar arquivo PDF"},

    "payableInstallmentsHelper": "Dividir em N parcelas mensais",
    "@payableInstallmentsHelper": {"description": "Texto auxiliar para parcelamento de conta a pagar"},

    "payableRevertPaymentTooltip": "Estornar este pagamento",
    "@payableRevertPaymentTooltip": {"description": "Tooltip do botão de estorno de pagamento"},

    "dispatchPhysicalNotesHint": "Observações da saída física (opcional)",
    "@dispatchPhysicalNotesHint": {"description": "Dica de preenchimento para observações de saída física"},

    "dispatchCustomizationHint": "Ex: Cesta personalizada, lote específico",
    "@dispatchCustomizationHint": {"description": "Dica de personalização de cesta na saída"},

    "conferenceLossReasonHint": "Ex: Caixa molhou na chuva durante entrega",
    "@conferenceLossReasonHint": {"description": "Dica de justificativa para avaria ou perda na conferência"},

    "conferenceReceivedByHint": "Colaborador que conferiu e recebeu",
    "@conferenceReceivedByHint": {"description": "Dica do conferente que recebeu o repasse"},

    "conferenceAuditorNameHint": "Nome do conferente / auditor",
    "@conferenceAuditorNameHint": {"description": "Dica do nome do auditor na finalização do acerto"},

    "conferenceInitialJustificationHint": "Justificativa inicial das divergências",
    "@conferenceInitialJustificationHint": {"description": "Dica para justificativa inicial de pendências"},

    "conferenceInvestigationHint": "Descreva a apuração, se foi justificado, perdas aceitas ou ressarcimento",
    "@conferenceInvestigationHint": {"description": "Dica para investigação de divergência"}
}

for k, v in hints_entries.items():
    if k not in arb:
        arb[k] = v

with open(arb_path, "w", encoding="utf-8") as f:
    json.dump(arb, f, ensure_ascii=False, indent=2)

print("Added hint and tooltip keys to app_pt.arb successfully.")
