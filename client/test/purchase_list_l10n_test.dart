import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations_pt.dart';

void main() {
  final l10n = AppLocalizationsPt();

  test('purchaseDetailItems interpola a contagem real de itens', () {
    expect(l10n.purchaseDetailItems(0), 'Itens da Compra (0)');
    expect(l10n.purchaseDetailItems(3), 'Itens da Compra (3)');
  });

  test('purchasePaymentDetailMethod interpola forma e situacao', () {
    final text = l10n.purchasePaymentDetailMethod('PIX', 'Pendente');
    expect(text, contains('PIX'));
    expect(text, contains('Pendente'));
    expect(text, isNot(contains('()')));
  });
}