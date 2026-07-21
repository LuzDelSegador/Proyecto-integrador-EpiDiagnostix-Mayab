import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UpgradeRequiredWidget extends StatelessWidget {
  final String featureName;
  final String requiredPlan;
  final String description;
  final VoidCallback onVerPlanes;

  UpgradeRequiredWidget({
    super.key,
    required this.featureName,
    required this.requiredPlan,
    required this.description,
    required this.onVerPlanes,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.of(context).primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: AppColors.of(context).primary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              featureName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Requiere $requiredPlan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
            SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.of(context).textSecondary,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onVerPlanes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.of(context).primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(Icons.star_outline_rounded, size: 18),
                label: Text(
                  'Ver planes',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
