import 'package:flutter/material.dart';

import 'profitability.dart';
import 'profitability_insight.dart';

class ProfitabilityInsightCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double acreage;
  final double expectedYield;
  final double expectedSellingPrice;
  final String yieldUnit;

  const ProfitabilityInsightCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.acreage,
    required this.expectedYield,
    required this.expectedSellingPrice,
    required this.yieldUnit,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = ProfitabilitySnapshot(
      income: income,
      expenses: expenses,
      acreage: acreage,
      expectedYield: expectedYield,
      expectedSellingPrice: expectedSellingPrice,
    );
    final insight = buildProfitabilityInsight(snapshot, yieldUnit);
    final scheme = Theme.of(context).colorScheme;
    final accent = insight.isWarning ? scheme.error : scheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  insight.isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.lightbulb_outline,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.headline,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.message),
            if (snapshot.expectedRevenue > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Projected profit: GH₵${snapshot.projectedProfit.toStringAsFixed(2)} • Projected margin: ${snapshot.projectedMarginPercent.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
