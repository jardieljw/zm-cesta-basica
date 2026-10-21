"""Shared, conservative facts for card CSV/PDF. Never infer economic purpose."""
import re
import unicodedata


def normalized(text):
    return ''.join(c for c in unicodedata.normalize('NFD', text.upper())
                   if not unicodedata.combining(c)).strip()


def installment_facts(description):
    # A bare 3/10 can be a date. Require a label or the bank's terminal separator.
    matches = list(re.finditer(
        r'(?:\bPARCELA\s*|\bPARC\.?\s*|\s-\s*)([0-9]{1,4})\s*/\s*([0-9]{1,4})(?=\s*$)',
        description, re.I))
    if not matches:
        return {}
    current, total = map(int, matches[-1].groups())
    if not 1 <= current <= total <= 1000:
        raise ValueError('installment_number')
    return {'installment_number': current, 'total_installments': total}


def card_role(description, amount):
    text = normalized(description)
    if re.match(r'^(?:PAGAMENTO (?:RECEBIDO|EFETUADO|DA FATURA)|PAGAMENTOS EFETUADOS)\b', text):
        return 'PAYMENT' if amount < 0 else 'UNKNOWN'
    if re.match(r'^(?:ESTORNO|CREDITO|REEMBOLSO)\b', text):
        return 'CREDIT' if amount < 0 else 'UNKNOWN'
    if re.match(r'^(?:JUROS|IOF|ENCARGOS|MULTA|TARIFA|ANUIDADE)\b', text):
        return 'CHARGE' if amount > 0 else 'UNKNOWN'
    if re.match(r'^(?:SALDO ANTERIOR|FATURA ANTERIOR)\b', text):
        return 'PREVIOUS_BALANCE' if amount > 0 else 'UNKNOWN'
    if re.match(r'^(?:TOTAL|SUBTOTAL|PAGAMENTO MINIMO|OFERTA)\b', text):
        return 'UNKNOWN'
    return 'PURCHASE' if amount > 0 else 'UNKNOWN'


def control_kind(description):
    text = normalized(description)
    if re.match(r'^(?:PAGAMENTO MINIMO|VALOR MINIMO)\b', text):
        return 'MINIMUM'
    if re.match(r'^(?:OFERTA|PARCELAMENTO DA FATURA|OPCOES DE PARCELAMENTO|QUITACAO ANTECIPADA)\b', text):
        return 'OFFER'
    if re.match(r'^(?:TOTAL A PAGAR|TOTAL DA FATURA|TOTAL DA SUA FATURA|TOTAL DESTA FATURA)\b', text):
        return 'TOTAL'
    if re.match(r'^(?:SUBTOTAL|TOTAL DE COMPRAS|TOTAL GERAL)\b', text):
        return 'SUBTOTAL'
    return None


def normalize_card_data(data):
    inferred = installment_facts(data['description'])
    if inferred and data.get('installment_number') is not None:
        if any(data.get(k) != v for k, v in inferred.items()):
            raise ValueError('installment_number')
    else:
        data.update(inferred)
    role = card_role(data['description'], data['amount_cents'])
    kind = {
        'PURCHASE': 'PURCHASE', 'PAYMENT': 'BILL_PAYMENT', 'CREDIT': 'REFUND',
        'CHARGE': 'FEE',
    }.get(role, 'OTHER')
    text = normalized(data['description'])
    if role == 'CHARGE':
        kind = 'INTEREST' if text.startswith('JUROS') else 'TAX' if text.startswith('IOF') else 'FEE'
    data['transaction_kind'] = kind
    return role
