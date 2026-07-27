import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/request_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/request_card.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _firestoreService = FirestoreService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تسليحة إكسبريس', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (user != null)
              Text('مرحباً، ${user.firstName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(firestoreService: _firestoreService, user: user),
          const MyRequestsScreen2(),
          const _TechsTab(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.postRequest),
              icon: const Icon(Icons.add),
              label: const Text('طلب جديد'),
              backgroundColor: AppColors.secondary,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'طلباتي'),
          BottomNavigationBarItem(icon: Icon(Icons.engineering_outlined), activeIcon: Icon(Icons.engineering), label: 'الفنيون'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final FirestoreService firestoreService;
  final user;

  const _HomeTab({required this.firestoreService, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('خدماتك بين يديك', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text(
                        'انشر طلبك وتواصل\nmع أفضل الفنيين',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.postRequest),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('طلب جديد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.home_repair_service, size: 80, color: Colors.white24),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categories
          const Text('التخصصات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: const [
              _CategoryCard(label: 'كهرباء', icon: Icons.electric_bolt, color: Color(0xFFF57C00)),
              _CategoryCard(label: 'سباكة', icon: Icons.water, color: Color(0xFF1565C0)),
              _CategoryCard(label: 'تكييف', icon: Icons.ac_unit, color: Color(0xFF00897B)),
              _CategoryCard(label: 'إلكترونيات', icon: Icons.devices, color: Color(0xFF6A1B9A)),
              _CategoryCard(label: 'ميكانيك', icon: Icons.build, color: Color(0xFF37474F)),
              _CategoryCard(label: 'نجارة', icon: Icons.chair, color: Color(0xFF795548)),
            ],
          ),
          const SizedBox(height: 24),

          // Recent requests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('آخر طلباتك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('الكل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (user != null)
            StreamBuilder<List<RequestModel>>(
              stream: FirestoreService().watchClientRequests(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                final requests = snap.data ?? [];
                if (requests.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.inbox_outlined,
                    title: 'لا توجد طلبات بعد',
                    subtitle: 'انشر أول طلبك الآن',
                  );
                }
                return Column(
                  children: requests.take(3).map((r) => RequestCard(request: r, showPoints: true)).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryCard({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class MyRequestsScreen2 extends StatelessWidget {
  const MyRequestsScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUserModel?.uid ?? '';
    return StreamBuilder<List<RequestModel>>(
      stream: FirestoreService().watchClientRequests(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'لا توجد طلبات',
            subtitle: 'انشر أول طلبك بالضغط على + في الأسفل',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) => RequestCard(
            request: requests[i],
            showPoints: true,
            onTap: () {},
          ),
        );
      },
    );
  }
}

class _TechsTab extends StatelessWidget {
  const _TechsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService().watchTechs(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
        final techs = snap.data ?? [];
        if (techs.isEmpty) {
          return const EmptyStateWidget(icon: Icons.engineering, title: 'لا يوجد فنيون متاحون حالياً');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: techs.length,
          itemBuilder: (_, i) {
            final tech = techs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: tech.profileImageUrl != null ? NetworkImage(tech.profileImageUrl!) : null,
                  child: tech.profileImageUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(tech.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tech.specialties.take(2).join('، ')),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 16),
                      Text(tech.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    Text(tech.techLevel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
