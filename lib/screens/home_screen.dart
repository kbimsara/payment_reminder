import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';
import '../models/loan.dart';
import '../widgets/payment_card.dart';
import '../widgets/loan_card.dart';
import 'bills_screen.dart';
import 'loans_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const _HomeTab(),
      const BillsScreen(),
      const LoansScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            activeIcon: Icon(Icons.account_balance),
            label: 'Loans',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _db = DatabaseHelper();
  List<MonthlyPaymentStatus> _paymentStatuses = [];
  List<Loan> _activeLoans = [];
  Map<String, double> _summary = {};
  bool _isLoading = true;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statuses = await _db.getMonthlyPaymentStatuses(
        _currentMonth.year,
        _currentMonth.month,
      );
      final loans = await _db.getActiveLoans();
      final summary = await _db.getMonthSummary(
        _currentMonth.year,
        _currentMonth.month,
      );
      if (mounted) {
        setState(() {
          _paymentStatuses = statuses;
          _activeLoans = loans.where((l) => l.isCurrentMonthDue).toList();
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePaymentPaid(MonthlyPaymentStatus status) async {
    await _db.setPaymentPaidStatus(
      paymentId: status.payment.id!,
      year: _currentMonth.year,
      month: _currentMonth.month,
      isPaid: !status.isPaid,
    );
    await _loadData();
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadData();
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final next =
        DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month + 2))) {
      setState(() {
        _currentMonth = next;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthTitle = DateFormat('MMMM yyyy').format(_currentMonth);
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final totalDue = _summary['totalDue'] ?? 0;
    final totalPaid = _summary['totalPaid'] ?? 0;
    final remaining = _summary['remaining'] ?? 0;
    final paidCount = _paymentStatuses.where((s) => s.isPaid).length;
    final totalCount = _paymentStatuses.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Month navigation header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _goToPreviousMonth,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.surfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                monthTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _goToNextMonth,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.surfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Summary card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SummaryCard(
                        totalDue: totalDue,
                        totalPaid: totalPaid,
                        remaining: remaining,
                        paidCount: paidCount,
                        totalCount: totalCount,
                        currencyFormatter: currencyFormatter,
                      ),
                    ),
                  ),
                  // Bills section
                  if (_paymentStatuses.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Bills',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$paidCount / $totalCount paid',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final status = _paymentStatuses[index];
                          return PaymentCard(
                            status: status,
                            onTogglePaid: () => _togglePaymentPaid(status),
                          );
                        },
                        childCount: _paymentStatuses.length,
                      ),
                    ),
                  ] else
                    SliverToBoxAdapter(
                      child: _EmptyBillsHint(),
                    ),
                  // Loans section
                  if (_activeLoans.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Active Loans This Month',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final loan = _activeLoans[index];
                          return LoanCard(
                            loan: loan,
                            onMarkPaid: () async {
                              await _db.incrementLoanPaidMonths(loan.id!);
                              await _loadData();
                            },
                          );
                        },
                        childCount: _activeLoans.length,
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalDue;
  final double totalPaid;
  final double remaining;
  final int paidCount;
  final int totalCount;
  final NumberFormat currencyFormatter;

  const _SummaryCard({
    required this.totalDue,
    required this.totalPaid,
    required this.remaining,
    required this.paidCount,
    required this.totalCount,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalDue > 0 ? totalPaid / totalDue : 0.0;
    final progressClamped = progress.clamp(0.0, 1.0);

    Color progressColor;
    if (progressClamped >= 1.0) {
      progressColor = Colors.green;
    } else if (progressClamped >= 0.5) {
      progressColor = theme.colorScheme.secondary;
    } else {
      progressColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Due',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    currencyFormatter.format(totalDue),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Paid',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    currencyFormatter.format(totalPaid),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressClamped,
              backgroundColor:
                  theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining: ${currencyFormatter.format(remaining)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$paidCount / $totalCount bills paid',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBillsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No bills for this month',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to the Bills tab to add your recurring payments.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
