import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/request_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStatus;
  final bool showPoints;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.trailing,
    this.showStatus = true,
    this.showPoints = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (showStatus) _StatusBadge(status: request.status),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 10),
              Text(
                request.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                request.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${request.clientWilaya} - ${request.clientCommune}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (showPoints && request.pointsRequired > 0) ...[
                    const Icon(Icons.stars, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${request.pointsRequired} نقطة',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(request.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (request.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: request.imageUrls.length.clamp(0, 3),
                    itemBuilder: (_, i) => Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(request.imageUrls[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    const colors = {
      'كهرباء منازل': Color(0xFFF57C00),
      'سباكة': Color(0xFF1565C0),
      'تبريد وتكييف': Color(0xFF00897B),
      'إلكترونيات وصيانة': Color(0xFF6A1B9A),
      'ميكانيك': Color(0xFF37474F),
    };
    return colors[request.category] ?? AppColors.primary;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final info = _getStatusInfo();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: info['color'].withOpacity(0.3)),
      ),
      child: Text(
        info['label'],
        style: TextStyle(
          fontSize: 12,
          color: info['color'],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (status) {
      case AppConstants.statusPending:
        return {'label': 'قيد المراجعة', 'color': AppColors.warning};
      case AppConstants.statusReviewedByAdmin:
        return {'label': 'مراجع', 'color': AppColors.info};
      case AppConstants.statusAvailable:
        return {'label': 'متاح', 'color': AppColors.success};
      case AppConstants.statusAccepted:
        return {'label': 'مقبول', 'color': AppColors.primary};
      case AppConstants.statusInProgress:
        return {'label': 'جارٍ التنفيذ', 'color': AppColors.primaryLight};
      case AppConstants.statusCompleted:
        return {'label': 'مكتمل', 'color': AppColors.success};
      case AppConstants.statusCancelled:
        return {'label': 'ملغى', 'color': AppColors.error};
      default:
        return {'label': status, 'color': AppColors.textSecondary};
    }
  }
}
