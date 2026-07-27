import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_routes.dart';
import '../../constants/algeria_wilayas.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final Map<String, dynamic>? args;
  const RegisterScreen({super.key, this.args});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late String _type;
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String? _selectedWilaya;
  String? _selectedCommune;
  List<String> _communes = [];
  List<String> _selectedSpecialties = [];
  File? _profileImage;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.args?['type'] ?? 'client';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'tech' && _profileImage == null) {
      setState(() => _error = 'الصورة الشخصية إلزامية للفني');
      return;
    }
    if (_type == 'tech' && _selectedSpecialties.isEmpty) {
      setState(() => _error = 'اختر تخصصاً واحداً على الأقل');
      return;
    }
    if (_passwordCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }

    // OTP verification first
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.otp,
      arguments: {
        'phone': _phoneCtrl.text.trim(),
        'type': _type,
        'formData': {
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'wilaya': _selectedWilaya,
          'commune': _selectedCommune,
          'specialties': _selectedSpecialties,
          'profileImage': _profileImage?.path,
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClient = _type == 'client';
    final roleColor = isClient ? AppColors.clientColor : AppColors.techColor;
    final roleLabel = isClient ? 'حساب عميل' : 'حساب فني';
    final roleIcon = isClient ? Icons.person : Icons.engineering;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('إنشاء $roleLabel'),
        backgroundColor: roleColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(roleIcon, color: roleColor),
                    const SizedBox(width: 12),
                    Text(
                      isClient
                          ? 'ستتمكن من نشر طلبات الخدمة'
                          : 'ستتمكن من قبول طلبات الخدمة وكسب المال',
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: roleColor.withOpacity(0.1),
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, color: roleColor, size: 32),
                                  const SizedBox(height: 4),
                                  Text(
                                    isClient ? 'اختياري' : 'إلزامي',
                                    style: TextStyle(fontSize: 11, color: roleColor),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Personal info
              _SectionTitle(title: 'المعلومات الشخصية', icon: Icons.person_outline),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'الاسم',
                      hint: 'محمد',
                      controller: _firstNameCtrl,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'اللقب',
                      hint: 'بن علي',
                      controller: _lastNameCtrl,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'البريد الإلكتروني',
                hint: 'example@email.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (!v.contains('@')) return 'صيغة غير صحيحة';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'رقم الهاتف',
                hint: '0550000000',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (v.length < 9) return 'رقم غير صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Location
              _SectionTitle(title: 'الموقع الجغرافي', icon: Icons.location_on_outlined),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'الولاية',
                value: _selectedWilaya,
                hint: 'اختر الولاية',
                items: AlgeriaData.wilayas
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                onChanged: (w) {
                  setState(() {
                    _selectedWilaya = w;
                    _selectedCommune = null;
                    _communes = w != null ? AlgeriaData.getCommunesByWilaya(w) : [];
                  });
                },
                validator: (v) => v == null ? 'اختر الولاية' : null,
              ),
              const SizedBox(height: 16),
              DropdownField<String>(
                label: 'البلدية',
                value: _selectedCommune,
                hint: 'اختر البلدية',
                items: _communes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (c) => setState(() => _selectedCommune = c),
                validator: (v) => v == null ? 'اختر البلدية' : null,
              ),
              const SizedBox(height: 24),

              // Specialties (tech only)
              if (!isClient) ...[
                _SectionTitle(title: 'التخصصات', icon: Icons.build_outlined),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.techSpecialties.map((s) {
                    final selected = _selectedSpecialties.contains(s);
                    return FilterChip(
                      label: Text(s, style: const TextStyle(fontSize: 13)),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedSpecialties.add(s);
                          } else {
                            _selectedSpecialties.remove(s);
                          }
                        });
                      },
                      selectedColor: AppColors.techColor.withOpacity(0.2),
                      checkmarkColor: AppColors.techColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Password
              _SectionTitle(title: 'كلمة المرور', icon: Icons.lock_outlined),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'كلمة المرور',
                hint: '8 أحرف على الأقل',
                controller: _passwordCtrl,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outlined),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'تأكيد كلمة المرور',
                hint: 'أعد إدخال كلمة المرور',
                controller: _confirmPassCtrl,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outlined),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (v != _passwordCtrl.text) return 'كلمتا المرور غير متطابقتين';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              GradientButton(
                label: 'التالي - التحقق من الهاتف',
                isLoading: _isLoading,
                onPressed: _register,
                icon: Icons.arrow_forward,
                colors: [roleColor, roleColor.withOpacity(0.8)],
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('لديك حساب؟ سجل الدخول'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
