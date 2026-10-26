import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

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
                    Text('Payments & Transactions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.inkPrimary)),
                    SizedBox(height: 4),
                    Text('Record settlements, verify bank transfers, and generate receipts', style: TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Record Payment'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentSuccess, foregroundColor: AppColors.inkWhite),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                color: AppColors.surfaceRaised,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.borderSubtle)),
                child: const Center(
                  child: Text('Payment history & allocation ledger (Story 3.1 & 3.3)', style: TextStyle(color: AppColors.inkSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
