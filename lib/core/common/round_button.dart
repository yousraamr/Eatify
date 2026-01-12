import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum RoundButtonType { bgPrimary, textPrimary }

class RoundButton extends StatelessWidget {
  final VoidCallback? onPressed; //nullable
  final String title;
  final RoundButtonType type;
  final double fontSize;
  const RoundButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.fontSize = 16,
    this.type = RoundButtonType.bgPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: type == RoundButtonType.bgPrimary
              ? null
              : Border.all(color: AppTheme.primary, width: 1),
          color: type == RoundButtonType.bgPrimary
              ? AppTheme.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: type == RoundButtonType.bgPrimary
                ? AppTheme.card
                : AppTheme.textPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
