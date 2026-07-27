import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_routes.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rating_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUpdatingImage = false;

  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _isUpdatingImage = true);
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final url = await StorageService().uploadProfileImage(File(picked.path), uid);
      if (url != null) {
        await auth.refreshCurrentUser();
      }
    } finally {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUserModel;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 18),
            label: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _changeProfileImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    backgroundImage: user.profileImageUrl != null
                                        ? NetworkImage(user.profileImageUrl!)
                                        : null,
                                    child: _isUpdatingImage
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : user.profileImageUrl == null
                                            ? const Icon(Icons.person, size: 48, color: Colors.white)
                                            : null,
                                  ),
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt, size: 14, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getRoleLabel(user.role),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (user.role == AppConstants.roleTech) ...[
                              const SizedBox(height: 8),
                              RatingDisplay(rating: user.rating, count: user.ratingCount),
                              const SizedBox(height: 4),
                              Text(user.techLevel, style: const TextStyle(color: Colors.white70)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Info card
                        _InfoCard(
                          title: 'المعلومات الشخصية',
                          children: [
                            _InfoRow(icon: Icons.email_outlined, label: 'البريد', value: user.email),
                            _InfoRow(icon: Icons.phone_outlined, label: 'الهاتف', value: user.phone),
                            _InfoRow(icon: Icons.location_on_outlined, label: 'الولاية', value: user.wilaya),
                            _InfoRow(icon: Icons.location_city_outlined, label: 'البلدية', value: user.commune),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Points card (tech only)
                        if (user.role == AppConstants.roleTech) ...[
                          _InfoCard(
                            title: 'النقاط',
                            children: [
                              _InfoRow(icon: Icons.stars, label: 'النقاط المدفوعة', value: '${user.totalPoints}'),
                              _InfoRow(icon: Icons.card_giftcard, label: 'النقاط المجانية', value: '${user.freePoints}'),
                              _InfoRow(icon: Icons.account_balance_wallet, label: 'المجموع المتاح', value: '${user.availablePoints}'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CustomButton(
                            label: 'شحن نقاط',
                            icon: Icons.add_circle_outline,
                            color: AppColors.secondary,
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.recharge),
                          ),
                          const SizedBox(height: 8),
                          CustomButton(
                            label: 'سجل النقاط',
                            icon: Icons.history,
                            isOutlined: true,
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.points),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Language switcher
                        _InfoCard(
                          title: 'اللغة',
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _LangButton(
                                  label: 'العربية',
                                  flag: '🇩🇿',
                                  selected: localeProvider.locale.languageCode == 'ar',
                                  onTap: () => localeProvider.setLocale(const Locale('ar')),
                                ),
                                _LangButton(
                                  label: 'Français',
                                  flag: '🇫🇷',
                                  selected: localeProvider.locale.languageCode == 'fr',
                                  onTap: () => localeProvider.setLocale(const Locale('fr')),
                                ),
                                _LangButton(
                                  label: 'English',
                                  flag: '🇬🇧',
                                  selected: localeProvider.locale.languageCode == 'en',
                                  onTap: () => localeProvider.setLocale(const Locale('en')),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'client': return 'عميل';
      case 'tech': return 'فني';
      case 'manager': return 'مدير';
      case 'admin': return 'أدمن';
      default: return role;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({required this.label, required this.flag, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
