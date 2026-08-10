import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sscs_mobile/core/localization/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads a supported locale from shared preferences', () async {
    SharedPreferences.setMockInitialValues({'appLocale': 'am'});

    final notifier = LocaleNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(notifier.state, const Locale('am'));
  });

  test('falls back to English when no locale is saved', () async {
    final notifier = LocaleNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(notifier.state, const Locale('en'));
  });
}
