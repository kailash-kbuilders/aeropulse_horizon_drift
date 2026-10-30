import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.rp(56),
      padding: EdgeInsets.symmetric(horizontal: context.rp(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rp(18)),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search_rounded,
            size: context.rp(20),
            color: AppColors.textTertiary,
          ),
          SizedBox(width: context.rp(10)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: context.rp(13),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: AppColors.orange,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search your favorite food',
                hintStyle: TextStyle(
                  fontSize: context.rp(13),
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SizedBox(width: context.rp(8)),
          GestureDetector(
            onTap: onFilterTap,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.tune_rounded,
              size: context.rp(20),
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
