import 'package:flutter/material.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/product.dart';

/// Edits one assembly's composition, never a catalog recipe.
class AssemblyCompositionEditor extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<Product> products;
  final bool enabled;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const AssemblyCompositionEditor({
    super.key,
    required this.items,
    required this.products,
    required this.enabled,
    required this.onChanged,
  });

  Map<String, dynamic> _item(Product product) => {
        'product_id': product.id,
        'product_name': product.name,
        'product_base_unit': product.baseUnit,
        'quantity_in_base_units': 0,
        'section': product.category,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void update(int index, Map<String, dynamic> item) {
      final next = items.map((e) => Map<String, dynamic>.from(e)).toList();
      next[index] = item;
      onChanged(next);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.assemblyCustomItemsHelp),
      const SizedBox(height: 12),
      for (var index = 0; index < items.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                          'assembly-product-$index-${items[index]['product_id']}'),
                      initialValue: items[index]['product_id'] as String,
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: l10n.assemblyProduct,
                          border: const OutlineInputBorder()),
                      items: [
                        if (!products
                            .any((p) => p.id == items[index]['product_id']))
                          DropdownMenuItem(
                            value: items[index]['product_id'] as String,
                            child: Text(
                                items[index]['product_name'] as String? ??
                                    l10n.assemblyProduct),
                          ),
                        for (final product in products.where((p) =>
                            p.id == items[index]['product_id'] ||
                            !items.any((it) => it['product_id'] == p.id)))
                          DropdownMenuItem(
                              value: product.id,
                              child: Text(product.name,
                                  overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: !enabled
                          ? null
                          : (id) {
                              if (id == null ||
                                  id == items[index]['product_id']) {
                                return;
                              }
                              // A replacement can have a different base unit: require a new quantity.
                              update(
                                  index,
                                  _item(
                                      products.firstWhere((p) => p.id == id)));
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey(
                          'assembly-ingredient-$index-${items[index]['product_id']}'),
                      initialValue:
                          (items[index]['quantity_in_base_units'] as int) > 0
                              ? items[index]['quantity_in_base_units']
                                  .toString()
                              : '',
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.assemblyQuantityPerBasket,
                        suffixText:
                            items[index]['product_base_unit'] as String? ?? '',
                        helperText: l10n.assemblyBaseUnitsHelp,
                        helperMaxLines: 3,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (int.tryParse(value?.trim() ?? '') ?? 0) > 0
                              ? null
                              : l10n.saleQuantityMustBePositive,
                      onChanged: (value) => update(index, {
                        ...items[index],
                        'quantity_in_base_units':
                            int.tryParse(value.trim()) ?? 0,
                      }),
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: !enabled
                              ? null
                              : () => onChanged([...items]..removeAt(index)),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: Text(l10n.assemblyRemoveProduct),
                        )),
                  ]),
            ),
          ),
        ),
      OutlinedButton.icon(
        onPressed: !enabled ||
                products
                    .every((p) => items.any((it) => it['product_id'] == p.id))
            ? null
            : () async {
                var search = '';
                final selected = await showDialog<Product>(
                    context: context,
                    builder: (dialogContext) => StatefulBuilder(
                          builder: (context, setDialogState) => AlertDialog(
                            title: Text(l10n.assemblyAddProduct),
                            content: SizedBox(
                                width: 480,
                                height: 340,
                                child: Column(children: [
                                  TextField(
                                    decoration: InputDecoration(
                                        labelText: l10n.commonSearch,
                                        prefixIcon: const Icon(Icons.search)),
                                    onChanged: (value) => setDialogState(() =>
                                        search = value.trim().toLowerCase()),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                      child: ListView(children: [
                                    for (final product in products.where((p) =>
                                        !items.any(
                                            (it) => it['product_id'] == p.id) &&
                                        p.name.toLowerCase().contains(search)))
                                      ListTile(
                                          title: Text(product.name),
                                          subtitle: Text(product.baseUnit),
                                          onTap: () => Navigator.pop(
                                              dialogContext, product)),
                                  ])),
                                ])),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: Text(l10n.commonCancel))
                            ],
                          ),
                        ));
                if (selected != null && context.mounted) {
                  onChanged([...items, _item(selected)]);
                }
              },
        icon: const Icon(Icons.add),
        label: Text(l10n.assemblyAddProduct),
      ),
      if (items.isEmpty) Text(l10n.assemblyCustomItemsRequired),
    ]);
  }
}
