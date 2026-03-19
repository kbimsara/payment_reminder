import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/income_source.dart';
import '../models/income_transaction.dart';
import 'add_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _db = DatabaseHelper();
  late DateTime _currentMonth;

  List<IncomeSource> _sources = [];
  List<IncomeTransaction> _transactions = [];
  Map<int, double> _incomeBySource = {};
  Map<int, double> _spentBySource = {};   // combined: bills + loans per source
  double _totalBillsPaid = 0;
  double _totalLoansPaid = 0;
  bool _isLoading = true;

  final _currencyFmt =
      NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);
  final _monthFmt = DateFormat('MMMM yyyy');
  final _dateFmt = DateFormat('MMM d');

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sources = await _db.getActiveIncomeSources();
      final transactions = await _db.getIncomeTransactionsForMonth(
          _currentMonth.year, _currentMonth.month);
      final incomeBySource = await _db.getIncomeBySourceForMonth(
          _currentMonth.year, _currentMonth.month);
      final billsBySource = await _db.getBillsSpentBySourceForMonth(
          _currentMonth.year, _currentMonth.month);
      final loansBySource = await _db.getLoanSpentBySourceForMonth(
          _currentMonth.year, _currentMonth.month);
      final totalBills = await _db.getTotalBillsPaidForMonth(
          _currentMonth.year, _currentMonth.month);
      final totalLoans = await _db.getTotalLoansPaidForMonth(
          _currentMonth.year, _currentMonth.month);

      // Merge bills + loans spent per source
      final combinedSpent = <int, double>{...billsBySource};
      for (final entry in loansBySource.entries) {
        combinedSpent[entry.key] =
            (combinedSpent[entry.key] ?? 0) + entry.value;
      }

      if (mounted) {
        setState(() {
          _sources = sources;
          _transactions = transactions;
          _incomeBySource = incomeBySource;
          _spentBySource = combinedSpent;
          _totalBillsPaid = totalBills;
          _totalLoansPaid = totalLoans;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalIncome =>
      _incomeBySource.values.fold(0, (a, b) => a + b);

  double get _totalSpent => _totalBillsPaid + _totalLoansPaid;

  double get _balance => _totalIncome - _totalSpent;

  void _prevMonth() {
    setState(() => _currentMonth =
        DateTime(_currentMonth.year, _currentMonth.month - 1));
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month + 1))) {
      setState(() => _currentMonth = next);
      _loadData();
    }
  }

  Future<void> _addIncome() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
    );
    if (result == true) await _loadData();
  }

  Future<void> _editTransaction(IncomeTransaction tx) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => AddIncomeScreen(transaction: tx)),
    );
    if (result == true) await _loadData();
  }

  Future<void> _deleteTransaction(IncomeTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceVariant,
        title: const Text('Delete Transaction'),
        content: Text('Delete "${tx.title}"?'),
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
    if (confirmed == true) {
      await _db.deleteIncomeTransaction(tx.id!);
      await _loadData();
    }
  }

  Future<void> _navigateToManageSources() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageSourcesScreen()),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Manage Sources',
            onPressed: _navigateToManageSources,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addIncome,
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Month navigator
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _prevMonth,
                            style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.surfaceVariant),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                _monthFmt.format(_currentMonth),
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _nextMonth,
                            style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.surfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Summary card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSummaryCard(theme),
                    ),
                  ),

                  // Source breakdown
                  if (_sources.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _sectionHeader(
                          theme, Icons.account_balance_wallet, 'By Source'),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) =>
                            _buildSourceCard(theme, _sources[i]),
                        childCount: _sources.length,
                      ),
                    ),
                  ],

                  // Transactions
                  SliverToBoxAdapter(
                    child: _sectionHeader(
                        theme, Icons.receipt_long, 'Transactions',
                        trailing: _transactions.isEmpty
                            ? null
                            : '${_transactions.length} entries'),
                  ),

                  if (_transactions.isEmpty)
                    SliverToBoxAdapter(
                        child: _emptyTransactions(theme))
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) =>
                            _buildTransactionTile(theme, _transactions[i]),
                        childCount: _transactions.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  // ─── Summary Card ──────────────────────────────────────
  Widget _buildSummaryCard(ThemeData theme) {
    final isPositive = _balance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                label: 'Total Income',
                value: _currencyFmt.format(_totalIncome),
                color: Colors.green,
                theme: theme,
              ),
              _SummaryItem(
                label: 'Total Spent',
                value: '- ${_currencyFmt.format(_totalSpent)}',
                color: theme.colorScheme.error,
                theme: theme,
                align: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF3E3E3E)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Balance',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                _currencyFmt.format(_balance),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : theme.colorScheme.error,
                ),
              ),
            ],
          ),
          if (_totalIncome > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_totalSpent / _totalIncome).clamp(0.0, 1.0),
                backgroundColor:
                    theme.colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _totalSpent > _totalIncome
                      ? theme.colorScheme.error
                      : Colors.green,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${((_totalSpent / _totalIncome) * 100).clamp(0, 100).toStringAsFixed(0)}% of income spent',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Per-source Card ───────────────────────────────────
  Widget _buildSourceCard(ThemeData theme, IncomeSource src) {
    final income = _incomeBySource[src.id] ?? 0;
    final spent = _spentBySource[src.id] ?? 0;
    final balance = income - spent;
    final utilization =
        income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: src.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(src.icon, color: src.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(src.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                // Add income button for this source
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddIncomeScreen(
                            preselectedSourceId: src.id),
                      ),
                    );
                    if (result == true) await _loadData();
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    foregroundColor: src.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniChip(
                    label: 'Income',
                    value: _currencyFmt.format(income),
                    color: Colors.green),
                const SizedBox(width: 8),
                _MiniChip(
                    label: 'Spent',
                    value: '- ${_currencyFmt.format(spent)}',
                    color: theme.colorScheme.error),
                const SizedBox(width: 8),
                _MiniChip(
                    label: 'Balance',
                    value: _currencyFmt.format(balance),
                    color:
                        balance >= 0 ? src.color : theme.colorScheme.error),
              ],
            ),
            if (income > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: utilization,
                  backgroundColor:
                      theme.colorScheme.onSurface.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    utilization > 0.9 ? theme.colorScheme.error : src.color,
                  ),
                  minHeight: 5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Transaction Tile ──────────────────────────────────
  Widget _buildTransactionTile(ThemeData theme, IncomeTransaction tx) {
    final src = _sources.where((s) => s.id == tx.sourceId).firstOrNull;
    final srcColor = src?.color ?? theme.colorScheme.primary;
    final srcIcon = src?.icon ?? Icons.currency_rupee;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _editTransaction(tx),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: srcColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(srcIcon, color: srcColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(src?.name ?? 'Unknown',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: srcColor,
                                fontWeight: FontWeight.w500)),
                        Text(
                          '  ·  ${_dateFmt.format(tx.date)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFmt.format(tx.amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _deleteTransaction(tx),
                    child: Icon(Icons.delete_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────
  Widget _sectionHeader(ThemeData theme, IconData icon, String title,
      {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (trailing != null) ...[
            const Spacer(),
            Text(trailing, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _emptyTransactions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 60,
              color: theme.colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No income recorded',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Add Income" to record your earnings for this month.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  final CrossAxisAlignment align;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: align,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: color, fontWeight: FontWeight.bold)),
        ],
      );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
