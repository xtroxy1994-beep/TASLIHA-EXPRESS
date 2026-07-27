import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/point_transaction_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_widget.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

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
        title: const Text('إدارة المدفوعات'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'طلبات الشحن'),
            Tab(text: 'المعتمدة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PendingRechargesTab(),
          _ApprovedRechargesTab(),
        ],
      ),
    );
  }
}

class _PendingRechargesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RechargeRequestModel>>(
      stream: FirestoreService().watchPendingRechargeRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'جارٍ تحميل طلبات الشحن...');
        }
        final recharges = snap.data ?? [];
        if (recharges.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.check_circle_outline,
            title: 'لا توجد طلبات شحن معلقة',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recharges.length,
          itemBuilder: (_, i) {
            final r = recharges[i];
            return _RechargeCard(
              recharge: r,
              onApprove: (note) => _approve(context, r, note),
              onReject: (note) => _reject(context, r, note),
            );
          },
        );
      },
    );
  }

  Future<void> _approve(BuildContext ctx, RechargeRequestModel r, String? note) async {
    await FirestoreService().approveRechargeRequest(
      rechargeId: r.id,
      userId: r.userId,
      pointsToAdd: r.pointsRequested,
      adminNote: note,
    );
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('تم اعتماد الشحن لـ ${r.userName}'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _reject(BuildContext ctx, RechargeRequestModel r, String? note) async {
    await FirestoreService().rejectRechargeRequest(r.id, note);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('تم رفض طلب الشحن'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _ApprovedRechargesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.rechargeRequestsCollection)
          .where('status', isEqualTo: 'approved')
          .orderBy('reviewedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const EmptyStateWidget(icon: Icons.receipt, title: 'لا توجد عمليات معتمدة');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.check, color: Colors.white),
                ),
                title: Text(data['userName'] ?? ''),
                subtitle: Text('${data['pointsRequested']} نقطة - ${data['amountDZD']} دج'),
                trailing: Text(
                  DateFormat('dd/MM/yy').format(
                    (data['reviewedAt'] as Timestamp).toDate(),
                  ),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RechargeCard extends StatelessWidget {
  final RechargeRequestModel recharge;
  final Future<void> Function(String?) onApprove;
  final Future<void> Function(String?) onReject;

  const _RechargeCard({required this.recharge, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(recharge.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(recharge.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(label: '${recharge.pointsRequested} نقطة', color: AppColors.secondary),
                const SizedBox(width: 8),
                _InfoChip(label: '${recharge.amountDZD} دج', color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            // Receipt image
            if (recharge.receiptImageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _showImageDialog(context, recharge.receiptImageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    recharge.receiptImageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: Colors.grey.shade100,
                      child: const Center(child: Text('صورة الوصل', style: TextStyle(color: AppColors.textSecondary))),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showNoteDialog(context, 'رفض', onReject, isReject: true),
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('رفض', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showNoteDialog(context, 'اعتماد', onApprove),
                    icon: const Icon(Icons.check),
                    label: const Text('اعتماد'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, String action, Future<void> Function(String?) callback, {bool isReject = false}) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action طلب الشحن'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد $action طلب الشحن لـ ${recharge.userName}؟'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await callback(noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isReject ? AppColors.error : AppColors.success,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
