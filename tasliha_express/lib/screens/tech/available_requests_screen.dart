import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_routes.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/points_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/request_card.dart';
import '../../widgets/custom_button.dart';

class AvailableRequestsScreen extends StatefulWidget {
  const AvailableRequestsScreen({super.key});

  @override
  State<AvailableRequestsScreen> createState() => _AvailableRequestsScreenState();
}

class _AvailableRequestsScreenState extends State<AvailableRequestsScreen> {
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.techColor,
        title: const Text('الطلبات المتاحة'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filterCategory = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('الكل')),
              ...AppConstants.techSpecialties.map(
                (s) => PopupMenuItem(value: s, child: Text(s)),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: FirestoreService().watchAvailableRequests(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'جارٍ تحميل الطلبات...');
          }
          var requests = snap.data ?? [];
          if (_filterCategory != null) {
            requests = requests.where((r) => r.category == _filterCategory).toList();
          }
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.search_off,
              title: 'لا توجد طلبات متاحة',
              subtitle: 'عد لاحقاً للاطلاع على الطلبات الجديدة',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (_, i) {
              final r = requests[i];
              return RequestCard(
                request: r,
                showStatus: false,
                showPoints: true,
                onTap: () => _showRequestDetails(context, r),
              );
            },
          );
        },
      ),
    );
  }

  void _showRequestDetails(BuildContext context, RequestModel request) {
    final auth = context.read<AuthService>();
    final user = auth.currentUserModel!;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(request.category, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      Text(request.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(request.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                      const SizedBox(height: 16),

                      // Location (no phone shown)
                      _InfoRow(icon: Icons.location_on_outlined, label: 'الموقع', value: '${request.clientWilaya} - ${request.clientCommune}'),
                      _InfoRow(icon: Icons.person_outline, label: 'صاحب الطلب', value: request.clientName),

                      // Privacy notice
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.info.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, color: AppColors.info, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'رقم الهاتف والمحادثة المباشرة ستُفتح بعد قبولك للطلب',
                                style: TextStyle(fontSize: 12, color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Points info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('النقاط المطلوبة', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  '${request.pointsRequired} نقطة',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('رصيدك', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  '${user.availablePoints} نقطة',
                                  style: TextStyle(
                                    color: user.availablePoints >= request.pointsRequired ? Colors.white : Colors.red.shade200,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Images
                      if (request.imageUrls.isNotEmpty) ...[
                        const Text('صور الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: request.imageUrls.length,
                            itemBuilder: (_, j) => Container(
                              width: 120, height: 120,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(request.imageUrls[j]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (user.availablePoints < request.pointsRequired) ...[
                        CustomButton(
                          label: 'نقاطك غير كافية - اشحن الآن',
                          color: AppColors.secondary,
                          icon: Icons.add_circle_outline,
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, AppRoutes.recharge);
                          },
                        ),
                      ] else ...[
                        GradientButton(
                          label: isLoading ? '' : 'قبول الطلب (${request.pointsRequired} نقطة)',
                          isLoading: isLoading,
                          colors: [AppColors.techColor, AppColors.success],
                          icon: Icons.check_circle_outline,
                          onPressed: () async {
                            setModalState(() => isLoading = true);
                            await _acceptRequest(context, ctx, request, user.uid, user.fullName);
                            if (ctx.mounted) setModalState(() => isLoading = false);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptRequest(
    BuildContext outerCtx,
    BuildContext modalCtx,
    RequestModel request,
    String techId,
    String techName,
  ) async {
    final pointsService = PointsService();
    final firestoreService = FirestoreService();
    final chatService = ChatService();

    try {
      // Deduct points
      final error = await pointsService.deductPoints(
        techId: techId,
        amount: request.pointsRequired,
        requestId: request.id,
        description: 'قبول طلب: ${request.title}',
      );

      if (error != null) {
        if (modalCtx.mounted) {
          ScaffoldMessenger.of(modalCtx).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      // Update request status
      await firestoreService.updateRequest(request.id, {
        'status': 'accepted',
        'acceptedTechId': techId,
        'acceptedTechName': techName,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Initialize chat
      await chatService.initializeChatRoom(
        requestId: request.id,
        clientId: request.clientId,
        clientName: request.clientName,
        techId: techId,
        techName: techName,
      );

      if (modalCtx.mounted) Navigator.pop(modalCtx);
      if (outerCtx.mounted) {
        ScaffoldMessenger.of(outerCtx).showSnackBar(
          const SnackBar(content: Text('تم قبول الطلب بنجاح! تم فتح المحادثة مع العميل'), backgroundColor: AppColors.success),
        );
        Navigator.pushNamed(outerCtx, AppRoutes.chat, arguments: {
          'requestId': request.id,
          'otherName': request.clientName,
          'currentUserId': techId,
        });
      }
    } catch (e) {
      if (modalCtx.mounted) {
        ScaffoldMessenger.of(modalCtx).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
