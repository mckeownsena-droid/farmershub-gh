import 'package:flutter_test/flutter_test.dart';
import 'package:farmershub_gh/src/profitability.dart';
import 'package:farmershub_gh/src/profitability_insight.dart';

void main() {
  test('warns when expected selling price is below break-even', () {
    const snapshot = ProfitabilitySnapshot(
      income: 0,
      expenses: 2000,
      acreage: 2,
      expectedYield: 10,
      expectedSellingPrice: 150,
    );

    final insight = buildProfitabilityInsight(snapshot, 'bags');

    expect(insight.isWarning, isTrue);
    expect(insight.headline, 'Possible loss at this selling price');
  });

  test('shows positive insight when target price is above break-even', () {
    const snapshot = ProfitabilitySnapshot(
      income: 0,
      expenses: 2000,
      acreage: 2,
      expectedYield: 10,
      expectedSellingPrice: 250,
    );

    final insight = buildProfitabilityInsight(snapshot, 'bags');

    expect(insight.isWarning, isFalse);
    expect(insight.headline, 'Target price is above break-even');
  });
}
