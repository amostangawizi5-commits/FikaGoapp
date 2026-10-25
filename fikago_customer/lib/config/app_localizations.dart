import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

extension AppLocalization on BuildContext {
  String localized(String swahili, String english) =>
      locale.languageCode == 'en' ? english : swahili;
}
