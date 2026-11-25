import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://tfcpkoozqttdzligfizu.supabase.co';
const String supabaseAnonKey =
    'sb_publishable_nbqpxqvicOkjDlrtQmbrug_J0r557Sv';

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
        primaryColor: const Color(0xFF1B3A8F),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3A8F)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const PhoneEntryScreen(),
    );
  }
}

class IshtarWatermark extends StatelessWidget {
  final double opacity;
  const IshtarWatermark({super.key, this.opacity = 0.08});

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.001) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            'assets/ishtar_gate.jfif',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

class EngravedCreatorWatermark extends StatelessWidget {
  const EngravedCreatorWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, 1),
              child: const Text(
                'Created by: Atheer Sami',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
            const Text(
              'Created by: Atheer Sami',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
                color: Color(0x886E7785),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneEntryScreen extends StatefulWidget {
  final double watermarkOpacity;
  const PhoneEntryScreen({super.key, this.watermarkOpacity = 0.08});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  String? _errorText;
  bool _submitting = false;

  String? _normalizeIraqiPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('964') && digits.length == 13) {
      return '+$digits';
    }
    if (digits.startsWith('07') && digits.length == 11) {
      return '+964${digits.substring(1)}';
    }
    if (digits.startsWith('7') && digits.length == 10) {
      return '+964$digits';
    }
    return null;
  }

  Future<void> _onContinue() async {
    final normalized = _normalizeIraqiPhone(_phoneCtrl.text);
    if (normalized == null) {
      setState(() {
        _errorText = 'أدخل رقماً عراقياً صحيحاً بصيغة 07xxxxxxxxx';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _submitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم التحقق من صيغة الرقم: $normalized')),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);
    const softBg = Color(0xFFF7F5EF);

    return Scaffold(
      backgroundColor: softBg,
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
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
                  const Text(
                    'شلونكم چات - IQ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'تطبيق تواصل عراقي لكل العراق',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'تأكيد رقم الهاتف',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف العراقي',
                            hintText: '0770 000 0000',
                            prefixText: '+964 ',
                            errorText: _errorText,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: softBg,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'متابعة',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const EngravedCreatorWatermark(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
