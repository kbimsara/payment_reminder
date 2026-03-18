import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/loan.dart';

class AddLoanScreen extends StatefulWidget {
  final Loan? loan;

  const AddLoanScreen({super.key, this.loan});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _lenderController;
  late TextEditingController _totalAmountController;
  late TextEditingController _monthlyAmountController;
  late TextEditingController _interestRateController;
  late TextEditingController _notesController;
  late DateTime _startDate;
  late DateTime _endDate;
  late int _paidMonths;

  bool get _isEditing => widget.loan != null;
  final _dateFormatter = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    _titleController = TextEditingController(text: l?.title ?? '');
    _lenderController = TextEditingController(text: l?.lenderName ?? '');
    _totalAmountController =
        TextEditingController(text: l?.totalAmount.toStringAsFixed(2) ?? '');
    _monthlyAmountController =
        TextEditingController(text: l?.monthlyAmount.toStringAsFixed(2) ?? '');
    _interestRateController = TextEditingController(
        text: l?.interestRate != null && l!.interestRate > 0
            ? l.interestRate.toStringAsFixed(2)
            : '');
    _notesController = TextEditingController(text: l?.notes ?? '');
    _startDate = l?.startDate ?? DateTime.now();
    _endDate = l?.endDate ??
        DateTime(DateTime.now().year + 1, DateTime.now().month,
            DateTime.now().day);
    _paidMonths = l?.paidMonths ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lenderController.dispose();
    _totalAmountController.dispose();
    _monthlyAmountController.dispose();
    _interestRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = DateTime(
              _startDate.year + 1, _startDate.month, _startDate.day);
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _autoCalculateTotalAmount() {
    final monthly = double.tryParse(_monthlyAmountController.text.trim());
    if (monthly != null && monthly > 0) {
      final tempLoan = Loan(
        title: '',
        lenderName: '',
        totalAmount: 0,
        monthlyAmount: monthly,
        startDate: _startDate,
        endDate: _endDate,
      );
      final total = monthly * tempLoan.totalMonths;
      _totalAmountController.text = total.toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_endDate.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final loan = Loan(
        id: widget.loan?.id,
        title: _titleController.text.trim(),
        lenderName: _lenderController.text.trim(),
        totalAmount: double.parse(_totalAmountController.text.trim()),
        monthlyAmount: double.parse(_monthlyAmountController.text.trim()),
        startDate: _startDate,
        endDate: _endDate,
        paidMonths: _paidMonths,
        interestRate: double.tryParse(_interestRateController.text.trim()) ?? 0.0,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await _db.updateLoan(loan);
      } else {
        await _db.insertLoan(loan);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving loan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  int get _computedTotalMonths {
    final months = (_endDate.year - _startDate.year) * 12 +
        (_endDate.month - _startDate.month);
    return months <= 0 ? 1 : months;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Loan' : 'Add Loan'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Loan name
            _SectionLabel(label: 'Loan Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Car Loan, Home Mortgage',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a loan name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Lender name
            _SectionLabel(label: 'Lender / Bank Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lenderController,
              decoration: const InputDecoration(
                hintText: 'e.g. Chase Bank, Credit Union',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter lender name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Date range
            _SectionLabel(label: 'Loan Period'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: _selectStartDate,
                    dateFormatter: _dateFormatter,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'End Date',
                    date: _endDate,
                    onTap: _selectEndDate,
                    dateFormatter: _dateFormatter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: $_computedTotalMonths months',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Financial details
            _SectionLabel(label: 'Financial Details'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _monthlyAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Payment',
                      prefixIcon: Icon(Icons.payments_outlined),
                      prefixText: '\$',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => _autoCalculateTotalAmount(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      final val = double.tryParse(v.trim());
                      if (val == null || val <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _totalAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Total Amount',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      prefixText: '\$',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      final val = double.tryParse(v.trim());
                      if (val == null || val <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Interest rate
            TextFormField(
              controller: _interestRateController,
              decoration: const InputDecoration(
                labelText: 'Annual Interest Rate (optional)',
                hintText: 'e.g. 5.5',
                prefixIcon: Icon(Icons.percent),
                suffixText: '%',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 24),

            // Paid months (for existing loans being added)
            if (_isEditing) ...[
              _SectionLabel(label: 'Months Already Paid'),
              const SizedBox(height: 8),
              _PaidMonthsSelector(
                paidMonths: _paidMonths,
                totalMonths: _computedTotalMonths,
                onChanged: (v) => setState(() => _paidMonths = v),
              ),
              const SizedBox(height: 16),
            ] else ...[
              _SectionLabel(label: 'Months Already Paid (if any)'),
              const SizedBox(height: 8),
              _PaidMonthsSelector(
                paidMonths: _paidMonths,
                totalMonths: _computedTotalMonths,
                onChanged: (v) => setState(() => _paidMonths = v),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            _SectionLabel(label: 'Notes (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this loan...',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isEditing ? 'Update Loan' : 'Add Loan'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final DateFormat dateFormatter;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3E3E3E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8E8E8E),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateFormatter.format(date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidMonthsSelector extends StatelessWidget {
  final int paidMonths;
  final int totalMonths;
  final ValueChanged<int> onChanged;

  const _PaidMonthsSelector({
    required this.paidMonths,
    required this.totalMonths,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3E3E3E)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: paidMonths > 0
                    ? () => onChanged(paidMonths - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$paidMonths',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'of $totalMonths months paid',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: paidMonths < totalMonths
                    ? () => onChanged(paidMonths + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalMonths > 0 ? paidMonths / totalMonths : 0,
              backgroundColor:
                  theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
