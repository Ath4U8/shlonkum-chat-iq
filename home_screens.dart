import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screens.dart';

final _supabase = Supabase.instance.client;

class HomeShellScreen extends StatefulWidget {
  final double watermarkOpacity;
  final VoidCallback onSignedOut;

  const HomeShellScreen({
    super.key,
    this.watermarkOpacity = 0.08,
    required this.onSignedOut,
  });

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    ChatsTab(watermarkOpacity: widget.watermarkOpacity),
    FriendsTab(watermarkOpacity: widget.watermarkOpacity),
    CallsTab(watermarkOpacity: widget.watermarkOpacity),
    ProfileTab(
      watermarkOpacity: widget.watermarkOpacity,
      onSignedOut: widget.onSignedOut,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.black54,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'المحادثات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'الأصدقاء',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_outlined),
            activeIcon: Icon(Icons.call),
            label: 'المكالمات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

/// 1. تبويب المحادثات الفورية من Supabase
class ChatsTab extends StatefulWidget {
  final double watermarkOpacity;
  const ChatsTab({super.key, this.watermarkOpacity = 0.08});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  bool _loading = true;
  String? _error;
  List> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _conversations = [];
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _supabase
          .from('messages')
          .select('id, sender_id, receiver_id, content, created_at')
          .or('sender_id.eq.$uid,receiver_id.eq.$uid')
          .order('created_at', ascending: false)
          .limit(60);

      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in rows) {
        final sender = item['sender_id']?.toString() ?? '';
        final receiver = item['receiver_id']?.toString() ?? '';
        final peerId = sender == uid ? receiver : sender;
        if (peerId.isEmpty || grouped.containsKey(peerId)) continue;
        grouped[peerId] = {
          'peer_id': peerId,
          'last_message': item['content']?.toString() ?? '',
          'created_at': item['created_at']?.toString() ?? '',
        };
      }

      if (grouped.isNotEmpty) {
        final peerIds = grouped.keys.toList();
        final profiles = await _supabase
            .from('profiles')
            .select('id, display_name, username')
            .inFilter('id', peerIds);

        for (final p in profiles) {
          final pid = p['id']?.toString() ?? '';
          if (grouped.containsKey(pid)) {
            grouped[pid]!['display_name'] =
                p['display_name']?.toString() ?? 'مستخدم شلونكم';
            grouped[pid]!['username'] = p['username']?.toString() ?? '';
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _conversations = grouped.values.toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل المحادثات حالياً';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);
    const softBg = Color(0xFFF7F5EF);

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text('شلونكم چات - IQ'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset('assets/iraq_map.png', fit: BoxFit.contain),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _conversations.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد محادثات بعد — ابدأ محادثة من تبويب الأصدقاء',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.black54),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final chat = _conversations[index];
                            final name =
                                chat['display_name']?.toString() ?? 'مستخدم';
                            final msg = chat['last_message']?.toString() ?? '';
                            return ListTile(
                              tileColor: Colors.white.withValues(alpha: 0.92),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                child: Text(
                                  name.isNotEmpty ? name.characters.first : 'ع',
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                msg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DirectChatScreen(
                                      peerId: chat['peer_id'].toString(),
                                      peerName: name,
                                      watermarkOpacity: widget.watermarkOpacity,
                                    ),
                                  ),
                                ).then((_) => _loadConversations());
                              },
                            );
                          },
                        ),
        ],
      ),
    );
  }
}

/// شاشة محادثة مباشرة متصلة بـ Supabase
class DirectChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final double watermarkOpacity;

  const DirectChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.watermarkOpacity = 0.08,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    final uid = _supabase.auth.currentUser?.id;
    if (text.isEmpty || uid == null) return;

    setState(() => _sending = true);
    try {
      await _supabase.from('messages').insert({
        'sender_id': uid,
        'receiver_id': widget.peerId,
        'content': text,
      });
      _msgCtrl.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إرسال الرسالة')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);
    const softBg = Color(0xFFF7F5EF);
    final uid = _supabase.auth.currentUser?.id ?? '';

    final stream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: Text(widget.peerName),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final filtered = snapshot.data!.where((m) {
                      final s = m['sender_id']?.toString() ?? '';
                      final r = m['receiver_id']?.toString() ?? '';
                      return (s == uid && r == widget.peerId) ||
                          (s == widget.peerId && r == uid);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('ابدأ بإرسال رسالة الآن'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isMe = item['sender_id']?.toString() == uid;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              item['content']?.toString() ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: const InputDecoration(
                            hintText: 'اكتب رسالتك...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: primaryBlue),
                        onPressed: _sending ? null : _sendMessage,
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

/// 2. تبويب الأصدقاء / البحث عن مستخدمي التطبيق في العراق
class FriendsTab extends StatefulWidget {
  final double watermarkOpacity;
  const FriendsTab({super.key, this.watermarkOpacity = 0.08});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;
  List> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String query = ''}) async {
    final uid = _supabase.auth.currentUser?.id;
    setState(() => _loading = true);

    try {
      final rows = await _supabase
          .from('profiles')
          .select('id, display_name, username, bio')
          .limit(50);

      final q = query.trim().toLowerCase();
      final list = rows.where((u) {
        final id = u['id']?.toString() ?? '';
        if (uid != null && id == uid) return false;
        if (q.isEmpty) return true;
        final name = (u['display_name']?.toString() ?? '').toLowerCase();
        final uname = (u['username']?.toString() ?? '').toLowerCase();
        return name.contains(q) || uname.contains(q);
      }).toList();

      if (!mounted) return;
      setState(() {
        _users = List>.from(list);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);
    const softBg = Color(0xFFF7F5EF);

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text('الأصدقاء'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو @username...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => _loadUsers(query: val),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _users.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد حسابات مطابقة حالياً',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final u = _users[index];
                              final name =
                                  u['display_name']?.toString() ?? 'مستخدم';
                              final uname = u['username']?.toString() ?? '';
                              return Card(
                                color: Colors.white.withValues(alpha: 0.95),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    child: Text(
                                      name.isNotEmpty
                                          ? name.characters.first
                                          : 'ع',
                                    ),
                                  ),
                                  title: Text(name),
                                  subtitle: uname.isNotEmpty
                                      ? Text('@$uname',
                                          textDirection: TextDirection.ltr)
                                      : null,
                                  trailing: const Icon(
                                    Icons.chat_bubble_outline,
                                    color: primaryBlue,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DirectChatScreen(
                                          peerId: u['id'].toString(),
                                          peerName: name,
                                          watermarkOpacity:
                                              widget.watermarkOpacity,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3. تبويب المكالمات (نظيف بدون بيانات وهمية)
class CallsTab extends StatelessWidget {
  final double watermarkOpacity;
  const CallsTab({super.key, this.watermarkOpacity = 0.08});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);
    const softBg = Color(0xFFF7F5EF);

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text('المكالمات'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          IshtarWatermark(opacity: watermarkOpacity),
          const Center(
            child: Text(
              'سجل المكالمات فارغ حالياً',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. تبويب حسابي وتعديل الملف الشخصي
class ProfileTab extends StatefulWidget {
  final double watermarkOpacity;
  final VoidCallback onSignedOut;

  const ProfileTab({
    super.key,
    this.watermarkOpacity = 0.08,
    required this.onSignedOut,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select('display_name, username, bio, phone')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);
    const softBg = Color(0xFFF7F5EF);

    final name = _profile?['display_name']?.toString() ?? 'مستخدم شلونكم';
    final username = _profile?['username']?.toString() ?? '';
    final bio =
        _profile?['bio']?.toString() ?? 'أهلاً بكم في شلونكم چات - IQ';

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text('حسابي'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل الملف الشخصي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileSetupScreen(
                    watermarkOpacity: widget.watermarkOpacity,
                    isEditing: true,
                    onSaved: () {
                      Navigator.pop(context);
                      _loadProfile();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.20,
                          child: Image.asset(
                            'assets/iraq_map.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            if (username.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '@$username',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              bio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
