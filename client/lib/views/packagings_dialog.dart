import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../l10n/l10n_extension.dart';

class PackagingsDialog extends StatefulWidget {
  final Product product;
  const PackagingsDialog({super.key, required this.product});

  @override
  State<PackagingsDialog> createState() => _PackagingsDialogState();
}

class _PackagingsDialogState extends State<PackagingsDialog> {
  final ProductService _service = ProductService();
  List<ProductPackaging> _packagings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackagings();
  }

  Future<void> _loadPackagings() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getPackagings(widget.product.id);
      setState(() {
        _packagings = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.packagingDialogLoadError(e.toString()))),
        );
      }
    }
  }

  void _showAddPackagingDialog() {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.packagingDialogNewTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.packagingDialogNameLabel,
                    hintText: l10n.packagingDialogNameHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.packagingDialogQtyLabel(widget.product.baseUnit),
                    hintText: l10n.packagingDialogQtyHint,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(l10n.packagingDialogDefaultSwitch),
                  value: isDefault,
                  onChanged: (val) => setDialogState(() => isDefault = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (name.isEmpty || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.packagingDialogValidation)),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _service.createPackaging(widget.product.id, {
                    'name': name,
                    'quantity_in_base_units': qty,
                    'is_default': isDefault,
                    'is_active': true,
                  });
                  _loadPackagings();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.packagingDialogSaveError(e.toString()))),
                    );
                  }
                }
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.packagingsTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.packagingProductSubtitle(widget.product.name, widget.product.baseUnit),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            _isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                : _packagings.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.packagingEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _packagings.length,
                          itemBuilder: (context, index) {
                            final p = _packagings[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  p.isDefault ? Icons.star : Icons.inventory_2_outlined,
                                  color: p.isDefault ? Colors.amber.shade800 : Colors.blueGrey,
                                ),
                                title: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: p.isActive ? null : TextDecoration.lineThrough,
                                    color: p.isActive ? null : Colors.black45,
                                  ),
                                ),
                                subtitle: Text(
                                  l10n.packagingFactorLabel(
                                    p.quantityInBaseUnits,
                                    widget.product.baseUnit,
                                    p.isDefault ? l10n.packagingDefaultTag : '',
                                  ),
                                ),
                                trailing: p.isActive
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: l10n.packagingInactivateTooltip,
                                        onPressed: () async {
                                          await _service.inactivatePackaging(p.id);
                                          _loadPackagings();
                                        },
                                      )
                                    : Chip(label: Text(l10n.productInactive, style: const TextStyle(fontSize: 11))),
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.packagingAddButton),
              onPressed: _showAddPackagingDialog,
            ),
          ],
        ),
      ),
    );
  }
}
