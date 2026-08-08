import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const farmerGreen = Color(0xFF2E7D32);
const darkGreen = Color(0xFF1B5E20);
const pageBg = Color(0xFFF5F7F2);
const softGreen = Color(0xFFE8F5E9);
final money = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');

class FarmersHubApp extends StatelessWidget {
  const FarmersHubApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E7DE))),
          ),
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: farmerGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18))),
        ),
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (_, s) {
          if (s.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return s.data == null ? const LoginPage() : const MainShell();
        },
      );
}

String friendlyAuth(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'wrong-password':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'weak-password':
      return 'Choose a stronger password.';
    default:
      return e.message ?? 'Unable to complete this request.';
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
  String? error;
  bool loading = false;
  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) return setState(() => error = 'Enter your email and password.');
    setState(() { loading = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (e) {
      setState(() => error = friendlyAuth(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  Future<void> reset() async {
    if (email.text.trim().isEmpty) return setState(() => error = 'Enter your email first.');
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
    } on FirebaseAuthException catch (e) { setState(() => error = friendlyAuth(e)); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.eco, size: 72, color: farmerGreen),
            const Text('FarmersHub GH', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: darkGreen)),
            const Text('Know Your Farm. Grow Your Profit.', textAlign: TextAlign.center),
            const SizedBox(height: 30),
            const Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address')),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'Signing in...' : 'Login')),
            TextButton(onPressed: reset, child: const Text('Forgot Password?')),
            OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Create Account')),
          ]),
        ))),
      );
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController(), pass = TextEditingController(), confirm = TextEditingController();
  String? error; bool loading = false;
  String norm(String p) { p = p.replaceAll(RegExp(r'[^0-9+]'), ''); if (p.startsWith('0')) p = '+233${p.substring(1)}'; return p; }
  Future<void> create() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || pass.text.isEmpty) return setState(() => error = 'Complete your name, email and password.');
    if (pass.text.length < 6) return setState(() => error = 'Password must be at least 6 characters.');
    if (pass.text != confirm.text) return setState(() => error = 'Passwords do not match.');
    setState(() { loading = true; error = null; });
    try {
      final c = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text.trim(), password: pass.text);
      await c.user!.updateDisplayName(name.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(c.user!.uid).set({
        'uid': c.user!.uid, 'display_name': name.text.trim(), 'email': email.text.trim(), 'phone_number': phone.text.trim().isEmpty ? '' : norm(phone.text.trim()), 'created_time': FieldValue.serverTimestamp()
      });
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on FirebaseAuthException catch (e) { setState(() => error = friendlyAuth(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create Account')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 12),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number (optional)')),
          const SizedBox(height: 12),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address')),
          const SizedBox(height: 12),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 18),
          FilledButton(onPressed: loading ? null : create, child: Text(loading ? 'Creating...' : 'Create Account')),
        ]),
      );
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
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
      NavigationDestination(icon: Icon(Icons.agriculture_outlined), label: 'Farms'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ]),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: FirebaseFirestore.instance.collection('transactions').where('user_id', isEqualTo: uid).snapshots(),
      builder: (_, s) {
        final docs = s.data?.docs.toList() ?? [];
        docs.sort((a,b) => ((b.data()['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0).compareTo((a.data()['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
        double inc=0, exp=0; for (final d in docs) { final a=(d.data()['amount'] as num?)?.toDouble() ?? 0; d.data()['type']=='Income' ? inc+=a : exp+=a; }
        return ListView(padding: const EdgeInsets.fromLTRB(20,20,20,100), children: [
          const Text('Welcome to FarmersHub GH', style: TextStyle(fontSize: 24,fontWeight: FontWeight.w900)),
          const Text('Track your farm, costs and profit.'), const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: darkGreen,borderRadius: BorderRadius.circular(18)), child: Column(children:[
            const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70)),
            Text(money.format(inc-exp), style: const TextStyle(color: Colors.white,fontSize: 34,fontWeight: FontWeight.w900)),
            const SizedBox(height: 14), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text('Income\n${money.format(inc)}',style: const TextStyle(color:Colors.white)),Text('Expenses\n${money.format(exp)}',textAlign:TextAlign.right,style: const TextStyle(color:Colors.white))])
          ])),
          const SizedBox(height: 14), Row(children:[
            Expanded(child: FilledButton(onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AddTransactionPage())), child: const Text('Add Transaction'))),
            const SizedBox(width:10), Expanded(child: OutlinedButton(onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AddFarmPage())), child: const Text('Add Farm'))),
          ]),
          const SizedBox(height:20), const Text('Recent Transactions', style: TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
          if(docs.isEmpty) const Card(child:Padding(padding:EdgeInsets.all(22),child:Text('No transactions yet.',textAlign:TextAlign.center))) else ...docs.take(8).map((d){final x=d.data(),income=x['type']=='Income';return Card(child:ListTile(title:Text('${x['category'] ?? 'Transaction'}',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text([x['farm_name'],x['crop_name']].where((e)=>e!=null&&e.toString().isNotEmpty).join(' • ')),trailing:Text('${income?'+':'-'}${money.format((x['amount'] as num?)?.toDouble()??0)}',style:TextStyle(fontWeight:FontWeight.w900,color:income?farmerGreen:Colors.red))));}),
        ]);
      },
    ));
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid=FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('transactions').where('user_id',isEqualTo:uid).snapshots(),builder:(_,s){
      final ds=s.data?.docs??[];double i=0,e=0;final crops=<String,Map<String,double>>{};
      for(final d in ds){final x=d.data(),a=(x['amount']as num?)?.toDouble()??0;if(x['type']=='Income')i+=a;else e+=a;final cn=(x['crop_name']??'').toString();if(cn.isNotEmpty){crops.putIfAbsent(cn,()=>{'income':0,'expense':0});if(x['type']=='Income')crops[cn]!['income']=crops[cn]!['income']!+a;else crops[cn]!['expense']=crops[cn]!['expense']!+a;}}
      return ListView(padding:const EdgeInsets.all(20),children:[const Text('Reports',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900)),const SizedBox(height:14),_report('Total Income',i),_report('Total Expenses',e),_report('Net Profit',i-e),const SizedBox(height:20),const Text('Crop Profitability',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),if(crops.isEmpty)const Padding(padding:EdgeInsets.only(top:10),child:Text('Link transactions to crops to see crop-by-crop profit.'))else...crops.entries.map((c)=>Card(child:ListTile(title:Text(c.key),subtitle:Text('Income ${money.format(c.value['income'])} • Expenses ${money.format(c.value['expense'])}'),trailing:Text(money.format(c.value['income']!-c.value['expense']!),style:const TextStyle(fontWeight:FontWeight.w900))))]);
    }));
  }
  Widget _report(String l,double v)=>Card(child:ListTile(title:Text(l),trailing:Text(money.format(v),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900))));
}

class FarmsPage extends StatelessWidget {
  const FarmsPage({super.key});
  @override
  Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser!.uid;return SafeArea(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('farms').where('user_id',isEqualTo:uid).snapshots(),builder:(_,s){final fs=s.data?.docs??[];return ListView(padding:const EdgeInsets.all(20),children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('My Farms',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900)),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AddFarmPage())),child:const Text('Add Farm'))]),const SizedBox(height:12),if(fs.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(24),child:Text('No farms registered yet.',textAlign:TextAlign.center)))else...fs.map((f){final d=f.data();return Card(child:ListTile(title:Text('${d['name']??'Farm'}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${d['location']??''} • ${(d['size_acres']as num?)?.toStringAsFixed(1)??'0.0'} acres'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CropsPage(farmId:f.id,farmName:'${d['name']??'Farm'}')))));})]);}));}
}

class AddFarmPage extends StatefulWidget {const AddFarmPage({super.key});@override State<AddFarmPage> createState()=>_AddFarmPageState();}
class _AddFarmPageState extends State<AddFarmPage>{final name=TextEditingController(),location=TextEditingController(),size=TextEditingController();String type='Crop Farming';Future<void> save()async{final a=double.tryParse(size.text);if(name.text.trim().isEmpty||location.text.trim().isEmpty||a==null||a<=0)return;await FirebaseFirestore.instance.collection('farms').add({'user_id':FirebaseAuth.instance.currentUser!.uid,'name':name.text.trim(),'location':location.text.trim(),'farm_type':type,'size_acres':a,'created_time':FieldValue.serverTimestamp()});if(mounted)Navigator.pop(context);} @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Register Farm')),body:ListView(padding:const EdgeInsets.all(20),children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Farm Name')),const SizedBox(height:12),TextField(controller:location,decoration:const InputDecoration(labelText:'Location')),const SizedBox(height:12),DropdownButtonFormField(value:type,decoration:const InputDecoration(labelText:'Farm Type'),items:const ['Crop Farming','Livestock','Poultry','Mixed Farming','Other'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>type=v??type)),const SizedBox(height:12),TextField(controller:size,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Farm Size (acres)')),const SizedBox(height:20),FilledButton(onPressed:save,child:const Text('Save Farm'))]));}

class CropsPage extends StatelessWidget {
  final String farmId,farmName;const CropsPage({super.key,required this.farmId,required this.farmName});
  @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser!.uid;return Scaffold(appBar:AppBar(title:Text('$farmName Crops')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AddCropPage(farmId:farmId,farmName:farmName))),label:const Text('Add Crop'),icon:const Icon(Icons.add)),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('crops').where('user_id',isEqualTo:uid).where('farm_id',isEqualTo:farmId).snapshots(),builder:(_,s){final cs=s.data?.docs??[];if(cs.isEmpty)return const Center(child:Text('No crop records yet.'));return ListView(padding:const EdgeInsets.all(16),children:cs.map((c)=>CropCard(id:c.id,data:c.data())).toList());}));}
}

class CropCard extends StatelessWidget {final String id;final Map<String,dynamic> data;const CropCard({super.key,required this.id,required this.data});@override Widget build(BuildContext context){final harvest=(data['expected_harvest_date']as Timestamp?)?.toDate();return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${data['crop_name']??'Crop'}${(data['variety']??'').toString().isEmpty?'':' • ${data['variety']}'}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),Text('${(data['acreage']as num?)?.toStringAsFixed(1)??'0.0'} acres • ${data['status']??'Growing'}'),if(harvest!=null)Text('Expected harvest: ${DateFormat('dd MMM yyyy').format(harvest)}'),if((data['expected_yield']as num?)!=null)Text('Expected yield: ${data['expected_yield']} ${data['yield_unit']??''}'),const SizedBox(height:10),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CropProfitPage(cropId:id,crop:data))),child:const Text('View Profitability'))])));}}

class AddCropPage extends StatefulWidget {final String farmId,farmName;const AddCropPage({super.key,required this.farmId,required this.farmName});@override State<AddCropPage> createState()=>_AddCropPageState();}
class _AddCropPageState extends State<AddCropPage>{final crop=TextEditingController(),variety=TextEditingController(),acreage=TextEditingController(),yield=TextEditingController(),price=TextEditingController();DateTime planted=DateTime.now(),harvest=DateTime.now().add(const Duration(days:120));String status='Growing',unit='bags';Future<void> save()async{final a=double.tryParse(acreage.text),y=double.tryParse(yield.text),p=double.tryParse(price.text);if(crop.text.trim().isEmpty||a==null||a<=0)return;await FirebaseFirestore.instance.collection('crops').add({'user_id':FirebaseAuth.instance.currentUser!.uid,'farm_id':widget.farmId,'farm_name':widget.farmName,'crop_name':crop.text.trim(),'variety':variety.text.trim(),'acreage':a,'planting_date':Timestamp.fromDate(planted),'expected_harvest_date':Timestamp.fromDate(harvest),'expected_yield':y??0,'yield_unit':unit,'expected_selling_price':p??0,'status':status,'created_time':FieldValue.serverTimestamp()});if(mounted)Navigator.pop(context);}Future<DateTime?> pick(DateTime d)=>showDatePicker(context:context,initialDate:d,firstDate:DateTime(2020),lastDate:DateTime.now().add(const Duration(days:1095)));@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Add Crop')),body:ListView(padding:const EdgeInsets.all(20),children:[TextField(controller:crop,decoration:const InputDecoration(labelText:'Crop Name')),const SizedBox(height:12),TextField(controller:variety,decoration:const InputDecoration(labelText:'Variety (optional)')),const SizedBox(height:12),TextField(controller:acreage,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Acreage')),const SizedBox(height:12),DropdownButtonFormField(value:status,decoration:const InputDecoration(labelText:'Status'),items:const ['Planned','Growing','Harvested'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>status=v??status)),const SizedBox(height:12),ListTile(tileColor:Colors.white,title:const Text('Planting Date'),subtitle:Text(DateFormat('dd MMM yyyy').format(planted)),onTap:()async{final d=await pick(planted);if(d!=null)setState(()=>planted=d);}),const SizedBox(height:8),ListTile(tileColor:Colors.white,title:const Text('Expected Harvest Date'),subtitle:Text(DateFormat('dd MMM yyyy').format(harvest)),onTap:()async{final d=await pick(harvest);if(d!=null)setState(()=>harvest=d);}),const SizedBox(height:12),TextField(controller:yield,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Expected Yield')),const SizedBox(height:12),DropdownButtonFormField(value:unit,decoration:const InputDecoration(labelText:'Yield Unit'),items:const ['bags','kg','tonnes','crates','units'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>unit=v??unit)),const SizedBox(height:12),TextField(controller:price,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'Expected Selling Price per $unit (GH₵)')),const SizedBox(height:20),FilledButton(onPressed:save,child:const Text('Save Crop'))]));}

class CropProfitPage extends StatelessWidget {final String cropId;final Map<String,dynamic> crop;const CropProfitPage({super.key,required this.cropId,required this.crop});@override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser!.uid,acres=(crop['acreage']as num?)?.toDouble()??0,ey=(crop['expected_yield']as num?)?.toDouble()??0,ep=(crop['expected_selling_price']as num?)?.toDouble()??0;return Scaffold(appBar:AppBar(title:Text('${crop['crop_name']??'Crop'} Profitability')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AddTransactionPage(initialFarmId:'${crop['farm_id']??''}',initialFarmName:'${crop['farm_name']??''}',initialCropId:cropId,initialCropName:'${crop['crop_name']??''}'))),label:const Text('Add Transaction'),icon:const Icon(Icons.add)),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('transactions').where('user_id',isEqualTo:uid).snapshots(),builder:(_,s){final ds=(s.data?.docs??[]).where((d)=>d.data()['crop_id']==cropId);double i=0,e=0;for(final d in ds){final x=d.data(),a=(x['amount']as num?)?.toDouble()??0;x['type']=='Income'?i+=a:e+=a;}final p=i-e,ppa=acres>0?p/acres:0,be=ey>0?e/ey:0,expectedRevenue=ey*ep;return ListView(padding:const EdgeInsets.all(20),children:[Text('${crop['crop_name']??'Crop'} • ${crop['farm_name']??''}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:14),_stat('Income',i),_stat('Expenses',e),_stat('Net Profit',p),_stat('Profit per acre',ppa),_stat('Break-even price per ${crop['yield_unit']??'unit'}',be),_stat('Expected revenue',expectedRevenue),const SizedBox(height:12),Text('Break-even price is calculated from recorded crop expenses ÷ expected yield.',style:Theme.of(context).textTheme.bodySmall)]); }));}Widget _stat(String l,double v)=>Card(child:ListTile(title:Text(l),trailing:Text(money.format(v),style:const TextStyle(fontWeight:FontWeight.w900))));}

class AddTransactionPage extends StatefulWidget {final String? initialFarmId,initialFarmName,initialCropId,initialCropName;const AddTransactionPage({super.key,this.initialFarmId,this.initialFarmName,this.initialCropId,this.initialCropName});@override State<AddTransactionPage> createState()=>_AddTransactionPageState();}
class _AddTransactionPageState extends State<AddTransactionPage>{String? type,category,payment,farmId,farmName,cropId,cropName;final amount=TextEditingController(),notes=TextEditingController();DateTime date=DateTime.now();@override void initState(){super.initState();farmId=widget.initialFarmId;farmName=widget.initialFarmName;cropId=widget.initialCropId;cropName=widget.initialCropName;}Future<void> save()async{final a=double.tryParse(amount.text);if(type==null||category==null||payment==null||a==null||a<=0)return;await FirebaseFirestore.instance.collection('transactions').add({'user_id':FirebaseAuth.instance.currentUser!.uid,'farm_id':farmId??'','farm_name':farmName??'','crop_id':cropId??'','crop_name':cropName??'','type':type,'category':category,'amount':a,'payment_method':payment,'notes':notes.text.trim(),'date':Timestamp.fromDate(date),'created_time':FieldValue.serverTimestamp()});if(mounted)Navigator.pop(context);} @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser!.uid;return Scaffold(appBar:AppBar(title:const Text('Add Transaction')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('farms').where('user_id',isEqualTo:uid).snapshots(),builder:(_,fs){final farms=fs.data?.docs??[];return ListView(padding:const EdgeInsets.all(20),children:[DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'Type'),items:const ['Income','Expense'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>type=v)),const SizedBox(height:12),DropdownButtonFormField<String>(value:farmId,decoration:const InputDecoration(labelText:'Farm (optional)'),items:farms.map((f)=>DropdownMenuItem(value:f.id,child:Text('${f.data()['name']??'Farm'}'))).toList(),onChanged:(v){final m=farms.where((f)=>f.id==v);setState((){farmId=v;farmName=m.isEmpty?'':'${m.first.data()['name']??''}';cropId=null;cropName=null;});}),const SizedBox(height:12),if(farmId!=null&&farmId!.isNotEmpty)StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('crops').where('user_id',isEqualTo:uid).where('farm_id',isEqualTo:farmId).snapshots(),builder:(_,cs){final crops=cs.data?.docs??[];return DropdownButtonFormField<String>(value:cropId,decoration:const InputDecoration(labelText:'Crop (optional)'),items:crops.map((c)=>DropdownMenuItem(value:c.id,child:Text('${c.data()['crop_name']??'Crop'}'))).toList(),onChanged:(v){final m=crops.where((c)=>c.id==v);setState((){cropId=v;cropName=m.isEmpty?'':'${m.first.data()['crop_name']??''}';});});}),if(farmId!=null&&farmId!.isNotEmpty)const SizedBox(height:12),DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Category'),items:const ['Sales','Seeds','Fertilizer','Labour','Feed','Transport','Equipment','Fuel','Harvest','Other'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>category=v)),const SizedBox(height:12),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount (GH₵)')),const SizedBox(height:12),DropdownButtonFormField<String>(value:payment,decoration:const InputDecoration(labelText:'Payment Method'),items:const ['Cash','Mobile Money','Bank Transfer'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>payment=v)),const SizedBox(height:12),TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'Notes (optional)')),const SizedBox(height:20),FilledButton(onPressed:save,child:const Text('Save Transaction'))]);}));}}

class ProfilePage extends StatelessWidget {const ProfilePage({super.key});@override Widget build(BuildContext context){final u=FirebaseAuth.instance.currentUser!;return SafeArea(child:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots(),builder:(_,s){final d=s.data?.data()??{};return ListView(padding:const EdgeInsets.all(20),children:[const Text('Profile',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900)),const SizedBox(height:24),const CircleAvatar(radius:44,backgroundColor:softGreen,child:Icon(Icons.person,size:48,color:farmerGreen)),const SizedBox(height:12),Text('${d['display_name']??u.displayName??'Farmer'}',textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),Text('${d['email']??u.email??''}',textAlign:TextAlign.center),if('${d['phone_number']??''}'.isNotEmpty)Text('${d['phone_number']}',textAlign:TextAlign.center),const SizedBox(height:24),OutlinedButton.icon(onPressed:()=>FirebaseAuth.instance.signOut(),icon:const Icon(Icons.logout),label:const Text('Logout'))]);}));}}
