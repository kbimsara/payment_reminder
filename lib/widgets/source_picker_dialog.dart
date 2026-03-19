import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/income_source.dart';

/// Shows a dialog asking the user to pick an income source before marking
/// a bill or loan as paid. Returns the selected [IncomeSource.id] or null
/// if the user cancels or there are no sources.
Future<int?> showSourcePickerDialog({
  required BuildContext context,
  required String itemTitle,
  required String itemAmount,
  required IconData itemIcon,
  required Color itemColor,
}) async {
  final db = DatabaseHelper();
  final sources = await db.getActiveIncomeSources();
  if (!context.mounted) return null;

  if (sources.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('No income sources found. Add one in the Income tab.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return null;
  }

  int? selected = sources.first.id;

  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setInner) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceVariant,
        title: const Text('Mark as Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(itemIcon, color: itemColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      itemTitle,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    itemAmount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Paid from which income source?',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            ...sources.map((src) => SourceRadioTile(
                  source: src,
                  groupValue: selected,
                  onChanged: (v) => setInner(() => selected = v),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
}

/// A single radio-style tile used inside the source picker dialog.
class SourceRadioTile extends StatelessWidget {
  final IncomeSource source;
  final int? groupValue;
  final ValueChanged<int?> onChanged;

  const SourceRadioTile({
    super.key,
    required this.source,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = groupValue == source.id;
    return GestureDetector(
      onTap: () => onChanged(source.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? source.color.withOpacity(0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? source.color : const Color(0xFF3E3E3E),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(source.icon,
                color: isSelected ? source.color : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                source.name,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? source.color : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: source.color, size: 18),
          ],
        ),
      ),
    );
  }
}
