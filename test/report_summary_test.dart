import 'package:flutter_test/flutter_test.dart';
import 'package:farmershub_gh/src/report_summary.dart';

void main() {
  test('aggregates overall, farm and crop profitability', () {
    final summary = buildReportSummary([
      {
        'type': 'Expense',
        'amount': 1000,
        'farm_id': 'farm-a',
        'farm_name': 'A Farm',
        'crop_id': 'maize-a',
        'crop_name': 'Maize',
      },
      {
        'type': 'Income',
        'amount': 1800,
        'farm_id': 'farm-a',
        'farm_name': 'A Farm',
        'crop_id': 'maize-a',
        'crop_name': 'Maize',
      },
      {
        'type': 'Expense',
        'amount': 500,
        'farm_id': 'farm-b',
        'farm_name': 'B Farm',
        'crop_id': 'tomato-b',
        'crop_name': 'Tomato',
      },
      {
        'type': 'Income',
        'amount': 600,
        'farm_id': 'farm-b',
        'farm_name': 'B Farm',
        'crop_id': 'tomato-b',
        'crop_name': 'Tomato',
      },
    ]);

    expect(summary.totalIncome, 2400);
    expect(summary.totalExpenses, 1500);
    expect(summary.netProfit, 900);
    expect(summary.farms.length, 2);
    expect(summary.crops.length, 2);
    expect(summary.bestFarm?.name, 'A Farm');
    expect(summary.bestFarm?.netProfit, 800);
    expect(summary.bestCrop?.name, 'Maize');
    expect(summary.bestCrop?.netProfit, 800);
  });

  test('ignores unsupported transaction types', () {
    final summary = buildReportSummary([
      {'type': 'Adjustment', 'amount': 500},
    ]);

    expect(summary.totalIncome, 0);
    expect(summary.totalExpenses, 0);
    expect(summary.netProfit, 0);
  });
}
