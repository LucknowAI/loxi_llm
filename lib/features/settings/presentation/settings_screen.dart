import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'settings_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'RAG Chunk Size: ${settings.chunkSize}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: settings.chunkSize.toDouble(),
            min: 100,
            max: 500,
            divisions: 8,
            label: settings.chunkSize.toString(),
            onChanged: (v) => notifier.setChunkSize(v.round()),
          ),
          const SizedBox(height: 16),
          Text(
            'Top K Results: ${settings.topK}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: settings.topK.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: settings.topK.toString(),
            onChanged: (v) => notifier.setTopK(v.round()),
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Diagnostic logs'),
            subtitle: const Text('View app + inference logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/logs'),
          ),
        ],
      ),
    );
  }
}
