import 'package:flutter/material.dart';

class UserAccessHero extends StatelessWidget {
  const UserAccessHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.lineHeight = 182,
  });

  final String title;
  final String subtitle;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 4,
          height: lineHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1152D4),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF13171C),
                  height: 1.05,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2E3444),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
