import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/request_card.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.managerColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لوحة المدير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (user != null)
              Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
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
          _ManagerRequestsTab(),
          _ManagerTechsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.managerColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'الفنيون'),
        ],
      ),
    );
  }
}

class _ManagerRequestsTab extends StatelessWidget {
  const _ManagerRequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: FirestoreService().watchAllRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const EmptyStateWidget(icon: Icons.inbox, title: 'لا توجد طلبات');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) => RequestCard(request: requests[i], showPoints: true),
        );
      },
    );
  }
}

class _ManagerTechsTab extends StatelessWidget {
  const _ManagerTechsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().watchTechs(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
        final techs = snap.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: techs.length,
          itemBuilder: (_, i) {
            final t = techs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: t.profileImageUrl != null ? NetworkImage(t.profileImageUrl!) : null,
                  child: t.profileImageUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(t.specialties.take(2).join('، ')),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 14),
                      Text(t.rating.toStringAsFixed(1)),
                    ]),
                    Text('${t.availablePoints} نقطة', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
