import 'package:flutter/material.dart';

import '../core/theme.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    this.detail,
    this.positive,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    final color = positive == null
        ? AppTheme.ink
        : positive!
            ? AppTheme.green
            : AppTheme.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 9),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
            if (detail != null) ...[
              const SizedBox(height: 5),
              Text(detail!, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}