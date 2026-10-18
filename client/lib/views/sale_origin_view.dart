import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/l10n_extension.dart';
import '../models/sale.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../widgets/shared/financial_surface.dart';
import '../widgets/shared/approved_app_style.dart';

/// Read-only inspection of the sale that created a receivable. The caller
/// supplies the same origin-bound service used by the financial journey.
class SaleOriginView extends StatefulWidget {
  final String saleId;
  final int saleNumber;
  final Future<Sale> Function() load;
  const SaleOriginView({
    super.key,
    required this.saleId,
    required this.saleNumber,
    required this.load,
  });
  @override
  State<SaleOriginView> createState() => _SaleOriginViewState();
}

class _SaleOriginViewState extends State<SaleOriginView> {
  Sale? _sale;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sale = await widget.load();
      if (sale.id != widget.saleId || sale.saleNumber != widget.saleNumber) {
        throw ApiException(statusCode: 0, message: 'Unexpected sale origin');
      }
      if (mounted) setState(() => _sale = sale);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = ApiErrorMapper.toLocalizedMessage(error, context.l10n),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, sale = _sale;
    return FinancialJourneyTheme(
      child: ApprovedPage(
        title: l.receiptFlowSaleRef(widget.saleNumber),
        body: SizedBox.expand(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: FinancialSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _error != null
                              ? [
                                  Text(l.receiptFlowOriginUnavailable),
                                  Text(_error!),
                                  TextButton(
                                    onPressed: _load,
                                    child: Text(l.commonRefresh),
                                  ),
                                ]
                              : [
                                  if (sale?.customerName != null)
                                    Text(
                                      sale!.customerName!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  Text(l.receiptFlowOriginHelp),
                                  const SizedBox(height: 20),
                                  Text(l.receiptFlowSaleTotal),
                                  Text(
                                    AppFormatters.formatCurrency(
                                      sale!.totalAmountCents,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    l.receiptFlowSaleDate(
                                      AppFormatters.formatDate(sale.saleDate),
                                    ),
                                  ),
                                  Text(
                                    sale.paymentMode == 'CREDIT_TERM'
                                        ? l.salePaymentModeCredit
                                        : l.salePaymentMode,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(l.saleItemsSection),
                                  for (final item in sale.items) ...[
                                    const Divider(),
                                    Text(
                                      l.receiptFlowSaleItem(
                                        item.quantity,
                                        item.basketTypeName ??
                                            l.receiptFlowBasketFallback(
                                              item.basketTypeId,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.formatCurrency(
                                        item.totalCents,
                                      ),
                                    ),
                                  ],
                                  if (sale.notes?.isNotEmpty == true) ...[
                                    const SizedBox(height: 20),
                                    Text(sale.notes!),
                                  ],
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
