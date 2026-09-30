/// Build-time configuration for the Tawasul school server this app talks to.
class Env {
  static const baseUrl = String.fromEnvironment(
    'TAWASUL_BASE_URL',
    defaultValue: 'https://tos.fiksutiliratkaisut.fi/1/tawasul-os/',
  );

  /// Optional school API key, used only before anyone signs in. Pass it at
  /// build time: --dart-define=TAWASUL_API_KEY=... (never commit a real key).
  /// Once a person signs in, their own token replaces it.
  static const apiKey = String.fromEnvironment('TAWASUL_API_KEY', defaultValue: '');

  static const schoolName = 'Tawasul';
}
