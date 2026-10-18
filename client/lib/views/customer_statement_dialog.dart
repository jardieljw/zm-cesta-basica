import '../utils/adaptive_ui_color.dart';
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class CustomerStatementDialog extends StatefulWidget {
  final Customer customer;

  const CustomerStatementDialog({super.key, required this.customer});

  @override
  State<CustomerStatementDialog> createState() =>
      _CustomerStatementDialogState();
}

class _CustomerStatementDialogState extends State<CustomerStatementDialog> {
  final CustomerService _customerService = CustomerService();

  CustomerStatementResponse? _statement;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _customerService.getCustomerStatement(
        widget.customer.id,
      );
      setState(() {
        _statement = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.customerStatementTitle(widget.customer.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else if (_statement != null) ...[
                _buildSummaryCards(context, _statement!),
                const SizedBox(height: 16),
                Text(
                  l10n.receivablePaymentsHistory,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _statement!.entries.isEmpty
                      ? Center(child: Text(l10n.customerStatementEmpty))
                      : ListView.separated(
                          itemCount: _statement!.entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _statement!.entries[index];
                            final isPayment =
                                item.entryType == 'RECEIVABLE_PAYMENT';
                            final isCredit = item.entryType == 'SALE_CREDIT';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isPayment
                                    ? adaptiveUiSurface(
                                        context,
                                        Colors.green.shade100,
                                      )
                                    : (isCredit
                                          ? adaptiveUiSurface(
                                              context,
                                              Colors.orange.shade100,
                                            )
                                          : adaptiveUiSurface(
                                              context,
                                              Colors.blue.shade100,
                                            )),
                                child: Icon(
                                  isPayment
                                      ? Icons.price_check
                                      : (isCredit
                                            ? Icons.hourglass_top
                                            : Icons.shopping_bag),
                                  color: isPayment
                                      ? adaptiveUiText(
                                          context,
                                          Colors.green.shade800,
                                        )
                                      : (isCredit
                                            ? adaptiveUiText(
                                                context,
                                                Colors.orange.shade800,
                                              )
                                            : adaptiveUiText(
                                                context,
                                                Colors.blue.shade800,
                                              )),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                AppFormatters.formatDateTime(item.occurredAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Text(
                                isPayment
                                    ? '- ${AppFormatters.formatCurrency(item.amountCents)}'
                                    : '+ ${AppFormatters.formatCurrency(item.amountCents)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isPayment
                                      ? adaptiveUiText(
                                          context,
                                          Colors.green.shade700,
                                        )
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    CustomerStatementResponse stmt,
  ) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adaptiveUiSurface(context, Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoColumn(
            l10n.customerCurrentDebt,
            AppFormatters.formatCurrency(stmt.currentDebtCents),
            stmt.currentDebtCents > 0
                ? Colors.red.shade700
                : Colors.green.shade700,
          ),
          _buildInfoColumn(
            l10n.customerCreditLimit,
            stmt.creditLimitCents > 0
                ? AppFormatters.formatCurrency(stmt.creditLimitCents)
                : l10n.customerCreditLimitUnlimited,
            Theme.of(context).colorScheme.onSurface,
          ),
          if (stmt.availableCreditCents != null)
            _buildInfoColumn(
              l10n.customerAvailableCredit,
              AppFormatters.formatCurrency(stmt.availableCreditCents!),
              Colors.blue.shade800,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
