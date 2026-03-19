import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/income_source.dart';

class PaymentCard extends StatelessWidget {
  final MonthlyPaymentStatus status;
  final VoidCallback? onTogglePaid;
  final VoidCallback? onTap;
  final Map<int, IncomeSource>? sourcesMap;

  const PaymentCard({
    super.key,
    required this.status,
    this.onTogglePaid,
    this.onTap,
    this.sourcesMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payment = status.payment;
    final color = payment.displayColor;
    final formatter = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  payment.category.icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Title and due date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: status.isPaid
                            ? TextDecoration.lineThrough
                            : null,
                        color: status.isPaid
                            ? theme.colorScheme.onSurface.withOpacity(0.5)
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Due on day ${payment.dueDay}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status.isOverdue && !status.isPaid) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          payment.category.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Income source badge
                        if (status.isPaid &&
                            status.incomeSourceId != null &&
                            sourcesMap != null &&
                            sourcesMap![status.incomeSourceId] != null) ...[
                          const SizedBox(width: 6),
                          Builder(builder: (ctx) {
                            final src =
                                sourcesMap![status.incomeSourceId]!;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: src.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(src.icon,
                                      size: 10, color: src.color),
                                  const SizedBox(width: 3),
                                  Text(src.name,
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: src.color,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount and paid toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(payment.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: status.isPaid
                          ? theme.colorScheme.onSurface.withOpacity(0.5)
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTogglePaid?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.isPaid
                            ? Colors.green.withOpacity(0.15)
                            : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: status.isPaid
                              ? Colors.green
                              : theme.colorScheme.primary.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status.isPaid
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color: status.isPaid
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status.isPaid ? 'Paid' : 'Mark Paid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: status.isPaid
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
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

class BillListCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onToggleActive;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BillListCard({
    super.key,
    required this.payment,
    this.onToggleActive,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = payment.displayColor;
    final formatter = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: payment.isActive
                      ? color.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  payment.category.icon,
                  color: payment.isActive ? color : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            payment.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: payment.isActive
                                  ? null
                                  : theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!payment.isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${payment.category.displayName} · Due day ${payment.dueDay}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(payment.amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: payment.isActive
                          ? theme.colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment.isRecurring ? 'Monthly' : 'One-time',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
                color: theme.colorScheme.surfaceVariant,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          payment.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(payment.isActive ? 'Deactivate' : 'Activate'),
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
                            style:
                                TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'toggle':
                      onToggleActive?.call();
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
        ),
      ),
    );
  }
}
