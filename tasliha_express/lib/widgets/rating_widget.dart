import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../constants/app_colors.dart';

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 20,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemSize: size,
          itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.gold),
          unratedColor: Colors.grey.shade300,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size * 0.75,
            color: AppColors.textPrimary,
          ),
        ),
        if (showCount && count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size * 0.65,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;

  const RatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
  });

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.gold),
          onRatingUpdate: (rating) {
            setState(() => _rating = rating);
            widget.onRatingChanged(rating);
          },
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingLabel(),
          style: TextStyle(
            color: _getRatingColor(),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _getRatingLabel() {
    if (_rating >= 5) return 'رائع';
    if (_rating >= 4) return 'جيد جداً';
    if (_rating >= 3) return 'جيد';
    if (_rating >= 2) return 'مقبول';
    if (_rating >= 1) return 'ضعيف';
    return 'اختر تقييمك';
  }

  Color _getRatingColor() {
    if (_rating >= 4) return AppColors.success;
    if (_rating >= 3) return AppColors.info;
    if (_rating >= 2) return AppColors.warning;
    return AppColors.error;
  }
}
