class FinancialBucket {
  final String id;
  final String name;
  final double income;
  final double expenses;

  const FinancialBucket({
    required this.id,
    required this.name,
    required this.income,
    required this.expenses,
  });

  double get netProfit => income - expenses;
  double get marginPercent => income > 0 ? (netProfit / income) * 100 : 0;
}

class ReportSummary {
  final double totalIncome;
  final double totalExpenses;
  final List<FinancialBucket> farms;
  final List<FinancialBucket> crops;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.farms,
    required this.crops,
  });

  double get netProfit => totalIncome - totalExpenses;
  double get marginPercent => totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;

  FinancialBucket? get bestFarm {
    if (farms.isEmpty) return null;
    return farms.reduce((a, b) => b.netProfit > a.netProfit ? b : a);
  }

  FinancialBucket? get bestCrop {
    if (crops.isEmpty) return null;
    return crops.reduce((a, b) => b.netProfit > a.netProfit ? b : a);
  }
}

ReportSummary buildReportSummary(List<Map<String, dynamic>> transactions) {
  double totalIncome = 0;
  double totalExpenses = 0;
  final farmTotals = <String, _MutableBucket>{};
  final cropTotals = <String, _MutableBucket>{};

  for (final transaction in transactions) {
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final type = (transaction['type'] ?? '').toString();
    final isIncome = type == 'Income';
    final isExpense = type == 'Expense';
    if (!isIncome && !isExpense) continue;

    if (isIncome) {
      totalIncome += amount;
    } else {
      totalExpenses += amount;
    }

    final farmId = (transaction['farm_id'] ?? '').toString();
    final farmName = (transaction['farm_name'] ?? '').toString();
    if (farmId.isNotEmpty || farmName.isNotEmpty) {
      final key = farmId.isNotEmpty ? farmId : farmName;
      final bucket = farmTotals.putIfAbsent(key, () => _MutableBucket(key, farmName.isEmpty ? 'Farm' : farmName));
      if (isIncome) {
        bucket.income += amount;
      } else {
        bucket.expenses += amount;
      }
    }

    final cropId = (transaction['crop_id'] ?? '').toString();
    final cropName = (transaction['crop_name'] ?? '').toString();
    if (cropId.isNotEmpty || cropName.isNotEmpty) {
      final key = cropId.isNotEmpty ? cropId : cropName;
      final bucket = cropTotals.putIfAbsent(key, () => _MutableBucket(key, cropName.isEmpty ? 'Crop' : cropName));
      if (isIncome) {
        bucket.income += amount;
      } else {
        bucket.expenses += amount;
      }
    }
  }

  List<FinancialBucket> freeze(Map<String, _MutableBucket> source) {
    final result = source.values
        .map((x) => FinancialBucket(id: x.id, name: x.name, income: x.income, expenses: x.expenses))
        .toList();
    result.sort((a, b) => b.netProfit.compareTo(a.netProfit));
    return result;
  }

  return ReportSummary(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    farms: freeze(farmTotals),
    crops: freeze(cropTotals),
  );
}

class _MutableBucket {
  final String id;
  final String name;
  double income = 0;
  double expenses = 0;

  _MutableBucket(this.id, this.name);
}
