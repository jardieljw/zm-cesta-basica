import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_extension.dart';
import '../../services/basket_service.dart';
import '../../views/basket_assemblies_view.dart';
import '../../views/recipe_view.dart';
import '../../views/sales_view.dart';
import '../../views/purchases_view.dart';
import '../../views/inventory_movements_view.dart';
import '../../utils/api_error_mapper.dart';

class CatalogBlockers extends StatefulWidget {
  final List<Map<String, dynamic>> blockers;
  final ApiClient? apiClient;
  const CatalogBlockers({super.key, required this.blockers, this.apiClient});
  @override
  State<CatalogBlockers> createState() => _CatalogBlockersState();
}

class _CatalogBlockersState extends State<CatalogBlockers> {
  bool _opening = false;
  late List<Map<String, dynamic>> _blockers;

  @override
  void initState() {
    super.initState();
    _blockers = widget.blockers.map(Map<String, dynamic>.from).toList();
  }

  @override
  void didUpdateWidget(covariant CatalogBlockers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blockers != widget.blockers) {
      _blockers = widget.blockers.map(Map<String, dynamic>.from).toList();
    }
  }

  Future<void> _open(Map<String, dynamic> blocker) async {
    setState(() => _opening = true);
    try {
      final target = Map<String, dynamic>.from(blocker['target'] as Map? ?? {});
      Widget? page;
      if (target['basket_id'] != null) {
        final basket = await BasketService(
          client: widget.apiClient,
        ).getBasketType(target['basket_id'] as String);
        page = target['recipe_number'] != null
            ? RecipeView(
                basketType: basket,
                apiClient: widget.apiClient,
                initialVersionNumber: target['recipe_number'] as int,
              )
            : BasketAssembliesView(
                basketType: basket,
                apiClient: widget.apiClient,
                focusBatchId: target['batch_id'] as String?,
              );
      } else if (target['sale_id'] != null) {
        page = SalesView(
          apiClient: widget.apiClient,
          initialSaleId: target['sale_id'] as String,
        );
      } else if (target['purchase_id'] != null) {
        page = PurchasesView(
          apiClient: widget.apiClient,
          initialPurchaseId: target['purchase_id'] as String,
        );
      } else if (target['product_id'] != null) {
        page = InventoryMovementsView(
          apiClient: widget.apiClient,
          initialProductId: target['product_id'] as String,
        );
      }
      if (mounted && page != null) {
        final deleted = await Navigator.of(
          context,
        ).push<bool>(MaterialPageRoute<bool>(builder: (_) => page!));
        if (deleted == true && target['purchase_id'] != null && mounted) {
          setState(() {
            _blockers.removeWhere((entry) {
              final entryTarget = entry['target'] as Map? ?? {};
              return entryTarget['purchase_id'] == target['purchase_id'];
            });
          });
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMapper.toLocalizedMessage(error, context.l10n),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.l10n.catalogResolveLinks),
      const SizedBox(height: 12),
      for (final blocker in _blockers)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(blocker['label'] as String),
          trailing: (blocker['target'] as Map? ?? {}).isEmpty
              ? null
              : const Icon(Icons.chevron_right),
          onTap: _opening || (blocker['target'] as Map? ?? {}).isEmpty
              ? null
              : () => _open(blocker),
        ),
      if (_opening) const LinearProgressIndicator(),
    ],
  );
}
