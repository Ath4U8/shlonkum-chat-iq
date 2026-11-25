
// شلونكم چات - IQ | Shlonkum Chat - IQ
// التحديث الأخير المعتمد - نسخة مصححة 2 - الملفات بالجذر - عام لكل العراق
// - ماكو أسماء محافظات بأي مكان
// - خارطة العراق 20% ثابتة كملصق بالهيدر
// - بوابة عشتار هي العلامة المائية الوحيدة
// - السكرول يعمل لكل الشاشات
// - دخول برقم +964 أو رمز تفعيل
// GitHub: https://github.com/Ath4U8/shlonkum-chat-iq
// Backend: Supabase project tfcpkoozqttdzligfizu

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://tfcpkoozqttdzligfizu.supabase.co';
const String supabaseAnonKey = 'PUT_YOUR_ANON_KEY_HERE'; // من Supabase Settings > API

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ShlonkumApp());
}

final supabase = Supabase.instance.client;

class ShlonkumApp extends StatelessWidget {
  const ShlonkumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'شلونكم چات - IQ',
      theme: ThemeData(
        fontFamily: 'NotoNaskhArabic',
        primaryColor: const Color(0xFF1B3A8F),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3A8F)),
        useMaterial3: true,
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const AuthGate(),
    );
  }
}

// بوابة الدخول - تتحقق من الجلسة في Supabase
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    if (session != null) return const MainShell();
    return const LoginScreen();
  }
}

// شاشة الدخول - ثابتة التصميم لكن قابلة للسكرول إذا الشاشة صغيرة
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    // ملاحظة: التحقق الحقيقي يتم عبر Supabase Auth - OTP
    // للنسخة الأولى ندخل للواجهة الرئيسية، والربط الكامل في الخطوة التالية
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // خارطة العراق - 20% من عرض الشاشة - ثابتة كملصق
                // الملف: iraq_map.png - خارطة العراق بعلم العراق
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.20,
                  child: Image.asset('iraq_map.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                const Text('شلونكم چات - IQ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B3A8F))),
                const Text('تطبيق تواصل عراقي لكل العراق', style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 24),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف العراقي', prefixText: '+964 ', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رمز التفعيل (اختياري)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A8F), foregroundColor: Colors.white),
                    onPressed: _loading ? null : _login,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('دخول', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('اضغط دخول لعرض باقي التطبيق', style: TextStyle(color: Colors.black45)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// الهيكل الرئيسي - هيدر ثابت فيه الخارطة 20% كملصق + سكرول حر للمحتوى
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  double _watermarkOpacity = 0.08;
  final _pages = <Widget>[];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      ChatsScreen(watermarkOpacity: _watermarkOpacity),
      FriendsScreen(watermarkOpacity: _watermarkOpacity),
      CallsScreen(),
      ProfileScreen(onOpacityChanged: (v) => setState(() {
        _watermarkOpacity = v;
        _pages[0] = ChatsScreen(watermarkOpacity: v);
        _pages[1] = FriendsScreen(watermarkOpacity: v);
      }), opacity: _watermarkOpacity),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الهيدر الثابت - الخارطة لا تتحرك مع السكرول
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3A8F),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            // خارطة العراق 20% - ثابتة كملصق
            SizedBox(width: MediaQuery.of(context).size.width * 0.20, height: 32,
              child: Image.asset('iraq_map.png', fit: BoxFit.contain)),
            const SizedBox(width: 8),
            const Text('شلونكم چات - IQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B3A8F),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'المحادثات'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'الأصدقاء'),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'المكالمات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'),
        ],
      ),
    );
  }
}

// ودجت العلامة المائية الوحيدة - بوابة عشتار فقط
class IshtarWatermark extends StatelessWidget {
  final double opacity;
  const IshtarWatermark({super.key, required this.opacity});
  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.001) return const SizedBox.shrink();
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        // الملف: ishtar_gate.jfif - بوابة عشتار
        child: Image.asset('ishtar_gate.jfif', fit: BoxFit.cover, alignment: Alignment.center),
      ),
    );
  }
}

// شاشة المحادثات - سكرول حر + بوابة عشتار علامة مائية
class ChatsScreen extends StatefulWidget {
  final double watermarkOpacity;
  const ChatsScreen({super.key, required this.watermarkOpacity});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}
class _ChatsScreenState extends State<ChatsScreen> {
  String _q = '';
  final _all = [
    {'name': 'شلونكم العام', 'msg': 'هلا والله شلونكم', 'unread': 3},
    {'name': 'أخبار العراق', 'msg': 'آخر الأخبار اليوم', 'unread': 5},
    {'name': 'شعر شعبي', 'msg': 'بيت شعر جديد', 'unread': 0},
    {'name': 'رياضة عراقية', 'msg': 'المباراة اليوم', 'unread': 2},
    {'name': 'ضحك عراقي', 'msg': 'ههههه شوف هذا', 'unread': 0},
    {'name': 'دراسة وشغل', 'msg': 'ملخص المحاضرة', 'unread': 1},
    {'name': 'علي', 'msg': 'شلونك؟', 'unread': 0},
    {'name': 'زينب', 'msg': 'تمام الحمدلله', 'unread': 0},
  ];
  @override
  Widget build(BuildContext context) {
    final list = _all.where((e) => (e['name'] as String).contains(_q) || _q.isEmpty).toList();
    return Stack(
      children: [
        IshtarWatermark(opacity: widget.watermarkOpacity),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(hintText: 'بحث...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (c, i) {
                  final item = list[i];
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF00C2A8), child: Icon(Icons.person, color: Colors.white)),
                    title: Text(item['name'] as String),
                    subtitle: Text(item['msg'] as String),
                    trailing: (item['unread'] as int) > 0 ? CircleAvatar(radius: 12, backgroundColor: const Color(0xFFD9A441), child: Text('${item['unread']}', style: const TextStyle(color: Colors.white, fontSize: 12))) : null,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetail(name: item['name'] as String, watermarkOpacity: widget.watermarkOpacity))),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// شاشة المحادثة الفورية
class ChatDetail extends StatefulWidget {
  final String name; final double watermarkOpacity;
  const ChatDetail({super.key, required this.name, required this.watermarkOpacity});
  @override
  State<ChatDetail> createState() => _ChatDetailState();
}
class _ChatDetailState extends State<ChatDetail> {
  final _ctrl = TextEditingController();
  final _msgs = <String>['هلا والله', 'شلونكم؟', 'تمام الحمدلله'];
  void _send() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _msgs.add(_ctrl.text.trim()); _ctrl.clear(); });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name), backgroundColor: const Color(0xFF1B3A8F), foregroundColor: Colors.white),
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          Column(
            children: [
              Expanded(child: ListView.builder(itemCount: _msgs.length, itemBuilder: (c, i) => Align(
                alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: i.isEven ? Colors.white : const Color(0xFF00C2A8), borderRadius: BorderRadius.circular(16)),
                  child: Text(_msgs[i])),
              ))),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(spacing: 8, children: ['هلا', 'شلونكم', 'تمام الحمدلله', 'دزلي الموقع', 'يلا نطلع', 'هلا والله'].map((r) => ActionChip(label: Text(r), onPressed: () => setState(() => _msgs.add(r)))).toList()),
              ),
              Row(children: [
                Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder()))),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF1B3A8F)), onPressed: _send),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class FriendsScreen extends StatelessWidget {
  final double watermarkOpacity;
  const FriendsScreen({super.key, required this.watermarkOpacity});
  @override
  Widget build(BuildContext context) {
    final friends = ['علي', 'زينب', 'حسين', 'مريم', 'مصطفى', 'نور', 'أحمد', 'فاطمة'];
    return Stack(children: [
      IshtarWatermark(opacity: watermarkOpacity),
      ListView.builder(itemCount: friends.length, itemBuilder: (c, i) => ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFF1B3A8F), child: Icon(Icons.person, color: Colors.white)),
        title: Text(friends[i]),
        subtitle: const Text('متصل الآن'),
        trailing: const Icon(Icons.chat_bubble_outline),
      )),
    ]);
  }
}

class CallsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemCount: 6, itemBuilder: (c, i) => ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0xFFD9A441), child: Icon(Icons.call, color: Colors.white)),
      title: Text('مكالمة ${i + 1}'),
      subtitle: const Text('مكالمة صوتية - 5 دقائق'),
      trailing: IconButton(icon: const Icon(Icons.call), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جارٍ الاتصال...')))),
    ));
  }
}

class ProfileScreen extends StatelessWidget {
  final double opacity; final Function(double) onOpacityChanged;
  const ProfileScreen({super.key, required this.opacity, required this.onOpacityChanged});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const CircleAvatar(radius: 50, backgroundColor: Color(0xFF1B3A8F), child: Icon(Icons.person, size: 50, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('مستخدم شلونكم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('تطبيق تواصل عراقي لكل العراق'),
        const SizedBox(height: 24),
        const Text('علامة العراق المائية - بوابة عشتار فقط', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(value: opacity, min: 0, max: 0.20, onChanged: onOpacityChanged),
        Text('الشفافية: ${(opacity * 100).toStringAsFixed(0)}%'),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('من متصفح الهاتف: مشاركة ثم إضافة إلى الشاشة الرئيسية - لتثبيت التطبيق'))), child: const Text('ثبّت التطبيق على هاتفك'))),
        const SizedBox(height: 12),
        const Text('للنشر: GitHub + Supabase + Cloudflare', style: TextStyle(color: Colors.black45)),
      ]),
    );
  }
}
