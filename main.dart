// شلونكم چات - IQ | Shlonkum Chat - IQ
// المرحلة الأولى - النظام الجديد: الرقم الشخصي 9 أرقام
// الشاشات الخمسة: 1 تسجيل / 2 رقم شخصي / 3 ملف شخصي / 4 جهات اتصال / 5 محادثة
// التصميم الأصلي محفوظ: أزرق ملكي + تركوازي + ذهبي + بيج
// خارطة العراق 30% فقط بشاشة التسجيل - بوابة عشتار علامة مائية فقط
// Created by: Atheer Sami
// العمل حقيقي عبر Supabase - جداول: profiles / contacts / messages
// المكالمة الصوتية: مرحلة ثانية - الزر حاليا تنبيه فقط

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://tfcpkoozqttdzligfizu.supabase.co';
const String supabaseAnonKey = 'PUT_YOUR_ANON_KEY_HERE'; // من Supabase Settings > API

const Color kRoyal = Color(0xFF1B3A8F);
const Color kTurquoise = Color(0xFF00C2A8);
const Color kGold = Color(0xFFD9A441);
const Color kBeige = Color(0xFFF7F5EF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } catch (_) {}
  runApp(const ShlonkumApp());
}

final supabase = Supabase.instance.client;

// ذاكرة محلية احتياطية إذا جدول Supabase غير موجود بعد - لا تحذف جهات الاتصال
class LocalStore {
  static String name = '';
  static String password = '';
  static String personalNumber = '';
  static String status = '';
  static List<Map<String, dynamic>> contacts = [];
  static List<Map<String, dynamic>> messages = [];
}

class ShlonkumApp extends StatelessWidget {
  const ShlonkumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'شلونكم چات - IQ',
      theme: ThemeData(
        primaryColor: kRoyal,
        colorScheme: ColorScheme.fromSeed(seedColor: kRoyal),
        useMaterial3: true,
        fontFamily: 'Noto Naskh Arabic',
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const Screen1Register(),
    );
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
  // أول رقم لا يكون صفر - 9 أرقام
  return (100000000 + r.nextInt(900000000)).toString();
}

// ---------- الشاشة 1: سجل اسمك + انشاء كلمة مرور قوية ----------
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
    if (name.isEmpty) { setState(() => _msg = 'سجل اسمك أولاً'); return; }
    if (!isStrongPassword(pass)) {
      setState(() => _msg = 'كلمة المرور ضعيفة - راجع الملاحظة بالأسفل');
      return;
    }
    setState(() { _loading = true; _msg = ''; });
    // توليد رقم شخصي فريد 9 أرقام
    String num = generatePersonalNumber();
    try {
      // حاول التأكد من عدم التكرار في Supabase - إذا الجدول موجود
      for (int i = 0; i < 5; i++) {
        final ex = await supabase.from('profiles').select('personal_number').eq('personal_number', num).maybeSingle();
        if (ex == null) break;
        num = generatePersonalNumber();
      }
      await supabase.from('profiles').insert({
        'name': name,
        'password_hash': pass,
        'personal_number': num,
        'status': '',
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // إذا Supabase غير جاهز - نحفظ محليا ونكمل - لا نوقف المستخدم
    }
    LocalStore.name = name;
    LocalStore.password = pass;
    LocalStore.personalNumber = num;
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Screen2PersonalNumber(number: num)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // خارطة العراق 30% فقط هنا - ستيكر ثابت
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.30,
                  child: Image.asset('assets/iraq_map.png', fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(Icons.map, size: 70, color: kRoyal)),
                ),
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
                TextField(
                  controller: _pass, obscureText: _obscure, textDirection: TextDirection.ltr,
                  decoration: InputDecoration(hintText: 'Password', border: const OutlineInputBorder(), filled: true, fillColor: Colors.white,
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure))),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: kGold.withOpacity(0.5))),
                  child: const Text('كلمة المرور يجب أن تكون 8 أحرف، وتحتوي على حرف كبير ورقم وحرف خاص', style: TextStyle(fontSize: 13, color: Colors.black54), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 52,
                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kRoyal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: _loading ? null : _register,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 10),
                if (_msg.isNotEmpty) Text(_msg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                const Text('Created by: Atheer Sami', style: TextStyle(color: kRoyal, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- الشاشة 2: رقمك الشخصي 9 أرقام ----------
class Screen2PersonalNumber extends StatelessWidget {
  final String number;
  const Screen2PersonalNumber({super.key, required this.number});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text('شلونكم چات - IQ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kRoyal)),
              const SizedBox(height: 30),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFEDED), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
                child: const Text('هذا يعتبر رقمك الشخصي احفظه جيداً من خلاله تضيف جهات الاتصال لديك ويضيفونك وغير قابل للتغيير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGold, width: 1.5)),
                child: Column(children: [
                  const Text('رقمك الشخصي', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  SelectableText(number, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kRoyal, letterSpacing: 4), textDirection: TextDirection.ltr),
                  const SizedBox(height: 6),
                  const Text('اضغط مطولاً للنسخ', style: TextStyle(fontSize: 12, color: Colors.black45)),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kRoyal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Screen3Profile())),
                  child: const Text('ادخل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))),
              const Spacer(),
              const Text('Created by: Atheer Sami', style: TextStyle(color: kRoyal, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- الشاشة 3: انشاء ملفك الشخصي ----------
class Screen3Profile extends StatefulWidget {
  const Screen3Profile({super.key});
  @override
  State<Screen3Profile> createState() => _Screen3ProfileState();
}
class _Screen3ProfileState extends State<Screen3Profile> {
  final _status = TextEditingController();
  bool _loading = false;
  String _msg = '';
  Future<void> _save() async {
    setState(() => _loading = true);
    LocalStore.status = _status.text.trim();
    try {
      await supabase.from('profiles').update({'status': LocalStore.status}).eq('personal_number', LocalStore.personalNumber);
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Screen4Contacts()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(title: const Text('انشاء ملفك الشخصي'), backgroundColor: kRoyal, foregroundColor: Colors.white, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 10),
          Stack(children: [
            const CircleAvatar(radius: 58, backgroundColor: kRoyal, child: Icon(Icons.person, size: 60, color: Colors.white)),
            Positioned(bottom: 0, left: 0, child: CircleAvatar(radius: 18, backgroundColor: kGold, child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر صورة من معرض هاتفك - ستتوفر بعد ربط الصور')))))),
          ]),
          const SizedBox(height: 20),
          Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kGold.withOpacity(0.4))),
            child: Column(children: [
              Text(LocalStore.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kRoyal)),
              const SizedBox(height: 4),
              Text(LocalStore.personalNumber, style: const TextStyle(fontSize: 18, color: Colors.black54, letterSpacing: 2), textDirection: TextDirection.ltr),
            ])),
          const SizedBox(height: 18),
          const Align(alignment: Alignment.centerRight, child: Text('سجل حالتك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kRoyal))),
          const SizedBox(height: 6),
          TextField(controller: _status, maxLines: 3, decoration: const InputDecoration(hintText: 'مثال: شلونكم، أنا موجود', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kRoyal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _loading ? null : _save, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))),
          if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_msg)),
          const SizedBox(height: 20),
          const Text('Created by: Atheer Sami', style: TextStyle(color: kRoyal, fontSize: 12)),
        ]),
      ),
    );
  }
}

// ---------- الشاشة 4: جهات الاتصال ----------
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
      final res = await supabase.from('contacts').select('*, profiles!contacts_friend_number_fkey(*)').eq('owner_number', LocalStore.personalNumber);
      if (res is List && res.isNotEmpty) {
        _contacts = res.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _contacts = List.from(LocalStore.contacts);
      }
    } catch (_) { _contacts = List.from(LocalStore.contacts); }
    setState(() => _loading = false);
  }
  Future<void> _addContact() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (c) => AlertDialog(
      title: const Text('إضافة جهة اتصال'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 9, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'اكتب الرقم الشخصي - 9 أرقام', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('بحث'))],
    ));
    if (result == null || result.length != 9) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب رقم شخصي صحيح - 9 أرقام')));
      return;
    }
    if (result == LocalStore.personalNumber) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا رقمك أنت')));
      return;
    }
    // بحث حقيقي في Supabase
    Map<String, dynamic>? found;
    try {
      final r = await supabase.from('profiles').select().eq('personal_number', result).maybeSingle();
      if (r != null) found = Map<String, dynamic>.from(r);
    } catch (_) {}
    if (found == null) {
      // بحث محلي احتياطي
      final local = LocalStore.contacts.where((e) => e['personal_number'] == result).toList();
      if (local.isNotEmpty) found = local.first;
    }
    if (found == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الرقم ما مسجل بالتطبيق بعد - دزله رابط التطبيق')));
      return;
    }
    final name = found['name'] ?? 'صديق';
    final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('تم العثور عليه'),
      content: Text('الاسم: $name\nالرقم الشخصي: $result'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('إضافة'))],
    ));
    if (confirm != true) return;
    final newContact = {'name': name, 'personal_number': result, 'is_online': found['is_online'] ?? true, 'status': found['status'] ?? ''};
    try {
      await supabase.from('contacts').insert({'owner_number': LocalStore.personalNumber, 'friend_number': result});
    } catch (_) {}
    LocalStore.contacts.add(newContact);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة $name')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(title: const Text('جهات الاتصال'), backgroundColor: kRoyal, foregroundColor: Colors.white, centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading ? const Center(child: CircularProgressIndicator(color: kRoyal))
        : _contacts.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.people_outline, size: 70, color: kRoyal),
            const SizedBox(height: 12),
            const Text('لا يوجد أصدقاء بعد', style: TextStyle(fontSize: 18)),
            const Text('اضغط + وأضف صديقك برقمه الشخصي', style: TextStyle(color: Colors.black54)),
          ]))
        : ListView.builder(itemCount: _contacts.length, itemBuilder: (c, i) {
            final f = _contacts[i];
            // contacts من Supabase قد يأتي متداخل
            final profile = f['profiles'] is Map ? f['profiles'] as Map : f;
            final name = profile['name'] ?? f['name'] ?? 'صديق';
            final num = profile['personal_number'] ?? f['friend_number'] ?? f['personal_number'] ?? '';
            final online = profile['is_online'] ?? f['is_online'] ?? true;
            return Card(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: ListTile(
              leading: Stack(children: [
                const CircleAvatar(backgroundColor: kRoyal, child: Icon(Icons.person, color: Colors.white)),
                Positioned(bottom: 0, left: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: online == true ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
              ]),
              title: Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(num.toString(), textDirection: TextDirection.ltr),
              trailing: const Icon(Icons.chat_bubble_outline, color: kRoyal),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Screen5Chat(friendName: name.toString(), friendNumber: num.toString(), isOnline: online == true))),
            ));
          }),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addContact, backgroundColor: kRoyal, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('إضافة جهة اتصال')),
    );
  }
}

// ---------- الشاشة 5: المحادثة ----------
class Screen5Chat extends StatefulWidget {
  final String friendName; final String friendNumber; final bool isOnline;
  const Screen5Chat({super.key, required this.friendName, required this.friendNumber, required this.isOnline});
  @override
  State<Screen5Chat> createState() => _Screen5ChatState();
}
class _Screen5ChatState extends State<Screen5Chat> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _msgs = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final res = await supabase.from('messages').select().or('and(sender_number.eq.${LocalStore.personalNumber},receiver_number.eq.${widget.friendNumber}),and(sender_number.eq.${widget.friendNumber},receiver_number.eq.${LocalStore.personalNumber})').order('created_at');
      if (res is List) _msgs = res.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { _msgs = LocalStore.messages.where((m) => (m['sender_number'] == LocalStore.personalNumber && m['receiver_number'] == widget.friendNumber) || (m['sender_number'] == widget.friendNumber && m['receiver_number'] == LocalStore.personalNumber)).toList(); }
    setState(() {});
  }
  Future<void> _send() async {
    final text = _ctrl.text.trim(); if (text.isEmpty) return;
    _ctrl.clear();
    final msg = {'sender_number': LocalStore.personalNumber, 'receiver_number': widget.friendNumber, 'content': text, 'created_at': DateTime.now().toIso8601String()};
    try { await supabase.from('messages').insert(msg); } catch (_) {}
    LocalStore.messages.add(msg);
    await _load();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(backgroundColor: kRoyal, foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.friendName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          Row(children: [
            Text(widget.friendNumber, style: const TextStyle(fontSize: 12, color: Colors.white70), textDirection: TextDirection.ltr),
            const SizedBox(width: 6),
            Container(width: 9, height: 9, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(widget.isOnline ? 'متصل الآن' : 'غير متصل', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جارٍ الاتصال... - المكالمة الصوتية مرحلة ثانية')))),
        ]),
      ),
      body: Stack(children: [
        // بوابة عشتار علامة مائية فقط
        Positioned.fill(child: Opacity(opacity: 0.06, child: Image.asset('assets/ishtar_gate.jfif', fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox()))),
        Column(children: [
          Expanded(child: _msgs.isEmpty ? const Center(child: Text('لا توجد رسائل بعد - ابدأ المحادثة'))
            : ListView.builder(itemCount: _msgs.length, itemBuilder: (c, i) {
                final m = _msgs[i]; final isMine = m['sender_number'] == LocalStore.personalNumber;
                return Align(alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: isMine ? kTurquoise : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGold.withOpacity(0.3))),
                    child: Text(m['content'] ?? '', style: TextStyle(color: isMine ? Colors.white : Colors.black87))));
              })),
          Padding(padding: const EdgeInsets.all(10), child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder(), filled: true, fillColor: Colors.white))),
            const SizedBox(width: 8),
            CircleAvatar(backgroundColor: kRoyal, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _send)),
          ])),
        ]),
      ]),
    );
  }
}
