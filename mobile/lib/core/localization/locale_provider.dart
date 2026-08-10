import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the language selected by the signed-in teacher or parent.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  static const _preferenceKey = 'appLocale';

  Future<void> _loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_preferenceKey);
    if (languageCode == 'am' || languageCode == 'en') {
      state = Locale(languageCode!);
    } else {
      state = const Locale('en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'am' && locale.languageCode != 'en') return;

    state = locale;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
