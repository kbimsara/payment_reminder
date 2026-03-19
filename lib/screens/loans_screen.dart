import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/loan.dart';
import '../widgets/loan_card.dart';
import 'add_loan_screen.dart';
import 'loan_payment_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  List<Loan> _allLoans = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    try {
      final loans = await _db.getAllLoans();
      if (mounted) {
        setState(() {
          _allLoans = loans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Loan> get _activeLoans => _allLoans.where((l) => !l.isCompleted).toList();
  List<Loan> get _completedLoans =>
      _allLoans.where((l) => l.isCompleted).toList();

  Future<void> _navigateToAddLoan({Loan? loan}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddLoanScreen(loan: loan),
      ),
    );
    if (result == true) await _loadLoans();
  }

  Future<void> _markMonthPaid(Loan loan) async {
    final now = DateTime.now();
    await _db.toggleLoanMonthPaid(
      loanId: loan.id!,
      year: now.year,
      month: now.month,
      isPaid: true,
    );
    await _loadLoans();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${now.year}/${now.month} marked as paid for ${loan.title}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }

  Future<void> _navigateToPayments(Loan loan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanPaymentScreen(loan: loan),
      ),
    );
    await _loadLoans();
  }

  Future<void> _deleteLoan(Loan loan) async {
    final confirmed = await _showDeleteDialog(loan.title);
    if (confirmed == true) {
      await _db.deleteLoan(loan.id!);
      await _loadLoans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loan.title} deleted'),
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteDialog(String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        title: const Text('Delete Loan'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_activeLoans.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Completed'),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_completedLoans.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddLoan(),
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLoanList(
                  loans: _activeLoans,
                  emptyMessage: 'No active loans',
                  emptyIcon: Icons.account_balance_outlined,
                  emptySubtitle:
                      'Add a loan to track your monthly payments and progress.',
                  showStats: true,
                ),
                _buildLoanList(
                  loans: _completedLoans,
                  emptyMessage: 'No completed loans',
                  emptyIcon: Icons.check_circle_outline,
                  emptySubtitle: 'Completed loans will appear here.',
                  showStats: false,
                ),
              ],
            ),
    );
  }

  Widget _buildLoanList({
    required List<Loan> loans,
    required String emptyMessage,
    required IconData emptyIcon,
    required String emptySubtitle,
    required bool showStats,
  }) {
    final theme = Theme.of(context);

    if (loans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 80,
                color: theme.colorScheme.onSurface.withOpacity(0.15),
              ),
              const SizedBox(height: 24),
              Text(
                emptyMessage,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                emptySubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                textAlign: TextAlign.center,
              ),
              if (showStats) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddLoan(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Loan'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          if (showStats) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _LoanSummaryCard(loans: loans),
            ),
          ],
          for (final loan in loans)
            LoanCard(
              loan: loan,
              onViewPayments: () => _navigateToPayments(loan),
              onMarkPaid: () => _markMonthPaid(loan),
              onEdit: () => _navigateToAddLoan(loan: loan),
              onDelete: () => _deleteLoan(loan),
            ),
        ],
      ),
    );
  }
}

class _LoanSummaryCard extends StatelessWidget {
  final List<Loan> loans;

  const _LoanSummaryCard({required this.loans});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter =
        NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
    final totalRemaining =
        loans.fold<double>(0, (sum, l) => sum + l.remainingAmount);
    final monthlyTotal =
        loans.fold<double>(0, (sum, l) => sum + l.monthlyAmount);
    final expiringSoon = loans.where((l) => l.isExpiringSoon).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total Remaining',
                  value: currencyFormatter.format(totalRemaining),
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              const VerticalDivider(width: 24),
              Expanded(
                child: _SummaryItem(
                  label: 'Monthly Due',
                  value: currencyFormatter.format(monthlyTotal),
                  color: theme.colorScheme.secondary,
                  theme: theme,
                ),
              ),
              if (expiringSoon > 0) ...[
                const VerticalDivider(width: 24),
                Expanded(
                  child: _SummaryItem(
                    label: 'Expiring Soon',
                    value: expiringSoon.toString(),
                    color: Colors.orange,
                    theme: theme,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
