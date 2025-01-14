import 'package:shared_preferences/shared_preferences.dart';

class ImapConfig {
  final String server;
  final int port;
  final bool isSecure;
  final String username;
  final String password;

  ImapConfig({
    required this.server,
    required this.port,
    required this.isSecure,
    required this.username,
    required this.password,
  });

  static Future<ImapConfig?> fromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final server = prefs.getString('imapServer');
    final port = prefs.getInt('imapPort');
    final isSecure = prefs.getBool('imapSecure');
    final username = prefs.getString('email');
    final password = prefs.getString('password');

    if (server != null && port != null && isSecure != null && username != null && password != null) {
      return ImapConfig(
        server: server,
        port: port,
        isSecure: isSecure,
        username: username,
        password: password,
      );
    } else {
      print('IMAP configuration is incomplete in SharedPreferences');
      return null;
    }
  }
}