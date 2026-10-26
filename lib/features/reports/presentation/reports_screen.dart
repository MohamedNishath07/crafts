import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
                    Text('Financial & Recovery Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.inkPrimary)),
                    SizedBox(height: 4),
                    Text('Generate tabular financial reports and export to PDF or Excel (.xlsx)', style: TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Export PDF'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.table_view_outlined, size: 18),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentSuccess, foregroundColor: AppColors.inkWhite),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                color: AppColors.surfaceRaised,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.borderSubtle)),
                child: const Center(
                  child: Text('Custom report generator (Story 6.1, 6.2 & 6.3)', style: TextStyle(color: AppColors.inkSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
