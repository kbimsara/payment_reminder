import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LoanCard({
    super.key,
    required this.loan,
    this.onMarkPaid,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM d, yyyy');

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (loan.isCompleted) {
      statusColor = Colors.green;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (loan.isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = '${loan.daysUntilEnd}d left';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = theme.colorScheme.secondary;
      statusText = '${loan.remainingMonths}mo left';
      statusIcon = Icons.schedule;
    }

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 13,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loan.lenderName,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      size: 20,
                    ),
                    color: theme.colorScheme.surfaceVariant,
                    itemBuilder: (context) => [
                      if (!loan.isCompleted)
                        PopupMenuItem(
                          value: 'paid',
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Mark Month Paid'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'edit',
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(
                                    color: theme.colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'paid':
                          onMarkPaid?.call();
                          break;
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loan.paidMonths} / ${loan.totalMonths} months paid',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${(loan.progressPercentage * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: loan.progressPercentage,
                      backgroundColor:
                          theme.colorScheme.onSurface.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Amount info row
              Row(
                children: [
                  _AmountChip(
                    label: 'Monthly',
                    value: currencyFormatter.format(loan.monthlyAmount),
                    color: theme.colorScheme.primary,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _AmountChip(
                    label: 'Remaining',
                    value: currencyFormatter.format(loan.remainingAmount),
                    color: statusColor,
                    theme: theme,
                  ),
                  const Spacer(),
                  if (loan.interestRate > 0)
                    _AmountChip(
                      label: 'Rate',
                      value: '${loan.interestRate.toStringAsFixed(1)}%',
                      color: Colors.orange,
                      theme: theme,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Date row
              Row(
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${dateFormatter.format(loan.startDate)} — ${dateFormatter.format(loan.endDate)}',
                    style: theme.textTheme.bodySmall,
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

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
