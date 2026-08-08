import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_v4.dart' as v4;
import 'report_summary.dart';

class FarmersHubAppV5 extends StatelessWidget {
  const FarmersHubAppV5({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmersHub GH',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: v4.farmerGreen),
        scaffoldBackgroundColor: v4.pageBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: v4.farmerGreen,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: v4.farmerGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const _AuthGateV5(),
    );
  }
}

class _AuthGateV5 extends StatelessWidget {
  const _AuthGateV5();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null ? const v4.LoginPage() : const _MainShellV5();
      },
    );
  }
}

class _MainShellV5 extends StatefulWidget {
  const _MainShellV5();

  @override
  State<_MainShellV5> createState() => _MainShellV5State();
}

class _MainShellV5State extends State<_MainShellV5> {
  int index = 0;
  final pages = const [
    v4.DashboardPage(),
    EnhancedReportsPage(),
    v4.FarmsPage(),
    v4.ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.agriculture_outlined), label: 'Farms'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class EnhancedReportsPage extends StatelessWidget {
  const EnhancedReportsPage({super.key});

  Widget _moneyCard(String label, double value, {String? subtitle}) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: Text(
          v4.money.format(value),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _bucketCard(FinancialBucket bucket) {
    return Card(
      child: ListTile(
        title: Text(bucket.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          'Income ${v4.money.format(bucket.income)} • Expenses ${v4.money.format(bucket.expenses)}\n'
          'Margin ${bucket.marginPercent.toStringAsFixed(1)}%',
        ),
        isThreeLine: true,
        trailing: Text(
          v4.money.format(bucket.netProfit),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: bucket.netProfit >= 0 ? v4.farmerGreen : Colors.red,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('user_id', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load reports right now.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!.docs.map((doc) => doc.data()).toList();
          final summary = buildReportSummary(transactions);
          final bestFarm = summary.bestFarm;
          final bestCrop = summary.bestCrop;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              const Text(
                'Reports',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const Text('See where your farm is making or losing money.'),
              const SizedBox(height: 14),
              _moneyCard('Total Income', summary.totalIncome),
              _moneyCard('Total Expenses', summary.totalExpenses),
              _moneyCard(
                'Net Profit',
                summary.netProfit,
                subtitle: 'Overall margin ${summary.marginPercent.toStringAsFixed(1)}%',
              ),
              if (bestFarm != null || bestCrop != null) ...[
                const SizedBox(height: 18),
                const Text(
                  'Performance Highlights',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                if (bestFarm != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.agriculture, color: v4.farmerGreen),
                      title: const Text('Best-performing farm'),
                      subtitle: Text(bestFarm.name),
                      trailing: Text(
                        v4.money.format(bestFarm.netProfit),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                if (bestCrop != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.eco, color: v4.farmerGreen),
                      title: const Text('Best-performing crop'),
                      subtitle: Text(bestCrop.name),
                      trailing: Text(
                        v4.money.format(bestCrop.netProfit),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Farm Profitability',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              if (summary.farms.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Link transactions to a farm to see farm-by-farm performance.'),
                )
              else
                ...summary.farms.map(_bucketCard),
              const SizedBox(height: 18),
              const Text(
                'Crop Profitability',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              if (summary.crops.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Link transactions to crops to see crop-by-crop performance.'),
                )
              else
                ...summary.crops.map(_bucketCard),
            ],
          );
        },
      ),
    );
  }
}
