import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:virage_web/theme/app_theme.dart';

void main() {
  test('uses accessible, consistent themes', () {
    final lightTheme = AppTheme.lightTheme;
    final darkTheme = AppTheme.darkTheme;

    expect(lightTheme.useMaterial3, isTrue);
    expect(darkTheme.useMaterial3, isTrue);
    expect(lightTheme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(darkTheme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(lightTheme.outlinedButtonTheme.style, isNotNull);
    expect(darkTheme.outlinedButtonTheme.style, isNotNull);
  });
}
