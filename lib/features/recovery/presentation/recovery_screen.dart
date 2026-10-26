import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recovery Activities & Follow-ups', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.inkPrimary)),
                    SizedBox(height: 4),
                    Text('Track customer calls, field visits, and promised payment dates', style: TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_call, size: 18),
                  label: const Text('Log Action'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: AppColors.inkWhite),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                color: AppColors.surfaceRaised,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.borderSubtle)),
                child: const Center(
                  child: Text('Recovery activity timeline & PTP calendar (Story 4.1 & 4.2)', style: TextStyle(color: AppColors.inkSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
