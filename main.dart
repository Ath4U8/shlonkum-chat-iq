import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screens.dart';
import 'home_screens.dart';

const String supabaseUrl = 'https://tfcpkoozqttdzligfizu.supabase.co';
const String supabaseAnonKey =
    'sb_publishable_nbqpxqvicOkjDlrtQmbrug_J0r557Sv';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const ShlonkumChatApp());
}

class ShlonkumChatApp extends StatelessWidget {
  const ShlonkumChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'شلونكم چات - IQ',
      theme: ThemeData(
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SessionGateScreen(),
    );
  }
}

class SessionGateScreen extends StatefulWidget {
  const SessionGateScreen({super.key});

  @override
  State<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends State<SessionGateScreen> {
  static const double _watermarkOpacity = 0.08;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = Supabase.instance.client.auth.currentSession != null;

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _isAuthenticated = data.session != null;
      });
    });
  }

  void _refreshSessionState() {
    if (!mounted) return;
    setState(() {
      _isAuthenticated = Supabase.instance.client.auth.currentSession != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return HomeShellScreen(
        watermarkOpacity: _watermarkOpacity,
        onSignedOut: _refreshSessionState,
      );
    }

    return PhoneEntryScreen(
      watermarkOpacity: _watermarkOpacity,
      onAuthSuccess: _refreshSessionState,
    );
  }
}
