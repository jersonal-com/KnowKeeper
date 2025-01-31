import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../service/database_providers.dart';
import '../service/url_providers.dart';
import '../widgets/tag_text.dart';

class TagManagementPage extends ConsumerStatefulWidget {
  const TagManagementPage({super.key});

  @override
  TagManagementPageState createState() => TagManagementPageState();
}

class TagManagementPageState extends ConsumerState<TagManagementPage> {
  @override
  Widget build(BuildContext context) {
    final tagsAsyncValue = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
      ),
      body: tagsAsyncValue.when(
        data: (tags) => ListView.builder(
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return ListTile(
              title: TagText(tag),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.color_lens),
                    onPressed: () => _showColorPickerDialog(context, tag),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showRenameDialog(context, tag),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(context, tag),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context, String tag) {
    Color pickerColor = Colors.blue; // Default color
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color for "$tag"'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                _saveTagColor(tag, pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTagColor(String tag, Color color) async {
    final database = ref.read(databaseProvider);
    // TODO - Replace deprecated member use
    // ignore: deprecated_member_use
    final colorValue = color.value;
    await database.setTagColor(tag, colorValue);
    ref.invalidate(allTagsProvider);
    ref.invalidate(tagColorsProvider);
    setState(() {});
  }
  void _showRenameDialog(BuildContext context, String oldTag) {
    final TextEditingController controller = TextEditingController(text: oldTag);
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Tag'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New Tag Name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Rename'),
              onPressed: () async {
                final newTag = controller.text.trim();
                if (newTag.isNotEmpty && newTag != oldTag) {
                  await _renameTag(oldTag, newTag);
                  final context = navigatorKey.currentContext;
                  if (context == null || !context.mounted) return;

                  if (mounted) Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String tag) {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Tag'),
          content: Text('Are you sure you want to delete the tag "$tag"?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await _deleteTag(tag);
                final context = navigatorKey.currentContext;
                if (context == null || !context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameTag(String oldTag, String newTag) async {
    final database = ref.read(databaseProvider);
    await database.renameTag(oldTag, newTag);
    ref.invalidate(urlEntriesProvider);
    ref.invalidate(allTagsProvider);
    ref.invalidate(urlEntryProvider);
    setState(() {});
  }

  Future<void> _deleteTag(String tag) async {
    final database = ref.read(databaseProvider);
    await database.deleteTag(tag);
    ref.invalidate(urlEntriesProvider);
    ref.invalidate(allTagsProvider);
    ref.invalidate(urlEntryProvider);
    setState(() {});
  }
}