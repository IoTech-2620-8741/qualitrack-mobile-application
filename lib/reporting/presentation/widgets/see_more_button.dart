import 'package:flutter/material.dart';

class SeeMoreButton extends StatelessWidget {
  const SeeMoreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.alignment = Alignment.centerRight,
    this.icon = Icons.expand_more,
  });

  final String label;
  final VoidCallback onPressed;
  final Alignment alignment;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}