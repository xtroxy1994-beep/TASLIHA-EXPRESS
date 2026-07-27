import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const OtpScreen({super.key, required this.args});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _isLoading = false;
  String? _error;
  int _resendTimer = 60;
  bool _canResend = false;

  // Simulated OTP for demo (in production use Firebase Phone Auth)
  String _expectedOtp = '123456';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // In production: send real OTP via Firebase Phone Auth
    _simulateSendOtp();
  }

  void _simulateSendOtp() {
    // TODO: Integrate Firebase Phone Authentication
    // For demo purposes, OTP is shown in a SnackBar
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('رمز التحقق التجريبي: $_expectedOtp'),
            duration: const Duration(seconds: 8),
            backgroundColor: AppColors.info,
          ),
        );
      }
    });
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _error = 'أدخل الرمز المكون من 6 أرقام');
      return;
    }
    if (_otp != _expectedOtp) {
      setState(() => _error = 'رمز التحقق غير صحيح');
      return;
    }
    setState(() {_isLoading = true; _error = null;});
    
    final formData = widget.args['formData'] as Map<String, dynamic>;
    final type = widget.args['type'] as String;
    final auth = context.read<AuthService>();
    final storage = StorageService();

    try {
      String? profileImageUrl;
      if (formData['profileImage'] != null) {
        final file = File(formData['profileImage']);
        // upload after registration
        profileImageUrl = null; // will update after
      }

      String? error;
      if (type == 'client') {
        error = await auth.registerClient(
          firstName: formData['firstName'],
          lastName: formData['lastName'],
          email: formData['email'],
          phone: formData['phone'],
          password: formData['password'],
          wilaya: formData['wilaya'],
          commune: formData['commune'],
        );
      } else {
        error = await auth.registerTech(
          firstName: formData['firstName'],
          lastName: formData['lastName'],
          email: formData['email'],
          phone: formData['phone'],
          password: formData['password'],
          wilaya: formData['wilaya'],
          commune: formData['commune'],
          specialties: List<String>.from(formData['specialties'] ?? []),
          profileImageUrl: '', // will upload after
        );
      }

      // Upload profile image if present
      if (error == null && formData['profileImage'] != null && auth.currentUser != null) {
        final url = await storage.uploadProfileImage(
          File(formData['profileImage']),
          auth.currentUser!.uid,
        );
        if (url != null) {
          await auth.refreshCurrentUser();
        }
      }

      if (!mounted) return;
      if (error != null) {
        setState(() {_error = error; _isLoading = false;});
        return;
      }

      final user = auth.currentUserModel;
      switch (user?.role) {
        case AppConstants.roleTech:
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.techHome, (_) => false);
          break;
        default:
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.clientHome, (_) => false);
      }
    } catch (e) {
      setState(() {_error = 'حدث خطأ: $e'; _isLoading = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.args['phone'] ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('التحقق من الهاتف')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sms, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'التحقق من رقم الهاتف',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'تم إرسال رمز التحقق إلى\n$phone',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (v) => setState(() => _otp = v),
              onCompleted: (_) => _verify(),
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 52,
                fieldWidth: 44,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: AppColors.primary.withOpacity(0.05),
                activeColor: AppColors.primary,
                inactiveColor: Colors.grey.shade300,
                selectedColor: AppColors.primary,
              ),
              enableActiveFill: true,
              animationType: AnimationType.fade,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            GradientButton(
              label: 'تحقق',
              isLoading: _isLoading,
              onPressed: _verify,
              icon: Icons.verified_user,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('لم تستلم الرمز؟ '),
                _canResend
                    ? TextButton(
                        onPressed: () {
                          setState(() {_canResend = false; _resendTimer = 60;});
                          _startResendTimer();
                          _simulateSendOtp();
                        },
                        child: const Text('إعادة الإرسال'),
                      )
                    : Text(
                        'إعادة الإرسال (${_resendTimer}ث)',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
