import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

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

/// 1. شاشة إدخال رقم الهاتف العراقي
class PhoneEntryScreen extends StatefulWidget {
  final double watermarkOpacity;
  final VoidCallback onAuthSuccess;

  const PhoneEntryScreen({
    super.key,
    this.watermarkOpacity = 0.08,
    required this.onAuthSuccess,
  });

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

  Future<void> _sendOtp() async {
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

    try {
      await _supabase.auth.signInWithOtp(phone: normalized);
      if (!mounted) return;
      setState(() => _submitting = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: normalized,
            watermarkOpacity: widget.watermarkOpacity,
            onAuthSuccess: widget.onAuthSuccess,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = 'تعذر إرسال رمز التحقق: ${e.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = 'حدث خطأ في الاتصال، حاول مرة أخرى';
      });
    }
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
                            onPressed: _submitting ? null : _sendOtp,
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

/// 2. شاشة إدخال رمز التحقق (OTP)
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final double watermarkOpacity;
  final VoidCallback onAuthSuccess;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.watermarkOpacity = 0.08,
    required this.onAuthSuccess,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 119;
  String? _errorText;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 119);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resendCode() async {
    try {
      await _supabase.auth.signInWithOtp(phone: widget.phoneNumber);
      if (!mounted) return;
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إعادة إرسال رمز التحقق')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'تعذر إعادة إرسال الرمز حالياً');
    }
  }

  String get _formattedTimer {
    final mins = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String get _codeValue =>
      _controllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      if (_controllers[index].text.isNotEmpty) {
        _controllers[index].clear();
      }
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() => _errorText = null);
      return;
    }

    final char = digitsOnly.characters.last;
    _controllers[index].value = TextEditingValue(
      text: char,
      selection: TextSelection.collapsed(offset: char.length),
    );
    setState(() => _errorText = null);

    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeValue;
    if (code.length < 6) {
      setState(() {
        _errorText = 'أدخل رمز التحقق المكون من 6 أرقام';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _verifying = true;
    });

    try {
      final response = await _supabase.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: code,
        type: OtpType.sms,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('لم يتم إنشاء جلسة مستخدم');
      }

      final existingProfile = await _supabase
          .from('profiles')
          .select('display_name, username')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() => _verifying = false);

      final hasCompleteProfile = existingProfile != null &&
          (existingProfile['username']?.toString().trim().isNotEmpty ?? false) &&
          (existingProfile['display_name']?.toString().trim().isNotEmpty ??
              false);

      if (hasCompleteProfile) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onAuthSuccess();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              watermarkOpacity: widget.watermarkOpacity,
              isEditing: false,
              onSaved: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                widget.onAuthSuccess();
              },
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _errorText = 'رمز التحقق غير صحيح أو منتهي الصلاحية (${e.message})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _errorText = 'حدث خطأ أثناء التحقق من الرمز';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);
    const softBg = Color(0xFFF7F5EF);

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text('رمز التحقق'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                  const Text(
                    'أدخل رمز التحقق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تم إرسال الرمز إلى ${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
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
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 44,
                                height: 52,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: softBg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onChanged: (val) =>
                                      _onDigitChanged(index, val),
                                ),
                              );
                            }),
                          ),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formattedTimer,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  _secondsLeft == 0 ? _resendCode : null,
                              child: const Text('إعادة إرسال الرمز'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _verifying ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _verifying
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'تأكيد الرمز',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. شاشة إنشاء وتعديل الملف الشخصي (عام لكل العراق بدون محافظات)
class ProfileSetupScreen extends StatefulWidget {
  final double watermarkOpacity;
  final bool isEditing;
  final VoidCallback onSaved;

  const ProfileSetupScreen({
    super.key,
    this.watermarkOpacity = 0.08,
    this.isEditing = false,
    required this.onSaved,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select('display_name, username, bio')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final name = data['display_name']?.toString() ?? '';
        if (name != 'مستخدم شلونكم') {
          _nameCtrl.text = name;
        }
        _usernameCtrl.text = data['username']?.toString() ?? '';
        _bioCtrl.text = data['bio']?.toString() ?? '';
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final displayName = _nameCtrl.text.trim();
    final rawUsername = _usernameCtrl.text.trim().toLowerCase();
    final bio = _bioCtrl.text.trim();

    if (displayName.length < 2) {
      setState(() => _errorText = 'أدخل الاسم الكامل (حرفين على الأقل)');
      return;
    }

    final validUsername = RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(rawUsername);
    if (!validUsername) {
      setState(() {
        _errorText =
            'اسم المستخدم يجب أن يكون بالإنجليزية (3-20 حرفاً أو أرقام أو _)';
      });
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _errorText = null;
      _saving = true;
    });

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'phone': user.phone,
        'display_name': displayName,
        'username': rawUsername,
        'bio': bio.isEmpty ? 'أهلاً بكم في شلونكم چات - IQ' : bio,
      });

      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSaved();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = e.code == '23505'
            ? 'اسم المستخدم محجوز مسبقاً، اختر اسماً آخر'
            : 'تعذر حفظ الملف الشخصي: ${e.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = 'حدث خطأ أثناء حفظ البيانات';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1B3A8F);
    const softBg = Color(0xFFF7F5EF);

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'تعديل الملف الشخصي' : 'إنشاء الملف الشخصي',
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          IshtarWatermark(opacity: widget.watermarkOpacity),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'الاسم الكامل',
                                  hintText: 'اكتب اسمك الظاهر للجميع',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: softBg,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _usernameCtrl,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  labelText: 'اسم المستخدم (Username)',
                                  hintText: 'atheer_iq',
                                  prefixText: '@',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: softBg,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _bioCtrl,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: 'النبذة التعريفية',
                                  hintText: 'أهلاً بكم في شلونكم چات - IQ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: softBg,
                                ),
                              ),
                              if (_errorText != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _errorText!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          widget.isEditing
                                              ? 'حفظ التعديلات'
                                              : 'حفظ والدخول للتطبيق',
                                          style: const TextStyle(
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
