import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color textColor;
  final bool showSubtitle;

  const LogoHeader({
    super.key,
    this.iconSize = 48,
    this.fontSize = 28,
    this.textColor = Colors.white,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo icon
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: iconSize * 0.55,
          ),
        ),
        const SizedBox(height: 16),
        // Title
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: 'Car',
                style: TextStyle(color: textColor),
              ),
              TextSpan(
                text: 'Whats',
                style: TextStyle(color: textColor.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 6),
          Text(
            'النظام المحاسبي المتكامل',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
