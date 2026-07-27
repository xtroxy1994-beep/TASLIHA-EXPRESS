import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_routes.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key});

  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCategory;
  List<File> _images = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 75);
    if (picked.isNotEmpty) {
      setState(() {
        _images = picked.take(4).map((x) => File(x.path)).toList();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _error = 'اختر تخصص الخدمة');
      return;
    }
    setState(() {_isLoading = true; _error = null;});

    final auth = context.read<AuthService>();
    final user = auth.currentUserModel!;
    final firestoreService = FirestoreService();
    final storageService = StorageService();

    try {
      // Create request first to get ID
      final tempId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      List<String> imageUrls = [];

      // Upload images
      if (_images.isNotEmpty) {
        imageUrls = await storageService.uploadMultipleImages(_images, tempId);
      }

      final request = RequestModel(
        id: tempId,
        clientId: user.uid,
        clientName: user.fullName,
        clientWilaya: user.wilaya,
        clientCommune: user.commune,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _selectedCategory!,
        imageUrls: imageUrls,
        status: AppConstants.statusPending,
        createdAt: DateTime.now(),
      );

      await firestoreService.createRequest(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلبك للمراجعة بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text('نشر طلب جديد')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'سيقوم الأدمن بمراجعة طلبك وتحديد عدد النقاط المطلوبة قبل نشره للفنيين',
                        style: TextStyle(fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category selection
              const Text('تخصص الخدمة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.techSpecialties.map((s) {
                  final selected = _selectedCategory == s;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'عنوان الطلب',
                hint: 'مثال: إصلاح تسريب مياه في المطبخ',
                controller: _titleCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (v.length < 10) return 'العنوان قصير جداً';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'وصف المشكلة',
                hint: 'اشرح المشكلة بالتفصيل لمساعدة الفني على فهم ما تحتاجه...',
                controller: _descCtrl,
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (v.length < 20) return 'الوصف قصير جداً';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('صور (اختياري - 4 صور كحد أقصى)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (_images.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _images = []),
                      child: const Text('مسح الكل', style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade400, size: 32),
                            const SizedBox(height: 4),
                            Text('أضف صورة', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ),
                    ..._images.map((f) => Container(
                      width: 100, height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: FileImage(f), fit: BoxFit.cover),
                      ),
                    )),
                  ],
                ),
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
                label: 'إرسال الطلب',
                isLoading: _isLoading,
                onPressed: _submit,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
