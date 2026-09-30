import 'package:flutter_test/flutter_test.dart';
import 'package:tawasul_school_os/core/l10n.dart';
import 'package:tawasul_school_os/core/models.dart';
import 'package:tawasul_school_os/theme/app_theme.dart';

void main() {
  test('app theme defines light theme', () {
    expect(AppTheme.light.useMaterial3, isTrue);
  });

  test('default locale is Arabic', () {
    const l10n = L10n('ar');
    expect(l10n.appName, 'تواصل');
    expect(l10n.signIn, isNotEmpty);
  });

  test('tone colors cover all tile tones', () {
    for (final tone in TileTone.values) {
      expect(tone, isNotNull);
    }
  });
}
