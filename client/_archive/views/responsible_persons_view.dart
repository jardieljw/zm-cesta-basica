import 'package:flutter/material.dart';
import '../models/dispatch.dart';
import '../services/dispatch_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/api_error_mapper.dart';

class ResponsiblePersonsView extends StatefulWidget {
  const ResponsiblePersonsView({super.key});

  @override
  State<ResponsiblePersonsView> createState() => _ResponsiblePersonsViewState();
}

class _ResponsiblePersonsViewState extends State<ResponsiblePersonsView> {
  final DispatchService _dispatchService = DispatchService();

  List<ResponsiblePerson> _persons = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _activeFilter = true;

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _dispatchService.getResponsiblePersons(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _activeFilter,
      );
      setState(() {
        _persons = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  Future<void> _openPersonForm({ResponsiblePerson? person}) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: person?.name ?? '');
    final phoneCtrl = TextEditingController(text: person?.phone ?? '');
    final notesCtrl = TextEditingController(text: person?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? dialogError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(person == null ? l10n.responsiblePersonNew : l10n.responsiblePersonEdit),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(dialogError!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: '${l10n.responsiblePersonName} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return l10n.commonRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.responsiblePersonPhone,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.responsiblePersonNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });
                        try {
                          if (person == null) {
                            await _dispatchService.createResponsiblePerson(
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            );
                          } else {
                            await _dispatchService.updateResponsiblePerson(
                              person.id,
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            );
                          }
                          if (ctx.mounted) {
                            Navigator.pop(ctx, true);
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                          });
                        }
                      },
                child: Text(l10n.commonSave),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.responsiblePersonSavedSuccess)),
      );
      _loadPersons();
    }
  }

  Future<void> _viewCustody(ResponsiblePerson person) async {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<ResponsiblePersonCustody>(
          future: _dispatchService.getResponsiblePersonCustody(person.id),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ApiErrorMapper.toLocalizedMessage(snapshot.error, l10n),
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.commonClose),
                    ),
                  ],
                ),
              );
            }

            final custody = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.inventory_2, color: Colors.blue.shade800),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.responsiblePersonCustodyTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              custody.responsiblePersonName,
                              style: const TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: custody.totalCustodyBaskets > 0 ? Colors.amber.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: custody.totalCustodyBaskets > 0 ? Colors.amber.shade300 : Colors.green.shade300,
                      ),
                    ),
                    child: Text(
                      l10n.responsiblePersonTotalInCustody(custody.totalCustodyBaskets),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: custody.totalCustodyBaskets > 0 ? Colors.amber.shade900 : Colors.green.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (custody.baskets.isEmpty || custody.totalCustodyBaskets == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          l10n.responsiblePersonNoCustody,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: custody.baskets.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final item = custody.baskets[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.basketTypeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.balance} ${l10n.commonUnit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _togglePersonActive(ResponsiblePerson person) async {
    final l10n = context.l10n;
    try {
      await _dispatchService.updateResponsiblePerson(
        person.id,
        isActive: !person.isActive,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.responsiblePersonSavedSuccess)),
        );
        _loadPersons();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorMapper.toLocalizedMessage(e, l10n))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.responsiblePersonsTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: Text(l10n.responsiblePersonNew),
        onPressed: () => _openPersonForm(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPersons,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.commonSearch,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        _searchQuery = val.trim();
                        _loadPersons();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(_activeFilter == true ? l10n.responsiblePersonActive : l10n.commonFilter),
                    selected: _activeFilter != null,
                    onSelected: (val) {
                      setState(() {
                        if (_activeFilter == true) {
                          _activeFilter = null;
                        } else {
                          _activeFilter = true;
                        }
                      });
                      _loadPersons();
                    },
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800))),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _persons.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.responsiblePersonsEmpty,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _persons.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final person = _persons[i];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: person.isActive ? Colors.blue.shade100 : Colors.grey.shade300,
                                  child: Icon(
                                    Icons.person,
                                    color: person.isActive ? Colors.blue.shade800 : Colors.grey.shade700,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        person.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: person.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        person.isActive ? l10n.responsiblePersonActive : l10n.responsiblePersonInactive,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: person.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (person.phone != null && person.phone!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: Colors.black45),
                                          const SizedBox(width: 4),
                                          Text(person.phone!, style: const TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ],
                                    if (person.notes != null && person.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        person.notes!,
                                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'custody') {
                                      _viewCustody(person);
                                    } else if (val == 'edit') {
                                      _openPersonForm(person: person);
                                    } else if (val == 'toggle') {
                                      _togglePersonActive(person);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'custody',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.inventory, size: 18, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text(l10n.responsiblePersonCustodyTitle),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit, size: 18),
                                          const SizedBox(width: 8),
                                          Text(l10n.commonEdit),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(
                                            person.isActive ? Icons.block : Icons.check_circle,
                                            size: 18,
                                            color: person.isActive ? Colors.red : Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(person.isActive ? l10n.responsiblePersonInactive : l10n.responsiblePersonActive),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
