/// Configuration for test mode - set to true during testing
class TestConfiguration {
  static bool isTestMode = false;

  static void setTestMode(bool value) {
    isTestMode = value;
  }
}