import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const farmerGreen = Color(0xFF2E7D32);
const darkGreen = Color(0xFF1B5E20);
const pageBg = Color(0xFFF5F7F2);
const softGreen = Color(0xFFE8F5E9);

final moneyFormat = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');

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
        appBarTheme: const AppBarTheme(
          backgroundColor: farmerGreen,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E8E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: farmerGreen, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: farmerGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.eco, color: farmerGreen, size: 72),
        SizedBox(height: 8),
        Text('FarmersHub GH', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: darkGreen)),
        SizedBox(height: 3),
        Text('Know Your Farm. Grow Your Profit.', textAlign: TextAlign.center),
      ],
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
  bool obscure = true;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

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

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty) {
      setState(() => error = 'Enter your email address first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Unable to send reset email.');
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
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(),
                  const SizedBox(height: 34),
                  const Text('Welcome back!', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Sign in to continue'),
                  const SizedBox(height: 22),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Login'),
                  ),
                  TextButton(onPressed: resetPassword, child: const Text('Forgot Password?')),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: const Text('Create Account'),
                      ),
                    ],
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
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  bool obscure = true;
  String? error;

  String normalizedPhone(String input) {
    var p = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('0')) p = '+233${p.substring(1)}';
    if (!p.startsWith('+') && p.startsWith('233')) p = '+$p';
    return p;
  }

  Future<void> register() async {
    final fullName = name.text.trim();
    final mail = email.text.trim();
    final mobile = normalizedPhone(phone.text.trim());
    if (fullName.isEmpty || mail.isEmpty || mobile.isEmpty || password.text.isEmpty) {
      setState(() => error = 'Complete all required fields.');
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
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: mail, password: password.text);
      await credential.user!.updateDisplayName(fullName);
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'display_name': fullName,
        'phone_number': mobile,
        'email': mail,
        'photo_url': '',
        'created_time': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Unable to create account.');
    } catch (e) {
      setState(() => error = 'Account created, but profile setup failed. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const BrandHeader(),
          const SizedBox(height: 26),
          const Text('Create Your Account', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Join FarmersHub and start managing your farm.'),
          const SizedBox(height: 22),
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 13),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', hintText: 'e.g. 024 000 0000', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 13),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 13),
          TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
          const SizedBox(height: 13),
          TextField(controller: confirm, obscureText: obscure, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline))),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(onPressed: loading ? null : register, child: Text(loading ? 'Creating...' : 'Create Account')),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.agriculture_outlined), selectedIcon: Icon(Icons.agriculture), label: 'Farms'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Query<Map<String, dynamic>> transactionQuery() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('transactions').where('user_id', isEqualTo: uid);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: transactionQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Unable to load transactions: ${snapshot.error}')));
          }
          final docs = snapshot.data?.docs.toList() ?? [];
          docs.sort((a, b) {
            final aDate = (a.data()['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bDate = (b.data()['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bDate.compareTo(aDate);
          });
          var income = 0.0;
          var expenses = 0.0;
          for (final doc in docs) {
            final data = doc.data();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            if (data['type'] == 'Income') income += amount;
            if (data['type'] == 'Expense') expenses += amount;
          }
          final balance = income - expenses;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
            children: [
              const Text('Welcome to FarmersHub GH', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('Track your income, expenses and grow your profit.'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(moneyFormat.format(balance), style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Metric(label: 'Income', value: moneyFormat.format(income)),
                        _Metric(label: 'Expenses', value: moneyFormat.format(expenses)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _QuickAction(icon: Icons.add_circle_outline, label: 'Add Transaction', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionPage())))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.agriculture_outlined, label: 'Add Farm', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFarmPage())))),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Transactions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: darkGreen)),
                  Text('${docs.length} record${docs.length == 1 ? '' : 's'}', style: const TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const _EmptyTransactions()
              else
                ...docs.take(8).map((doc) => TransactionTile(id: doc.id, data: doc.data())),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE0E7DE))),
        child: Column(children: [Icon(icon, color: farmerGreen), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))]),
      ),
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
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: farmerGreen),
          SizedBox(height: 8),
          Text('No records yet', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Add your first income or expense to start tracking your farm.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const TransactionTile({super.key, required this.id, required this.data});

  Future<void> delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This record will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await FirebaseFirestore.instance.collection('transactions').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final income = data['type'] == 'Income';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final date = (data['date'] as Timestamp?)?.toDate();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onLongPress: () => delete(context),
        leading: CircleAvatar(
          backgroundColor: income ? softGreen : const Color(0xFFFFEBEE),
          child: Icon(income ? Icons.south_west : Icons.north_east, color: income ? farmerGreen : Colors.red),
        ),
        title: Text((data['category'] ?? 'Transaction').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${date == null ? 'Today' : DateFormat('dd MMM yyyy').format(date)} • ${data['type'] ?? ''}${(data['farm_name'] ?? '').toString().isEmpty ? '' : ' • ${data['farm_name']}'}'),
        trailing: Text('${income ? '+' : '-'}${moneyFormat.format(amount)}', style: TextStyle(fontWeight: FontWeight.w900, color: income ? farmerGreen : Colors.red)),
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
  String? payment;
  String? farmId;
  String? farmName;
  final amount = TextEditingController();
  final notes = TextEditingController();
  DateTime date = DateTime.now();
  bool saving = false;

  final categories = const ['Sales', 'Seeds', 'Fertilizer', 'Labour', 'Feed', 'Tools', 'Transport', 'Equipment', 'Fuel', 'Harvest', 'Other'];
  final payments = const ['Cash', 'Mobile Money', 'Bank Transfer'];

  Future<void> save() async {
    final value = double.tryParse(amount.text.replaceAll(',', '').trim());
    if (type == null || category == null || payment == null || value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete the required fields and enter a valid amount.')));
      return;
    }
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('transactions').add({
        'user_id': FirebaseAuth.instance.currentUser!.uid,
        'farm_id': farmId ?? '',
        'farm_name': farmName ?? '',
        'type': type,
        'category': category,
        'amount': value,
        'payment_method': payment,
        'notes': notes.text.trim(),
        'date': Timestamp.fromDate(date),
        'created_time': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction saved successfully.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save transaction: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('farms').where('user_id', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          final farms = snapshot.data?.docs ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Transaction Type'),
                items: const [DropdownMenuItem(value: 'Income', child: Text('Income')), DropdownMenuItem(value: 'Expense', child: Text('Expense'))],
                onChanged: (v) => setState(() => type = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: farmId,
                decoration: const InputDecoration(labelText: 'Farm (optional)'),
                items: farms.map((f) => DropdownMenuItem(value: f.id, child: Text((f.data()['name'] ?? 'Farm').toString()))).toList(),
                onChanged: (v) {
                  final match = farms.where((f) => f.id == v).toList();
                  setState(() {
                    farmId = v;
                    farmName = match.isEmpty ? '' : (match.first.data()['name'] ?? '').toString();
                  });
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => category = v),
              ),
              const SizedBox(height: 14),
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (GH₵)', hintText: 'Enter amount', prefixIcon: Icon(Icons.payments_outlined))),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: payment,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: payments.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => payment = v),
              ),
              const SizedBox(height: 14),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.calendar_today_outlined, color: farmerGreen),
                title: const Text('Transaction Date'),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(date)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setState(() => date = picked);
                },
              ),
              const SizedBox(height: 14),
              TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes', hintText: 'Optional details')),
              const SizedBox(height: 22),
              FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Saving...' : 'Save Transaction')),
            ],
          );
        },
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
          final docs = snapshot.data?.docs ?? [];
          var income = 0.0;
          var expense = 0.0;
          final expensesByCategory = <String, double>{};
          for (final doc in docs) {
            final d = doc.data();
            final amount = (d['amount'] as num?)?.toDouble() ?? 0;
            if (d['type'] == 'Income') {
              income += amount;
            } else if (d['type'] == 'Expense') {
              expense += amount;
              final category = (d['category'] ?? 'Other').toString();
              expensesByCategory[category] = (expensesByCategory[category] ?? 0) + amount;
            }
          }
          final categories = expensesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Reports', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('Understand how your farm money is moving.'),
              const SizedBox(height: 20),
              _ReportCard(label: 'Total Income', value: moneyFormat.format(income), icon: Icons.trending_up, color: farmerGreen),
              const SizedBox(height: 10),
              _ReportCard(label: 'Total Expenses', value: moneyFormat.format(expense), icon: Icons.trending_down, color: Colors.red),
              const SizedBox(height: 10),
              _ReportCard(label: 'Net Profit', value: moneyFormat.format(income - expense), icon: Icons.account_balance_wallet_outlined, color: darkGreen),
              const SizedBox(height: 24),
              const Text('Top Expense Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (categories.isEmpty)
                const Text('No expense records yet.')
              else
                ...categories.take(6).map((e) => Card(child: ListTile(title: Text(e.key), trailing: Text(moneyFormat.format(e.value), style: const TextStyle(fontWeight: FontWeight.w800))))),
            ],
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ReportCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)), const SizedBox(width: 14), Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color))]),
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
                  FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFarmPage())), icon: const Icon(Icons.add), label: const Text('Add Farm')),
                ],
              ),
              const SizedBox(height: 5),
              const Text('Keep each farm and its crops organised.'),
              const SizedBox(height: 18),
              if (farms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Column(children: [Icon(Icons.agriculture, size: 50, color: farmerGreen), SizedBox(height: 10), Text('No farms registered yet', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Add your first farm to link transactions and crops to it.', textAlign: TextAlign.center)]),
                )
              else
                ...farms.map((farm) => FarmCard(id: farm.id, data: farm.data())),
            ],
          );
        },
      ),
    );
  }
}

class FarmCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const FarmCard({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const CircleAvatar(backgroundColor: softGreen, child: Icon(Icons.agriculture, color: farmerGreen)), const SizedBox(width: 12), Expanded(child: Text((data['name'] ?? 'Farm').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))]),
            const SizedBox(height: 10),
            Text('${data['farm_type'] ?? 'Farm'} • ${data['location'] ?? 'Location not set'}'),
            const SizedBox(height: 3),
            Text('${(data['size_acres'] as num?)?.toStringAsFixed(1) ?? '0.0'} acres', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CropsPage(farmId: id, farmName: (data['name'] ?? 'Farm').toString()))), icon: const Icon(Icons.grass), label: const Text('View Crops')),
          ],
        ),
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
  String? farmType;
  bool saving = false;

  Future<void> save() async {
    final acres = double.tryParse(size.text.trim());
    if (name.text.trim().isEmpty || location.text.trim().isEmpty || farmType == null || acres == null || acres <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete all farm details.')));
      return;
    }
    setState(() => saving = true);
    await FirebaseFirestore.instance.collection('farms').add({
      'user_id': FirebaseAuth.instance.currentUser!.uid,
      'name': name.text.trim(),
      'location': location.text.trim(),
      'farm_type': farmType,
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
          const SizedBox(height: 14),
          TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: farmType,
            decoration: const InputDecoration(labelText: 'Farm Type'),
            items: const ['Crop Farming', 'Livestock', 'Poultry', 'Mixed Farming', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => farmType = v),
          ),
          const SizedBox(height: 14),
          TextField(controller: size, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Farm Size (acres)')),
          const SizedBox(height: 22),
          FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Saving...' : 'Save Farm')),
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
        backgroundColor: farmerGreen,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddCropPage(farmId: farmId, farmName: farmName))),
        icon: const Icon(Icons.add),
        label: const Text('Add Crop'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('crops').where('user_id', isEqualTo: uid).where('farm_id', isEqualTo: farmId).snapshots(),
        builder: (context, snapshot) {
          final crops = snapshot.data?.docs ?? [];
          if (crops.isEmpty) return const Center(child: Text('No crop records yet.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: crops.length,
            itemBuilder: (_, i) {
              final c = crops[i].data();
              final planted = (c['planting_date'] as Timestamp?)?.toDate();
              return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: softGreen, child: Icon(Icons.grass, color: farmerGreen)), title: Text((c['crop_name'] ?? 'Crop').toString(), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${(c['acreage'] as num?)?.toStringAsFixed(1) ?? '0.0'} acres${planted == null ? '' : ' • Planted ${DateFormat('dd MMM yyyy').format(planted)}'}'), trailing: Text((c['status'] ?? 'Growing').toString())));
            },
          );
        },
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
  final crop = TextEditingController();
  final acreage = TextEditingController();
  DateTime plantingDate = DateTime.now();
  String status = 'Growing';

  Future<void> save() async {
    final acres = double.tryParse(acreage.text.trim());
    if (crop.text.trim().isEmpty || acres == null || acres <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the crop name and acreage.')));
      return;
    }
    await FirebaseFirestore.instance.collection('crops').add({
      'user_id': FirebaseAuth.instance.currentUser!.uid,
      'farm_id': widget.farmId,
      'farm_name': widget.farmName,
      'crop_name': crop.text.trim(),
      'acreage': acres,
      'planting_date': Timestamp.fromDate(plantingDate),
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
          TextField(controller: crop, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Crop Name', hintText: 'e.g. Maize')),
          const SizedBox(height: 14),
          TextField(controller: acreage, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Acreage')),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Status'), items: const ['Planned', 'Growing', 'Harvested'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => status = v ?? status)),
          const SizedBox(height: 14),
          ListTile(tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), title: const Text('Planting Date'), subtitle: Text(DateFormat('dd MMMM yyyy').format(plantingDate)), trailing: const Icon(Icons.calendar_today), onTap: () async { final d = await showDatePicker(context: context, initialDate: plantingDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) setState(() => plantingDate = d); }),
          const SizedBox(height: 22),
          FilledButton(onPressed: save, child: const Text('Save Crop')),
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
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Profile', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              const CircleAvatar(radius: 45, backgroundColor: softGreen, child: Icon(Icons.person, size: 50, color: farmerGreen)),
              const SizedBox(height: 14),
              Text((data['display_name'] ?? user.displayName ?? 'Farmer').toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text((data['email'] ?? user.email ?? '').toString(), textAlign: TextAlign.center),
              if ((data['phone_number'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(data['phone_number'].toString(), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 28),
              Card(child: ListTile(leading: const Icon(Icons.shield_outlined, color: farmerGreen), title: const Text('Account Security'), subtitle: const Text('Password reset is available from the login screen.'))),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout), label: const Text('Logout')),
            ],
          );
        },
      ),
    );
  }
}
