import 'package:farmershub_gh/src/profitability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfitabilitySnapshot', () {
    test('calculates profit, cost per acre and break-even price', () {
      const result = ProfitabilitySnapshot(
        income: 7200,
        expenses: 4850,
        acreage: 3,
        expectedYield: 40,
        expectedSellingPrice: 180,
      );

      expect(result.netProfit, 2350);
      expect(result.profitPerAcre, closeTo(783.3333, 0.001));
      expect(result.costPerAcre, closeTo(1616.6667, 0.001));
      expect(result.breakEvenPrice, 121.25);
      expect(result.expectedRevenue, 7200);
      expect(result.projectedProfit, 2350);
      expect(result.status, ProfitabilityStatus.profitable);
      expect(result.sellingPriceStatus, SellingPriceStatus.aboveBreakEven);
    });

    test('flags expected selling price below break-even', () {
      const result = ProfitabilitySnapshot(
        income: 0,
        expenses: 5000,
        acreage: 2,
        expectedYield: 25,
        expectedSellingPrice: 150,
      );

      expect(result.breakEvenPrice, 200);
      expect(result.projectedProfit, -1250);
      expect(result.sellingPriceStatus, SellingPriceStatus.belowBreakEven);
      expect(result.recommendation('bags'), contains('may result in a loss'));
    });

    test('handles missing yield without division errors', () {
      const result = ProfitabilitySnapshot(
        income: 0,
        expenses: 1000,
        acreage: 1,
        expectedYield: 0,
        expectedSellingPrice: 100,
      );

      expect(result.breakEvenPrice, 0);
      expect(result.sellingPriceStatus, SellingPriceStatus.insufficientData);
      expect(result.recommendation('bags'), contains('expected yield'));
    });
  });
}
