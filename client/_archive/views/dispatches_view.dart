import 'package:flutter/material.dart';
import '../models/dispatch.dart';
import '../services/dispatch_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';
import 'dispatch_form_view.dart';
import 'dispatch_conference_view.dart';

class DispatchesView extends StatefulWidget {
  const DispatchesView({super.key});

  @override
  State<DispatchesView> createState() => _DispatchesViewState();
}

class _DispatchesViewState extends State<DispatchesView> {
  final DispatchService _dispatchService = DispatchService();

  List<StockDispatch> _dispatches = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedStatus;
  String? _selectedResponsiblePersonId;
  List<ResponsiblePerson> _responsiblePersons = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final persons = await _dispatchService.getResponsiblePersons();
      if (mounted) {
        setState(() {
          _responsiblePersons = persons;
        });
      }
    } catch (_) {}
    _loadDispatches();
  }

  Future<void> _loadDispatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _dispatchService.getDispatches(
        responsiblePersonId: _selectedResponsiblePersonId,
        status: _selectedStatus,
      );
      setState(() {
        _dispatches = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelDispatch(StockDispatch dispatch) async {
    final l10n = context.l10n;
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dispatchCancel),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.dispatchCancelConfirm(dispatch.dispatchNumber)),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.dispatchCancelReason} *',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 3) return l10n.commonRequired;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _dispatchService.cancelDispatch(dispatch.id, reasonCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dispatchCancelSuccess)),
        );
        _loadDispatches();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorMapper.toLocalizedMessage(e, l10n))),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.blue.shade700;
      case 'CONCLUDED':
        return Colors.green.shade700;
      case 'PENDING_INVESTIGATION':
        return Colors.orange.shade800;
      case 'CANCELED':
        return Colors.grey.shade600;
      default:
        return Colors.black87;
    }
  }

  String _getStatusText(String status) {
    final l10n = context.l10n;
    switch (status) {
      case 'OPEN':
        return l10n.dispatchStatusOpen;
      case 'CONCLUDED':
        return l10n.dispatchStatusConcluded;
      case 'PENDING_INVESTIGATION':
        return l10n.dispatchStatusPendingInvestigation;
      case 'CANCELED':
        return l10n.dispatchStatusCanceled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dispatchesTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.dispatchNew),
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const DispatchFormView()),
          );
          if (res == true) {
            _loadDispatches();
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadDispatches,
        child: Column(
          children: [
            // Filter Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.commonFilter),
                      selected: _selectedStatus == null && _selectedResponsiblePersonId == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedStatus = null;
                          _selectedResponsiblePersonId = null;
                        });
                        _loadDispatches();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.dispatchStatusOpen),
                      selected: _selectedStatus == 'OPEN',
                      onSelected: (val) {
                        setState(() => _selectedStatus = val ? 'OPEN' : null);
                        _loadDispatches();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.dispatchStatusPendingInvestigation),
                      selected: _selectedStatus == 'PENDING_INVESTIGATION',
                      onSelected: (val) {
                        setState(() => _selectedStatus = val ? 'PENDING_INVESTIGATION' : null);
                        _loadDispatches();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.dispatchStatusConcluded),
                      selected: _selectedStatus == 'CONCLUDED',
                      onSelected: (val) {
                        setState(() => _selectedStatus = val ? 'CONCLUDED' : null);
                        _loadDispatches();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.dispatchStatusCanceled),
                      selected: _selectedStatus == 'CANCELED',
                      onSelected: (val) {
                        setState(() => _selectedStatus = val ? 'CANCELED' : null);
                        _loadDispatches();
                      },
                    ),
                    if (_responsiblePersons.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      DropdownButton<String?>(
                        value: _selectedResponsiblePersonId,
                        hint: Text(l10n.dispatchResponsible),
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.commonFilter),
                          ),
                          ..._responsiblePersons.map((p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(p.name),
                          )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedResponsiblePersonId = val);
                          _loadDispatches();
                        },
                      ),
                    ],
                  ],
                ),
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
                  : _dispatches.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.dispatchesEmpty,
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
                          itemCount: _dispatches.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final d = _dispatches[i];
                            final statusColor = _getStatusColor(d.status);

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DispatchConferenceView(dispatchId: d.id),
                                    ),
                                  );
                                  _loadDispatches();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            l10n.dispatchNumber(d.dispatchNumber),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: statusColor, width: 1),
                                            ),
                                            child: Text(
                                              _getStatusText(d.status),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Text(
                                            d.responsiblePersonName ?? 'N/A',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          const Spacer(),
                                          Text(
                                            AppFormatters.formatDateTime(d.dispatchDate),
                                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${l10n.dispatchTotalBaskets}: ${d.totalItemsQuantity} ${l10n.commonUnit}',
                                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                                          ),
                                          Text(
                                            AppFormatters.formatCurrency(d.totalReferenceAmountCents),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (d.notes != null && d.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          d.notes!,
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                      if (d.status == 'OPEN') ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                                              label: Text(l10n.dispatchCancel, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                              onPressed: () => _cancelDispatch(d),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
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
