/// This file contains the See More Button widget.
///
/// It is a reusable text button with an icon, used across the Reporting
/// screens to navigate to a full list of items (e.g., "See all", "See 7 more").
///
import 'package:flutter/material.dart';

/// A reusable button to navigate to a "See All" screen.
class SeeMoreButton extends StatelessWidget {
  const SeeMoreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.alignment = Alignment.centerRight,
    this.icon = Icons.expand_more,
  });

  /// The text to display on the button (e.g., "See all", "See 5 more").
  final String label;

  /// Callback triggered when the button is pressed.
  final VoidCallback onPressed;

  /// The alignment of the button within its parent. Defaults to the right.
  final Alignment alignment;

  /// The icon to display alongside the text. Defaults to a down arrow.
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