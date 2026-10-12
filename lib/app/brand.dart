/// Product identity. The name is a configurable placeholder until final
/// branding is supplied: `--dart-define=APP_NAME="Your Name"`.
abstract final class AppBrand {
  static const String name =
      String.fromEnvironment('APP_NAME', defaultValue: 'Stillbeat');

  /// Production links are injected at build time. Empty means "not
  /// configured" and the UI hides the link instead of pointing nowhere.
  static const String privacyPolicyUrl =
      String.fromEnvironment('PRIVACY_POLICY_URL');
  static const String supportUrl = String.fromEnvironment('SUPPORT_URL');
}

class AppVersion {
  const AppVersion({required this.version, required this.buildNumber});
  final String version;
  final String buildNumber;
  String get display => '$version+$buildNumber';
}
