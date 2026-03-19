import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/income_source.dart';
import '../models/income_transaction.dart';

class AddIncomeScreen extends StatefulWidget {
  final IncomeTransaction? transaction;
  final int? preselectedSourceId;

  const AddIncomeScreen({
    super.key,
    this.transaction,
    this.preselectedSourceId,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();
  bool _isSaving = false;
  List<IncomeSource> _sources = [];

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _date;
  int? _selectedSourceId;

  bool get _isEditing => widget.transaction != null;
  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
        text: tx?.amount.toStringAsFixed(2) ?? '');
    _notesController = TextEditingController(text: tx?.notes ?? '');
    _date = tx?.date ?? DateTime.now();
    _selectedSourceId = tx?.sourceId ?? widget.preselectedSourceId;
    _loadSources();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    final sources = await _db.getActiveIncomeSources();
    if (mounted) {
      setState(() {
        _sources = sources;
        _selectedSourceId ??=
            sources.isNotEmpty ? sources.first.id : null;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an income source')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final tx = IncomeTransaction(
        id: widget.transaction?.id,
        sourceId: _selectedSourceId!,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        date: _date,
        month: _date.month,
        year: _date.year,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await _db.updateIncomeTransaction(tx);
      } else {
        await _db.insertIncomeTransaction(tx);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Income' : 'Add Income'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Source selector
            _Label('Income Source'),
            const SizedBox(height: 8),
            _SourceGrid(
              sources: _sources,
              selectedId: _selectedSourceId,
              onSelected: (id) => setState(() => _selectedSourceId = id),
            ),
            const SizedBox(height: 24),

            // Title
            _Label('Title / Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. January Salary',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Amount
            _Label('Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: 'LKR ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final val = double.tryParse(v.trim());
                if (val == null || val <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            _Label('Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3E3E3E)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_dateFmt.format(_date),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                    ),
                    Icon(Icons.chevron_right,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            _Label('Notes (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Any additional notes...',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isEditing ? 'Update Income' : 'Add Income'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Manage Income Sources Screen ──────────────────────────
class ManageSourcesScreen extends StatefulWidget {
  const ManageSourcesScreen({super.key});

  @override
  State<ManageSourcesScreen> createState() => _ManageSourcesScreenState();
}

class _ManageSourcesScreenState extends State<ManageSourcesScreen> {
  final _db = DatabaseHelper();
  List<IncomeSource> _sources = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _db.getAllIncomeSources();
    if (mounted) setState(() => _sources = s);
  }

  Future<void> _addOrEdit([IncomeSource? existing]) async {
    final result = await showDialog<IncomeSource>(
      context: context,
      builder: (_) => _SourceFormDialog(source: existing),
    );
    if (result != null) {
      if (existing == null) {
        await _db.insertIncomeSource(result);
      } else {
        await _db.updateIncomeSource(result);
      }
      await _load();
    }
  }

  Future<void> _delete(IncomeSource source) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceVariant,
        title: const Text('Delete Source'),
        content: Text(
            'Delete "${source.name}"? Bills paid from this source will lose their source link.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteIncomeSource(source.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Income Sources')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Add Source'),
      ),
      body: _sources.isEmpty
          ? const Center(child: Text('No income sources'))
          : ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _sources.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final src = _sources[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3E3E3E)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: src.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(src.icon, color: src.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(src.name,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            if (src.isDefault)
                              Text('Built-in',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary)),
                          ],
                        ),
                      ),
                      if (!src.isDefault) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _addOrEdit(src),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error),
                          onPressed: () => _delete(src),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─── Source Form Dialog ────────────────────────────────────
class _SourceFormDialog extends StatefulWidget {
  final IncomeSource? source;
  const _SourceFormDialog({this.source});

  @override
  State<_SourceFormDialog> createState() => _SourceFormDialogState();
}

class _SourceFormDialogState extends State<_SourceFormDialog> {
  late TextEditingController _nameCtrl;
  late String _selectedIcon;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.source?.name ?? '');
    _selectedIcon = widget.source?.iconName ?? 'other';
    _selectedColor =
        widget.source?.colorHex ?? IncomeSource.availableColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surfaceVariant,
      title: Text(
          widget.source == null ? 'Add Income Source' : 'Edit Source'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Source Name',
                hintText: 'e.g. Freelance',
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Icon picker
            Text('Icon', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncomeSource.availableIcons.map((item) {
                final isSelected = _selectedIcon == item['name'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedIcon = item['name']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          IncomeSource.iconDataFromName(item['name']!),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withOpacity(0.5),
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(item['label']!,
                            style: TextStyle(
                                fontSize: 9,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.5))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Color picker
            Text('Color', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: IncomeSource.availableColors.map((hex) {
                final color = Color(
                    int.parse(hex.replaceFirst('#', '0xFF')));
                final isSelected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) return;
            final src = IncomeSource(
              id: widget.source?.id,
              name: _nameCtrl.text.trim(),
              iconName: _selectedIcon,
              colorHex: _selectedColor,
              isDefault: false,
            );
            Navigator.pop(context, src);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Small helpers ─────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      );
}

class _SourceGrid extends StatelessWidget {
  final List<IncomeSource> sources;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const _SourceGrid({
    required this.sources,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sources.isEmpty) {
      return const Text('No income sources available');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sources.map((src) {
        final isSelected = selectedId == src.id;
        return GestureDetector(
          onTap: () => onSelected(src.id!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? src.color.withOpacity(0.2)
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? src.color : const Color(0xFF3E3E3E),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(src.icon,
                    color: isSelected ? src.color : Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  src.name,
                  style: TextStyle(
                    color: isSelected ? src.color : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
