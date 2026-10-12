import json

arb_path = "client/lib/l10n/app_pt.arb"

with open(arb_path, "r", encoding="utf-8") as f:
    arb = json.load(f)

new_entries = {
    # 1. Blank forms
    "formXlsxDownloadSuccess": "Planilha XLSX baixada com sucesso: {filename}",
    "@formXlsxDownloadSuccess": {
        "description": "Mensagem de sucesso ao baixar modelo ou auditoria XLSX",
        "placeholders": {"filename": {"type": "String"}}
    },
    "formXlsxDownloadError": "Erro ao baixar planilha: {error}",
    "@formXlsxDownloadError": {
        "description": "Mensagem de erro ao baixar modelo ou auditoria XLSX",
        "placeholders": {"error": {"type": "String"}}
    },

    # 2. PDF Viewer / Printers
    "printerLocating": "Localizando impressoras instaladas...",
    "@printerLocating": {"description": "Mensagem durante busca de impressoras"},
    "printerSystemDefault": "Padrão do Sistema",
    "@printerSystemDefault": {"description": "Badge de impressora padrão do sistema operacional"},
    "printerAvailable": "Disponível",
    "@printerAvailable": {"description": "Badge de impressora online/disponível"},
    "printerActionPrint": "Imprimir",
    "@printerActionPrint": {"description": "Botão de impressão direta"},

    # 3. Reports
    "reportExportSuccess": "Planilha {format} exportada com sucesso!",
    "@reportExportSuccess": {
        "description": "Mensagem de sucesso ao exportar relatório em CSV ou XLSX",
        "placeholders": {"format": {"type": "String"}}
    },
    "reportExportError": "Erro ao exportar {format}: {error}",
    "@reportExportError": {
        "description": "Mensagem de erro ao exportar relatório",
        "placeholders": {"format": {"type": "String"}, "error": {"type": "String"}}
    },
    "commonSelectedDateLabel": "Data: {date}",
    "@commonSelectedDateLabel": {
        "description": "Label com a data selecionada",
        "placeholders": {"date": {"type": "String"}}
    },
    "commonChange": "Alterar",
    "@commonChange": {"description": "Botão para alterar data ou período"},
    "commonPeriodLabel": "Período: {start} até {end}",
    "@commonPeriodLabel": {
        "description": "Label com intervalo de datas",
        "placeholders": {"start": {"type": "String"}, "end": {"type": "String"}}
    },
    "commonMonthNumber": "Mês {month}",
    "@commonMonthNumber": {
        "description": "Exibição do número do mês",
        "placeholders": {"month": {"type": "int"}}
    },
    "commonYearLabel": "Ano:",
    "@commonYearLabel": {"description": "Rótulo do seletor de ano"},
    "reportPhysicalBelowMinOnly": "Exibir apenas itens abaixo do estoque mínimo",
    "@reportPhysicalBelowMinOnly": {"description": "Filtro de contagem física"},

    # 4. Dashboard
    "dashboardSelectedDate": "Data selecionada: {date}",
    "@dashboardSelectedDate": {
        "description": "Data selecionada no dashboard",
        "placeholders": {"date": {"type": "String"}}
    },
    "dashboardBatchesCount": "Lotes ({count})",
    "@dashboardBatchesCount": {
        "description": "Título da lista de lotes com contagem",
        "placeholders": {"count": {"type": "int"}}
    },
    "dashboardNoBatches": "Nenhum lote montado no período.",
    "@dashboardNoBatches": {"description": "Estado vazio da lista de lotes"},
    "dashboardSalesCount": "Vendas ({count})",
    "@dashboardSalesCount": {
        "description": "Título da lista de vendas com contagem",
        "placeholders": {"count": {"type": "int"}}
    },
    "dashboardNoSales": "Nenhuma venda registrada no período.",
    "@dashboardNoSales": {"description": "Estado vazio da lista de vendas"},
    "dashboardDispatchesCount": "Saídas ({count})",
    "@dashboardDispatchesCount": {
        "description": "Título da lista de saídas com contagem",
        "placeholders": {"count": {"type": "int"}}
    },
    "dashboardExaminePendingDivergences": "Examinar Divergências Pendentes ({count})",
    "@dashboardExaminePendingDivergences": {
        "description": "Botão de conferência com divergências pendentes",
        "placeholders": {"count": {"type": "int"}}
    },
    "dashboardNoDispatches": "Nenhuma saída registrada no período.",
    "@dashboardNoDispatches": {"description": "Estado vazio de saídas"},
    "dashboardDispatchItemSubtitle": "Data: {date} | Cestas: {baskets} un.",
    "@dashboardDispatchItemSubtitle": {
        "description": "Subtítulo do item de saída no dashboard",
        "placeholders": {"date": {"type": "String"}, "baskets": {"type": "int"}}
    },
    "dashboardNoRetainedValues": "Nenhum valor retido por responsável no momento.",
    "@dashboardNoRetainedValues": {"description": "Estado vazio de valores retidos por responsáveis"},
    "dashboardResponsiblePhone": "Tel: {phone}",
    "@dashboardResponsiblePhone": {
        "description": "Telefone do responsável",
        "placeholders": {"phone": {"type": "String"}}
    },
    "dashboardResponsibleDate": "Data: {date}",
    "@dashboardResponsibleDate": {
        "description": "Data da saída do responsável",
        "placeholders": {"date": {"type": "String"}}
    },
    "dashboardNoDivergences": "Nenhuma divergência pendente.",
    "@dashboardNoDivergences": {"description": "Estado vazio de divergências"},
    "dashboardSettledAt": "Acerto em: {date}",
    "@dashboardSettledAt": {
        "description": "Data e hora do acerto da divergência",
        "placeholders": {"date": {"type": "String"}}
    },
    "commonNotesPrefix": "Obs: {notes}",
    "@commonNotesPrefix": {
        "description": "Observações prefixadas",
        "placeholders": {"notes": {"type": "String"}}
    },
    "dashboardStockColBasket": "Cesta",
    "@dashboardStockColBasket": {"description": "Coluna Cesta no cabeçalho de estoque"},
    "dashboardStockColStore": "Loja",
    "@dashboardStockColStore": {"description": "Coluna Loja no cabeçalho de estoque"},
    "dashboardStockColTransit": "Trânsito",
    "@dashboardStockColTransit": {"description": "Coluna Trânsito no cabeçalho de estoque"},
    "dashboardStockColTotal": "Total",
    "@dashboardStockColTotal": {"description": "Coluna Total no cabeçalho de estoque"},
    "dashboardAllAboveMinStock": "Todos os itens estão acima do estoque mínimo.",
    "@dashboardAllAboveMinStock": {"description": "Alerta de que não há insumos em falta"},
    "dashboardItemSku": "SKU: {sku}",
    "@dashboardItemSku": {
        "description": "Código SKU do item",
        "placeholders": {"sku": {"type": "String"}}
    },
    "dashboardCashRecordsCount": "Caixa ({count})",
    "@dashboardCashRecordsCount": {
        "description": "Contagem de lançamentos de caixa",
        "placeholders": {"count": {"type": "int"}}
    },
    "dashboardProjectedInflow": "Entradas Previstas: {amount}",
    "@dashboardProjectedInflow": {
        "description": "Total de entradas financeiras previstas",
        "placeholders": {"amount": {"type": "String"}}
    },
    "dashboardProjectedOutflow": "Saídas Previstas: {amount}",
    "@dashboardProjectedOutflow": {
        "description": "Total de saídas financeiras previstas",
        "placeholders": {"amount": {"type": "String"}}
    },
    "dashboardNoCashRecords": "Nenhum lançamento no período.",
    "@dashboardNoCashRecords": {"description": "Estado vazio do extrato de caixa"},
    "dashboardNoOpenReceivables": "Nenhum título a receber em aberto.",
    "@dashboardNoOpenReceivables": {"description": "Estado vazio de títulos a receber"},
    "dashboardNoOpenPayables": "Nenhuma conta a pagar em aberto.",
    "@dashboardNoOpenPayables": {"description": "Estado vazio de contas a pagar"},

    # 5. Dispatch conference
    "conferenceMethodCashHand": "Dinheiro em Mãos",
    "@conferenceMethodCashHand": {"description": "Forma de repasse: Dinheiro em Mãos"},
    "conferenceMethodPixSettled": "PIX Repassado",
    "@conferenceMethodPixSettled": {"description": "Forma de repasse: PIX Repassado"},
    "conferenceMethodBankTransfer": "Transferência Bancária",
    "@conferenceMethodBankTransfer": {"description": "Forma de repasse: Transferência Bancária"},
    "commonObservationsPrefix": "Observações: {notes}",
    "@commonObservationsPrefix": {
        "description": "Prefixo de observações completas",
        "placeholders": {"notes": {"type": "String"}}
    },

    # 6. Payables
    "payableCategorySupplier": "Fornecedor",
    "@payableCategorySupplier": {"description": "Categoria de conta: Fornecedor"},
    "payableCategoryElectricity": "Energia Elétrica",
    "@payableCategoryElectricity": {"description": "Categoria de conta: Energia Elétrica"},
    "payableCategoryRent": "Aluguel",
    "@payableCategoryRent": {"description": "Categoria de conta: Aluguel"},
    "payableCategoryFreight": "Frete / Logística",
    "@payableCategoryFreight": {"description": "Categoria de conta: Frete / Logística"},
    "payableCategoryFreightShort": "Frete",
    "@payableCategoryFreightShort": {"description": "Categoria de conta: Frete simplificado"},
    "payableCategoryMaintenance": "Manutenção",
    "@payableCategoryMaintenance": {"description": "Categoria de conta: Manutenção"},
    "payableCategoryLoan": "Empréstimo",
    "@payableCategoryLoan": {"description": "Categoria de conta: Empréstimo"},
    "payableCategoryCreditCard": "Cartão de Crédito",
    "@payableCategoryCreditCard": {"description": "Categoria de conta: Cartão de Crédito"},
    "payableCategoryPartnerWithdrawal": "Retirada Sócios",
    "@payableCategoryPartnerWithdrawal": {"description": "Categoria de conta: Retirada de Sócios"},
    "payableCategoryTaxes": "Impostos / Taxas",
    "@payableCategoryTaxes": {"description": "Categoria de conta: Impostos / Taxas"},
    "payableCategoryTaxesShort": "Impostos",
    "@payableCategoryTaxesShort": {"description": "Categoria de conta: Impostos simplificado"},
    "payableCategoryOthers": "Outros",
    "@payableCategoryOthers": {"description": "Categoria de conta: Outros"},

    "payablePaymentMethodBoleto": "Boleto",
    "@payablePaymentMethodBoleto": {"description": "Forma de pagamento de despesa: Boleto"},
    "payablePaymentMethodPix": "PIX",
    "@payablePaymentMethodPix": {"description": "Forma de pagamento de despesa: PIX"},
    "payablePaymentMethodTransfer": "Transferência",
    "@payablePaymentMethodTransfer": {"description": "Forma de pagamento de despesa: Transferência"},
    "payablePaymentMethodCheck": "Cheque",
    "@payablePaymentMethodCheck": {"description": "Forma de pagamento de despesa: Cheque"},
    "payablePaymentMethodCard": "Cartão de Crédito",
    "@payablePaymentMethodCard": {"description": "Forma de pagamento de despesa: Cartão de Crédito"},
    "payablePaymentMethodCash": "Dinheiro",
    "@payablePaymentMethodCash": {"description": "Forma de pagamento de despesa: Dinheiro"},
    "payablePaymentMethodOther": "Outro",
    "@payablePaymentMethodOther": {"description": "Forma de pagamento de despesa: Outro"},

    "payableRecurrenceFrequency": "Periodicidade",
    "@payableRecurrenceFrequency": {"description": "Campo de periodicidade de recorrência"},
    "payableNoPaymentsYet": "Nenhum pagamento efetuado até o momento.",
    "@payableNoPaymentsYet": {"description": "Histórico vazio de pagamentos de uma conta a pagar"},
    "payableRevertPaymentTitle": "Estornar Pagamento",
    "@payableRevertPaymentTitle": {"description": "Título do modal de estorno de pagamento"},
    "payableRevertPaymentReason": "Justificativa do Estorno",
    "@payableRevertPaymentReason": {"description": "Campo de justificativa para estorno"},
    "payableConfirmCancelObligation": "Tem certeza que deseja cancelar a obrigação?",
    "@payableConfirmCancelObligation": {"description": "Confirmação de cancelamento de conta a pagar"},

    "monthJan": "Jan",
    "@monthJan": {"description": "Janeiro abreviado"},
    "monthFeb": "Fev",
    "@monthFeb": {"description": "Fevereiro abreviado"},
    "monthMar": "Mar",
    "@monthMar": {"description": "Março abreviado"},
    "monthApr": "Abr",
    "@monthApr": {"description": "Abril abreviado"},
    "monthMay": "Mai",
    "@monthMay": {"description": "Maio abreviado"},
    "monthJun": "Jun",
    "@monthJun": {"description": "Junho abreviado"},
    "monthJul": "Jul",
    "@monthJul": {"description": "Julho abreviado"},
    "monthAug": "Ago",
    "@monthAug": {"description": "Agosto abreviado"},
    "monthSep": "Set",
    "@monthSep": {"description": "Setembro abreviado"},
    "monthOct": "Out",
    "@monthOct": {"description": "Outubro abreviado"},
    "monthNov": "Nov",
    "@monthNov": {"description": "Novembro abreviado"},
    "monthDec": "Dez",
    "@monthDec": {"description": "Dezembro abreviado"},
    "filterAllOption": "Todos",
    "@filterAllOption": {"description": "Opção Todos em filtros suspensos"},

    # 7. Treasury
    "treasuryNeedTwoAccountsForTransfer": "São necessárias ao menos 2 contas para realizar transferências.",
    "@treasuryNeedTwoAccountsForTransfer": {"description": "Alerta de contas insuficientes para transferência"},
    "treasuryAccountLabel": "Conta Financeira",
    "@treasuryAccountLabel": {"description": "Rótulo do seletor de conta financeira"},
    "treasuryAccountFilterLabel": "Conta",
    "@treasuryAccountFilterLabel": {"description": "Filtro de conta"},
    "treasuryLaunchEntry": "Lançamento",
    "@treasuryLaunchEntry": {"description": "Botão de novo lançamento na tesouraria"},
    "treasuryConsolidatedPosition": "Posição Consolidada da Empresa",
    "@treasuryConsolidatedPosition": {"description": "Título do quadro consolidado da tesouraria"},
    "treasuryCashPhysicalLabel": "Caixa Físico: {amount}",
    "@treasuryCashPhysicalLabel": {
        "description": "Saldo em espécie/caixa físico",
        "placeholders": {"amount": {"type": "String"}}
    },
    "treasuryBankLabel": "Bancos: {amount}",
    "@treasuryBankLabel": {
        "description": "Saldo em contas bancárias",
        "placeholders": {"amount": {"type": "String"}}
    },
    "treasuryFormulaExplanation": "Fórmula: Disponível + A Receber - A Pagar",
    "@treasuryFormulaExplanation": {"description": "Legenda explicativa do cálculo de previsão"},
    "treasuryFutureCommitmentsTitle": "Compromissos Futuros & Fiados",
    "@treasuryFutureCommitmentsTitle": {"description": "Título do quadro de compromissos futuros"},
    "treasuryCustodyCouriers": "Em custódia de entregadores",
    "@treasuryCustodyCouriers": {"description": "Subtítulo de valores em custódia externa"},
    "treasuryExpenseSegregationTitle": "Segregação de Despesas (Mês)",
    "@treasuryExpenseSegregationTitle": {"description": "Título do quadro de segregação de despesas"},
    "treasuryBusinessExpensesDesc": "Gastos operacionais da atividade",
    "@treasuryBusinessExpensesDesc": {"description": "Descrição de despesas empresariais"},
    "treasuryPersonalWithdrawalsDesc": "Não misturar com contas da empresa",
    "@treasuryPersonalWithdrawalsDesc": {"description": "Descrição de retiradas de sócios"},

    "treasuryCatCapitalContribution": "Aporte de Capital",
    "@treasuryCatCapitalContribution": {"description": "Categoria: Aporte de Capital"},
    "treasuryCatSalesRevenue": "Receita de Vendas",
    "@treasuryCatSalesRevenue": {"description": "Categoria: Receita de Vendas"},
    "treasuryCatCustomerReceipt": "Recebimento de Cliente",
    "@treasuryCatCustomerReceipt": {"description": "Categoria: Recebimento de Cliente"},
    "treasuryCatOtherCredits": "Outros Créditos",
    "@treasuryCatOtherCredits": {"description": "Categoria: Outros Créditos"},
    "treasuryCatPartnerWithdrawal": "Retirada de Sócios / Pró-labore",
    "@treasuryCatPartnerWithdrawal": {"description": "Categoria: Retirada de Sócios / Pró-labore"},
    "treasuryCatSupplierPayment": "Pagamento Fornecedor",
    "@treasuryCatSupplierPayment": {"description": "Categoria: Pagamento Fornecedor"},
    "treasuryCatElectricity": "Energia Elétrica",
    "@treasuryCatElectricity": {"description": "Categoria: Energia Elétrica"},
    "treasuryCatRent": "Aluguel",
    "@treasuryCatRent": {"description": "Categoria: Aluguel"},
    "treasuryCatFreightFuel": "Frete / Combustível",
    "@treasuryCatFreightFuel": {"description": "Categoria: Frete / Combustível"},
    "treasuryCatMaintenance": "Manutenção",
    "@treasuryCatMaintenance": {"description": "Categoria: Manutenção"},
    "treasuryCatOtherExpenses": "Outras Despesas",
    "@treasuryCatOtherExpenses": {"description": "Categoria: Outras Despesas"},

    "treasuryMethodPix": "PIX",
    "@treasuryMethodPix": {"description": "Método de pagamento: PIX"},
    "treasuryMethodCash": "Dinheiro",
    "@treasuryMethodCash": {"description": "Método de pagamento: Dinheiro"},
    "treasuryMethodTransfer": "Transferência",
    "@treasuryMethodTransfer": {"description": "Método de pagamento: Transferência"},
    "treasuryMethodCard": "Cartão",
    "@treasuryMethodCard": {"description": "Método de pagamento: Cartão"},
    "treasuryMethodOther": "Outro",
    "@treasuryMethodOther": {"description": "Método de pagamento: Outro"},

    # 8. Receivables
    "receivablesBasketsPrefix": "Cestas: {summary}",
    "@receivablesBasketsPrefix": {
        "description": "Resumo de cestas do recebível",
        "placeholders": {"summary": {"type": "String"}}
    }
}

count_added = 0
for k, v in new_entries.items():
    if k not in arb:
        arb[k] = v
        count_added += 1

print(f"Added {count_added} new entries to {arb_path}")

with open(arb_path, "w", encoding="utf-8") as f:
    json.dump(arb, f, ensure_ascii=False, indent=2)

print("Saved successfully.")
