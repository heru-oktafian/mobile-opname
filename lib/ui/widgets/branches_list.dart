// lib/ui/widgets/branches_list.dart

import 'package:flutter/material.dart';
import 'package:viopname/shared/theme.dart'; // Asumsikan Anda punya theme.dart

class BranchesList extends StatelessWidget {
  final String iconUrl;
  final String branchName;
  final String branchId;
  final VoidCallback? onTap; // Tambahkan ini

  const BranchesList({
    super.key,
    required this.iconUrl,
    required this.branchName,
    required this.branchId,
    this.onTap, // Inisialisasi di konstruktor
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Gunakan GestureDetector untuk mendeteksi tap
      onTap: onTap, // Panggil fungsi onTap saat di-tap
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        child: Row(
          children: [
            Image.asset(iconUrl, width: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branchName,
                  style: blackTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: medium,
                  ),
                ),
                Text(branchId, style: greyTextStyle.copyWith(fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
