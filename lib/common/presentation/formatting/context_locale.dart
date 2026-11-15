import 'package:flutter/widgets.dart';

extension ContextLocale on BuildContext {
  /// Language code used for `intl` formatting (`en` or `es`).
  String get localeName => Localizations.localeOf(this).languageCode;
}
