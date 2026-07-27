import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/request_card.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUserModel?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.techColor,
        title: const Text('أعمالي'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: FirestoreService().watchTechJobs(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'جارٍ تحميل أعمالك...');
          }
          final jobs = snap.data ?? [];
          if (jobs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.work_outline,
              title: 'لا توجد أعمال بعد',
              subtitle: 'اقبل الطلبات المتاحة لتبدأ بكسب الدخل',
            );
          }

          final active = jobs.where((j) => j.status == 'accepted' || j.status == 'in_progress').toList();
          final completed = jobs.where((j) => j.status == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                const _SectionHeader(title: 'الأعمال الجارية', color: AppColors.primary),
                const SizedBox(height: 8),
                ...active.map((r) => RequestCard(
                  request: r,
                  showPoints: false,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.chat, arguments: {
                    'requestId': r.id,
                    'otherName': r.clientName,
                    'currentUserId': uid,
                  }),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('محادثة', style: TextStyle(fontSize: 12)),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.chat, arguments: {
                      'requestId': r.id,
                      'otherName': r.clientName,
                      'currentUserId': uid,
                    }),
                  ),
                )),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                const _SectionHeader(title: 'الأعمال المكتملة', color: AppColors.success),
                const SizedBox(height: 8),
                ...completed.map((r) => RequestCard(request: r, showPoints: false)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
