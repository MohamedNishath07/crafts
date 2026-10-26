import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Audit Logs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.inkPrimary)),
            SizedBox(height: 4),
            Text('Immutable chronological trail of staff logins, transactions, and mutations', style: TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
            SizedBox(height: 20),
            Expanded(
              child: Card(
                color: AppColors.surfaceRaised,
                child: Center(
                  child: Text('Audit log timeline (Story 7.1 & 7.2)', style: TextStyle(color: AppColors.inkSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
