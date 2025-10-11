// lib/ui/widgets/home_latest_opnames.dart

import 'package:flutter/material.dart';
import 'package:viopname/shared/theme.dart';

class HomeLatestOpnames extends StatelessWidget {
  final String iconUrl;
  final String description;
  final String opnameDate;
  final String totalOpname;
  final String?
  opnameId; // Properti ini tetap ada, tapi hanya digunakan jika item bisa diklik
  final VoidCallback?
  onTap; // <<=== PERUBAHAN UTAMA: Tambah tanda '?' untuk opsional

  const HomeLatestOpnames({
    super.key,
    required this.iconUrl,
    required this.description,
    required this.opnameDate,
    required this.totalOpname,
    this.opnameId,
    this.onTap, // onTap sekarang opsional
  });

  @override
  Widget build(BuildContext context) {
    // === PERUBAHAN: Gunakan InkWell/GestureDetector HANYA jika onTap tidak null ===
    Widget cardContent = Container(
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(iconUrl, width: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: blackTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: medium,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(opnameDate, style: greyTextStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const Spacer(),
          Text(
            totalOpname,
            style: blackTextStyle.copyWith(
              fontSize: 14,
              fontWeight: semiBold,
              color: totalOpname.contains('-')
                  ? AppColors.error
                  : AppColors.primary,
            ),
          ),
          // Tambahkan ikon panah HANYA jika bisa diklik
          if (onTap !=
              null) // <<=== PERUBAHAN: Ikon hanya muncul jika onTap ada
            const SizedBox(width: 8),
          if (onTap !=
              null) // <<=== PERUBAHAN: Ikon hanya muncul jika onTap ada
            Icon(Icons.chevron_right, color: AppColors.gray),
        ],
      ),
    );

    // Jika onTap diberikan, bungkus dengan GestureDetector
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    } else {
      // Jika onTap null, kembalikan saja konten kartu
      return cardContent;
    }
  }
}
