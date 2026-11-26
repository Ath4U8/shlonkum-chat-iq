import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dev_auth_bypass.dart';
import 'home_screens.dart' as home;

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  bool otpSent = false;
  String? errorMessage;

  Widget _resolveNextScreen() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return const home.HomeScreens();
    }
    return const home.HomeScreens();
  }

  String _normalizeIraqPhone(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('07')) return '+964${cleaned.substring(1)}';
    if (cleaned.startsWith('964')) return '+$cleaned';
    return '+964$cleaned';
  }

  Future<void> _sendOtp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final phone = _normalizeIraqPhone(phoneController.text);
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      if (!mounted) return;
      setState(() {
        otpSent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'تعذر إرسال رمز التحقق: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final phone = _normalizeIraqPhone(phoneController.text);
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: otpController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _resolveNextScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'رمز التحقق غير صحيح: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول - شلونكم IQ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (مثال: 07740140888)',
                border: OutlineInputBorder(),
              ),
            ),
            if (otpSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رمز التحقق OTP',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : (otpSent ? _verifyOtp : _sendOtp),
              child: Text(
                isLoading
                    ? 'جاري التنفيذ...'
                    : (otpSent ? 'تأكيد رمز التحقق' : 'إرسال رمز التحقق'),
              ),
            ),
            DevBypassButton(
              phoneController: phoneController,
              nextScreen: _resolveNextScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
