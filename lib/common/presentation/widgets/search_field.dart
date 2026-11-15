import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// M3 search bar used to filter lists.
///
/// A 56dp pill on a tonal surface, no border:
/// - At rest: search icon + hint.
/// - While typing (focused): the leading icon turns into a back arrow that
///   leaves the search (clears the text and closes the keyboard), and a clear
///   (×) button appears once there is text (clears it and keeps typing).
/// Both icons are 48dp touch targets.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Rebuild to swap the leading icon and show / hide the clear button.
    _focus.addListener(_refresh);
    _controller.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    if (_controller.text.isEmpty) return;
    _controller.clear();
    widget.onChanged('');
  }

  /// Back arrow: leaves the search, like closing an M3 search view. It clears
  /// the text, shows the whole list again and hides the keyboard.
  void _close() {
    _clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final active = _focus.hasFocus;
    final hasText = _controller.text.isNotEmpty;
    return SearchBar(
      controller: _controller,
      focusNode: _focus,
      hintText: widget.hint,
      onChanged: widget.onChanged,
      onTapOutside: (_) => _focus.unfocus(),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _focus.unfocus(),
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 56),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: const WidgetStatePropertyAll(AppColors.neutralContainer),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStateProperty.resolveWith(
        (states) => StadiumBorder(
          side: states.contains(WidgetState.focused)
              ? const BorderSide(color: AppColors.primaryDark, width: 1.5)
              : BorderSide.none,
        ),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.xs)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 16, color: AppColors.textPrimary),
      ),
      hintStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 16, color: AppColors.textMuted),
      ),
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: active
            ? IconButton(
                key: const ValueKey('search.back'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                color: AppColors.textPrimary,
                onPressed: _close,
              )
            : const SizedBox.square(
                key: ValueKey('search.icon'),
                dimension: AppSpacing.minTouchTarget,
                child: Icon(Icons.search, color: AppColors.textMuted),
              ),
      ),
      trailing: [
        if (hasText)
          IconButton(
            tooltip: i18n.clearSearch,
            icon: const Icon(Icons.close),
            color: AppColors.textPrimary,
            onPressed: _clear,
          ),
      ],
    );
  }
}
