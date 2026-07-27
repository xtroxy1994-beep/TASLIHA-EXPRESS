import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../models/point_transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_button.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final user = auth.currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('نقاطي')),
      body: user == null
          ? const LoadingWidget()
          : Column(
              children: [
                // Points summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.stars, size: 48, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        '${user.availablePoints}',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text('نقطة متاحة', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _PointStat(label: 'نقاط مدفوعة', value: '${user.totalPoints}', icon: Icons.paid),
                          Container(width: 1, height: 40, color: Colors.white24),
                          _PointStat(label: 'نقاط مجانية', value: '${user.freePoints}', icon: Icons.card_giftcard),
                        ],
                      ),
                      if (user.freePointsExpiry != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'النقاط المجانية تنتهي: ${DateFormat('dd/MM/yyyy').format(user.freePointsExpiry!)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Recharge button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomButton(
                    label: 'شحن نقاط (2000 دج = 200 نقطة)',
                    icon: Icons.add_circle_outline,
                    color: AppColors.secondary,
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.recharge),
                  ),
                ),
                const SizedBox(height: 16),

                // Transactions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      const Text('سجل المعاملات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<PointTransactionModel>>(
                    stream: FirestoreService().watchUserTransactions(user.uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
                      final txs = snap.data ?? [];
                      if (txs.isEmpty) {
                        return const EmptyStateWidget(
                          icon: Icons.receipt_long,
                          title: 'لا توجد معاملات بعد',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: txs.length,
                        itemBuilder: (_, i) => _TransactionTile(tx: txs[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _PointStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PointStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PointTransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == TransactionType.credit || tx.type == TransactionType.free || tx.type == TransactionType.bonus;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit ? Icons.add : Icons.remove,
            color: isCredit ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(tx.description, style: const TextStyle(fontSize: 13)),
        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt), style: const TextStyle(fontSize: 11)),
        trailing: Text(
          '${isCredit ? '+' : ''}${tx.amount} نقطة',
          style: TextStyle(
            color: isCredit ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
