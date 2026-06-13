import 'package:flutter/material.dart';

class SkillChip extends StatelessWidget {
  final String skill;
  final Color? color;
  final bool isMatched;
  final bool isMissing;

  const SkillChip({
    super.key,
    required this.skill,
    this.color,
    this.isMatched = false,
    this.isMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    if (isMatched) {
      bg = const Color(0xFFD4EDDA);
      text = const Color(0xFF155724);
    } else if (isMissing) {
      bg = const Color(0xFFF8D7DA);
      text = const Color(0xFF721C24);
    } else {
      bg = color ?? const Color(0xFFE4D6FF);
      text = const Color(0xFF4B0082);
    }

    return Chip(
      label: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: text,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
