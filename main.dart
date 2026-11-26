import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// شلونكم چات - IQ - تطبيق تواصل عراقي
// خارطة العراق 30% - بوابة عشتار علامة مائية - Created by: Atheer Sami علامة مائية زرقاء
// ملف واحد كامل - عمل حقيقي

const String supabaseUrl = 'https://tfcpkoozqttdzligfizu.supabase.co';
const String supabaseAnonKey = 'PUT_YOUR_ANON_KEY_HERE';

const Color kBlue = Color(0xFF1B3A8F);
const Color kTeal = Color(0xFF00C2A8);
const Color kGold = Color(0xFFD9A441);
const Color kBg = Color(0xFFF7F5EF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseAnonKey != 'PUT_YOUR_ANON_KEY_HERE' && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const ShlonkumApp());
}

SupabaseClient? get supabaseClient {
  try { return Supabase.instance.client; } catch (_) { return null; }
}

class ShlonkumApp extends StatelessWidget {
  const ShlonkumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'شلونكم چات - IQ',
      theme: ThemeData(primaryColor: kBlue, colorScheme: ColorScheme.fromSeed(seedColor: kBlue), useMaterial3: true),
      home: const AuthGate(),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}

// بوابة عشتار - العلامة المائية
class IshtarWatermark extends StatelessWidget {
  final double opacity;
  const IshtarWatermark({super.key, this.opacity = 0.08});
  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Center(child: Image.asset('assets/ishtar_gate.jfif', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        ),
      ),
    );
  }
}

// العلامة المائية الزرقاء النظيفة - أسفل شاشة التسجيل + أسفل إنشاء الملف الشخصي
class CreatedByWatermark extends StatelessWidget {
  const CreatedByWatermark({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: kBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: kBlue.withOpacity(0.15))),
      child: const Text('Created by: Atheer Sami', textAlign: TextAlign.center, style: TextStyle(color: kBlue, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}

// خارطة العراق 30% - ثابتة كملصق
class IraqMapSticker extends StatelessWidget {
  const IraqMapSticker({super.key});
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * 0.30;
    return SizedBox(width: w, height: w * 0.85, child: Image.asset('assets/iraq_map.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.map, color: Colors.white)));
  }
}

String normalizeIraqiPhone(String raw) {
  String s = raw.trim().replaceAll(' ', '').replaceAll('-', '');
  if (s.startsWith('+964')) return s;
  if (s.startsWith('964')) return '+$s';
  if (s.startsWith('0')) s = s.substring(1);
  if (s.length == 10 && s.startsWith('7')) return '+964$s';
  return '+964$s';
}

bool isValidIraqiPhone(String raw) {
  final n = normalizeIraqiPhone(raw);
  final d = n.replaceAll('+', '');
  return d.startsWith('964') && d.length == 13 && d[3] == '7';
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final c = supabaseClient;
    if (c != null && c.auth.currentSession != null) return const HomeScreens();
    return const LoginScreen();
  }
}

// شاشة التسجيل / الدخول
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final raw = _phone.text.trim();
    if (!isValidIraqiPhone(raw)) { setState(() => _error = 'أدخل رقماً عراقياً صحيحاً بصيغة 07xxxxxxxxxx'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final c = supabaseClient;
      if (c != null) {
        final phone = normalizeIraqiPhone(raw);
        await c.auth.signInWithOtp(phone: phone);
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
        return;
      }
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreens()));
    } catch (e) {
      setState(() => _error = 'فشل إرسال الرمز: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [const IraqMapSticker(), const SizedBox(height: 8), const Text('شلونكم چات - IQ', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), const Text('تطبيق تواصل عراقي', style: TextStyle(color: Colors.white70))]),
                ),
                const SizedBox(height: 24),
                const Text('دخول برقم الهاتف العراقي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: '07xxxxxxxxxx', prefixText: '+964 ', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
                const SizedBox(height: 12),
                TextField(controller: _code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز التفعيل (اختياري)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
                if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white), onPressed: _loading ? null : _login, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('دخول', style: TextStyle(fontSize: 18)))),
                const SizedBox(height: 24),
                const CreatedByWatermark(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  bool _loading = false;
  String? _error;
  Future<void> _verify() async {
    setState(() { _loading = true; _error = null; });
    try {
      final c = supabaseClient;
      if (c == null) throw Exception('Supabase غير مهيأ');
      await c.auth.verifyOTP(phone: widget.phone, token: _otp.text.trim(), type: OtpType.sms);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreens()), (_) => false);
    } catch (e) {
      setState(() => _error = 'الرمز خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الرمز'), backgroundColor: kBlue, foregroundColor: Colors.white),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Text('أرسلنا رمزاً إلى ${widget.phone}'), const SizedBox(height: 16), TextField(controller: _otp, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), labelText: 'رمز التفعيل')), if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))], const SizedBox(height: 16), SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kBlue), onPressed: _loading ? null : _verify, child: const Text('تأكيد ودخول', style: TextStyle(color: Colors.white)))), const SizedBox(height: 24), const CreatedByWatermark()])),
    );
  }
}

// الشاشة الرئيسية
class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});
  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  int _index = 0;
  double _opacity = 0.08;
  @override
  Widget build(BuildContext context) {
    final pages = [ChatsTab(watermarkOpacity: _opacity), FriendsTab(watermarkOpacity: _opacity), CallsTab(watermarkOpacity: _opacity), ProfileTab(watermarkOpacity: _opacity, onOpacityChanged: (v) => setState(() => _opacity = v))];
    return Scaffold(
      appBar: AppBar(backgroundColor: kBlue, foregroundColor: Colors.white, title: const Row(children: [IraqMapSticker(), SizedBox(width: 8), Text('شلونكم چات - IQ')]), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async { final c = supabaseClient; if (c != null) await c.auth.signOut(); if (!mounted) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); })]),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(currentIndex: _index, selectedItemColor: kBlue, unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed, onTap: (i) => setState(() => _index = i), items: const [BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'محادثات'), BottomNavigationBarItem(icon: Icon(Icons.people), label: 'أصدقاء'), BottomNavigationBarItem(icon: Icon(Icons.call), label: 'مكالمات'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي')]),
    );
  }
}

class ChatsTab extends StatefulWidget {
  final double watermarkOpacity;
  const ChatsTab({super.key, required this.watermarkOpacity});
  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  List<Map<String, dynamic>> _msgs = [];
  bool _loading = true;
  final _q = TextEditingController();
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final c = supabaseClient;
      if (c == null) { setState(() => _loading = false); return; }
      final res = await c.from('messages').select().order('created_at', ascending: false).limit(50);
      setState(() { _msgs = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim();
    final filtered = q.isEmpty ? _msgs : _msgs.where((m) => (m['content'] ?? '').toString().contains(q)).toList();
    return Stack(children: [
      IshtarWatermark(opacity: widget.watermarkOpacity),
      Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _q, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'بحث...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: Colors.white))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : filtered.isEmpty ? const Center(child: Text('لا توجد محادثات بعد - ابدأ محادثة جديدة')) : ListView.builder(itemCount: filtered.length, itemBuilder: (_, i) { final m = filtered[i]; return ListTile(leading: const CircleAvatar(backgroundColor: kTeal, child: Icon(Icons.person, color: Colors.white)), title: Text((m['sender_phone'] ?? '').toString()), subtitle: Text((m['content'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DirectChatScreen(receiverPhone: (m['sender_phone'] ?? '').toString(), watermarkOpacity: widget.watermarkOpacity)))); })),
      ]),
    ]);
  }
}

class DirectChatScreen extends StatefulWidget {
  final String receiverPhone;
  final double watermarkOpacity;
  const DirectChatScreen({super.key, required this.receiverPhone, required this.watermarkOpacity});
  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final c = supabaseClient;
    if (c == null) return;
    final res = await c.from('messages').select().order('created_at', ascending: true).limit(200);
    if (mounted) setState(() => _list = List<Map<String, dynamic>>.from(res));
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    final c = supabaseClient;
    if (c == null) return;
    final me = c.auth.currentUser?.phone ?? 'me';
    _ctrl.clear();
    try { await c.from('messages').insert({'sender_phone': me, 'receiver_phone': widget.receiverPhone, 'content': t}); _load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإرسال: $e'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverPhone), backgroundColor: kBlue, foregroundColor: Colors.white),
      body: Stack(children: [
        IshtarWatermark(opacity: widget.watermarkOpacity),
        Column(children: [
          Expanded(child: ListView.builder(itemCount: _list.length, itemBuilder: (_, i) { final m = _list[i]; final isMe = (m['sender_phone'] ?? '') == (supabaseClient?.auth.currentUser?.phone ?? 'me'); return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe ? kBlue : kTeal, borderRadius: BorderRadius.circular(14)), child: Text((m['content'] ?? '').toString(), style: const TextStyle(color: Colors.white)))); })),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.send, color: kBlue), onPressed: _send)])),
        ]),
      ]),
    );
  }
}

class FriendsTab extends StatelessWidget {
  final double watermarkOpacity;
  const FriendsTab({super.key, required this.watermarkOpacity});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      IshtarWatermark(opacity: watermarkOpacity),
      FutureBuilder(future: supabaseClient?.from('profiles').select().limit(50), builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snap.data is List ? List<Map<String, dynamic>>.from(snap.data as List) : <Map<String, dynamic>>[];
        if (data.isEmpty) return const Center(child: Text('لا يوجد أصدقاء بعد'));
        return ListView.builder(itemCount: data.length, itemBuilder: (_, i) { final p = data[i]; final phone = (p['phone'] ?? '').toString(); return ListTile(leading: const CircleAvatar(backgroundColor: kBlue, child: Icon(Icons.person, color: Colors.white)), title: Text(phone), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DirectChatScreen(receiverPhone: phone, watermarkOpacity: watermarkOpacity)))); });
      }),
    ]);
  }
}

class CallsTab extends StatelessWidget {
  final double watermarkOpacity;
  const CallsTab({super.key, required this.watermarkOpacity});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      IshtarWatermark(opacity: watermarkOpacity),
      FutureBuilder(future: supabaseClient?.from('calls').select().order('created_at', ascending: false).limit(50), builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snap.data is List ? List<Map<String, dynamic>>.from(snap.data as List) : <Map<String, dynamic>>[];
        if (data.isEmpty) return const Center(child: Text('لا توجد مكالمات بعد'));
        return ListView.builder(itemCount: data.length, itemBuilder: (_, i) { final c = data[i]; return ListTile(leading: const CircleAvatar(backgroundColor: kGold, child: Icon(Icons.call, color: Colors.white)), title: Text((c['receiver_phone'] ?? '').toString()), subtitle: Text((c['status'] ?? 'مكالمة صوتية').toString())); });
      }),
    ]);
  }
}

class ProfileTab extends StatelessWidget {
  final double watermarkOpacity;
  final ValueChanged<double> onOpacityChanged;
  const ProfileTab({super.key, required this.watermarkOpacity, required this.onOpacityChanged});
  @override
  Widget build(BuildContext context) {
    final phone = supabaseClient?.auth.currentUser?.phone ?? 'غير مسجل';
    return Stack(children: [
      IshtarWatermark(opacity: watermarkOpacity),
      SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        const CircleAvatar(radius: 48, backgroundColor: kBlue, child: Icon(Icons.person, size: 48, color: Colors.white)),
        const SizedBox(height: 12),
        Text(phone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        const Text('شفافية بوابة عشتار', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(value: watermarkOpacity, min: 0, max: 0.20, onChanged: onOpacityChanged),
        Text('${(watermarkOpacity * 100).round()}%'),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kGold), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen())), child: const Text('تعديل الملف الشخصي', style: TextStyle(color: Colors.white)))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 52, child: OutlinedButton(onPressed: () async { final c = supabaseClient; if (c != null) await c.auth.signOut(); if (!context.mounted) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); }, child: const Text('تسجيل خروج', style: TextStyle(color: Colors.red)))),
      ])),
    ]);
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء الملف الشخصي'), backgroundColor: kBlue, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 48, backgroundColor: kBlue, child: Icon(Icons.person, size: 48, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: InputDecoration(labelText: 'الاسم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kBlue), onPressed: () async { final c = supabaseClient; final phone = c?.auth.currentUser?.phone ?? ''; if (c != null && phone.isNotEmpty) { await c.from('profiles').upsert({'phone': phone}); } if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الملف'))); Navigator.pop(context); }, child: const Text('حفظ', style: TextStyle(color: Colors.white)))),
            const Spacer(),
            const CreatedByWatermark(),
          ],
        ),
      ),
    );
  }
}
