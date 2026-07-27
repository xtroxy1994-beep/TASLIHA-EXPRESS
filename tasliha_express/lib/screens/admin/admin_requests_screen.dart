import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../models/request_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/request_card.dart';
import '../../widgets/custom_button.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        title: const Text('إدارة الطلبات'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'قيد المراجعة'),
            Tab(text: 'جميع الطلبات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PendingRequestsList(fs: _fs),
          _AllRequestsList(fs: _fs),
        ],
      ),
    );
  }
}

class _PendingRequestsList extends StatelessWidget {
  final FirestoreService fs;
  const _PendingRequestsList({required this.fs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: fs.watchPendingRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const EmptyStateWidget(icon: Icons.check_circle_outline, title: 'لا توجد طلبات قيد المراجعة');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final r = requests[i];
            return RequestCard(
              request: r,
              showPoints: true,
              onTap: () => _showReviewDialog(context, r),
              trailing: ElevatedButton(
                onPressed: () => _showReviewDialog(context, r),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('مراجعة'),
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, RequestModel request) {
    int points = 5;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('مراجعة الطلب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(request.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              const Text('حدد عدد النقاط المطلوبة للفني:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () { if (points > 1) setDialogState(() => points--); },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Expanded(
                    child: Text(
                      '$points نقطة',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setDialogState(() => points++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: [3, 5, 10, 15, 20].map((p) => ActionChip(
                  label: Text('$p'),
                  onPressed: () => setDialogState(() => points = p),
                  backgroundColor: points == p ? AppColors.primary.withOpacity(0.1) : null,
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                setDialogState(() => isLoading = true);
                await FirestoreService().updateRequest(request.id, {
                  'status': 'cancelled',
                  'reviewedAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('رفض', style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setDialogState(() => isLoading = true);
                await FirestoreService().updateRequest(request.id, {
                  'status': 'available',
                  'pointsRequired': points,
                  'reviewedAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('نشر للفنيين'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllRequestsList extends StatelessWidget {
  final FirestoreService fs;
  const _AllRequestsList({required this.fs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: fs.watchAllRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
        final requests = snap.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) => RequestCard(request: requests[i], showPoints: true),
        );
      },
    );
  }
}
