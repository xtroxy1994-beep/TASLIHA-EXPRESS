import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  File? _receiptImage;
  bool _isLoading = false;
  String? _error;
  String? _success;
  int _selectedPackage = 1; // number of packages

  int get totalPoints => _selectedPackage * AppConstants.pointsPerPackage;
  int get totalDZD => _selectedPackage * AppConstants.pricePerPackageDZD;

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _receiptImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (_receiptImage == null) {
      setState(() => _error = 'يرجى رفع صورة الوصل أولاً');
      return;
    }
    setState(() {_isLoading = true; _error = null; _success = null;});

    final auth = context.read<AuthService>();
    final user = auth.currentUserModel;
    if (user == null) return;

    try {
      // Upload receipt
      final receiptUrl = await StorageService().uploadRechargeReceipt(_receiptImage!, user.uid);
      if (receiptUrl == null) {
        setState(() {_error = 'فشل رفع الصورة، حاول مرة أخرى'; _isLoading = false;});
        return;
      }

      // Create recharge request in Firestore
      await FirebaseFirestore.instance
          .collection(AppConstants.rechargeRequestsCollection)
          .add({
        'userId': user.uid,
        'userName': user.fullName,
        'userEmail': user.email,
        'pointsRequested': totalPoints,
        'amountDZD': totalDZD,
        'receiptImageUrl': receiptUrl,
        'status': AppConstants.rechargeStatusPending,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _success = 'تم إرسال طلب الشحن بنجاح!\nسيتم مراجعته خلال 24 ساعة.';
        _receiptImage = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {_error = 'حدث خطأ: $e'; _isLoading = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('شحن نقاط')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package selection
            const Text('اختر الباقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [1, 2, 3, 5].map((p) {
                final selected = _selectedPackage == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPackage = p),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.secondary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.secondary : Colors.grey.shade300, width: 2),
                        boxShadow: selected ? [BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 8)] : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${p * AppConstants.pointsPerPackage}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.textPrimary),
                          ),
                          Text(
                            'نقطة',
                            style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p * AppConstants.pricePerPackageDZD} دج',
                            style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.secondary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$totalPoints نقطة', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('مقابل $totalDZD دج', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Text('تفاصيل الدفع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 15)),
                    ],
                  ),
                  const Divider(color: Colors.teal),
                  const Text('يمكنك الدفع عبر:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _PayMethod(
                    icon: Icons.phone_android,
                    title: 'BaridiMob',
                    detail: 'رقم الحساب: ${AppConstants.ccpAccount}',
                  ),
                  const SizedBox(height: 6),
                  _PayMethod(
                    icon: Icons.credit_card,
                    title: 'CCP',
                    detail: 'رقم الحساب: ${AppConstants.ccpAccount}\nالاسم: ${AppConstants.ccpOwner}',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'بعد الدفع، ارفع صورة الوصل أدناه وسيتم تحديث نقاطك خلال 24 ساعة',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Receipt upload
            const Text('رفع صورة الوصل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickReceipt,
              child: Container(
                width: double.infinity,
                height: _receiptImage != null ? 200 : 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _receiptImage != null ? AppColors.success : Colors.grey.shade300,
                    style: BorderStyle.solid,
                    width: _receiptImage != null ? 2 : 1,
                  ),
                ),
                child: _receiptImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_receiptImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('اضغط لرفع صورة الوصل', style: TextStyle(color: Colors.grey.shade500)),
                          Text('JPG, PNG مسموح بها', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            if (_success != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_success!, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            GradientButton(
              label: 'إرسال طلب الشحن',
              isLoading: _isLoading,
              onPressed: _submit,
              icon: Icons.send,
              colors: [AppColors.secondary, AppColors.secondaryLight],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _PayMethod({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
