import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// عناوين الخادم بالترتيب: الوسيط (Cloudflare Worker) اولا ثم Supabase مباشرة
const List<String> kApiBaseUrls = [
  'https://iq-api.a00072288.workers.dev',
  'https://tfcpkoozqttdzligfizu.supabase.co',
];
// جداول هذا التطبيق منفصلة عن جداول التطبيقات الاخرى بنفس مشروع Supabase
const String kTablePrefix = 'iq_';
const String kApiAnonKey = 'sb_publishable_nbqpxqvicOkjDlrtQmbrug_J0r557Sv';

const Color kRoyal = Color(0xFF1B3A8F);
const Color kTurquoise = Color(0xFF00C2A8);
const Color kGold = Color(0xFFD9A441);
const Color kBeige = Color(0xFFF7F5EF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShlonkumApp());
}

class ApiClient {
  static Map<String, String> get _headers => {
        'apikey': kApiAnonKey,
        'Authorization': 'Bearer $kApiAnonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  static Uri _uri(String base, String table, [Map<String, String>? query]) {
    final u = Uri.parse('$base/rest/v1/$kTablePrefix$table');
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: query);
  }

  // يجرب العناوين بالترتيب، وينتقل للتالي فقط عند فشل الشبكة
  static Future<http.Response> _request(
    String method,
    String table,
    Map<String, String>? query, {
    Object? body,
  }) async {
    Object? lastError;
    for (final base in kApiBaseUrls) {
      try {
        final uri = _uri(base, table, query);
        final Future<http.Response> req;
        if (method == 'GET') {
          req = http.get(uri, headers: _headers);
        } else if (method == 'POST') {
          req = http.post(uri, headers: _headers, body: jsonEncode(body));
        } else {
          req = http.patch(uri, headers: _headers, body: jsonEncode(body));
        }
        return await req.timeout(const Duration(seconds: 12));
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('لا يوجد اتصال');
  }

  static Future<List> getRows(String table, Map<String, String> query) async {
    final res = await _request('GET', table, query);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;
    return [];
  }

  static Future<void> insertRow(String table, Map<String, dynamic> body) async {
    final res = await _request('POST', table, null, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  static Future<void> updateRows(
    String table,
    Map<String, String> query,
    Map<String, dynamic> body,
  ) async {
    final res = await _request('PATCH', table, query, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }
}

class LocalStore {
  static String name = '';
  static String password = '';
  static String personalNumber = '';
  static String status = '';
  static String photoPath = '';
  static List contacts = [];
  static List messages = [];

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('name', name);
    await p.setString('password', password);
    await p.setString('personalNumber', personalNumber);
    await p.setString('status', status);
    await p.setString('photoPath', photoPath);
    await p.setString('contacts', jsonEncode(contacts));
    await p.setString('messages', jsonEncode(messages));
  }

  static Future<bool> load() async {
    final p = await SharedPreferences.getInstance();
    name = p.getString('name') ?? '';
    password = p.getString('password') ?? '';
    personalNumber = p.getString('personalNumber') ?? '';
    status = p.getString('status') ?? '';
    photoPath = p.getString('photoPath') ?? '';
    try {
      final c = p.getString('contacts');
      if (c != null && c.isNotEmpty) contacts = jsonDecode(c) as List;
      final m = p.getString('messages');
      if (m != null && m.isNotEmpty) messages = jsonDecode(m) as List;
    } catch (_) {}
    return personalNumber.length == 9 && name.isNotEmpty;
  }
}

class IshtarWatermark extends StatelessWidget {
  const IshtarWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.12,
          child: Image.asset(
            'assets/ishtar_gate.jfif',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const SizedBox(),
          ),
        ),
      ),
    );
  }
}

class CreatorWatermark extends StatelessWidget {
  const CreatorWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        'Created by: Atheer Sami',
        style: TextStyle(
          color: Color(0xFF1B3A8F),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
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
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const SplashGate(),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final has = await LocalStore.load();
    if (!mounted) return;
    if (has) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Screen4Contacts()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Screen1Register()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBeige,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'شلونكم چات - IQ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kRoyal,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: kRoyal),
          ],
        ),
      ),
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
  final r = Random.secure();
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

  @override
  void dispose() {
    _name.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final pass = _pass.text.trim();
    if (name.isEmpty) {
      setState(() => _msg = 'سجل اسمك اولا');
      return;
    }
    if (!isStrongPassword(pass)) {
      setState(() => _msg = 'كلمة المرور ضعيفة - راجع الملاحظة بالاسفل');
      return;
    }

    setState(() {
      _loading = true;
      _msg = '';
    });

    await LocalStore.load();
    String num = '';
    bool isReturning = false;

    // 1) حساب محفوظ على الجهاز بنفس الاسم وكلمة المرور
    if (LocalStore.name == name &&
        LocalStore.password == pass &&
        LocalStore.personalNumber.length == 9) {
      num = LocalStore.personalNumber;
      isReturning = true;
    }

    // 2) الخادم
    try {
      final rows = await ApiClient.getRows('profiles', {
        'select': 'personal_number,status',
        'name': 'eq.$name',
        'password_hash': 'eq.$pass',
        'limit': '1',
      });

      if (rows.isNotEmpty) {
        final serverNum = (rows[0]['personal_number'] ?? '').toString().trim();
        if (serverNum.length == 9) {
          num = serverNum; // رقم الخادم هو المرجع
          LocalStore.status = (rows[0]['status'] ?? '').toString();
          isReturning = true;
        }
      } else if (isReturning) {
        // الحساب موجود محليا وغير موجود بالخادم: ارفعه بنفس الرقم
        try {
          await ApiClient.insertRow('profiles', {
            'name': name,
            'password_hash': pass,
            'personal_number': num,
            'status': LocalStore.status,
            'is_online': true,
            'last_seen': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {}
      } else {
        // حساب جديد فعلا
        num = generatePersonalNumber();
        for (int i = 0; i < 5; i++) {
          final ex = await ApiClient.getRows('profiles', {
            'select': 'personal_number',
            'personal_number': 'eq.$num',
            'limit': '1',
          });
          if (ex.isEmpty) break;
          num = generatePersonalNumber();
        }
        await ApiClient.insertRow('profiles', {
          'name': name,
          'password_hash': pass,
          'personal_number': num,
          'status': LocalStore.status,
          'is_online': true,
          'last_seen': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      if (num.isEmpty) {
        // لا حساب محلي ولا وصول للخادم: لا نولّد رقما جديدا ابدا
        if (mounted) {
          setState(() {
            _loading = false;
            _msg =
                'تعذر الاتصال بالخادم. اول تسجيل او الدخول من جهاز جديد يحتاج اتصالا بالخادم. حاول لاحقا.\n$e';
          });
        }
        return;
      }
      // يوجد رقم محلي: نكمل به دون الخادم
    }

    LocalStore.name = name;
    LocalStore.password = pass;
    LocalStore.personalNumber = num;
    await LocalStore.save();

    if (!mounted) return;
    setState(() => _loading = false);
    if (isReturning) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Screen4Contacts()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Screen2PersonalNumber(number: num)),
      );
    }
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
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.30,
                  child: Image.asset(
                    'assets/iraq_map.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.map, size: 70, color: kRoyal),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'شلونكم چات - IQ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: kRoyal,
                  ),
                ),
                const Text(
                  'تطبيق تواصل عراقي لكل العراق',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'سجل اسمك',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kRoyal,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    hintText: 'مثال: أثير سامي',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'انشاء كلمة مرور قوية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kRoyal,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pass,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kGold.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'كلمة المرور يجب ان تكون 8 احرف، وتحتوي على حرف كبير ورقم وحرف خاص',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRoyal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تسجيل',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_msg.isNotEmpty)
                  Text(
                    _msg,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                const CreatorWatermark(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Screen2PersonalNumber extends StatelessWidget {
  final String number;
  const Screen2PersonalNumber({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: Stack(
        children: [
          const IshtarWatermark(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'شلونكم چات - IQ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kRoyal,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'هذا يعتبر رقمك الشخصي احفظه جيدا من خلاله تضيف جهات الاتصال لديك ويضيفونك وغير قابل للتغيير',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kGold, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'رقمك الشخصي',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          number,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: kRoyal,
                            letterSpacing: 4,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'اضغط مطولا للنسخ',
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRoyal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Screen3Profile()),
                      ),
                      child: const Text(
                        'ادخل',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const CreatorWatermark(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _status.text = LocalStore.status;
  }

  @override
  void dispose() {
    _status.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (f != null) {
      setState(() => _picked = f);
      LocalStore.photoPath = f.path;
      await LocalStore.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير الصورة الشخصية')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    LocalStore.status = _status.text.trim();
    try {
      await ApiClient.updateRows(
        'profiles',
        {'personal_number': 'eq.${LocalStore.personalNumber}'},
        {'status': LocalStore.status},
      );
    } catch (_) {}
    await LocalStore.save();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Screen4Contacts()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePath = _picked?.path ?? LocalStore.photoPath;
    final hasPhoto = activePath.isNotEmpty && File(activePath).existsSync();
    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(
        title: const Text('انشاء ملفك الشخصي'),
        backgroundColor: kRoyal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const IshtarWatermark(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 58,
                        backgroundColor: kRoyal,
                        backgroundImage:
                            hasPhoto ? FileImage(File(activePath)) : null,
                        child: hasPhoto
                            ? null
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: kGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'اضغط على الصورة لتغييرها',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kGold.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        LocalStore.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kRoyal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocalStore.personalNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          letterSpacing: 2,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'سجل حالتك',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kRoyal,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _status,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'مثال: شلونكم، انا موجود',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRoyal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'حفظ',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const CreatorWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Screen4Contacts extends StatefulWidget {
  const Screen4Contacts({super.key});

  @override
  State<Screen4Contacts> createState() => _Screen4ContactsState();
}

class _Screen4ContactsState extends State<Screen4Contacts> {
  List _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getRows('contacts', {
        'select': 'friend_number',
        'owner_number': 'eq.${LocalStore.personalNumber}',
      });
      if (res.isNotEmpty) {
        final nums = res
            .map((e) => (e['friend_number'] ?? '').toString().trim())
            .where((n) => n.isNotEmpty)
            .toList();
        final merged = [];
        for (final n in nums) {
          final profs = await ApiClient.getRows('profiles', {
            'select': 'name,personal_number,is_online,status',
            'personal_number': 'eq.$n',
            'limit': '1',
          });
          final p = profs.isNotEmpty ? profs[0] : null;
          merged.add({
            'name': (p?['name'] ?? 'صديق').toString(),
            'friend_number': n,
            'is_online': p?['is_online'] == true,
            'status': (p?['status'] ?? '').toString(),
          });
        }
        _contacts = merged;
        LocalStore.contacts = merged;
        await LocalStore.save();
      } else {
        _contacts = List.from(LocalStore.contacts);
      }
    } catch (_) {
      _contacts = List.from(LocalStore.contacts);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _addFriend() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('إضافة صديق'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 9,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            hintText: 'اكتب الرقم الشخصي - 9 ارقام',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: const Text('بحث'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null) return;
    if (result.length != 9) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اكتب رقم شخصي صحيح - 9 ارقام')),
        );
      }
      return;
    }
    if (result == LocalStore.personalNumber) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذا رقمك انت')),
        );
      }
      return;
    }

    Map? found;
    try {
      final r = await ApiClient.getRows('profiles', {
        'select': 'name,personal_number,is_online,status',
        'personal_number': 'eq.$result',
        'limit': '1',
      });
      if (r.isNotEmpty) found = Map.from(r[0] as Map);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text('تعذر الاتصال بالخادم، تحقق من الانترنت وحاول مرة اخرى\n$e'),
          ),
        );
      }
      return;
    }

    if (found == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذا الرقم غير مسجل بالتطبيق بعد')),
        );
      }
      return;
    }
    if (!mounted) return;

    final name = (found['name'] ?? 'صديق').toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تم العثور عليه'),
        content: Text('الاسم: $name\nالرقم الشخصي: $result'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('إضافة صديق'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final newContact = {
      'name': name,
      'personal_number': result,
      'friend_number': result,
      'is_online': found['is_online'] == true,
      'status': (found['status'] ?? '').toString(),
    };
    try {
      await ApiClient.insertRow('contacts', {
        'owner_number': LocalStore.personalNumber,
        'friend_number': result,
      });
    } catch (_) {}
    final already = LocalStore.contacts.any((c) =>
        (c['friend_number'] ?? c['personal_number'] ?? '').toString() ==
        result);
    if (!already) LocalStore.contacts.add(newContact);
    await LocalStore.save();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة $name كصديق')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(
        title: const Text('الأصدقاء'),
        backgroundColor: kRoyal,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Stack(
        children: [
          const IshtarWatermark(),
          _loading
              ? const Center(child: CircularProgressIndicator(color: kRoyal))
              : _contacts.isEmpty
                  ? const Center(
                      child: Text(
                        'لا يوجد أصدقاء بعد - اضغط + وأضف صديقك برقمه الشخصي',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (c, i) {
                        final f = _contacts[i];
                        final name = (f['name'] ?? 'صديق').toString();
                        final num =
                            (f['friend_number'] ?? f['personal_number'] ?? '')
                                .toString();
                        final online = f['is_online'] == true;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: Stack(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: kRoyal,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: online ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text(num, textDirection: TextDirection.ltr),
                            trailing: const Icon(
                              Icons.chat_bubble_outline,
                              color: kRoyal,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Screen5Chat(
                                  friendName: name,
                                  friendNumber: num,
                                  isOnline: online,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFriend,
        backgroundColor: kRoyal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة صديق'),
      ),
    );
  }
}

class Screen5Chat extends StatefulWidget {
  final String friendName;
  final String friendNumber;
  final bool isOnline;

  const Screen5Chat({
    super.key,
    required this.friendName,
    required this.friendNumber,
    required this.isOnline,
  });

  @override
  State<Screen5Chat> createState() => _Screen5ChatState();
}

class _Screen5ChatState extends State<Screen5Chat> {
  final _ctrl = TextEditingController();
  List _msgs = [];
  bool _showStickers = false;
  final List _emojis = [
    '😀', '😂', '❤️', '😍', '👍', '🙏', '🇮🇶', '☕', '🍵', '⚽', '🎉', '😢', '😡', '👋'
  ];
  final List _iraqiStickers = [
    'شلونك', 'هلا', 'هلا والله', 'تمام', 'يالله', 'أكو', 'ماكو', 'شلونكم', 'حبيبي', 'عاشت إيدك', 'الله كريم', 'إن شاء الله'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await ApiClient.updateRows(
        'messages',
        {
          'sender_number': 'eq.${widget.friendNumber}',
          'receiver_number': 'eq.${LocalStore.personalNumber}',
          'is_read': 'eq.false',
        },
        {'is_read': true},
      );
    } catch (_) {}
  }

  Future<void> _load() async {
    await _markRead();
    final me = LocalStore.personalNumber;
    final peer = widget.friendNumber;
    try {
      final res = await ApiClient.getRows('messages', {
        'select': '*',
        'or':
            '(and(sender_number.eq.$me,receiver_number.eq.$peer),and(sender_number.eq.$peer,receiver_number.eq.$me))',
        'order': 'created_at.asc',
      });
      _msgs = res;
    } catch (_) {
      _msgs = LocalStore.messages
          .where((m) =>
              (m['sender_number'] == me && m['receiver_number'] == peer) ||
              (m['sender_number'] == peer && m['receiver_number'] == me))
          .toList();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    setState(() => _showStickers = false);
    final msg = {
      'sender_number': LocalStore.personalNumber,
      'receiver_number': widget.friendNumber,
      'content': t,
      'message_type': 'text',
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      await ApiClient.insertRow('messages', msg);
    } catch (_) {}
    LocalStore.messages.add(msg);
    await LocalStore.save();
    await _load();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (f == null) return;
    final msg = {
      'sender_number': LocalStore.personalNumber,
      'receiver_number': widget.friendNumber,
      'content': '[صورة]',
      'message_type': 'image',
      'image_path': f.path,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      await ApiClient.insertRow('messages', {
        'sender_number': LocalStore.personalNumber,
        'receiver_number': widget.friendNumber,
        'content': '[صورة]',
        'message_type': 'image',
        'image_path': f.path,
        'is_read': false,
      });
    } catch (_) {}
    LocalStore.messages.add(msg);
    await LocalStore.save();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الصورة')),
      );
    }
  }

  void _openImage(String? path) {
    if (path == null || path.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('الصورة'),
            backgroundColor: kRoyal,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Image.file(
              File(path),
              errorBuilder: (c, e, s) => const Text('لا يمكن فتح الصورة'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _readIcon(Map m) {
    final isMine = m['sender_number'] == LocalStore.personalNumber;
    if (!isMine) return const SizedBox();
    final read = m['is_read'] == true;
    if (read) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 14, color: Colors.blue),
          SizedBox(width: 2),
          Text('تمت القراءة', style: TextStyle(fontSize: 10, color: Colors.blue)),
        ],
      );
    }
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done, size: 14, color: Colors.black45),
        SizedBox(width: 2),
        Text(
          'تم الإرسال',
          style: TextStyle(fontSize: 10, color: Colors.black45),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(
        backgroundColor: kRoyal,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.friendName,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  widget.friendNumber,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: widget.isOnline ? Colors.greenAccent : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isOnline ? 'متصل الان' : 'غير متصل',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('جار الاتصال... - المكالمة الصوتية مرحلة ثانية'),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const IshtarWatermark(),
          Column(
            children: [
              Expanded(
                child: _msgs.isEmpty
                    ? const Center(
                        child: Text('لا توجد رسائل بعد - ابدا المحادثة'),
                      )
                    : ListView.builder(
                        itemCount: _msgs.length,
                        itemBuilder: (c, i) {
                          final m = _msgs[i];
                          final isMine =
                              m['sender_number'] == LocalStore.personalNumber;
                          final isImage = m['message_type'] == 'image';
                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMine ? kTurquoise : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: kGold.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isImage)
                                    GestureDetector(
                                      onTap: () => _openImage(
                                        m['image_path']?.toString(),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: (m['image_path'] != null &&
                                                m['image_path']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? Image.file(
                                                File(m['image_path'].toString()),
                                                width: 180,
                                                height: 140,
                                                fit: BoxFit.cover,
                                                errorBuilder: (cc, e, s) =>
                                                    Container(
                                                  width: 180,
                                                  height: 100,
                                                  color: Colors.black12,
                                                  child: const Center(
                                                    child: Icon(Icons.image),
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                width: 180,
                                                height: 100,
                                                color: Colors.black12,
                                                child: const Center(
                                                  child: Text('اضغط لفتح الصورة'),
                                                ),
                                              ),
                                      ),
                                    ),
                                  if (isImage) const SizedBox(height: 4),
                                  Text(
                                    (m['content'] ?? '').toString(),
                                    style: TextStyle(
                                      color:
                                          isMine ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _readIcon(m),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_showStickers)
                Container(
                  height: 200,
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إيموجي',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8,
                          children: _emojis
                              .map(
                                (e) => GestureDetector(
                                  onTap: () => _sendText(e),
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'ملصقات عراقية',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _iraqiStickers
                              .map(
                                (s) => GestureDetector(
                                  onTap: () => _sendText(s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kBeige,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: kGold),
                                    ),
                                    child: Text(s),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.emoji_emotions,
                        color: kRoyal,
                        size: 28,
                      ),
                      onPressed: () =>
                          setState(() => _showStickers = !_showStickers),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: kRoyal),
                      onPressed: _sendImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.image, color: kRoyal),
                      onPressed: _sendImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالتك...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: kRoyal,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendText(_ctrl.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
