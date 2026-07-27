import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../shared/points_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_payments_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لوحة الأدمن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('تسليحة إكسبريس', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _AdminDashboard(),
          AdminRequestsScreen(),
          AdminPaymentsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.adminColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'اللوحة'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.payment_outlined), activeIcon: Icon(Icons.payment), label: 'المدفوعات'),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          FutureBuilder(
            future: Future.wait([fs.getAllUsers(), fs.getAllTechs()]),
            builder: (context, snap) {
              final users = snap.data?[0] ?? [];
              final techs = snap.data?[1] ?? [];
              final clients = users.where((u) => u.role == 'client').length;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _StatCard(label: 'إجمالي المستخدمين', value: '${users.length}', icon: Icons.people, color: AppColors.primary),
                  _StatCard(label: 'الفنيون', value: '${techs.length}', icon: Icons.engineering, color: AppColors.techColor),
                  _StatCard(label: 'العملاء', value: '$clients', icon: Icons.person, color: AppColors.clientColor),
                  _StatCard(label: 'الطلبات', value: '—', icon: Icons.list_alt, color: AppColors.secondary),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          const Text('إجراءات سريعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _AdminAction(
            icon: Icons.pending_actions,
            label: 'مراجعة طلبات العملاء',
            subtitle: 'راجع الطلبات وحدد النقاط',
            color: AppColors.primary,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _AdminAction(
            icon: Icons.receipt_long,
            label: 'طلبات الشحن المعلقة',
            subtitle: 'راجع وصولات BaridiMob/CCP',
            color: AppColors.secondary,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _AdminAction(
            icon: Icons.people,
            label: 'إدارة المستخدمين',
            subtitle: 'عرض وتعطيل الحسابات',
            color: AppColors.managerColor,
            onTap: () {},
          ),

          const SizedBox(height: 24),
          // CCP info card
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
                    Icon(Icons.account_balance, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('معلومات حساب CCP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('رقم الحساب: 0012345678901', style: TextStyle(fontSize: 13)),
                const Text('الكلمة الدالة: 67', style: TextStyle(fontSize: 13)),
                const Text('الاسم: تسليحة إكسبريس', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                const Text('📱 BaridiMob: نفس رقم الحساب', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminAction({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
