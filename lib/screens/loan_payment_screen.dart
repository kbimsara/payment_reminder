import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/loan.dart';
import '../models/loan_payment_month.dart';
import '../models/income_source.dart';
import '../widgets/source_picker_dialog.dart';

class LoanPaymentScreen extends StatefulWidget {
  final Loan loan;

  const LoanPaymentScreen({super.key, required this.loan});

  @override
  State<LoanPaymentScreen> createState() => _LoanPaymentScreenState();
}

class _LoanPaymentScreenState extends State<LoanPaymentScreen> {
  final _db = DatabaseHelper();
  Map<String, LoanPaymentMonth> _paymentMap = {};
  Map<int, IncomeSource> _sourcesMap = {};
  bool _isLoading = true;

  final _monthFmt = DateFormat('MMM');
  final _fullMonthFmt = DateFormat('MMMM yyyy');
  final _paidDateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final records = await _db.getLoanPaymentMonths(widget.loan.id!);
    final sources = await _db.getActiveIncomeSources();
    if (mounted) {
      setState(() {
        _paymentMap = {
          for (final r in records) '${r.year}-${r.month}': r,
        };
        _sourcesMap = {for (final s in sources) s.id!: s};
        _isLoading = false;
      });
    }
  }

  // Generate every month from loan start → end
  List<DateTime> get _allMonths {
    final result = <DateTime>[];
    var current = DateTime(
        widget.loan.startDate.year, widget.loan.startDate.month, 1);
    final end =
        DateTime(widget.loan.endDate.year, widget.loan.endDate.month, 1);
    while (!current.isAfter(end)) {
      result.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return result;
  }

  // Group months by year
  Map<int, List<DateTime>> get _groupedByYear {
    final map = <int, List<DateTime>>{};
    for (final m in _allMonths) {
      map.putIfAbsent(m.year, () => []).add(m);
    }
    return map;
  }

  int get _paidCount =>
      _paymentMap.values.where((r) => r.isPaid).length;

  Future<void> _toggleMonth(DateTime date) async {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);

    if (date.isAfter(currentMonthStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot mark future months as paid'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final key = '${date.year}-${date.month}';
    final current = _paymentMap[key];
    final newIsPaid = !(current?.isPaid ?? false);

    if (newIsPaid) {
      // Ask which income source
      final sourceId = await showSourcePickerDialog(
        context: context,
        itemTitle: widget.loan.title,
        itemAmount: 'LKR ${widget.loan.monthlyAmount.toStringAsFixed(0)}',
        itemIcon: Icons.account_balance_outlined,
        itemColor: Theme.of(context).colorScheme.primary,
      );
      if (sourceId == null) return; // user cancelled
      await _db.toggleLoanMonthPaid(
        loanId: widget.loan.id!,
        year: date.year,
        month: date.month,
        isPaid: true,
        incomeSourceId: sourceId,
      );
    } else {
      await _db.toggleLoanMonthPaid(
        loanId: widget.loan.id!,
        year: date.year,
        month: date.month,
        isPaid: false,
      );
    }

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loan = widget.loan;
    final grouped = _groupedByYear;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loan.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              loan.lenderName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary card
                _buildSummaryCard(theme, loan),
                // Month list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        for (final entry in grouped.entries) ...[
                          // Year header
                          _buildYearHeader(theme, entry.key, entry.value),
                          // Month tiles
                          for (final date in entry.value)
                            _buildMonthTile(theme, date, loan),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Summary Card ─────────────────────────────────────
  Widget _buildSummaryCard(ThemeData theme, Loan loan) {
    final total = loan.totalMonths;
    final paid = _paidCount;
    final remaining = total - paid;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final isComplete = paid >= total;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryChip(
                label: 'Paid',
                value: '$paid months',
                color: Colors.green,
                theme: theme,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Remaining',
                value: '$remaining months',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Monthly',
                value: 'LKR ${loan.monthlyAmount.toStringAsFixed(0)}',
                color: theme.colorScheme.secondary,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors.green : theme.colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LKR ${(loan.monthlyAmount * paid).toStringAsFixed(0)} paid',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isComplete
                      ? Colors.green
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Year Header ──────────────────────────────────────
  Widget _buildYearHeader(
      ThemeData theme, int year, List<DateTime> months) {
    final paidInYear = months.where((d) {
      final k = '${d.year}-${d.month}';
      return _paymentMap[k]?.isPaid ?? false;
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$year',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '$paidInYear / ${months.length} paid',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ─── Month Tile ───────────────────────────────────────
  Widget _buildMonthTile(ThemeData theme, DateTime date, Loan loan) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final isFuture = date.isAfter(currentMonthStart);
    final isCurrent =
        date.year == now.year && date.month == now.month;

    final key = '${date.year}-${date.month}';
    final record = _paymentMap[key];
    final isPaid = record?.isPaid ?? false;
    final paidDate = record?.paidDate;
    final paidSource = record?.incomeSourceId != null
        ? _sourcesMap[record!.incomeSourceId!]
        : null;

    // Determine colours & labels
    Color accent;
    IconData statusIcon;
    String statusLabel;

    if (isPaid) {
      accent = Colors.green;
      statusIcon = Icons.check_circle;
      statusLabel = paidDate != null
          ? 'Paid on ${_paidDateFmt.format(paidDate)}'
          : 'Paid';
    } else if (isFuture) {
      accent = theme.colorScheme.onSurface.withOpacity(0.3);
      statusIcon = Icons.schedule_outlined;
      statusLabel = 'Upcoming';
    } else if (isCurrent) {
      accent = theme.colorScheme.primary;
      statusIcon = Icons.radio_button_unchecked;
      statusLabel = 'Due now';
    } else {
      accent = theme.colorScheme.error;
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = 'Unpaid';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: isFuture ? null : () => _toggleMonth(date),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Month badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrent && !isPaid
                      ? Border.all(
                          color: theme.colorScheme.primary, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _monthFmt.format(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    Text(
                      date.year.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: accent.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Month info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _fullMonthFmt.format(date),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isFuture
                                ? theme.colorScheme.onSurface
                                    .withOpacity(0.35)
                                : null,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NOW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(statusIcon, size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accent,
                            fontWeight: isPaid ? FontWeight.w500 : null,
                          ),
                        ),
                      ],
                    ),
                    // Income source badge when paid
                    if (isPaid && paidSource != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: paidSource.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(paidSource.icon,
                                size: 10, color: paidSource.color),
                            const SizedBox(width: 3),
                            Text(
                              paidSource.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: paidSource.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Amount + toggle button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LKR ${loan.monthlyAmount.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isFuture
                          ? theme.colorScheme.onSurface.withOpacity(0.3)
                          : isPaid
                              ? Colors.green
                              : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!isFuture)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green.withOpacity(0.12)
                            : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPaid
                              ? Colors.green.withOpacity(0.4)
                              : theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 12,
                            color: isPaid
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPaid ? 'Paid' : 'Mark Paid',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isPaid
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
