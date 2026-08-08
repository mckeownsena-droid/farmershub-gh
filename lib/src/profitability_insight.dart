import 'profitability.dart';

class ProfitabilityInsight {
  final String headline;
  final String message;
  final bool isWarning;

  const ProfitabilityInsight({
    required this.headline,
    required this.message,
    required this.isWarning,
  });
}

ProfitabilityInsight buildProfitabilityInsight(
  ProfitabilitySnapshot snapshot,
  String yieldUnit,
) {
  switch (snapshot.sellingPriceStatus) {
    case SellingPriceStatus.aboveBreakEven:
      return ProfitabilityInsight(
        headline: 'Target price is above break-even',
        message: snapshot.recommendation(yieldUnit),
        isWarning: false,
      );
    case SellingPriceStatus.atBreakEven:
      return ProfitabilityInsight(
        headline: 'Target price is at break-even',
        message: snapshot.recommendation(yieldUnit),
        isWarning: true,
      );
    case SellingPriceStatus.belowBreakEven:
      return ProfitabilityInsight(
        headline: 'Possible loss at this selling price',
        message: snapshot.recommendation(yieldUnit),
        isWarning: true,
      );
    case SellingPriceStatus.insufficientData:
      return ProfitabilityInsight(
        headline: 'More farm data needed',
        message: snapshot.recommendation(yieldUnit),
        isWarning: false,
      );
  }
}
