class OrbDriveServerConfig {
  static const baseUrl = String.fromEnvironment(
    'ORB_SERVER_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
