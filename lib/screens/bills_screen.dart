import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';
import '../widgets/payment_card.dart';
import 'add_bill_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _db = DatabaseHelper();
  List<Payment> _payments = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = _showInactive
          ? await _db.getAllPayments()
          : await _db.getActivePayments();
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToAddBill({Payment? payment}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBillScreen(payment: payment),
      ),
    );
    if (result == true) await _loadPayments();
  }

  Future<void> _toggleActive(Payment payment) async {
    await _db.togglePaymentActive(payment.id!, !payment.isActive);
    await _loadPayments();
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirmed = await _showDeleteDialog(payment.title);
    if (confirmed == true) {
      await _db.deletePayment(payment.id!);
      await _loadPayments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${payment.title} deleted'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
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
        title: const Text('Delete Bill'),
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

  Map<BillCategory, List<Payment>> get _groupedPayments {
    final grouped = <BillCategory, List<Payment>>{};
    for (final payment in _payments) {
      grouped.putIfAbsent(payment.category, () => []).add(payment);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupedPayments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          Row(
            children: [
              Text(
                'Show all',
                style: theme.textTheme.bodySmall,
              ),
              Switch(
                value: _showInactive,
                onChanged: (v) {
                  setState(() => _showInactive = v);
                  _loadPayments();
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddBill(),
        icon: const Icon(Icons.add),
        label: const Text('Add Bill'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      // Stats row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _StatsRow(payments: _payments),
                      ),
                      // Categories
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Icon(
                                entry.key.icon,
                                size: 16,
                                color: entry.key.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key.displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: entry.key.color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${entry.value.length})',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        for (final payment in entry.value)
                          BillListCard(
                            payment: payment,
                            onToggleActive: () => _toggleActive(payment),
                            onEdit: () =>
                                _navigateToAddBill(payment: payment),
                            onDelete: () => _deletePayment(payment),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: 24),
            Text(
              'No bills yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first recurring bill by tapping the button below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddBill(),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Bill'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<Payment> payments;

  const _StatsRow({required this.payments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = payments.where((p) => p.isActive).length;
    final totalAmount = payments
        .where((p) => p.isActive)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Active Bills',
            value: activeCount.toString(),
            color: theme.colorScheme.primary,
            theme: theme,
          ),
          const VerticalDivider(width: 32),
          _StatItem(
            label: 'Monthly Total',
            value: '\$${totalAmount.toStringAsFixed(0)}',
            color: theme.colorScheme.secondary,
            theme: theme,
          ),
          const VerticalDivider(width: 32),
          _StatItem(
            label: 'Total Bills',
            value: payments.length.toString(),
            color: Colors.grey,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
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
      ),
    );
  }
}
