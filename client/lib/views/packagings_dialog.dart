import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

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
          SnackBar(content: Text('Erro ao carregar embalagens: $e')),
        );
      }
    }
  }

  void _showAddPackagingDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Embalagem Comercial'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Embalagem *',
                    hintText: 'Ex: Fardo c/ 10 un, Caixa c/ 12',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantidade na Unidade Base * (${widget.product.baseUnit})',
                    hintText: 'Ex: 10, 5000',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Embalagem Padrao de Compra'),
                  value: isDefault,
                  onChanged: (val) => setDialogState(() => isDefault = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (name.isEmpty || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe nome e quantidade maior que 0.')),
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
                      SnackBar(content: Text('Falha ao cadastrar: $e')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        'Embalagens Comerciais',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.product.name} (Base: ${widget.product.baseUnit})',
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
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Nenhuma embalagem comercial cadastrada. O estoque sera movimentado diretamente na unidade base.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
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
                                  'Fator: ${p.quantityInBaseUnits} ${widget.product.baseUnit} ${p.isDefault ? "• (Padrao)" : ""}',
                                ),
                                trailing: p.isActive
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'Inativar',
                                        onPressed: () async {
                                          await _service.inactivatePackaging(p.id);
                                          _loadPackagings();
                                        },
                                      )
                                    : const Chip(label: Text('Inativo', style: TextStyle(fontSize: 11))),
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Embalagem'),
              onPressed: _showAddPackagingDialog,
            ),
          ],
        ),
      ),
    );
  }
}
