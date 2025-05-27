import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: context.locale,
      items: [
        DropdownMenuItem(
          value: const Locale('uk'),
          child: Text('language.ukrainian'.tr()),
        ),
        DropdownMenuItem(
          value: const Locale('en'),
          child: Text('language.english'.tr()),
        ),
      ],
      onChanged: (locale) {
        if (locale != null) {
          context.setLocale(locale);
        }
      },
    );
  }
}
