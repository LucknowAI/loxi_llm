import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_notifier.dart';

class PromptLibraryScreen extends ConsumerWidget {
  const PromptLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final prompts = notifier.savedPrompts();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Prompts'),
        actions: [
          IconButton(
            tooltip: 'Add prompt',
            onPressed: () => _editPrompt(context, notifier),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: prompts.isEmpty
          ? const Center(child: Text('No saved prompts'))
          : ListView(
              children: [
                for (final prompt in prompts)
                  ListTile(
                    title: Text(prompt.name),
                    subtitle: Text(
                      prompt.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _editPrompt(
                      context,
                      notifier,
                      existing: prompt,
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      onPressed: () => notifier.deletePrompt(prompt.name),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
              ],
            ),
    );
  }
}

Future<void> _editPrompt(
  BuildContext context,
  SettingsNotifier notifier, {
  SavedPrompt? existing,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _PromptEditor(notifier: notifier, existing: existing),
  );
}

/// Asks for a library name. Stays open when the name is empty or already used.
Future<String?> askPromptName(
  BuildContext context, {
  required bool Function(String name) nameTaken,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _PromptNameDialog(nameTaken: nameTaken),
  );
}

class _PromptEditor extends StatefulWidget {
  const _PromptEditor({required this.notifier, this.existing});

  final SettingsNotifier notifier;
  final SavedPrompt? existing;

  @override
  State<_PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<_PromptEditor> {
  late final TextEditingController _name;
  late final TextEditingController _body;
  var _error = '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _body = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    final taken = widget.notifier.savedPrompts().any(
          (prompt) =>
              prompt.name == name && prompt.name != widget.existing?.name,
        );
    if (taken) {
      setState(() => _error = 'That name is already used');
      return;
    }
    if (widget.existing != null && widget.existing!.name != name) {
      widget.notifier.deletePrompt(widget.existing!.name);
    }
    widget.notifier.savePrompt(name, _body.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add prompt' : 'Edit prompt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              hintText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'System prompt',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _PromptNameDialog extends StatefulWidget {
  const _PromptNameDialog({required this.nameTaken});

  final bool Function(String name) nameTaken;

  @override
  State<_PromptNameDialog> createState() => _PromptNameDialogState();
}

class _PromptNameDialogState extends State<_PromptNameDialog> {
  final _name = TextEditingController();
  var _error = '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save to library'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              setState(() => _error = 'Enter a name');
              return;
            }
            if (widget.nameTaken(name)) {
              setState(() => _error = 'That name is already used');
              return;
            }
            Navigator.pop(context, name);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

