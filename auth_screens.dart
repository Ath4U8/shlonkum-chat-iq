import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screens.dart';

String? normalizeIraqiPhone(String rawInput) {
  String cleaned = rawInput.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (cleaned.startsWith('00964')) {
    cleaned = '+964${cleaned.substring(5)}';
  } else if (cleaned.startsWith('964')) {
    cleaned = '+$cleaned';
  } else if (cleaned.startsWith('07')) {
    cleaned = '+964${cleaned.substring(1)}';
  } else if (cleaned.startsWith('7') && cleaned.length == 10) {
    cleaned = '+964$cleaned';
  }

  final validRegex = RegExp(r'^\+9647[3-9]\d{8}$');
  if (!validRegex.hasMatch(cleaned)) {
    return null;
  }
  return cleaned;
}

class CreatorWatermark extends StatelessWidget {
  const CreatorWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      alignment: Alignment.center,
      child: Text(
        'Created by: Atheer Sami',
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.78),
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class IraqIdentityBackground extends StatelessWidget {
  final Widget child;
  final double mapHeightFraction;

  const IraqIdentityBackground({
    super.key,
    required this.child,
    this.mapHeightFraction = 0.30,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.14,
            child: Image.asset(
              'assets/ishtar_gate.jfif',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Opacity(
              opacity: 0.20,
              child: SizedBox(
                height: screenHeight * mapHeightFraction,
                child: Image.asset(
                  'assets/iraq_map.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  bool _submitting = false;
  String? _normalizedPhone;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final normalized = normalizeIraqiPhone(_phoneController.text);
    if (normalized == null) {
      setState(() {
        _errorMessage =
            'أدخل رقماً عراقياً صحيحاً يبدأ بـ 07 أو 7 (مثال: 07740140555)';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.signInWithOtp(phone: normalized);
      if (mounted) {
        setState(() {
          _normalizedPhone = normalized;
          _otpSent = true;
          _submitting = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = 'تعذر إرسال رمز التحقق: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage =
              'تعذر إرسال رمز التحقق ($e). تأكد من تفعيل Phone/SMS Provider في Supabase Auth ومن اتصال الشبكة.';
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    final phone = _normalizedPhone ?? normalizeIraqiPhone(_phoneController.text);
    if (phone == null || code.length < 4) {
      setState(() {
        _errorMessage = 'أدخل رمز التحقق الذي وصلك بشكل صحيح';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: code,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('لم يتم تأكيد الجلسة');
      }

      final existingProfile = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      final username = (existingProfile?['username'] as String?)?.trim() ?? '';
      if (!mounted) return;

      if (username.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShellScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = 'رمز التحقق غير صحيح أو منتهي: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = 'فشل التحقق من الرمز: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شلونكم IQ'),
        centerTitle: true,
      ),
      body: IraqIdentityBackground(
        mapHeightFraction: 0.30,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.24,
                      ),
                      const Text(
                        'شلونكم چات - IQ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'تطبيق تواصل عراقي لكل العراق',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _phoneController,
                        enabled: !_otpSent && !_submitting,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف العراقي',
                          hintText: '07740140555',
                          prefixText: '+964  ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpController,
                          enabled: !_submitting,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'رمز التحقق (OTP)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _otpSent = false;
                                      _otpController.clear();
                                      _errorMessage = null;
                                    });
                                  },
                            child: const Text('تغيير الرقم أو إعادة الإرسال'),
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : (_otpSent ? _verifyOtp : _sendOtp),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Text(
                                  _otpSent ? 'تأكيد رمز التحقق' : 'متابعة',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const CreatorWatermark(),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final row = await _supabase
          .from('profiles')
          .select('display_name, username, bio')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null && mounted) {
        _nameController.text = (row['display_name'] as String?) ?? '';
        _usernameController.text = (row['username'] as String?) ?? '';
        _bioController.text = (row['bio'] as String?) ?? '';
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final displayName = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim().isEmpty
        ? 'أهلاً بكم في شلونكم چات - IQ'
        : _bioController.text.trim();

    if (displayName.isEmpty) {
      setState(() => _errorMessage = 'اكتب الاسم الظاهر');
      return;
    }

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      setState(() {
        _errorMessage =
            'اسم المستخدم يجب أن يكون من 3 إلى 20 حرفاً إنجليزياً صغيراً أو أرقاماً أو _';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'phone': user.phone,
        'display_name': displayName,
        'username': username,
        'bio': bio,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShellScreen()),
      );
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = e.code == '23505'
              ? 'اسم المستخدم مستخدم مسبقاً، اختر اسماً آخر'
              : 'تعذر حفظ الملف الشخصي: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'حدث خطأ أثناء الحفظ: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء الملف الشخصي'),
        centerTitle: true,
      ),
      body: IraqIdentityBackground(
        mapHeightFraction: 0.25,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم (username)',
                          hintText: 'atheer_iq',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bioController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'النبذة الشخصية',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          child: _saving
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'حفظ والدخول للتطبيق',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const CreatorWatermark(),
            ],
          ),
        ),
      ),
    );
  }
}
