import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rating_widget.dart';

class RatingScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const RatingScreen({super.key, required this.args});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String get requestId => widget.args['requestId'] ?? '';
  String get techId => widget.args['techId'] ?? '';
  String get techName => widget.args['techName'] ?? 'الفني';

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'اختر عدد النجوم أولاً');
      return;
    }
    setState(() {_isLoading = true; _error = null;});

    final auth = context.read<AuthService>();
    final user = auth.currentUserModel;
    if (user == null) return;

    try {
      await FirestoreService().submitRating(
        requestId: requestId,
        clientId: user.uid,
        clientName: user.fullName,
        techId: techId,
        stars: _rating,
        comment: _commentCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شكراً على تقييمك!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تقييم الخدمة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.engineering, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              techName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'كيف كانت تجربتك مع هذا الفني؟',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Stars
            RatingInput(
              initialRating: _rating,
              onRatingChanged: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 32),

            // Comment
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تعليق (اختياري)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'أخبرنا عن تجربتك مع الفني...',
                    hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: 12),
            ],

            GradientButton(
              label: 'إرسال التقييم',
              isLoading: _isLoading,
              onPressed: _submit,
              icon: Icons.send,
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'تخطي',
              isOutlined: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
