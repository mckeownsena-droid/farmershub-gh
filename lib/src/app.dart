import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const farmerGreen = Color(0xFF2E7D32);
const darkGreen = Color(0xFF1B5E20);
const pageBg = Color(0xFFF5F7F2);

class FarmersHubApp extends StatelessWidget {
  const FarmersHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmersHub GH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: farmerGreen),
        scaffoldBackgroundColor: pageBg,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Unable to sign in.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.eco, size: 84, color: farmerGreen),
                  const SizedBox(height: 16),
                  const Text('FarmersHub GH', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: darkGreen)),
                  const Text('Know Your Farm. Grow Your Profit.', textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                  const Text('Welcome back!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Sign in to continue'),
                  const SizedBox(height: 24),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
                  if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : login,
                    style: FilledButton.styleFrom(backgroundColor: farmerGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (email.text.trim().isEmpty) {
                        setState(() => error = 'Enter your email address first.');
                        return;
                      }
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
                    },
                    child: const Text('Forgot Password?'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                    child: const Text('Create Account'),
                  ),
                ],
              ),
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
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> register() async {
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
        'phone_number': '',
        'photo_url': '',
        'created_time': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Unable to create account.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: farmerGreen, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 14),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 14),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
          const SizedBox(height: 14),
          TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline))),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(onPressed: loading ? null : register, style: FilledButton.styleFrom(backgroundColor: farmerGreen, padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(loading ? 'Creating...' : 'Create Account')),
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
  final pages = const [DashboardPage(), ReportsPage(), CropsPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.grass_outlined), selectedIcon: Icon(Icons.grass), label: 'Crops'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> transactions() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('transactions').where('user_id', isEqualTo: uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: transactions(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs.toList() ?? [];
          docs.sort((a, b) {
            final at = (a.data()['created_time'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bt = (b.data()['created_time'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at);
          });
          double income = 0;
          double expense = 0;
          for (final doc in docs) {
            final d = doc.data();
            final amount = (d['amount'] as num?)?.toDouble() ?? 0;
            if (d['type'] == 'Income') income += amount;
            if (d['type'] == 'Expense') expense += amount;
          }
          final balance = income - expense;
          final money = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
            children: [
              const Text('Welcome to FarmersHub GH', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Track your income, expenses and grow your profit.'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(money.format(balance), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Metric(label: 'Income', value: money.format(income)),
                        _Metric(label: 'Expenses', value: money.format(expense)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Transactions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: darkGreen)),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTransactionPage())),
                    style: FilledButton.styleFrom(backgroundColor: farmerGreen),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const _EmptyTransactions()
              else
                ...docs.take(8).map((doc) => TransactionTile(data: doc.data())),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Column(children: [Icon(Icons.receipt_long_outlined, size: 42, color: farmerGreen), SizedBox(height: 8), Text('No records yet', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('Add your first income or expense to start tracking your farm.', textAlign: TextAlign.center)]),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const TransactionTile({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isIncome = data['type'] == 'Income';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final date = (data['date'] as Timestamp?)?.toDate();
    final money = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: (isIncome ? farmerGreen : Colors.red).withValues(alpha: .1), child: Icon(isIncome ? Icons.south_west : Icons.north_east, color: isIncome ? farmerGreen : Colors.red)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((data['category'] ?? 'Transaction').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('${date == null ? 'Today' : DateFormat('dd MMM yyyy').format(date)} • ${data['type'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ),
          Text('${isIncome ? '+' : '-'}${money.format(amount)}', style: TextStyle(fontWeight: FontWeight.w800, color: isIncome ? farmerGreen : Colors.red)),
        ],
      ),
    );
  }
}

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  String? type;
  String? category;
  final amount = TextEditingController();
  final description = TextEditingController();
  DateTime date = DateTime.now();
  bool saving = false;

  final categories = const ['Seeds', 'Fertilizer', 'Labour', 'Transport', 'Sales', 'Equipment', 'Feed', 'Fuel', 'Harvest', 'Other'];

  Future<void> save() async {
    final value = double.tryParse(amount.text.replaceAll(',', '').trim());
    if (type == null || category == null || value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a type and category, then enter a valid amount.')));
      return;
    }
    setState(() => saving = true);
    await FirebaseFirestore.instance.collection('transactions').add({
      'user_id': FirebaseAuth.instance.currentUser!.uid,
      'type': type,
      'category': category,
      'amount': value,
      'description': description.text.trim(),
      'date': Timestamp.fromDate(date),
      'created_time': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      setState(() => saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction'), backgroundColor: farmerGreen, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(value: type, items: const [DropdownMenuItem(value: 'Income', child: Text('Income')), DropdownMenuItem(value: 'Expense', child: Text('Expense'))], onChanged: (v) => setState(() => type = v), decoration: const InputDecoration(hintText: 'Select...')),
          const SizedBox(height: 18),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(value: category, items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v), decoration: const InputDecoration(hintText: 'Select...')),
          const SizedBox(height: 18),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (GH₵)', hintText: 'Enter amount')),
          const SizedBox(height: 18),
          TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional notes about this transaction')),
          const SizedBox(height: 18),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.calendar_month, color: farmerGreen),
            title: const Text('Date'),
            subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setState(() => date = picked);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: saving ? null : save, style: FilledButton.styleFrom(backgroundColor: farmerGreen, padding: const EdgeInsets.symmetric(vertical: 16)), icon: const Icon(Icons.save_outlined), label: Text(saving ? 'Saving...' : 'Save Transaction')),
        ],
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('transactions').where('user_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          double income = 0, expense = 0;
          final docs = snapshot.data?.docs ?? [];
          for (final doc in docs) {
            final d = doc.data();
            final v = (d['amount'] as num?)?.toDouble() ?? 0;
            d['type'] == 'Income' ? income += v : expense += v;
          }
          final money = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Reports', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              _ReportCard(title: 'Total Income', value: money.format(income), icon: Icons.trending_up, color: farmerGreen),
              const SizedBox(height: 12),
              _ReportCard(title: 'Total Expenses', value: money.format(expense), icon: Icons.trending_down, color: Colors.red),
              const SizedBox(height: 12),
              _ReportCard(title: 'Net Profit', value: money.format(income - expense), icon: Icons.account_balance_wallet_outlined, color: darkGreen),
            ],
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _ReportCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [CircleAvatar(backgroundColor: color.withValues(alpha: .1), child: Icon(icon, color: color)), const SizedBox(width: 14), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color))]),
    );
  }
}

class CropsPage extends StatelessWidget {
  const CropsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('My Crops', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Crop-level records will help you understand which farm activities make or lose money.'),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Column(children: [Icon(Icons.grass, size: 48, color: farmerGreen), SizedBox(height: 10), Text('Crop tracking is ready for the next build stage.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700))])),
        ],
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
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          const CircleAvatar(radius: 42, backgroundColor: farmerGreen, child: Icon(Icons.person, size: 48, color: Colors.white)),
          const SizedBox(height: 14),
          Text(user.displayName?.isNotEmpty == true ? user.displayName! : 'Farmer', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(user.email ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ListTile(tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Log out'), onTap: () => FirebaseAuth.instance.signOut()),
        ],
      ),
    );
  }
}
