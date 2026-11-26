import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DevAuthBypass {
  static const bool enableInDebug = true;

  static Future<void> continueAsTestUser({
    required BuildContext context,
    required String phoneInput,
    required Widget nextScreen,
  }) async {
    if (!kDebugMode || !enableInDebug) return;

    final cleanedPhone = phoneInput.trim().replaceAll(RegExp(r'\s+'), '');
    debugPrint('DevAuthBypass phone input: $cleanedPhone');

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        await Supabase.instance.client.auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('DevAuthBypass anonymous sign-in skipped/failed: $e');
    }

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }
}

class DevBypassButton extends StatelessWidget {
  final TextEditingController phoneController;
  final Widget nextScreen;
  final String label;

  const DevBypassButton({
    super.key,
    required this.phoneController,
    required this.nextScreen,
    this.label = 'تجاوز مؤقت للتطوير',
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !DevAuthBypass.enableInDebug) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton(
        onPressed: () => DevAuthBypass.continueAsTestUser(
          context: context,
          phoneInput: phoneController.text,
          nextScreen: nextScreen,
        ),
        child: Text(label),
      ),
    );
  }
}
