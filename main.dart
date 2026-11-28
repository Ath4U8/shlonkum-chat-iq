import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

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
const Color kBeige = Color(0xFFFBF7EE);

const Color kNight = Color(0xFF0A1B52);
const Color kGoldLight = Color(0xFFF3D98B);
const Color kGoldDeep = Color(0xFFB9852C);

const LinearGradient kHeaderGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [kNight, kRoyal, Color(0xFF2450B8)],
);
const LinearGradient kGoldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kGoldLight, kGold, kGoldDeep],
);
const LinearGradient kMineGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [Color(0xFF00C2A8), Color(0xFF008F8C)],
);

// نمط هندسي عباسي: نجوم ثمانية مرسومة بالكود
class GeoPatternPainter extends CustomPainter {
  final Color color;
  final double cell;
  GeoPatternPainter({required this.color, this.cell = 46});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        _star(canvas, p, Offset(x, y), cell * 0.42);
      }
    }
  }

  void _star(Canvas canvas, Paint p, Offset c, double r) {
    for (final rot in [0.0, pi / 4]) {
      final path = Path();
      for (int i = 0; i < 4; i++) {
        final a = rot + i * pi / 2 + pi / 4;
        final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, p);
    }
    canvas.drawCircle(c, r * 0.28, p);
  }

  @override
  bool shouldRepaint(covariant GeoPatternPainter old) =>
      old.color != color || old.cell != cell;
}

class GeoPattern extends StatelessWidget {
  final Color color;
  final double cell;
  const GeoPattern({
    super.key,
    this.color = const Color(0x1AFFFFFF),
    this.cell = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: GeoPatternPainter(color: color, cell: cell)),
      ),
    );
  }
}

// قوس عراقي مدبب
class ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final w = s.width;
    final h = s.height;
    final p = Path();
    p.moveTo(0, h);
    p.lineTo(0, h * 0.5);
    p.cubicTo(0, h * 0.25, w * 0.38, h * 0.12, w * 0.5, 0);
    p.cubicTo(w * 0.62, h * 0.12, w, h * 0.25, w, h * 0.5);
    p.lineTo(w, h);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class ArchFrame extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  const ArchFrame({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: ArchClipper(),
              child: Container(
                decoration: const BoxDecoration(gradient: kGoldGradient),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(3.5),
              child: ClipPath(
                clipper: ArchClipper(),
                child: Container(color: const Color(0xFFFDFBF4), child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1.2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x00D9A441), kGold],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: pi / 4,
            child: Container(width: 8, height: 8, color: kGold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1.2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kGold, Color(0x00D9A441)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// بطاقة بإطار ذهبي رفيع وظل ناعم
class GoldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const GoldCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        gradient: kGoldGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261B3A8F),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.5),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.75 : 1,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: kHeaderGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGold, width: 1.6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x401B3A8F),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget iqAppBar({
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  bool center = true,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Colors.white,
    centerTitle: center,
    title: title,
    actions: actions,
    bottom: bottom,
    flexibleSpace: Stack(
      fit: StackFit.expand,
      children: [
        Container(decoration: const BoxDecoration(gradient: kHeaderGradient)),
        const GeoPattern(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(gradient: kGoldGradient),
          ),
        ),
      ],
    ),
  );
}

InputDecoration iqInput(String hint, {Widget? suffix}) {
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: b(kGold, 1),
    enabledBorder: b(kGold.withOpacity(0.6), 1),
    focusedBorder: b(kRoyal, 1.8),
  );
}

Widget iqLabel(String t) => Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kRoyal,
          ),
        ),
      ),
    );

// المدة التي يعتبر بعدها الصديق غير متصل
const int kOfflineAfterSeconds = 20;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShlonkumApp());
}

class ApiClient {
  // آخر عنوان نجح الاتصال به، يُجرَّب اولا في الطلبات التالية
  static int _preferred = 0;
  static int get preferredIndex => _preferred;

  // فرق الوقت بين ساعة الخادم وساعة هذا الهاتف (من ترويسة Date)
  static Duration _clockOffset = Duration.zero;
  static Duration get clockOffset => _clockOffset;

  static List<int> get _order => [
        _preferred,
        ...List.generate(kApiBaseUrls.length, (i) => i)
            .where((i) => i != _preferred),
      ];

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

  static String imageUrl(String name, int baseIndex) =>
      '${kApiBaseUrls[baseIndex]}/storage/v1/object/public/iq-images/$name';

  // يجرب العناوين بالترتيب، وينتقل للتالي فقط عند فشل الشبكة
  static Future<http.Response> _request(
    String method,
    String table,
    Map<String, String>? query, {
    Object? body,
  }) async {
    final errors = <String>[];
    for (final i in _order) {
      final base = kApiBaseUrls[i];
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
        final res = await req.timeout(const Duration(seconds: 10));
        _preferred = i;
        final d = res.headers['date'];
        if (d != null) {
          try {
            _clockOffset =
                HttpDate.parse(d).difference(DateTime.now().toUtc());
          } catch (_) {}
        }
        return res;
      } catch (e) {
        errors.add('[$base] $e');
      }
    }
    throw Exception(errors.join('\n'));
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

  static Future<void> insertRow(String table, Object body) async {
    final res = await _request('POST', table, null, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  // اضافة صف او اكثر وارجاع الصفوف المضافة
  static Future<List> insertReturning(String table, Object body) async {
    final res = await _request('POST', table, null, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final d = jsonDecode(res.body);
    return d is List ? d : [];
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

  // رفع صورة الى Supabase Storage وارجاع اسم الملف
  static Future<String> uploadImage(File file) async {
    final bytes = await file.readAsBytes();
    final isPng = file.path.toLowerCase().endsWith('.png');
    final ext = isPng ? 'png' : 'jpg';
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}.$ext';
    final errors = <String>[];
    for (final i in _order) {
      final base = kApiBaseUrls[i];
      try {
        final res = await http
            .post(
              Uri.parse('$base/storage/v1/object/iq-images/$name'),
              headers: {
                'apikey': kApiAnonKey,
                'Authorization': 'Bearer $kApiAnonKey',
                'Content-Type': isPng ? 'image/png' : 'image/jpeg',
              },
              body: bytes,
            )
            .timeout(const Duration(seconds: 45));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _preferred = i;
          return name;
        }
        errors.add('[$base] HTTP ${res.statusCode}: ${res.body}');
      } catch (e) {
        errors.add('[$base] $e');
      }
    }
    throw Exception(errors.join('\n'));
  }
}

// هل الصديق متصل الان: متصل فقط اذا آخر ظهور له خلال 20 ثانية
bool presenceOnline(Map? p) {
  if (p == null) return false;
  if (p['is_online'] != true) return false;
  final ls = DateTime.tryParse((p['last_seen'] ?? '').toString());
  if (ls == null) return false;
  final now = DateTime.now().toUtc().add(ApiClient.clockOffset);
  return now.difference(ls.toUtc()).inSeconds < kOfflineAfterSeconds;
}

// يرسل نبضة كل 5 ثوانٍ وانت داخل التطبيق، ويوقفها عند الخروج منه
class Presence with WidgetsBindingObserver {
  static final Presence _i = Presence._();
  Presence._();

  Timer? _t;
  bool _started = false;

  static void start() {
    if (_i._started) return;
    _i._started = true;
    WidgetsBinding.instance.addObserver(_i);
    _i._beat();
    _i._run();
  }

  void _run() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 5), (_) => _beat());
  }

  Future<void> _beat({bool online = true}) async {
    final me = LocalStore.personalNumber;
    if (me.length != 9) return;
    try {
      await ApiClient.updateRows(
        'profiles',
        {'personal_number': 'eq.$me'},
        {
          'is_online': online,
          'last_seen': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _beat();
      _run();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _t?.cancel();
      _beat(online: false);
    }
  }
}

// صوت واهتزاز عند وصول رسالة (والتطبيق مفتوح)
class Alerts {
  static final AudioPlayer _player = AudioPlayer();
  static Uint8List? _wav;

  // نغمة قصيرة من نوتتين تُولَّد داخل التطبيق بدون ملف صوت
  static Uint8List _makeWav() {
    const rate = 22050;
    final n = (rate * 0.45).toInt();
    final b = ByteData(44 + n * 2);
    void tag(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        b.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    b.setUint32(4, 36 + n * 2, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little);
    b.setUint16(22, 1, Endian.little);
    b.setUint32(24, rate, Endian.little);
    b.setUint32(28, rate * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    b.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      final first = t < 0.2;
      final local = first ? t : t - 0.2;
      final f = first ? 880.0 : 1318.5;
      final env = exp(-7 * local);
      final v = (sin(2 * pi * f * t) * env * 0.7 * 32767).toInt();
      b.setInt16(44 + i * 2, v, Endian.little);
    }
    return b.buffer.asUint8List();
  }

  static Future<void> ping() async {
    try {
      await Vibration.vibrate(duration: 300);
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
    try {
      _wav ??= _makeWav();
      await _player.play(BytesSource(_wav!));
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
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

// آخر رسالة قرأتها في كل مجموعة (لحساب الرسائل غير المقروءة)
class GroupSeen {
  static Map<String, int> _m = {};
  static bool _loaded = false;

  static Future<void> _ensure() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    try {
      final s = p.getString('groupSeen');
      if (s != null && s.isNotEmpty) {
        final d = jsonDecode(s) as Map;
        _m = d.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {}
    _loaded = true;
  }

  static Future<Map<String, int>> all() async {
    await _ensure();
    return Map<String, int>.from(_m);
  }

  static Future<void> set(int gid, int id) async {
    await _ensure();
    if ((_m['$gid'] ?? -1) >= id) return;
    _m['$gid'] = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('groupSeen', jsonEncode(_m));
  }
}

// ===================== الايموجي والملصقات =====================

class EmojiTab {
  final String title;
  final List<String> items;
  const EmojiTab(this.title, this.items);
}

const List<EmojiTab> kEmojiTabs = [
  EmojiTab('😀 وجوه', [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
    '😊', '😇', '🙂', '😉', '😍', '😘', '😋', '😜',
    '🤔', '😎', '😴', '😢', '😭', '😡', '😱', '🙄',
    '😏', '😌', '😔', '😞', '😤', '😳', '🤗', '🤐',
  ]),
  EmojiTab('❤️ قلوب وأيدي', [
    '❤️', '💙', '💚', '💛', '🧡', '💜', '🖤', '💔',
    '💕', '💖', '👍', '👎', '👏', '🙏', '🤝', '✌️',
    '👋', '💪', '🤲', '👌', '🙌', '✋', '👀', '🔥',
  ]),
  EmojiTab('🍵 طعام', [
    '☕', '🍵', '🍞', '🍚', '🍗', '🍖', '🍕', '🍔',
    '🍟', '🍉', '🍇', '🍎', '🍌', '🍊', '🍋', '🥛',
    '🍯', '🍰', '🍪', '🍫', '🍦', '🥗', '🌶️', '🍽️',
  ]),
  EmojiTab('⚽ متفرقات', [
    '⚽', '🏀', '🏈', '🎾', '🏐', '🏆', '🥇', '🎮',
    '🎵', '🎶', '🎉', '🎊', '🎁', '🚗', '✈️', '🌙',
    '⭐', '☀️', '🌧️', '🌴', '🕌', '🇮🇶', '📍', '💯',
  ]),
];

class IqSticker {
  final String text;
  final String emoji;
  final Color color;
  const IqSticker(this.text, this.emoji, this.color);
}

const List<IqSticker> kStickers = [
  IqSticker('شلونك؟', '🤝', kRoyal),
  IqSticker('هلا والله', '👋', Color(0xFF16A085)),
  IqSticker('شكو ماكو؟', '☕', Color(0xFF8E4A1F)),
  IqSticker('يا هلا', '🎉', Color(0xFFE67E22)),
  IqSticker('حبيبي', '❤️', Color(0xFFC0392B)),
  IqSticker('گلبي', '💙', kRoyal),
  IqSticker('عاشت ايدك', '👏', Color(0xFF27AE60)),
  IqSticker('تدلل', '👑', kGold),
  IqSticker('تسلم', '🙏', Color(0xFF2C3E50)),
  IqSticker('ما قصرت', '💪', Color(0xFF8E44AD)),
  IqSticker('يابه', '😮', Color(0xFFE67E22)),
  IqSticker('عاش', '🔥', Color(0xFFC0392B)),
  IqSticker('خوش ولد', '😎', kRoyal),
  IqSticker('فدوه', '🥰', Color(0xFFD35486)),
  IqSticker('لا تزعل', '🥺', Color(0xFF16A085)),
  IqSticker('الله كريم', '🤲', Color(0xFF2C3E50)),
  IqSticker('ان شاء الله', '🌙', Color(0xFF1B3A8F)),
  IqSticker('بالعافية', '🍽️', Color(0xFF27AE60)),
  IqSticker('چاي وكعدة', '🍵', Color(0xFF8E4A1F)),
  IqSticker('صباح الخير', '☀️', Color(0xFFE6A100)),
  IqSticker('تصبح على خير', '🌙', Color(0xFF2C3E50)),
  IqSticker('الله يسلمك', '🤝', Color(0xFF16A085)),
  IqSticker('يا وجه الخير', '😊', Color(0xFFE67E22)),
  IqSticker('ماكو مثلك', '🌟', kGold),
  IqSticker('عراقي وافتخر', '🇮🇶', Color(0xFFC0392B)),
];

IqSticker? findSticker(String text) {
  for (final s in kStickers) {
    if (s.text == text) return s;
  }
  return null;
}

Widget stickerCard(IqSticker s) {
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: s.color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kGold, width: 2),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(s.emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          s.text,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class StickerPanel extends StatefulWidget {
  final void Function(String) onEmoji;
  final void Function(IqSticker) onSticker;
  const StickerPanel({
    super.key,
    required this.onEmoji,
    required this.onSticker,
  });

  @override
  State<StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends State<StickerPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final last = kEmojiTabs.length;
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kGold, width: 1.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i <= last; i++)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: ChoiceChip(
                      label: Text(
                        i < last ? kEmojiTabs[i].title : '🇮🇶 ملصقات عراقية',
                      ),
                      selected: _tab == i,
                      selectedColor: kGoldLight,
                      backgroundColor: kBeige,
                      side: const BorderSide(color: kGold),
                      onSelected: (_) => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _tab < last
                ? GridView.count(
                    crossAxisCount: 8,
                    padding: const EdgeInsets.all(6),
                    children: [
                      for (final e in kEmojiTabs[_tab].items)
                        InkWell(
                          onTap: () => widget.onEmoji(e),
                          child: Center(
                            child:
                                Text(e, style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                    ],
                  )
                : GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(8),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      for (final s in kStickers)
                        GestureDetector(
                          onTap: () => widget.onSticker(s),
                          child: stickerCard(s),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ===================== عناصر عامة =====================

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
        scaffoldBackgroundColor: kBeige,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: kNight,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kHeaderGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const GeoPattern(),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (c, v, child) => Opacity(
                  opacity: v,
                  child: Transform.scale(scale: 0.88 + 0.12 * v, child: child),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ArchFrame(
                      width: 130,
                      height: 150,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/iraq_map.png',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.map, size: 60, color: kRoyal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'شلونكم چات',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'IQ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kGoldLight,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(width: 120, child: OrnamentDivider()),
                    const SizedBox(height: 12),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: kGold,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: kHeaderGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x551B3A8F),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(40)),
                child: Stack(
                  children: [
                    const GeoPattern(),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 4,
                        decoration: const BoxDecoration(gradient: kGoldGradient),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
                        child: Column(
                          children: [
                            ArchFrame(
                              width: 120,
                              height: 140,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Image.asset(
                                  'assets/iraq_map.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.map,
                                    size: 60,
                                    color: kRoyal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'شلونكم چات - IQ',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'تطبيق تواصل عراقي لكل العراق',
                              style: TextStyle(fontSize: 15, color: kGoldLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
              child: Column(
                children: [
                  iqLabel('سجل اسمك'),
                  TextField(
                    controller: _name,
                    decoration: iqInput('اسم المستخدم ( عربي او انكليزي )'),
                  ),
                  const SizedBox(height: 18),
                  iqLabel('انشاء كلمة مرور قوية'),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    textDirection: TextDirection.ltr,
                    decoration: iqInput(
                      'Password',
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                          color: kRoyal,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGold.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'كلمة المرور يجب ان تكون 8 احرف، وتحتوي على حرف كبير ورقم وحرف خاص',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 22),
                  GradientButton(
                    label: 'تسجيل',
                    loading: _loading,
                    onPressed: _loading ? null : _register,
                  ),
                  const SizedBox(height: 10),
                  if (_msg.isNotEmpty)
                    Text(
                      _msg,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  const OrnamentDivider(),
                  const CreatorWatermark(),
                ],
              ),
            ),
          ],
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
          const GeoPattern(color: Color(0x0F1B3A8F), cell: 54),
          const IshtarWatermark(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ArchFrame(
                    width: 100,
                    height: 118,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        'assets/iraq_map.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.map, size: 50, color: kRoyal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'شلونكم چات - IQ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kRoyal,
                    ),
                  ),
                  const OrnamentDivider(),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDED),
                      borderRadius: BorderRadius.circular(14),
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
                  GoldCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration:
                                const BoxDecoration(gradient: kHeaderGradient),
                            child: const Text(
                              'بطاقة الرقم الشخصي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kGoldLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                SelectableText(
                                  number,
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: kRoyal,
                                    letterSpacing: 4,
                                  ),
                                  textDirection: TextDirection.ltr,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'اضغط مطولا للنسخ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: 'ادخل',
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const Screen3Profile()),
                    ),
                  ),
                  const SizedBox(height: 10),
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
      appBar: iqAppBar(
        title: const Text(
          'انشاء ملفك الشخصي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const GeoPattern(color: Color(0x0F1B3A8F), cell: 54),
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
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          gradient: kGoldGradient,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
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
                      ),
                      Positioned(
                        bottom: 2,
                        left: 2,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kGold,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
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
                SizedBox(
                  width: double.infinity,
                  child: GoldCard(
                    padding: const EdgeInsets.all(16),
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
                ),
                const OrnamentDivider(),
                iqLabel('سجل حالتك'),
                TextField(
                  controller: _status,
                  maxLines: 3,
                  decoration: iqInput('مثال: شلونكم، انا موجود'),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: 'حفظ',
                  loading: _loading,
                  onPressed: _loading ? null : _save,
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

class RemoteImage extends StatefulWidget {
  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;

  const RemoteImage({
    super.key,
    required this.name,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<RemoteImage> {
  int _tries = 0;
  late final int _start = ApiClient.preferredIndex;

  Widget _box(Widget child) => SizedBox(
        width: widget.width,
        height: widget.height ?? 100,
        child: Center(child: child),
      );

  @override
  Widget build(BuildContext context) {
    final idx = (_start + _tries) % kApiBaseUrls.length;
    return Image.network(
      ApiClient.imageUrl(widget.name, idx),
      key: ValueKey('${widget.name}_$idx'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (c, child, p) =>
          p == null ? child : _box(const CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (c, e, s) {
        if (_tries < kApiBaseUrls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _tries < kApiBaseUrls.length - 1) {
              setState(() => _tries++);
            }
          });
          return _box(const CircularProgressIndicator(strokeWidth: 2));
        }
        return Container(
          width: widget.width,
          height: widget.height ?? 100,
          color: Colors.black12,
          child: const Center(child: Icon(Icons.broken_image)),
        );
      },
    );
  }
}

// ===================== شاشة الاصدقاء والمجموعات =====================

class Screen4Contacts extends StatefulWidget {
  const Screen4Contacts({super.key});

  @override
  State<Screen4Contacts> createState() => _Screen4ContactsState();
}

class _Screen4ContactsState extends State<Screen4Contacts>
    with SingleTickerProviderStateMixin {
  List _contacts = [];
  List _groups = [];
  bool _loading = true;
  bool _inChat = false;
  bool _busy = false;
  int _prevUnread = -1;
  Timer? _timer;
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    Presence.start();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_inChat && !_busy) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  void _snack(String t, {int seconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t), duration: Duration(seconds: seconds)),
    );
  }

  void _notifyNew() {
    Alerts.ping();
    _snack('وصلتك رسالة جديدة', seconds: 2);
  }

  Future<void> _load({bool silent = false}) async {
    if (_busy) return;
    _busy = true;
    if (!silent && mounted) setState(() => _loading = true);
    final me = LocalStore.personalNumber;
    int total = 0;
    try {
      final res = await ApiClient.getRows('contacts', {
        'select': 'friend_number',
        'owner_number': 'eq.$me',
      });
      final nums = <String>[];
      for (final e in res) {
        final n = (e['friend_number'] ?? '').toString().trim();
        if (n.isNotEmpty && !nums.contains(n)) nums.add(n);
      }

      // الرسائل غير المقروءة (للعداد وللتعرف على من راسلني ولم اضفه)
      final unreadRows = await ApiClient.getRows('messages', {
        'select': 'sender_number',
        'receiver_number': 'eq.$me',
        'is_read': 'eq.false',
      });
      final counts = <String, int>{};
      for (final r in unreadRows) {
        final s = (r['sender_number'] ?? '').toString();
        if (s.isNotEmpty) counts[s] = (counts[s] ?? 0) + 1;
      }
      for (final s in counts.keys) {
        if (!nums.contains(s)) {
          nums.add(s);
          try {
            await ApiClient.insertRow('contacts', {
              'owner_number': me,
              'friend_number': s,
            });
          } catch (_) {}
        }
      }

      final profMap = <String, Map>{};
      if (nums.isNotEmpty) {
        final profs = await ApiClient.getRows('profiles', {
          'select': 'name,personal_number,is_online,last_seen,status',
          'personal_number': 'in.(${nums.join(',')})',
        });
        for (final p in profs) {
          profMap[(p['personal_number'] ?? '').toString()] =
              Map.from(p as Map);
        }
      }

      final merged = [];
      for (final n in nums) {
        final p = profMap[n];
        merged.add({
          'name': (p?['name'] ?? 'صديق').toString(),
          'friend_number': n,
          'is_online': presenceOnline(p),
          'status': (p?['status'] ?? '').toString(),
          'unread': counts[n] ?? 0,
        });
      }
      merged.sort(
        (a, b) => (b['unread'] as int).compareTo(a['unread'] as int),
      );
      _contacts = merged;
      LocalStore.contacts = merged;
      await LocalStore.save();

      total += counts.values.fold<int>(0, (a, b) => a + b);
    } catch (_) {
      if (_contacts.isEmpty) _contacts = List.from(LocalStore.contacts);
    }

    // المجموعات (منفصلة حتى لا تتعطل قائمة الاصدقاء اذا لم يُشغَّل كود SQL)
    try {
      final mem = await ApiClient.getRows('group_members', {
        'select': 'group_id',
        'member_number': 'eq.$me',
      });
      final ids = <int>[];
      for (final e in mem) {
        final g = int.tryParse('${e['group_id']}');
        if (g != null && !ids.contains(g)) ids.add(g);
      }
      final groups = [];
      if (ids.isNotEmpty) {
        final gs = await ApiClient.getRows('groups', {
          'select': 'id,name,creator_number',
          'id': 'in.(${ids.join(',')})',
          'order': 'id.asc',
        });
        final seen = await GroupSeen.all();
        int minSeen = seen['${ids.first}'] ?? 0;
        for (final g in ids) {
          final s = seen['$g'] ?? 0;
          if (s < minSeen) minSeen = s;
        }
        final msgs = await ApiClient.getRows('messages', {
          'select': 'id,group_id',
          'group_id': 'in.(${ids.join(',')})',
          'sender_number': 'neq.$me',
          'id': 'gt.$minSeen',
        });
        final gcounts = <int, int>{};
        final firstMax = <int, int>{};
        for (final m in msgs) {
          final gid = int.tryParse('${m['group_id']}');
          final id = int.tryParse('${m['id']}');
          if (gid == null || id == null) continue;
          final last = seen['$gid'];
          if (last == null) {
            firstMax[gid] = max(firstMax[gid] ?? 0, id);
          } else if (id > last) {
            gcounts[gid] = (gcounts[gid] ?? 0) + 1;
          }
        }
        // مجموعة جديدة بالنسبة لي: لا نعتبر رسائلها القديمة غير مقروءة
        for (final g in ids) {
          if (seen['$g'] == null) {
            await GroupSeen.set(g, firstMax[g] ?? 0);
          }
        }
        for (final g in gs) {
          final gid = int.tryParse('${g['id']}') ?? 0;
          groups.add({
            'id': gid,
            'name': (g['name'] ?? 'مجموعة').toString(),
            'unread': gcounts[gid] ?? 0,
          });
        }
        total += gcounts.values.fold<int>(0, (a, b) => a + b);
      }
      _groups = groups;
    } catch (_) {}

    if (_prevUnread >= 0 && total > _prevUnread && mounted) {
      _notifyNew();
    }
    _prevUnread = total;

    _busy = false;
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
      _snack('اكتب رقم شخصي صحيح - 9 ارقام');
      return;
    }
    if (result == LocalStore.personalNumber) {
      _snack('هذا رقمك انت');
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
      _snack('تعذر الاتصال بالخادم، تحقق من الانترنت وحاول مرة اخرى\n$e',
          seconds: 8);
      return;
    }

    if (found == null) {
      _snack('هذا الرقم غير مسجل بالتطبيق بعد');
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

    // اضافة متبادلة: انت تضيفه وهو يضيفك تلقائيا ليتمكن من مراسلتك
    try {
      await ApiClient.insertRow('contacts', {
        'owner_number': LocalStore.personalNumber,
        'friend_number': result,
      });
    } catch (_) {}
    try {
      await ApiClient.insertRow('contacts', {
        'owner_number': result,
        'friend_number': LocalStore.personalNumber,
      });
    } catch (_) {}
    await _load();
    _snack('تمت إضافة $name كصديق');
  }

  Future<void> _createGroup() async {
    if (_contacts.isEmpty) {
      _snack('اضف اصدقاء اولا حتى تتمكن من انشاء مجموعة');
      return;
    }
    final nameCtrl = TextEditingController();
    final picked = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('مجموعة جديدة'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'اسم المجموعة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'اختر الاعضاء',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _contacts.map<Widget>((f) {
                      final n = (f['friend_number'] ?? '').toString();
                      final nm = (f['name'] ?? 'صديق').toString();
                      return CheckboxListTile(
                        dense: true,
                        value: picked.contains(n),
                        title: Text(nm),
                        subtitle: Text(n, textDirection: TextDirection.ltr),
                        onChanged: (v) {
                          setD(() {
                            if (v == true) {
                              picked.add(n);
                            } else {
                              picked.remove(n);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
    final gname = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (ok != true) return;
    if (gname.isEmpty) {
      _snack('اكتب اسم المجموعة');
      return;
    }
    if (picked.isEmpty) {
      _snack('اختر عضوا واحدا على الاقل');
      return;
    }
    final me = LocalStore.personalNumber;
    try {
      final rows = await ApiClient.insertReturning('groups', {
        'name': gname,
        'creator_number': me,
      });
      final gid = int.parse('${(rows.first as Map)['id']}');
      await ApiClient.insertReturning('group_members', [
        {'group_id': gid, 'member_number': me},
        for (final n in picked) {'group_id': gid, 'member_number': n},
      ]);
      await GroupSeen.set(gid, 0);
      await _load();
      _tab.animateTo(1);
      _snack('تم انشاء المجموعة $gname');
    } catch (e) {
      _snack(
        'تعذر انشاء المجموعة، تاكد من تشغيل كود SQL الخاص بالمجموعات\n$e',
        seconds: 8,
      );
    }
  }

  Widget _presenceDot(bool online) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: online ? Colors.green : Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );

  Widget _emptyNote(String t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            t,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
        ),
      );

  Widget _friendsList() {
    if (_contacts.isEmpty) {
      return _emptyNote('لا يوجد أصدقاء بعد - اضغط + وأضف صديقك برقمه الشخصي');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 90),
      itemCount: _contacts.length,
      itemBuilder: (c, i) {
        final f = _contacts[i];
        final name = (f['name'] ?? 'صديق').toString();
        final num =
            (f['friend_number'] ?? f['personal_number'] ?? '').toString();
        final online = f['is_online'] == true;
        final unread = (f['unread'] ?? 0) as int;
        return GoldCard(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    gradient: kGoldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    backgroundColor: kRoyal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                Positioned(bottom: 0, left: 0, child: _presenceDot(online)),
              ],
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kNight,
              ),
            ),
            subtitle: Row(
              children: [
                Text(num, textDirection: TextDirection.ltr),
                const SizedBox(width: 8),
                Text(
                  online ? 'متصل' : 'غير متصل',
                  style: TextStyle(
                    fontSize: 12,
                    color: online ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            trailing: _unreadBadge(unread),
            onTap: () async {
              _inChat = true;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Screen5Chat(
                    friendName: name,
                    friendNumber: num,
                    isOnline: online,
                  ),
                ),
              );
              _inChat = false;
              _load(silent: true);
            },
          ),
        );
      },
    );
  }

  Widget _unreadBadge(int unread) {
    if (unread > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55FF0000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$unread',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const Icon(Icons.chat_bubble_outline, color: kRoyal);
  }

  Widget _groupsList() {
    if (_groups.isEmpty) {
      return _emptyNote('لا توجد مجموعات - اضغط + لانشاء مجموعة');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 90),
      itemCount: _groups.length,
      itemBuilder: (c, i) {
        final g = _groups[i];
        final name = (g['name'] ?? 'مجموعة').toString();
        final gid = g['id'] as int;
        final unread = (g['unread'] ?? 0) as int;
        return GoldCard(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                gradient: kGoldGradient,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                backgroundColor: kTurquoise,
                child: Icon(Icons.groups, color: Colors.white),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kNight,
              ),
            ),
            subtitle: const Text('مجموعة'),
            trailing: _unreadBadge(unread),
            onTap: () async {
              _inChat = true;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Screen5Chat(
                    friendName: name,
                    groupId: gid,
                  ),
                ),
              );
              _inChat = false;
              _load(silent: true);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onFriends = _tab.index == 0;
    return Scaffold(
      backgroundColor: kBeige,
      appBar: iqAppBar(
        title: const Text(
          'شلونكم چات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kGoldLight,
          indicatorWeight: 3,
          labelColor: kGoldLight,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'الأصدقاء'),
            Tab(text: 'المجموعات'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const GeoPattern(color: Color(0x0F1B3A8F), cell: 54),
          const IshtarWatermark(),
          _loading
              ? const Center(child: CircularProgressIndicator(color: kRoyal))
              : TabBarView(
                  controller: _tab,
                  children: [_friendsList(), _groupsList()],
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onFriends ? _addFriend : _createGroup,
        backgroundColor: kGold,
        foregroundColor: kNight,
        icon: Icon(onFriends ? Icons.person_add : Icons.group_add),
        label: Text(
          onFriends ? 'إضافة صديق' : 'مجموعة جديدة',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ===================== شاشة المحادثة (فردية او مجموعة) =====================

class Screen5Chat extends StatefulWidget {
  final String friendName;
  final String friendNumber;
  final bool isOnline;
  final int? groupId;

  const Screen5Chat({
    super.key,
    required this.friendName,
    this.friendNumber = '',
    this.isOnline = false,
    this.groupId,
  });

  @override
  State<Screen5Chat> createState() => _Screen5ChatState();
}

class _Screen5ChatState extends State<Screen5Chat> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List _msgs = [];
  final List _pending = [];
  final Map<String, String> _names = {};
  bool _showPanel = false;
  bool _busy = false;
  bool _online = false;
  int _prevIncoming = -1;
  int _namesTried = 0;
  Timer? _timer;

  bool get _isGroup => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    _online = widget.isOnline;
    if (_isGroup) _loadNames();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _snack(String t, {int seconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t), duration: Duration(seconds: seconds)),
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadNames() async {
    _namesTried++;
    try {
      final mem = await ApiClient.getRows('group_members', {
        'select': 'member_number',
        'group_id': 'eq.${widget.groupId}',
      });
      final nums = mem
          .map((e) => (e['member_number'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
      if (nums.isEmpty) return;
      final profs = await ApiClient.getRows('profiles', {
        'select': 'name,personal_number',
        'personal_number': 'in.(${nums.join(',')})',
      });
      for (final n in nums) {
        _names[n] = n;
      }
      for (final p in profs) {
        _names[(p['personal_number'] ?? '').toString()] =
            (p['name'] ?? '').toString();
      }
      if (mounted) setState(() {});
    } catch (_) {}
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
    if (_busy) return;
    _busy = true;
    final me = LocalStore.personalNumber;
    final peer = widget.friendNumber;
    try {
      final List res;
      if (_isGroup) {
        res = await ApiClient.getRows('messages', {
          'select': '*',
          'group_id': 'eq.${widget.groupId}',
          'order': 'created_at.asc',
        });
      } else {
        res = await ApiClient.getRows('messages', {
          'select': '*',
          'or':
              '(and(sender_number.eq.$me,receiver_number.eq.$peer),and(sender_number.eq.$peer,receiver_number.eq.$me))',
          'order': 'created_at.asc',
        });
        // حالة الصديق (متصل / غير متصل)
        try {
          final p = await ApiClient.getRows('profiles', {
            'select': 'is_online,last_seen',
            'personal_number': 'eq.$peer',
            'limit': '1',
          });
          if (p.isNotEmpty) _online = presenceOnline(p[0] as Map);
        } catch (_) {}
      }

      // الرسائل التي حذفتها انت (عندك فقط) لا تظهر لك
      final vis = res
          .where((m) =>
              !(m['sender_number'] == me && m['hidden_for_sender'] == true))
          .toList();

      final incoming = vis.where((m) => m['sender_number'] != me).length;
      final hasNew = _prevIncoming >= 0 && incoming > _prevIncoming;
      final changed = vis.length != _msgs.length;
      _prevIncoming = incoming;
      _msgs = vis;

      if (_isGroup) {
        int maxId = 0;
        for (final m in res) {
          final id = int.tryParse('${m['id']}') ?? 0;
          if (id > maxId) maxId = id;
        }
        await GroupSeen.set(widget.groupId!, maxId);
        if (_namesTried < 3 &&
            vis.any((m) => !_names.containsKey('${m['sender_number']}'))) {
          _loadNames();
        }
      } else {
        final hasUnread = res.any(
          (m) => m['sender_number'] == peer && m['is_read'] != true,
        );
        if (hasUnread) _markRead();
      }

      if (hasNew) Alerts.ping();
      if (mounted) {
        setState(() {});
        if (changed) _scrollToEnd();
      }
    } catch (_) {}
    _busy = false;
  }

  Map<String, dynamic> _base(String type, String content) => {
        'sender_number': LocalStore.personalNumber,
        if (_isGroup)
          'group_id': widget.groupId
        else
          'receiver_number': widget.friendNumber,
        'content': content,
        'message_type': type,
        'is_read': false,
      };

  Future<void> _send(String type, String content) async {
    final msg = _base(type, content);
    setState(() {
      _showPanel = false;
      _pending.add(msg);
    });
    _scrollToEnd();
    try {
      await ApiClient.insertRow('messages', msg);
    } catch (e) {
      _snack('تعذر ارسال الرسالة\n$e', seconds: 6);
    }
    _pending.remove(msg);
    _busy = false;
    await _load();
  }

  Future<void> _sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    await _send('text', t);
  }

  void _insertEmoji(String e) {
    final t = _ctrl.text + e;
    _ctrl.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1280,
    );
    if (f == null) return;
    final msg = {
      ..._base('image', '[صورة]'),
      'local_path': f.path,
    };
    setState(() => _pending.add(msg));
    _scrollToEnd();
    try {
      final name = await ApiClient.uploadImage(File(f.path));
      final toSend = _base('image', '[صورة]');
      toSend['image_path'] = name;
      await ApiClient.insertRow('messages', toSend);
    } catch (e) {
      _snack('تعذر ارسال الصورة\n$e', seconds: 8);
    }
    _pending.remove(msg);
    _busy = false;
    await _load();
  }

  // حذف الرسالة من جهة المرسل فقط
  Future<void> _deleteMine(Map m) async {
    final id = m['id'];
    if (id == null) return;
    try {
      await ApiClient.updateRows(
        'messages',
        {'id': 'eq.$id'},
        {'hidden_for_sender': true},
      );
      if (mounted) setState(() => _msgs.removeWhere((x) => x['id'] == id));
    } catch (e) {
      _snack('تعذر حذف الرسالة. تاكد من تشغيل كود SQL الجديد\n$e', seconds: 6);
    }
  }

  void _msgMenu(Map m) {
    final isText = (m['message_type'] ?? 'text') == 'text';
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isText)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('نسخ'),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: (m['content'] ?? '').toString()),
                  );
                  Navigator.pop(c);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف عندي'),
              subtitle: Text(
                _isGroup
                    ? 'تبقى الرسالة ظاهرة عند باقي الاعضاء'
                    : 'تبقى الرسالة ظاهرة عند الطرف الاخر',
              ),
              onTap: () {
                Navigator.pop(c);
                _deleteMine(m);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMembers() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('الاعضاء'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _names.entries
                .map(
                  (e) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.person),
                    title: Text(e.value),
                    subtitle: Text(e.key, textDirection: TextDirection.ltr),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('اغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _imageOf(Map m, {double? w, double? h, BoxFit fit = BoxFit.cover}) {
    final local = (m['local_path'] ?? '').toString();
    final remote = (m['image_path'] ?? '').toString();
    if (local.isNotEmpty && File(local).existsSync()) {
      return Image.file(File(local), width: w, height: h, fit: fit);
    }
    if (remote.isNotEmpty && !remote.startsWith('/')) {
      return RemoteImage(name: remote, width: w, height: h, fit: fit);
    }
    if (remote.startsWith('/') && File(remote).existsSync()) {
      return Image.file(File(remote), width: w, height: h, fit: fit);
    }
    return Container(
      width: w ?? 180,
      height: h ?? 100,
      color: Colors.black12,
      child: const Center(
        child: Text('الصورة غير متاحة', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  void _openImage(Map m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('الصورة'),
            backgroundColor: kRoyal,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: _imageOf(m, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _readIcon(Map m) {
    if (_isGroup) return const SizedBox();
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

  Widget _bubbleBody(Map m, bool isMine) {
    final type = (m['message_type'] ?? 'text').toString();
    if (type == 'image') {
      return GestureDetector(
        onTap: () => _openImage(m),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _imageOf(m, w: 180, h: 140),
        ),
      );
    }
    final content = (m['content'] ?? '').toString();
    if (type == 'sticker') {
      final s = findSticker(content);
      if (s != null) {
        return SizedBox(width: 130, height: 110, child: stickerCard(s));
      }
    }
    return Text(
      content,
      style: TextStyle(color: isMine ? Colors.white : Colors.black87),
    );
  }

  PreferredSizeWidget _appBar() {
    if (_isGroup) {
      return iqAppBar(
        center: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.friendName,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text(
              _names.isEmpty ? 'مجموعة' : '${_names.length} عضو',
              style: const TextStyle(fontSize: 12, color: kGoldLight),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.people), onPressed: _showMembers),
        ],
      );
    }
    return iqAppBar(
      center: false,
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
                  color: _online ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _online ? 'متصل' : 'غير متصل',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = [..._msgs, ..._pending];
    final maxW = MediaQuery.of(context).size.width * 0.78;
    OutlineInputBorder ob(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: c, width: w),
        );
    return Scaffold(
      backgroundColor: kBeige,
      appBar: _appBar(),
      body: Stack(
        children: [
          const GeoPattern(color: Color(0x0F1B3A8F), cell: 54),
          const IshtarWatermark(),
          Column(
            children: [
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Text('لا توجد رسائل بعد - ابدا المحادثة'),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: shown.length,
                        itemBuilder: (c, i) {
                          final m = shown[i] as Map;
                          final isMine =
                              m['sender_number'] == LocalStore.personalNumber;
                          final sender = (m['sender_number'] ?? '').toString();
                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: (isMine && m['id'] != null)
                                  ? () => _msgMenu(m)
                                  : null,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: maxW),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isMine ? kMineGradient : null,
                                  color: isMine ? null : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft:
                                        Radius.circular(isMine ? 18 : 4),
                                    bottomRight:
                                        Radius.circular(isMine ? 4 : 18),
                                  ),
                                  border: isMine
                                      ? null
                                      : Border.all(
                                          color: kGold.withOpacity(0.45),
                                        ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x141B3A8F),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (_isGroup && !isMine)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          _names[sender] ?? sender,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: kRoyal,
                                          ),
                                        ),
                                      ),
                                    _bubbleBody(m, isMine),
                                    const SizedBox(height: 4),
                                    _readIcon(m),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_showPanel)
                StickerPanel(
                  onEmoji: _insertEmoji,
                  onSticker: (s) => _send('sticker', s.text),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: kGold, width: 1.2)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: kRoyal,
                          size: 28,
                        ),
                        onPressed: () =>
                            setState(() => _showPanel = !_showPanel),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image_outlined, color: kRoyal),
                        onPressed: _sendImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالتك...',
                            filled: true,
                            fillColor: kBeige,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: ob(kGold, 1),
                            enabledBorder: ob(kGold.withOpacity(0.6), 1),
                            focusedBorder: ob(kRoyal, 1.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _sendText(_ctrl.text),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            gradient: kHeaderGradient,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: kGold, width: 1.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
