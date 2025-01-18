import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/theme_provider.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConfigPageState createState() => ConfigPageState();
}

class ConfigPageState extends ConsumerState<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _imapServerController = TextEditingController();
  final _imapPortController = TextEditingController();
  bool _imapSecure = true;
  List<String> _rssFeeds = [];
  final _rssFeedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _imapServerController.dispose();
    _imapPortController.dispose();
    _rssFeedController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
        _imapServerController.text = prefs.getString('imapServer') ?? '';
        _imapPortController.text = (prefs.getInt('imapPort') ?? 993).toString();
        _imapSecure = prefs.getBool('imapSecure') ?? true;
        _rssFeeds = prefs.getStringList('rssFeeds') ?? [];
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading saved data: $e');
    }
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', _emailController.text);
        await prefs.setString('password', _passwordController.text);
        await prefs.setString('imapServer', _imapServerController.text);
        await prefs.setInt('imapPort', int.parse(_imapPortController.text));
        await prefs.setBool('imapSecure', _imapSecure);
        await prefs.setStringList('rssFeeds', _rssFeeds);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuration saved')),
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error saving data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving configuration: $e')),
          );
        }
      }
    }
  }

  void _addRssFeed() {
    if (_rssFeedController.text.isNotEmpty) {
      setState(() {
        _rssFeeds.add(_rssFeedController.text);
        _rssFeedController.clear();
      });
    }
  }

  void _removeRssFeed(int index) {
    setState(() {
      _rssFeeds.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: Theme.of(context).textTheme.titleLarge),
              DropdownButton<ThemeMode>(
                value: currentTheme,
                onChanged: (ThemeMode? newThemeMode) {
                  if (newThemeMode != null) {
                    ref.read(themeProvider.notifier).setThemeMode(newThemeMode);
                  }
                },
                items: ThemeMode.values.map((ThemeMode themeMode) {
                  return DropdownMenuItem<ThemeMode>(
                    value: themeMode,
                    child: Text(themeMode.toString().split('.').last),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Email', style: Theme.of(context).textTheme.titleLarge),
              Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an email';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _imapServerController,
                      decoration: const InputDecoration(labelText: 'IMAP Server'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an IMAP server';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _imapPortController,
                      decoration: const InputDecoration(labelText: 'IMAP Port'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an IMAP port';
                        if (int.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    SwitchListTile(
                      title: const Text('IMAP Secure'),
                      value: _imapSecure,
                      onChanged: (bool value) {
                        setState(() {
                          _imapSecure = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('RSS Feeds', style: Theme.of(context).textTheme.titleLarge),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _rssFeeds.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_rssFeeds[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeRssFeed(index),
                          ),
                        );
                      },
                    ),
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
                          onPressed: _addRssFeed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveData,
                      child: const Text('Save Configuration'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}