import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/url_providers.dart';

class TagAutomationPage extends ConsumerStatefulWidget {
  const TagAutomationPage({super.key});

  @override
  TagAutomationPageState createState() => TagAutomationPageState();
}

class TagAutomationPageState extends ConsumerState<TagAutomationPage> {
  Map<String, List<String>> tagKeywords = {};

  @override
  void initState() {
    super.initState();
    _loadTagKeywords();
  }

  void _loadTagKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tagKeywords = Map.fromEntries(
        prefs.getKeys().where((key) => key.startsWith('tag_keywords_')).map(
              (key) => MapEntry(
            key.substring('tag_keywords_'.length),
            prefs.getStringList(key) ?? [],
          ),
        ),
      );
    });
  }

  void _saveTagKeywords(String tag, List<String> keywords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tag_keywords_$tag', keywords);
    setState(() {
      tagKeywords[tag] = keywords;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsyncValue = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Automation'),
      ),
      body: tagsAsyncValue.when(
        data: (tags) => ListView(
          children: [
            for (final tag in tags)
              ListTile(
                title: Text(tag),
                subtitle: Text(tagKeywords[tag]?.join(', ') ?? 'No keywords set'),
                onTap: () => _showKeywordDialog(tag),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showKeywordDialog(String tag) {
    final controller = TextEditingController(
      text: tagKeywords[tag]?.join(', ') ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Keywords for $tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter keywords separated by commas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _saveTagKeywords(
                tag,
                controller.text.split(',').map((e) => e.trim()).toList(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}