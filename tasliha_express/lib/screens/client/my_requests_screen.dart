import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/request_card.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUserModel?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('طلباتي')),
      body: StreamBuilder<List<RequestModel>>(
        stream: FirestoreService().watchClientRequests(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'جارٍ تحميل الطلبات...');
          }
          final requests = snap.data ?? [];
          if (requests.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'لا توجد طلبات بعد',
              subtitle: 'انشر طلبك الأول للحصول على خدمة من فنيين محترفين',
              actionLabel: 'نشر طلب جديد',
              onAction: () => Navigator.pushNamed(context, AppRoutes.postRequest),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (_, i) {
              final r = requests[i];
              return RequestCard(
                request: r,
                showPoints: true,
                onTap: r.isAccepted
                    ? () => Navigator.pushNamed(
                          context,
                          AppRoutes.chat,
                          arguments: {
                            'requestId': r.id,
                            'otherName': r.acceptedTechName ?? 'الفني',
                            'currentUserId': uid,
                          },
                        )
                    : null,
                trailing: r.isCompleted && !r.isRated
                    ? TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.rating,
                          arguments: {
                            'requestId': r.id,
                            'techId': r.acceptedTechId,
                            'techName': r.acceptedTechName,
                          },
                        ),
                        child: const Text('قيّم', style: TextStyle(color: AppColors.secondary)),
                      )
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.postRequest),
        icon: const Icon(Icons.add),
        label: const Text('طلب جديد'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }
}
