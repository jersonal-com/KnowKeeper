import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _imapServer = '';
  int _imapPort = 993;
  bool _imapSecure = true;
  List<String> _rssFeeds = [];
  final TextEditingController _rssFeedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email') ?? '';
      _password = prefs.getString('password') ?? '';
      _imapServer = prefs.getString('imapServer') ?? '';
      _imapPort = prefs.getInt('imapPort') ?? 993;
      _imapSecure = prefs.getBool('imapSecure') ?? true;
      _rssFeeds = prefs.getStringList('rssFeeds') ?? [];
    });
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _email);
      await prefs.setString('password', _password);
      await prefs.setString('imapServer', _imapServer);
      await prefs.setInt('imapPort', _imapPort);
      await prefs.setBool('imapSecure', _imapSecure);
      await prefs.setStringList('rssFeeds', _rssFeeds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuration saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter an email';
                return null;
              },
              onSaved: (value) => _email = value!,
            ),
            TextFormField(
              initialValue: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value!.isEmpty) return 'Please enter a password';
                return null;
              },
              onSaved: (value) => _password = value!,
            ),
            TextFormField(
              initialValue: _imapServer,
              decoration: const InputDecoration(labelText: 'IMAP Server'),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter IMAP server';
                return null;
              },
              onSaved: (value) => _imapServer = value!,
            ),
            TextFormField(
              initialValue: _imapPort.toString(),
              decoration: const InputDecoration(labelText: 'IMAP Port'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Please enter IMAP port';
                if (int.tryParse(value) == null) return 'Please enter a valid port number';
                return null;
              },
              onSaved: (value) => _imapPort = int.parse(value!),
            ),
            SwitchListTile(
              title: const Text('Use Secure Connection'),
              value: _imapSecure,
              onChanged: (bool value) {
                setState(() {
                  _imapSecure = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('RSS Feeds:'),
            ..._rssFeeds.map((feed) => ListTile(
              title: Text(feed),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _rssFeeds.remove(feed);
                  });
                },
              ),
            )).toList(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rssFeedController,
                    decoration: const InputDecoration(labelText: 'Add RSS Feed'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_rssFeedController.text.isNotEmpty) {
                      setState(() {
                        _rssFeeds.add(_rssFeedController.text);
                        _rssFeedController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Save Configuration'),
              onPressed: _saveData,
            ),
          ],
        ),
      ),
    );
  }
}