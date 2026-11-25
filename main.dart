// شلونكم چات - IQ | Shlonkum Chat - IQ
// التحديث الأخير المعتمد - عام لكل العراق
// - ماكو أسماء محافظات بأي مكان
// - خارطة العراق 20% ثابتة كملصق بالهيدر
// - بوابة عشتار هي العلامة المائية الوحيدة
// - السكرول يعمل لكل الشاشات
// - دخول برقم +964 أو رمز تفعيل + ربط Supabase (chats & messages + Realtime)
// GitHub: https://github.com/Ath4U8/shlonkum-chat-iq
// Backend: Supabase project tfcpkoozqttdzligfizu

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://tfcpkoozqttdzligfizu.supabase.co';
const String supabaseAnonKey = 'sb_publishable_nbqpxqvicOkjDlrtQmbrug_J0r557Sv';

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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    if (session != null) return const MainShell();
    return const LoginScreen();
  }
}

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
    try {
      if (supabase.auth.currentSession == null) {
        await supabase.auth.signInAnonymously(
          data: {
            'display_name': 'مستخدم شلونكم',
            'phone': _phone.text.trim().isEmpty ? null : '+964${_phone.text.trim()}',
          },
        );
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
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
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.20,
                  child: Image.asset('assets/iraq_map.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                const Text(
                  'شلونكم چات - IQ',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B3A8F)),
                ),
                const Text(
                  'تطبيق تواصل عراقي لكل العراق',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف العراقي',
                    prefixText: '+964 ',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رمز التفعيل (اختياري)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B3A8F),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('دخول', style: TextStyle(fontSize: 18)),
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
      ProfileScreen(
        onOpacityChanged: (v) => setState(() {
          _watermarkOpacity = v;
          _pages[0] = ChatsScreen(watermarkOpacity: v);
          _pages[1] = FriendsScreen(watermarkOpacity: v);
        }),
        opacity: _watermarkOpacity,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3A8F),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.20,
              height: 32,
              child: Image.asset('assets/iraq_map.png', fit: BoxFit.contain),
            ),
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

class IshtarWatermark extends StatelessWidget {
  final double opacity;
  const IshtarWatermark({super.key, required this.opacity});

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.001) return const SizedBox.shrink();
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Image.asset('assets/ishtar_gate.jfif', fit: BoxFit.cover, alignment: Alignment.center),
      ),
    );
  }
}

class ChatsScreen extends StatefulWidget {
  final double watermarkOpacity;
  const ChatsScreen({super.key, required this.watermarkOpacity});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String _q = '';
  bool _loading = true;
  List<dynamic> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final data = await supabase
          .from('chats')
          .select('id, title, type, created_at')
          .order('created_at', ascending: true);
      if (!mounted) return;
      setState(() {
        _chats = List<dynamic>.from(data);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chats = [
          {'id': null, 'title': 'شلونكم العام', 'type': 'group'},
          {'id': null, 'title': 'أخبار العراق', 'type': 'group'},
          {'id': null, 'title': 'شعر شعبي', 'type': 'group'},
          {'id': null, 'title': 'رياضة عراقية', 'type': 'group'},
          {'id': null, 'title': 'ضحك عراقي', 'type': 'group'},
          {'id': null, 'title': 'دراسة وشغل', 'type': 'group'},
        ];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _chats
        .where((e) => (e['title']?.toString() ?? '').contains(_q) || _q.isEmpty)
        .toList();

    return Stack(
      children: [
        IshtarWatermark(opacity: widget.watermarkOpacity),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'بحث...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadChats,
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (c, i) {
                          final item = list[i];
                          final title = item['title']?.toString() ?? 'قناة عامة';
                          final chatId = item['id']?.toString();
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF00C2A8),
                              child: Icon(Icons.forum, color: Colors.white),
                            ),
                            title: Text(title),
                            subtitle: const Text('قناة عامة - لكل العراق'),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetail(
                                  chatId: chatId,
                                  name: title,
                                  watermarkOpacity: widget.watermarkOpacity,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatDetail extends StatefulWidget {
  final String? chatId;
  final String name;
  final double watermarkOpacity;

  const ChatDetail({
    super.key,
    required this.chatId,
    required this.name,
    required this.watermarkOpacity,
  });

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<dynamic> _msgs = [];
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    if (widget.chatId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final rows = await supabase
          .from('messages')
          .select('id, chat_id, sender_id, body, created_at')
          .eq('chat_id', widget.chatId!)
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _msgs
          ..clear()
          ..addAll(List<dynamic>.from(rows));
        _loading = false;
      });
      _scrollToBottom();

      _channel = supabase
          .channel('messages-chat-${widget.chatId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'chat_id',
              value: widget.chatId!,
            ),
            callback: (payload) {
              final newRow = payload.newRecord;
              if (!mounted) return;
              final exists = _msgs.any((m) => m['id'] == newRow['id']);
              if (!exists) {
                setState(() => _msgs.add(newRow));
                _scrollToBottom();
              }
            },
          )
          .subscribe();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;

    if (widget.chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر ربط القناة بقاعدة البيانات')),
      );
      return;
    }

    var userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      try {
        final res = await supabase.auth.signInAnonymously();
        userId = res.user?.id;
      } catch (_) {}
    }

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً لإرسال الرسائل')),
      );
      return;
    }

    setState(() => _sending = true);
    if (preset == null) _ctrl.clear();

    try {
      await supabase.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': userId,
        'body': text,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الرسالة: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: const Color(0xFF1B3A8F),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _msgs.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد رسائل بعد، ابدأ أول رسالة',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            itemCount: _msgs.length,
                            itemBuilder: (c, i) {
                              final msg = _msgs[i];
                              final body = msg['body']?.toString() ?? '';
                              final isMine = currentUserId != null && msg['sender_id'] == currentUserId;
                              return Align(
                                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMine ? const Color(0xFF00C2A8) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                                    ],
                                  ),
                                  child: Text(
                                    body,
                                    style: TextStyle(color: isMine ? Colors.white : Colors.black87),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  children: ['هلا', 'شلونكم', 'تمام الحمدلله', 'دزلي الموقع', 'يلا نطلع', 'هلا والله']
                      .map((r) => ActionChip(label: Text(r), onPressed: () => _send(r)))
                      .toList(),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send, color: Color(0xFF1B3A8F)),
                    onPressed: _sending ? null : () => _send(),
                  ),
                ],
              ),
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
    return Stack(
      children: [
        IshtarWatermark(opacity: watermarkOpacity),
        ListView.builder(
          itemCount: friends.length,
          itemBuilder: (c, i) => ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF1B3A8F), child: Icon(Icons.person, color: Colors.white)),
            title: Text(friends[i]),
            subtitle: const Text('متصل الآن'),
            trailing: const Icon(Icons.chat_bubble_outline),
          ),
        ),
      ],
    );
  }
}

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (c, i) => ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFFD9A441), child: Icon(Icons.call, color: Colors.white)),
        title: Text('مكالمة ${i + 1}'),
        subtitle: const Text('مكالمة صوتية - 5 دقائق'),
        trailing: IconButton(
          icon: const Icon(Icons.call),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جارٍ الاتصال...'))),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final double opacity;
  final Function(double) onOpacityChanged;

  const ProfileScreen({super.key, required this.opacity, required this.onOpacityChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, backgroundColor: Color(0xFF1B3A8F), child: Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('مستخدم شلونكم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('تطبيق تواصل عراقي لكل العراق'),
          const SizedBox(height: 24),
          const Text('علامة العراق المائية - بوابة عشتار فقط', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: opacity, min: 0, max: 0.20, onChanged: onOpacityChanged),
          Text('الشفافية: ${(opacity * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('من متصفح الهاتف: مشاركة ثم إضافة إلى الشاشة الرئيسية - لتثبيت التطبيق')),
              ),
              child: const Text('ثبّت التطبيق على هاتفك'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('للنشر: GitHub + Supabase + Cloudflare', style: TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }
}
