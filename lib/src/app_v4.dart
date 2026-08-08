import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const farmerGreen = Color(0xFF2E7D32);
const darkGreen = Color(0xFF1B5E20);
const pageBg = Color(0xFFF5F7F2);
final money = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');

class FarmersHubApp extends StatelessWidget {
  const FarmersHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmersHub GH',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: farmerGreen),
        scaffoldBackgroundColor: pageBg,
        appBarTheme: const AppBarTheme(backgroundColor: farmerGreen, foregroundColor: Colors.white),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(backgroundColor: farmerGreen, foregroundColor: Colors.white),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data == null ? const LoginPage() : const MainShell();
      },
    );
  }
}

String authMessage(FirebaseAuthException e) {
  if (e.code == 'invalid-credential' || e.code == 'wrong-password') return 'Incorrect email or password.';
  if (e.code == 'email-already-in-use') return 'An account already exists with this email.';
  if (e.code == 'weak-password') return 'Choose a stronger password.';
  return e.message ?? 'Unable to complete this request.';
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter your email and password.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (e) {
      setState(() => error = authMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty) {
      setState(() => error = 'Enter your email first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = authMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.eco, size: 72, color: farmerGreen),
                const Text('FarmersHub GH', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: darkGreen)),
                const Text('Know Your Farm. Grow Your Profit.', textAlign: TextAlign.center),
                const SizedBox(height: 30),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 16),
                FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'Signing in...' : 'Login')),
                TextButton(onPressed: resetPassword, child: const Text('Forgot Password?')),
                OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Create Account')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  String? error;

  String normalizePhone(String value) {
    var p = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('0')) p = '+233${p.substring(1)}';
    return p;
  }

  Future<void> createAccount() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Complete your name, email and password.');
      return;
    }
    if (password.text.length < 6) {
      setState(() => error = 'Password must be at least 6 characters.');
      return;
    }
    if (password.text != confirm.text) {
      setState(() => error = 'Passwords do not match.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text);
      await credential.user!.updateDisplayName(name.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'display_name': name.text.trim(),
        'email': email.text.trim(),
        'phone_number': phone.text.trim().isEmpty ? '' : normalizePhone(phone.text.trim()),
        'created_time': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => error = authMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 12),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number (optional)')),
          const SizedBox(height: 12),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 18),
          FilledButton(onPressed: loading ? null : createAccount, child: Text(loading ? 'Creating...' : 'Create Account')),
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [DashboardPage(), ReportsPage(), FarmsPage(), ProfilePage()];

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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('transactions').where('user_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs.toList() ?? [];
          docs.sort((a, b) {
            final aDate = (a.data()['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bDate = (b.data()['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bDate.compareTo(aDate);
          });
          double income = 0;
          double expenses = 0;
          for (final doc in docs) {
            final data = doc.data();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            if (data['type'] == 'Income') {
              income += amount;
            } else if (data['type'] == 'Expense') {
              expenses += amount;
            }
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              const Text('Welcome to FarmersHub GH', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const Text('Track your farm, costs and profit.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70)),
                    Text(money.format(income - expenses), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Income\n${money.format(income)}', style: const TextStyle(color: Colors.white)),
                        Text('Expenses\n${money.format(expenses)}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionPage())), child: const Text('Add Transaction'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFarmPage())), child: const Text('Add Farm'))),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              if (docs.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('No transactions yet.', textAlign: TextAlign.center)))
              else
                ...docs.take(8).map((doc) {
                  final data = doc.data();
                  final isIncome = data['type'] == 'Income';
                  final subtitle = [data['farm_name'], data['crop_name']].where((e) => e != null && e.toString().isNotEmpty).join(' • ');
                  return Card(
                    child: ListTile(
                      title: Text('${data['category'] ?? 'Transaction'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(subtitle),
                      trailing: Text('${isIncome ? '+' : '-'}${money.format((data['amount'] as num?)?.toDouble() ?? 0)}', style: TextStyle(fontWeight: FontWeight.w900, color: isIncome ? farmerGreen : Colors.red)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  Widget reportCard(String label, double value) {
    return Card(child: ListTile(title: Text(label), trailing: Text(money.format(value), style: const TextStyle(fontWeight: FontWeight.w900))));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('transactions').where('user_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          double income = 0;
          double expenses = 0;
          final cropTotals = <String, Map<String, double>>{};
          for (final doc in snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
            final data = doc.data();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            if (data['type'] == 'Income') {
              income += amount;
            } else if (data['type'] == 'Expense') {
              expenses += amount;
            }
            final cropName = (data['crop_name'] ?? '').toString();
            if (cropName.isNotEmpty) {
              cropTotals.putIfAbsent(cropName, () => {'income': 0.0, 'expense': 0.0});
              if (data['type'] == 'Income') {
                cropTotals[cropName]!['income'] = cropTotals[cropName]!['income']! + amount;
              } else if (data['type'] == 'Expense') {
                cropTotals[cropName]!['expense'] = cropTotals[cropName]!['expense']! + amount;
              }
            }
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Reports', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              reportCard('Total Income', income),
              reportCard('Total Expenses', expenses),
              reportCard('Net Profit', income - expenses),
              const SizedBox(height: 20),
              const Text('Crop Profitability', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              if (cropTotals.isEmpty)
                const Padding(padding: EdgeInsets.only(top: 10), child: Text('Link transactions to crops to see crop-by-crop profit.'))
              else
                ...cropTotals.entries.map((entry) {
                  final cropIncome = entry.value['income'] ?? 0;
                  final cropExpense = entry.value['expense'] ?? 0;
                  return Card(
                    child: ListTile(
                      title: Text(entry.key),
                      subtitle: Text('Income ${money.format(cropIncome)} • Expenses ${money.format(cropExpense)}'),
                      trailing: Text(money.format(cropIncome - cropExpense), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class FarmsPage extends StatelessWidget {
  const FarmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('farms').where('user_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          final farms = snapshot.data?.docs ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Farms', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                  FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFarmPage())), child: const Text('Add Farm')),
                ],
              ),
              const SizedBox(height: 12),
              if (farms.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No farms registered yet.', textAlign: TextAlign.center)))
              else
                ...farms.map((farm) {
                  final data = farm.data();
                  final acres = (data['size_acres'] as num?)?.toDouble() ?? 0;
                  return Card(
                    child: ListTile(
                      title: Text('${data['name'] ?? 'Farm'}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text('${data['location'] ?? ''} • ${acres.toStringAsFixed(1)} acres'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CropsPage(farmId: farm.id, farmName: '${data['name'] ?? 'Farm'}'))),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class AddFarmPage extends StatefulWidget {
  const AddFarmPage({super.key});

  @override
  State<AddFarmPage> createState() => _AddFarmPageState();
}

class _AddFarmPageState extends State<AddFarmPage> {
  final name = TextEditingController();
  final location = TextEditingController();
  final size = TextEditingController();
  String type = 'Crop Farming';

  Future<void> save() async {
    final acres = double.tryParse(size.text.trim());
    if (name.text.trim().isEmpty || location.text.trim().isEmpty || acres == null || acres <= 0) return;
    await FirebaseFirestore.instance.collection('farms').add({
      'user_id': FirebaseAuth.instance.currentUser!.uid,
      'name': name.text.trim(),
      'location': location.text.trim(),
      'farm_type': type,
      'size_acres': acres,
      'created_time': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Farm')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Farm Name')),
          const SizedBox(height: 12),
          TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Farm Type'), items: const ['Crop Farming', 'Livestock', 'Poultry', 'Mixed Farming', 'Other'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => type = v ?? type)),
          const SizedBox(height: 12),
          TextField(controller: size, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Farm Size (acres)')),
          const SizedBox(height: 20),
          FilledButton(onPressed: save, child: const Text('Save Farm')),
        ],
      ),
    );
  }
}

class CropsPage extends StatelessWidget {
  final String farmId;
  final String farmName;
  const CropsPage({super.key, required this.farmId, required this.farmName});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: Text('$farmName Crops')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddCropPage(farmId: farmId, farmName: farmName))),
        label: const Text('Add Crop'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('crops').where('user_id', isEqualTo: uid).where('farm_id', isEqualTo: farmId).snapshots(),
        builder: (context, snapshot) {
          final crops = snapshot.data?.docs ?? [];
          if (crops.isEmpty) return const Center(child: Text('No crop records yet.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: crops.map((crop) => CropCard(id: crop.id, data: crop.data())).toList(),
          );
        },
      ),
    );
  }
}

class CropCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const CropCard({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final harvest = (data['expected_harvest_date'] as Timestamp?)?.toDate();
    final acreage = (data['acreage'] as num?)?.toDouble() ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data['crop_name'] ?? 'Crop'}${(data['variety'] ?? '').toString().isEmpty ? '' : ' • ${data['variety']}'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text('${acreage.toStringAsFixed(1)} acres • ${data['status'] ?? 'Growing'}'),
            if (harvest != null) Text('Expected harvest: ${DateFormat('dd MMM yyyy').format(harvest)}'),
            if (((data['expected_yield'] as num?)?.toDouble() ?? 0) > 0) Text('Expected yield: ${data['expected_yield']} ${data['yield_unit'] ?? ''}'),
            const SizedBox(height: 10),
            FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CropProfitPage(cropId: id, crop: data))), child: const Text('View Profitability')),
          ],
        ),
      ),
    );
  }
}

class AddCropPage extends StatefulWidget {
  final String farmId;
  final String farmName;
  const AddCropPage({super.key, required this.farmId, required this.farmName});

  @override
  State<AddCropPage> createState() => _AddCropPageState();
}

class _AddCropPageState extends State<AddCropPage> {
  final cropName = TextEditingController();
  final variety = TextEditingController();
  final acreage = TextEditingController();
  final expectedYield = TextEditingController();
  final sellingPrice = TextEditingController();
  DateTime plantingDate = DateTime.now();
  DateTime harvestDate = DateTime.now().add(const Duration(days: 120));
  String status = 'Growing';
  String unit = 'bags';

  Future<DateTime?> pickDate(DateTime initial) {
    return showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1095)));
  }

  Future<void> save() async {
    final acres = double.tryParse(acreage.text.trim());
    final yieldAmount = double.tryParse(expectedYield.text.trim()) ?? 0;
    final price = double.tryParse(sellingPrice.text.trim()) ?? 0;
    if (cropName.text.trim().isEmpty || acres == null || acres <= 0) return;
    await FirebaseFirestore.instance.collection('crops').add({
      'user_id': FirebaseAuth.instance.currentUser!.uid,
      'farm_id': widget.farmId,
      'farm_name': widget.farmName,
      'crop_name': cropName.text.trim(),
      'variety': variety.text.trim(),
      'acreage': acres,
      'planting_date': Timestamp.fromDate(plantingDate),
      'expected_harvest_date': Timestamp.fromDate(harvestDate),
      'expected_yield': yieldAmount,
      'yield_unit': unit,
      'expected_selling_price': price,
      'status': status,
      'created_time': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Crop')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: cropName, decoration: const InputDecoration(labelText: 'Crop Name')),
          const SizedBox(height: 12),
          TextField(controller: variety, decoration: const InputDecoration(labelText: 'Variety (optional)')),
          const SizedBox(height: 12),
          TextField(controller: acreage, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Acreage')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'Status'), items: const ['Planned', 'Growing', 'Harvested'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => status = v ?? status)),
          const SizedBox(height: 12),
          ListTile(tileColor: Colors.white, title: const Text('Planting Date'), subtitle: Text(DateFormat('dd MMM yyyy').format(plantingDate)), onTap: () async { final d = await pickDate(plantingDate); if (d != null) setState(() => plantingDate = d); }),
          const SizedBox(height: 8),
          ListTile(tileColor: Colors.white, title: const Text('Expected Harvest Date'), subtitle: Text(DateFormat('dd MMM yyyy').format(harvestDate)), onTap: () async { final d = await pickDate(harvestDate); if (d != null) setState(() => harvestDate = d); }),
          const SizedBox(height: 12),
          TextField(controller: expectedYield, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Expected Yield')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: unit, decoration: const InputDecoration(labelText: 'Yield Unit'), items: const ['bags', 'kg', 'tonnes', 'crates', 'units'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => unit = v ?? unit)),
          const SizedBox(height: 12),
          TextField(controller: sellingPrice, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Expected Selling Price per $unit (GH₵)')),
          const SizedBox(height: 20),
          FilledButton(onPressed: save, child: const Text('Save Crop')),
        ],
      ),
    );
  }
}

class CropProfitPage extends StatelessWidget {
  final String cropId;
  final Map<String, dynamic> crop;
  const CropProfitPage({super.key, required this.cropId, required this.crop});

  Widget stat(String label, double value) {
    return Card(child: ListTile(title: Text(label), trailing: Text(money.format(value), style: const TextStyle(fontWeight: FontWeight.w900))));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final acres = (crop['acreage'] as num?)?.toDouble() ?? 0;
    final expectedYield = (crop['expected_yield'] as num?)?.toDouble() ?? 0;
    final expectedPrice = (crop['expected_selling_price'] as num?)?.toDouble() ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text('${crop['crop_name'] ?? 'Crop'} Profitability')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionPage(
          initialFarmId: '${crop['farm_id'] ?? ''}',
          initialFarmName: '${crop['farm_name'] ?? ''}',
          initialCropId: cropId,
          initialCropName: '${crop['crop_name'] ?? ''}',
        ))),
        label: const Text('Add Transaction'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('transactions').where('user_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          double income = 0;
          double expenses = 0;
          for (final doc in snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
            final data = doc.data();
            if (data['crop_id'] != cropId) continue;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            if (data['type'] == 'Income') {
              income += amount;
            } else if (data['type'] == 'Expense') {
              expenses += amount;
            }
          }
          final netProfit = income - expenses;
          final profitPerAcre = acres > 0 ? netProfit / acres : 0.0;
          final breakEven = expectedYield > 0 ? expenses / expectedYield : 0.0;
          final expectedRevenue = expectedYield * expectedPrice;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('${crop['crop_name'] ?? 'Crop'} • ${crop['farm_name'] ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              stat('Income', income),
              stat('Expenses', expenses),
              stat('Net Profit', netProfit),
              stat('Profit per acre', profitPerAcre),
              stat('Break-even price per ${crop['yield_unit'] ?? 'unit'}', breakEven),
              stat('Expected revenue', expectedRevenue),
              const SizedBox(height: 8),
              const Text('Break-even price = recorded crop expenses ÷ expected yield.'),
            ],
          );
        },
      ),
    );
  }
}

class AddTransactionPage extends StatefulWidget {
  final String? initialFarmId;
  final String? initialFarmName;
  final String? initialCropId;
  final String? initialCropName;
  const AddTransactionPage({super.key, this.initialFarmId, this.initialFarmName, this.initialCropId, this.initialCropName});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  String? type;
  String? category;
  String? payment;
  String? farmId;
  String? farmName;
  String? cropId;
  String? cropName;
  final amount = TextEditingController();
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    farmId = widget.initialFarmId;
    farmName = widget.initialFarmName;
    cropId = widget.initialCropId;
    cropName = widget.initialCropName;
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.trim());
    if (type == null || category == null || payment == null || value == null || value <= 0) return;
    await FirebaseFirestore.instance.collection('transactions').add({
      'user_id': FirebaseAuth.instance.currentUser!.uid,
      'farm_id': farmId ?? '',
      'farm_name': farmName ?? '',
      'crop_id': cropId ?? '',
      'crop_name': cropName ?? '',
      'type': type,
      'category': category,
      'amount': value,
      'payment_method': payment,
      'notes': notes.text.trim(),
      'date': Timestamp.fromDate(DateTime.now()),
      'created_time': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('farms').where('user_id', isEqualTo: uid).snapshots(),
        builder: (context, farmSnapshot) {
          final farms = farmSnapshot.data?.docs ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Type'), items: const ['Income', 'Expense'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => type = v)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(initialValue: farmId, decoration: const InputDecoration(labelText: 'Farm (optional)'), items: farms.map((f) => DropdownMenuItem(value: f.id, child: Text('${f.data()['name'] ?? 'Farm'}'))).toList(), onChanged: (v) {
                final matches = farms.where((f) => f.id == v);
                setState(() {
                  farmId = v;
                  farmName = matches.isEmpty ? '' : '${matches.first.data()['name'] ?? ''}';
                  cropId = null;
                  cropName = null;
                });
              }),
              const SizedBox(height: 12),
              if (farmId != null && farmId!.isNotEmpty)
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('crops').where('user_id', isEqualTo: uid).where('farm_id', isEqualTo: farmId).snapshots(),
                  builder: (context, cropSnapshot) {
                    final crops = cropSnapshot.data?.docs ?? [];
                    return DropdownButtonFormField<String>(initialValue: cropId, decoration: const InputDecoration(labelText: 'Crop (optional)'), items: crops.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.data()['crop_name'] ?? 'Crop'}'))).toList(), onChanged: (v) {
                      final matches = crops.where((c) => c.id == v);
                      setState(() {
                        cropId = v;
                        cropName = matches.isEmpty ? '' : '${matches.first.data()['crop_name'] ?? ''}';
                      });
                    });
                  },
                ),
              if (farmId != null && farmId!.isNotEmpty) const SizedBox(height: 12),
              DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Category'), items: const ['Sales', 'Seeds', 'Fertilizer', 'Labour', 'Feed', 'Transport', 'Equipment', 'Fuel', 'Harvest', 'Other'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => category = v)),
              const SizedBox(height: 12),
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (GH₵)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(initialValue: payment, decoration: const InputDecoration(labelText: 'Payment Method'), items: const ['Cash', 'Mobile Money', 'Bank Transfer'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => payment = v)),
              const SizedBox(height: 12),
              TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 20),
              FilledButton(onPressed: save, child: const Text('Save Transaction')),
            ],
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Profile', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              const CircleAvatar(radius: 44, child: Icon(Icons.person, size: 48)),
              const SizedBox(height: 12),
              Text('${data['display_name'] ?? user.displayName ?? 'Farmer'}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('${data['email'] ?? user.email ?? ''}', textAlign: TextAlign.center),
              if ('${data['phone_number'] ?? ''}'.isNotEmpty) Text('${data['phone_number']}', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton.icon(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout), label: const Text('Logout')),
            ],
          );
        },
      ),
    );
  }
}
