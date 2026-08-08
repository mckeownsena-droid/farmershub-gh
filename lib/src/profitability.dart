class ProfitabilitySnapshot {
  final double income;
  final double expenses;
  final double acreage;
  final double expectedYield;
  final double expectedSellingPrice;

  const ProfitabilitySnapshot({
    required this.income,
    required this.expenses,
    required this.acreage,
    required this.expectedYield,
    required this.expectedSellingPrice,
  });

  double get netProfit => income - expenses;
  double get profitPerAcre => acreage > 0 ? netProfit / acreage : 0;
  double get costPerAcre => acreage > 0 ? expenses / acreage : 0;
  double get breakEvenPrice => expectedYield > 0 ? expenses / expectedYield : 0;
  double get expectedRevenue => expectedYield * expectedSellingPrice;
  double get projectedProfit => expectedRevenue - expenses;
  double get marginPercent => income > 0 ? (netProfit / income) * 100 : 0;
  double get projectedMarginPercent => expectedRevenue > 0 ? (projectedProfit / expectedRevenue) * 100 : 0;

  ProfitabilityStatus get status {
    if (expenses <= 0 && income <= 0) return ProfitabilityStatus.noData;
    if (netProfit > 0) return ProfitabilityStatus.profitable;
    if (netProfit == 0 && income > 0) return ProfitabilityStatus.breakEven;
    return ProfitabilityStatus.loss;
  }

  SellingPriceStatus get sellingPriceStatus {
    if (expectedYield <= 0 || expectedSellingPrice <= 0 || expenses <= 0) {
      return SellingPriceStatus.insufficientData;
    }
    if (expectedSellingPrice > breakEvenPrice) return SellingPriceStatus.aboveBreakEven;
    if (expectedSellingPrice == breakEvenPrice) return SellingPriceStatus.atBreakEven;
    return SellingPriceStatus.belowBreakEven;
  }

  String recommendation(String yieldUnit) {
    switch (sellingPriceStatus) {
      case SellingPriceStatus.aboveBreakEven:
        return 'Your expected selling price is above the current break-even price. Keep recording all crop costs so this estimate stays accurate.';
      case SellingPriceStatus.atBreakEven:
        return 'Your expected selling price is currently at break-even. Any additional cost could move this crop into a loss.';
      case SellingPriceStatus.belowBreakEven:
        return 'Your expected selling price is below the current break-even price. At the recorded cost and expected yield, selling at this price may result in a loss.';
      case SellingPriceStatus.insufficientData:
        if (expectedYield <= 0) {
          return 'Add an expected yield in $yieldUnit to calculate the minimum selling price needed to cover recorded costs.';
        }
        if (expectedSellingPrice <= 0) {
          return 'Add an expected selling price per $yieldUnit to compare your target price with the crop break-even price.';
        }
        return 'Record crop expenses to calculate break-even price and profitability guidance.';
    }
  }
}

enum ProfitabilityStatus { noData, profitable, breakEven, loss }

enum SellingPriceStatus {
  insufficientData,
  aboveBreakEven,
  atBreakEven,
  belowBreakEven,
}
