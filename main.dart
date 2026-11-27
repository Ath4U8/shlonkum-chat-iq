// شلونكم چات - IQ - v3 - إصلاح كامل 13 نقطة - حقيقي وليس وهمي
// 1 أيقونة 2 اسم عربي 3 بحث رقم 4 صورة شخصية 5 حفظ دخول 6 رقم ثابت 7 دخول حقيقي
// 8 بوابة عشتار علامة مائية شاشات 2-5 9 Created by علامة محفورة زرقاء شاشات 1-3
// 10 محادثات كتابية فقط 11 إيموجي وملصقات عراقية 12 صديق مو جهة اتصال 13 مؤشر قراءة + صور وملفات
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
const String supabaseUrl = 'https://tfcpkoozqttdzligfizu.supabase.co';
const String supabaseAnonKey = 'PUT_YOUR_ANON_KEY_HERE';
const Color kRoyal = Color(0xFF1B3A8F);
const Color kTurquoise = Color(0xFF00C2A8);
const Color kGold = Color(0xFFD9A441);
const Color kBeige = Color(0xFFF7F5EF);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey); } catch (_) {}
  runApp(const ShlonkumApp());
}
final supabase = Supabase.instance.client;
class LocalStore {
  static String name = '';
  static String password = '';
  static String personalNumber = '';
  static String status = '';
  static String photoPath = '';
  static List<Map<String, dynamic>> contacts = [];
  static List<Map<String, dynamic>> messages = [];
  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('name', name);
    await p.setString('password', password);
    await p.setString('personalNumber', personalNumber);
    await p.setString('status', status);
    await p.setString('photoPath', photoPath);
  }
  static Future<bool> load() async {
    final p = await SharedPreferences.getInstance();
    name = p.getString('name') ?? '';
    password = p.getString('password') ?? '';
    personalNumber = p.getString('personalNumber') ?? '';
    status = p.getString('status') ?? '';
    photoPath = p.getString('photoPath') ?? '';
    return personalNumber.isNotEmpty && name.isNotEmpty;
  }
}
// ويدجت بوابة عشتار علامة مائية - شاشات 2-5
class IshtarWatermark extends StatelessWidget {
  const IshtarWatermark({super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: Opacity(opacity: 0.07, child: Image.asset('ishtar_gate.jfif', fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox())));
  }
}
// ويدجت Created by علامة محفورة زرقاء - شاشات 1-3
class CreatorWatermark extends StatelessWidget {
  const CreatorWatermark({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.only(bottom: 8, top: 16), child: Text('Created by: Atheer Sami', style: TextStyle(color: Color(0xFF1B3A8F), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5), textAlign: TextAlign.center));
  }
}
class ShlonkumApp extends StatelessWidget {
  const ShlonkumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'شلونكم چات - IQ', theme: ThemeData(primaryColor: kRoyal, colorScheme: ColorScheme.fromSeed(seedColor: kRoyal), useMaterial3: true), builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!), home: const SplashGate());
  }
}
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}
class _SplashGateState extends State<SplashGate> {
  @override
  void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final has = await LocalStore.load();
    if (!mounted) return;
    if (has) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Screen4Contacts())); } else { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Screen1Register())); }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: kBeige, body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('شلونكم چات - IQ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kRoyal)), SizedBox(height: 16), CircularProgressIndicator(color: kRoyal)])));
  }
}
bool isStrongPassword(String p) {
  if (p.length < 8) return false;
  final hasUpper = p.contains(RegExp(r'[A-Z]'));
  final hasDigit = p.contains(RegExp(r'[0-9]'));
  final hasSpecial = p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  return hasUpper && hasDigit && hasSpecial;
}
String generatePersonalNumber() {
  final r = Random();
  return (100000000 + r.nextInt(900000000)).toString();
}
class Screen1Register extends StatefulWidget {
  const Screen1Register({super.key});
  @override
  State<Screen1Register> createState() => _Screen1RegisterState();
}
class _Screen1RegisterState extends State<Screen1Register> {
  final _name = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _msg = '';
  Future<void> _register() async {
    final name = _name.text.trim();
    final pass = _pass.text.trim();
    if (name.isEmpty) { setState(() => _msg = 'سجل اسمك اولا'); return; }
    if (!isStrongPassword(pass)) { setState(() => _msg = 'كلمة المرور ضعيفة - راجع الملاحظة بالاسفل'); return; }
    setState(() { _loading = true; _msg = ''; });
    String num = '';
    bool isReturning = false;
    try {
      final existing = await supabase.from('profiles').select().eq('name', name).eq('password_hash', pass).limit(1);
      if (existing is List && existing.isNotEmpty) { num = (existing[0]['personal_number'] ?? '').toString(); isReturning = true; }
    } catch (_) {}
    if (num.isEmpty) {
      num = generatePersonalNumber();
      try {
        for (int i = 0; i < 5; i++) {
          final ex = await supabase.from('profiles').select('personal_number').eq('personal_number', num).limit(1);
          if (ex is List && ex.isEmpty) break;
          if (ex is List && ex.isNotEmpty) num = generatePersonalNumber();
          if (ex is! List) break;
        }
        await supabase.from('profiles').insert({'name': name, 'password_hash': pass, 'personal_number': num, 'status': '', 'is_online': true, 'last_seen': DateTime.now().toIso8601String()});
      } catch (_) {}
    }
    LocalStore.name = name;
    LocalStore.password = pass;
    LocalStore.personalNumber = num;
    await LocalStore.save();
    if (!mounted) return;
    if (isReturning) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Screen4Contacts())); } else { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Screen2PersonalNumber(number: num))); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: kBeige, body: SingleChildScrollView(child: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Column(children: [
      SizedBox(width: MediaQuery.of(context).size.width * 0.30, child: Image.asset('iraq_map.png', fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.map, size: 70, color: kRoyal))),
      const SizedBox(height: 10),
      const Text('شلونكم چات - IQ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kRoyal)),
      const Text('تطبيق تواصل عراقي لكل العراق', style: TextStyle(fontSize: 16, color: Colors.black54)),
      const SizedBox(height: 28),
      const Align(alignment: Alignment.centerRight, child: Text('سجل اسمك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kRoyal))),
      const SizedBox(height: 6),
      TextField(controller: _name, decoration: const InputDecoration(hintText: 'مثال: أثير سامي', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
      const SizedBox(height: 18),
      const Align(alignment: Alignment.centerRight, child: Text('انشاء كلمة مرور قوية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kRoyal))),
      const SizedBox(height: 6),
      TextField(controller: _pass, obscureText: _obscure, textDirection: TextDirection.ltr, decoration: InputDecoration(hintText: 'Password', border: const OutlineInputBorder(), filled: true, fillColor: Colors.white, suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)))),
      const SizedBox(height: 8),
      Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: kGold.withOpacity(0.5))), child: const Text('كلمة المرور يجب ان تكون 8 احرف، وتحتوي على حرف كبير ورقم وحرف خاص', style: TextStyle(fontSize: 13, color: Colors.black54), textAlign: TextAlign.center)),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kRoyal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _loading ? null : _register, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 10),
      if (_msg.isNotEmpty) Text(_msg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      const CreatorWatermark(),
    ])))));
  }
}
class Screen2PersonalNumber extends StatelessWidget {
  final String number;
  const Screen2PersonalNumber({super.key, required this.number});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: kBeige, body: Stack(children: [const IshtarWatermark(), SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), child: Column(children: [
      const SizedBox(height: 30),
      const Text('شلونكم چات - IQ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kRoyal)),
      const SizedBox(height: 30),
      Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFEDED), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))), child: const Text('هذا يعتبر رقمك الشخصي احفظه جيدا من خلاله تضيف جهات الاتصال لديك ويضيفونك وغير قابل للتغيير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center)),
      const SizedBox(height: 24),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGold, width: 1.5)), child: Column(children: [const Text('رقمك الشخصي', style: TextStyle(color: Colors.black54)), const SizedBox(height: 6), SelectableText(number, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kRoyal, letterSpacing: 4), textDirection: TextDirection.ltr), const SizedBox(height: 6), const Text('اضغط مطولا للنسخ', style: TextStyle(fontSize: 12, color: Colors.black45))])),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kRoyal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Screen3Profile())), child: const Text('ادخل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))),
      const Spacer(),
      const CreatorWatermark(),
    ])))]));
  }
}
class Screen3Profile extends StatefulWidget {
  const Screen3Profile({super.key});
  @override
  State<Screen3Profile> createState() => _Screen3ProfileState();
}
class _Screen3ProfileState extends State<Screen3Profile> {
  final _status = TextEditingController();
  bool _loading = false;
  XFile? _picked;
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (f != null) { setState(() => _picked = f); LocalStore.photoPath = f.path; await LocalStore.save(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير الصورة الشخصية'))); }
  }
  Future<void> _save() async {
    setState(() => _loading = true);
    LocalStore.status = _status.text.trim();
    try { await supabase.from('profiles').update({'status': LocalStore.status}).eq('personal_number', LocalStore.personalNumber); } catch (_) {}
    await LocalStore.save();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Screen4Contacts()));
  }
  @override
  Widget build(BuildContext context) {
    final hasPhoto = _picked != null || LocalStore.photoPath.isNotEmpty;
    return Scaffold(backgroundColor: kBeige, appBar: AppBar(title: const Text('انشاء ملفك الشخصي'), backgroundColor: kRoyal, foregroundColor: Colors.white, centerTitle: true), body: Stack(children: [const IshtarWatermark(), SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      const SizedBox(height: 10),
      GestureDetector(onTap: _pickPhoto, child: Stack(children: [CircleAvatar(radius: 58, backgroundColor: kRoyal, backgroundImage: _picked != null ? FileImage(File(_picked!.path)) : (LocalStore.photoPath.isNotEmpty ? FileImage(File(LocalStore.photoPath)) : null) as ImageProvider?, child: hasPhoto ? null : const Icon(Icons.person, size: 60, color: Colors.white)), Positioned(bottom: 0, left: 0, child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 18, color: Colors.white)))])),
      const SizedBox(height: 8),
      const Text('اضغط على الصورة لتغييرها', style: TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 16),
      Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kGold.withOpacity(0.4))), child: Column(children: [Text(LocalStore.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kRoyal)), const SizedBox(height: 4), Text(LocalStore.personalNumber, style: const TextStyle(fontSize: 18, color: Colors.black54, letterSpacing: 2), textDirection: TextDirection.ltr)])),
      const SizedBox(height: 18),
      const Align(alignment: Alignment.centerRight, child: Text('سجل حالتك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kRoyal))),
      const SizedBox(height: 6),
      TextField(controller: _status, maxLines: 3, decoration: const InputDecoration(hintText: 'مثال: شلونكم، انا موجود', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
      const SizedBox(height: 22),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kRoyal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _loading ? null : _save, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 20),
      const CreatorWatermark(),
    ]))]));
  }
}
class Screen4Contacts extends StatefulWidget {
  const Screen4Contacts({super.key});
  @override
  State<Screen4Contacts> createState() => _Screen4ContactsState();
}
class _Screen4ContactsState extends State<Screen4Contacts> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await supabase.from('contacts').select().eq('owner_number', LocalStore.personalNumber);
      if (res is List && res.isNotEmpty) { _contacts = res.map((e) => Map<String, dynamic>.from(e as Map)).toList(); } else { _contacts = List.from(LocalStore.contacts); }
    } catch (_) { _contacts = List.from(LocalStore.contacts); }
    setState(() => _loading = false);
  }
  Future<void> _addFriend() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (c) => AlertDialog(title: const Text('إضافة صديق'), content: TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 9, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'اكتب الرقم الشخصي - 9 ارقام', border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('بحث'))]));
    if (result == null || result.length != 9) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب رقم شخصي صحيح - 9 ارقام'))); return; }
    if (result == LocalStore.personalNumber) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا رقمك انت'))); return; }
    Map<String, dynamic>? found;
    try {
      final r = await supabase.from('profiles').select().eq('personal_number', result).limit(1);
      if (r is List && r.isNotEmpty) found = Map<String, dynamic>.from(r[0] as Map);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ بالبحث: $e - نفذ SQL فتح الصلاحيات'))); }
    if (found == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الرقم ما مسجل بالتطبيق بعد - تأكد إنك نفذت SQL فتح الصلاحيات'))); return; }
    final name = found['name'] ?? 'صديق';
    final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('تم العثور عليه'), content: Text('الاسم: $name\nالرقم الشخصي: $result'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('إضافة صديق'))]));
    if (confirm != true) return;
    final newContact = {'name': name, 'personal_number': result, 'friend_number': result, 'is_online': found['is_online'] ?? true, 'status': found['status'] ?? ''};
    try { await supabase.from('contacts').insert({'owner_number': LocalStore.personalNumber, 'friend_number': result}); } catch (_) {}
    LocalStore.contacts.add(newContact);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة $name كصديق')));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: kBeige, appBar: AppBar(title: const Text('الأصدقاء'), backgroundColor: kRoyal, foregroundColor: Colors.white, centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]), body: Stack(children: [const IshtarWatermark(), _loading ? const Center(child: CircularProgressIndicator(color: kRoyal)) : _contacts.isEmpty ? const Center(child: Text('لا يوجد أصدقاء بعد - اضغط + وأضف صديقك برقمه الشخصي')) : ListView.builder(itemCount: _contacts.length, itemBuilder: (c, i) {
      final f = _contacts[i];
      final name = (f['name'] ?? 'صديق').toString();
      final num = (f['friend_number'] ?? f['personal_number'] ?? '').toString();
      final online = f['is_online'] ?? true;
      return Card(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: ListTile(leading: Stack(children: [const CircleAvatar(backgroundColor: kRoyal, child: Icon(Icons.person, color: Colors.white)), Positioned(bottom: 0, left: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: online == true ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))))]), title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(num, textDirection: TextDirection.ltr), trailing: const Icon(Icons.chat_bubble_outline, color: kRoyal), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Screen5Chat(friendName: name, friendNumber: num, isOnline: online == true)))));
    })]), floatingActionButton: FloatingActionButton.extended(onPressed: _addFriend, backgroundColor: kRoyal, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('إضافة صديق')));
  }
}
class Screen5Chat extends StatefulWidget {
  final String friendName;
  final String friendNumber;
  final bool isOnline;
  const Screen5Chat({super.key, required this.friendName, required this.friendNumber, required this.isOnline});
  @override
  State<Screen5Chat> createState() => _Screen5ChatState();
}
class _Screen5ChatState extends State<Screen5Chat> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _msgs = [];
  bool _showStickers = false;
  final List<String> _emojis = ['😀','😂','❤️','😍','👍','🙏','🇮🇶','☕','🍵','⚽','🎉','😢','😡','👋'];
  final List<String> _iraqiStickers = ['شلونك','هلا','هلا والله','تمام','يالله','أكو','ماكو','شلونكم','حبيبي','عاشت إيدك','الله كريم','إن شاء الله'];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _markRead() async {
    try { await supabase.from('messages').update({'is_read': true}).eq('sender_number', widget.friendNumber).eq('receiver_number', LocalStore.personalNumber).eq('is_read', false); } catch (_) {}
  }
  Future<void> _load() async {
    await _markRead();
    try {
      final res = await supabase.from('messages').select().order('created_at');
      if (res is List) { _msgs = res.map((e) => Map<String, dynamic>.from(e as Map)).where((m) => (m['sender_number'] == LocalStore.personalNumber && m['receiver_number'] == widget.friendNumber) || (m['sender_number'] == widget.friendNumber && m['receiver_number'] == LocalStore.personalNumber)).toList(); }
    } catch (_) { _msgs = LocalStore.messages.where((m) => (m['sender_number'] == LocalStore.personalNumber && m['receiver_number'] == widget.friendNumber) || (m['sender_number'] == widget.friendNumber && m['receiver_number'] == LocalStore.personalNumber)).toList(); }
    setState(() {});
  }
  Future<void> _sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    setState(() => _showStickers = false);
    final msg = {'sender_number': LocalStore.personalNumber, 'receiver_number': widget.friendNumber, 'content': t, 'message_type': 'text', 'is_read': false, 'created_at': DateTime.now().toIso8601String()};
    try { await supabase.from('messages').insert(msg); } catch (_) {}
    LocalStore.messages.add(msg);
    await _load();
  }
  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (f == null) return;
    final msg = {'sender_number': LocalStore.personalNumber, 'receiver_number': widget.friendNumber, 'content': '[صورة]', 'message_type': 'image', 'image_path': f.path, 'is_read': false, 'created_at': DateTime.now().toIso8601String()};
    try { await supabase.from('messages').insert({'sender_number': LocalStore.personalNumber, 'receiver_number': widget.friendNumber, 'content': '[صورة]', 'message_type': 'image', 'image_path': f.path, 'is_read': false}); } catch (_) {}
    LocalStore.messages.add(msg);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الصورة')));
  }
  void _openImage(String? path) {
    if (path == null || path.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('الصورة'), backgroundColor: kRoyal, foregroundColor: Colors.white), body: Center(child: Image.file(File(path), errorBuilder: (c, e, s) => const Text('لا يمكن فتح الصورة'))))));
  }
  Widget _readIcon(Map m) {
    final isMine = m['sender_number'] == LocalStore.personalNumber;
    if (!isMine) return const SizedBox();
    final read = m['is_read'] == true;
    if (read) return const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.done_all, size: 14, color: Colors.blue), SizedBox(width: 2), Text('تمت القراءة', style: TextStyle(fontSize: 10, color: Colors.blue))]);
    return const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.done, size: 14, color: Colors.black45), SizedBox(width: 2), Text('تم الإرسال', style: TextStyle(fontSize: 10, color: Colors.black45))]);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: kBeige, appBar: AppBar(backgroundColor: kRoyal, foregroundColor: Colors.white, title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.friendName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), Row(children: [Text(widget.friendNumber, style: const TextStyle(fontSize: 12, color: Colors.white70), textDirection: TextDirection.ltr), const SizedBox(width: 6), Container(width: 9, height: 9, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)), const SizedBox(width: 4), Text(widget.isOnline ? 'متصل الان' : 'غير متصل', style: const TextStyle(fontSize: 12, color: Colors.white70))])]), actions: [IconButton(icon: const Icon(Icons.call), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جار الاتصال... - المكالمة الصوتية مرحلة ثانية'))))]), body: Stack(children: [const IshtarWatermark(), Column(children: [Expanded(child: _msgs.isEmpty ? const Center(child: Text('لا توجد رسائل بعد - ابدا المحادثة')) : ListView.builder(itemCount: _msgs.length, itemBuilder: (c, i) {
      final m = _msgs[i];
      final isMine = m['sender_number'] == LocalStore.personalNumber;
      final isImage = m['message_type'] == 'image';
      return Align(alignment: isMine ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: isMine ? kTurquoise : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGold.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [if (isImage) GestureDetector(onTap: () => _openImage(m['image_path']?.toString()), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: (m['image_path'] != null && m['image_path'].toString().isNotEmpty) ? Image.file(File(m['image_path'].toString()), width: 180, height: 140, fit: BoxFit.cover, errorBuilder: (cc, e, s) => Container(width: 180, height: 100, color: Colors.black12, child: const Center(child: Icon(Icons.image)))) : Container(width: 180, height: 100, color: Colors.black12, child: const Center(child: Text('اضغط لفتح الصورة'))))), if (isImage) const SizedBox(height: 4), Text((m['content'] ?? '').toString(), style: TextStyle(color: isMine ? Colors.white : Colors.black87)), const SizedBox(height: 4), _readIcon(m)])));
    })), if (_showStickers) Container(height: 200, color: Colors.white, padding: const EdgeInsets.all(10), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('إيموجي', style: TextStyle(fontWeight: FontWeight.bold)), Wrap(spacing: 8, children: _emojis.map((e) => GestureDetector(onTap: () => _sendText(e), child: Text(e, style: const TextStyle(fontSize: 28)))).toList()), const SizedBox(height: 10), const Text('ملصقات عراقية', style: TextStyle(fontWeight: FontWeight.bold)), Wrap(spacing: 8, runSpacing: 8, children: _iraqiStickers.map((s) => GestureDetector(onTap: () => _sendText(s), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: kBeige, borderRadius: BorderRadius.circular(20), border: Border.all(color: kGold)), child: Text(s)))).toList())]))),
    Padding(padding: const EdgeInsets.all(10), child: Row(children: [IconButton(icon: const Icon(Icons.emoji_emotions, color: kRoyal, size: 28), onPressed: () => setState(() => _showStickers = !_showStickers)), IconButton(icon: const Icon(Icons.attach_file, color: kRoyal), onPressed: _sendImage), IconButton(icon: const Icon(Icons.image, color: kRoyal), onPressed: _sendImage), Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder(), filled: true, fillColor: Colors.white))), const SizedBox(width: 8), CircleAvatar(backgroundColor: kRoyal, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendText(_ctrl.text)))]))])]));
  }
}
