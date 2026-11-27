import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://tfcpkoozqttdzligfizu.supabase.co';
const String supabaseAnonKey = 'sb_publishable_nbqpxqvicOkjDlrtQmbrug_J0r557Sv';

const Color kRoyal = Color(0xFF1B3A8F);
const Color kTurquoise = Color(0xFF00C2A8);
const Color kGold = Color(0xFFD9A441);
const Color kBeige = Color(0xFFF7F5EF);

bool supabaseReady = false;
String? supabaseInitError;

final SupabaseClient supabase = Supabase.instance.client;

String describeError(Object e) {
  final raw = e.toString();
  if (raw.contains('Failed host lookup') || raw.contains('SocketException')) {
    return 'تعذر الوصول إلى الخادم (مشكلة اتصال أو DNS على الجهاز).';
  }
  if (raw.contains('TimeoutException')) {
    return 'انتهت مهلة الاتصال بالخادم، أعد المحاولة.';
  }
  if (raw.contains('PostgrestException')) {
    return 'خطأ من قاعدة البيانات: $raw';
  }
  return raw;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    supabaseReady = true;
  } catch (e) {
    supabaseReady = false;
    supabaseInitError = describeError(e);
  }
  runApp(const ShlonkumApp());
}

class LocalStore {
  static String name = '';
  static String password = '';
  static String personalNumber = '';
  static String status = '';
  static String photoPath = '';
  static List> contacts = [];
  static List> messages = [];

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
          opacity: 0.07,
          child: Image.asset(
            'ishtar_gate.jfif',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
          color: kRoyal,
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
        child: child ?? const SizedBox.shrink(),
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
    await Future.delayed(const Duration(milliseconds: 450));
    final hasAccount = await LocalStore.load();
    if (!mounted) return;
    if (hasAccount) {
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

  Future<String> _pickUniqueNumber() async {
    for (int i = 0; i < 8; i++) {
      final candidate = generatePersonalNumber();
      final existing = await supabase
          .from('profiles')
          .select('personal_number')
          .eq('personal_number', candidate)
          .maybeSingle();
      if (existing == null) {
        return candidate;
      }
    }
    throw Exception('تعذر توليد رقم شخصي فريد بعد عدة محاولات.');
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final pass = _pass.text.trim();

    if (name.isEmpty) {
      setState(() => _msg = 'سجل اسمك أولاً.');
      return;
    }
    if (!isStrongPassword(pass)) {
      setState(() => _msg = 'كلمة المرور ضعيفة - راجع الملاحظة بالأسفل.');
      return;
    }
    if (!supabaseReady) {
      setState(
        () => _msg = supabaseInitError ?? 'تعذر تهيئة الاتصال بقاعدة البيانات.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _msg = '';
    });

    try {
      final existingUser = await supabase
          .from('profiles')
          .select('personal_number, status')
          .eq('name', name)
          .eq('password_hash', pass)
          .maybeSingle();

      String num = '';
      bool isReturning = false;

      if (existingUser != null) {
        num = (existingUser['personal_number'] ?? '').toString();
        LocalStore.status = (existingUser['status'] ?? '').toString();
        isReturning = num.length == 9;
      }

      if (!isReturning) {
        num = await _pickUniqueNumber();
        await supabase.from('profiles').insert({
          'name': name,
          'password_hash': pass,
          'personal_number': num,
          'status': '',
          'is_online': true,
          'last_seen': DateTime.now().toUtc().toIso8601String(),
        });
      }

      LocalStore.name = name;
      LocalStore.password = pass;
      LocalStore.personalNumber = num;
      await LocalStore.save();

      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = describeError(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                    'iraq_map.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.map,
                      size: 70,
                      color: kRoyal,
                    ),
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
                    'إنشاء كلمة مرور قوية',
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
                    border: Border.all(color: kGold.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'كلمة المرور يجب أن تكون 8 أحرف على الأقل، وتحتوي على حرف كبير ورقم ورمز خاص.',
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
                if (_msg.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _msg,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'هذا يعتبر رقمك الشخصي، احفظه جيداً؛ من خلاله تضيف جهات الاتصال ويضيفونك وهو غير قابل للتغيير.',
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
                          'اضغط مطولاً للنسخ',
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
    if (f == null) return;
    setState(() => _picked = f);
    LocalStore.photoPath = f.path;
    await LocalStore.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم اختيار الصورة الشخصية')),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final newStatus = _status.text.trim();
    LocalStore.status = newStatus;

    try {
      if (supabaseReady && LocalStore.personalNumber.isNotEmpty) {
        await supabase
            .from('profiles')
            .update({
              'status': newStatus,
              'is_online': true,
              'last_seen': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('personal_number', LocalStore.personalNumber);
      }
      await LocalStore.save();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Screen4Contacts()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePath = _picked?.path ?? LocalStore.photoPath;
    final hasPhoto = activePath.isNotEmpty && File(activePath).existsSync();

    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(
        title: const Text('إنشاء ملفك الشخصي'),
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
                    border: Border.all(color: kGold.withValues(alpha: 0.4)),
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
                    hintText: 'مثال: شلونكم، أنا موجود',
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
  List> _contacts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!supabaseReady) {
        throw Exception(
          supabaseInitError ?? 'الاتصال بقاعدة البيانات غير جاهز.',
        );
      }

      final contactRows = await supabase
          .from('contacts')
          .select('friend_number')
          .eq('owner_number', LocalStore.personalNumber);

      final friendNumbers = contactRows
          .map((e) => (e['friend_number'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();

      if (friendNumbers.isEmpty) {
        if (!mounted) return;
        setState(() {
          _contacts = [];
          _loading = false;
        });
        return;
      }

      final profileRows = await supabase
          .from('profiles')
          .select('name, personal_number, is_online, status')
          .inFilter('personal_number', friendNumbers);

      final byNumber = <String, Map<String, dynamic>>{};
      for (final p in profileRows) {
        final num = (p['personal_number'] ?? '').toString();
        byNumber[num] = Map<String, dynamic>.from(p);
      }

      final merged = friendNumbers.map((num) {
        final profile = byNumber[num];
        return <String, dynamic>{
          'name': (profile?['name'] ?? 'صديق').toString(),
          'friend_number': num,
          'is_online': profile?['is_online'] == true,
          'status': (profile?['status'] ?? '').toString(),
        };
      }).toList();

      LocalStore.contacts = merged;
      if (!mounted) return;
      setState(() {
        _contacts = merged;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contacts = List>.from(LocalStore.contacts);
        _error = describeError(e);
        _loading = false;
      });
    }
  }

  Future<void> _addFriend() async {
    final ctrl = TextEditingController();
    final targetNumber = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('إضافة صديق'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 9,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            hintText: 'اكتب الرقم الشخصي - 9 أرقام',
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

    if (targetNumber == null) return;
    if (!RegExp(r'^[1-9][0-9]{8}$').hasMatch(targetNumber)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أدخل رقماً شخصياً صحيحاً مكوّناً من 9 أرقام.'),
          ),
        );
      }
      return;
    }
    if (targetNumber == LocalStore.personalNumber) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذا رقمك أنت.')),
        );
      }
      return;
    }

    try {
      final found = await supabase
          .from('profiles')
          .select('name, personal_number, is_online, status')
          .eq('personal_number', targetNumber)
          .maybeSingle();

      if (!mounted) return;

      if (found == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذا الرقم غير مسجل في التطبيق.')),
        );
        return;
      }

      final friendName = (found['name'] ?? 'صديق').toString();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('تم العثور عليه'),
          content: Text('الاسم: $friendName\nالرقم الشخصي: $targetNumber'),
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

      await supabase.from('contacts').upsert(
        {
          'owner_number': LocalStore.personalNumber,
          'friend_number': targetNumber,
        },
        onConflict: 'owner_number,friend_number',
      );

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة $friendName كصديق.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(e))),
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
          if (_loading)
            const Center(child: CircularProgressIndicator(color: kRoyal))
          else ...[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Material(
                  color: const Color(0xFFFFEDED),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _contacts.isEmpty
                  ? const Center(
                      child: Text(
                        'لا يوجد أصدقاء بعد - اضغط + وأضف صديقك برقمه الشخصي',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (c, i) {
                        final f = _contacts[i];
                        final name = (f['name'] ?? 'صديق').toString();
                        final num = (f['friend_number'] ?? '').toString();
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
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(num, textDirection: TextDirection.ltr),
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
            ),
          ],
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
  List> _msgs = [];
  bool _showStickers = false;
  bool _isOnline = false;
  Timer? _pollTimer;

  final List<String> _emojis = [
    '😀', '😂', '❤️', '😍', '👍', '🙏', '🇮🇶', '☕', '🍵', '⚽', '🎉', '😢', '😡', '👋'
  ];
  final List<String> _iraqiStickers = [
    'شلونك', 'هلا', 'هلا والله', 'تمام', 'يالله', 'أكو', 'ماكو', 'شلونكم', 'حبيبي', 'عاشت إيدك', 'الله كريم', 'إن شاء الله'
  ];

  @override
  void initState() {
    super.initState();
    _isOnline = widget.isOnline;
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (!supabaseReady) return;
    await supabase
        .from('messages')
        .update({'is_read': true})
        .eq('sender_number', widget.friendNumber)
        .eq('receiver_number', LocalStore.personalNumber)
        .eq('is_read', false);
  }

  Future<void> _load({bool silent = false}) async {
    if (!supabaseReady) return;
    try {
      await _markRead();
      final me = LocalStore.personalNumber;
      final peer = widget.friendNumber;

      final rows = await supabase
          .from('messages')
          .select()
          .or(
            'and(sender_number.eq.$me,receiver_number.eq.$peer),and(sender_number.eq.$peer,receiver_number.eq.$me)',
          )
          .order('created_at', ascending: true);

      final peerProfile = await supabase
          .from('profiles')
          .select('is_online')
          .eq('personal_number', peer)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _msgs = rows.map((e) => Map<String, dynamic>.from(e)).toList();
        if (peerProfile != null) {
          _isOnline = peerProfile['is_online'] == true;
        }
      });
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeError(e))),
        );
      }
    }
  }

  Future<void> _sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    setState(() => _showStickers = false);

    try {
      await supabase.from('messages').insert({
        'sender_number': LocalStore.personalNumber,
        'receiver_number': widget.friendNumber,
        'content': t,
        'message_type': 'text',
        'is_read': false,
      });
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(e))),
      );
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (f == null) return;

    try {
      await supabase.from('messages').insert({
        'sender_number': LocalStore.personalNumber,
        'receiver_number': widget.friendNumber,
        'content': '[صورة]',
        'message_type': 'image',
        'image_path': f.path,
        'is_read': false,
      });
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الصورة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(e))),
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
              errorBuilder: (_, __, ___) => const Text('لا يمكن فتح الصورة'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _readIcon(Map<String, dynamic> m) {
    final isMine = m['sender_number'] == LocalStore.personalNumber;
    if (!isMine) return const SizedBox.shrink();
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
                    color: _isOnline ? Colors.greenAccent : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'متصل الآن' : 'غير متصل',
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
                        child: Text('لا توجد رسائل بعد - ابدأ المحادثة'),
                      )
                    : ListView.builder(
                        itemCount: _msgs.length,
                        itemBuilder: (c, i) {
                          final m = _msgs[i];
                          final isMine =
                              m['sender_number'] == LocalStore.personalNumber;
                          final isImage = m['message_type'] == 'image';
                          final imgPath = m['image_path']?.toString() ?? '';

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
                                  color: kGold.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isImage) ...[
                                    GestureDetector(
                                      onTap: () => _openImage(imgPath),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: imgPath.isNotEmpty &&
                                                File(imgPath).existsSync()
                                            ? Image.file(
                                                File(imgPath),
                                                width: 180,
                                                height: 140,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 180,
                                                height: 100,
                                                color: Colors.black12,
                                                child: const Center(
                                                  child: Icon(Icons.image),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
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
