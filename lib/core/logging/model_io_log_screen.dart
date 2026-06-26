import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model_io_logger.dart';
import 'model_io_trace.dart';

/// Viewer for recorded model input/output traces. Loads the persisted file
/// (so traces survive restarts) and appends new ones live.
class ModelIoLogScreen extends StatefulWidget {
  const ModelIoLogScreen({super.key});

  @override
  State<ModelIoLogScreen> createState() => _ModelIoLogScreenState();
}

class _ModelIoLogScreenState extends State<ModelIoLogScreen> {
  final List<ModelIoTrace> _traces = [];
  StreamSubscription<ModelIoTrace>? _sub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = ModelIoLogger.instance.stream.listen((trace) {
      if (mounted) setState(() => _traces.add(trace));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final persisted = await ModelIoLogger.instance.readAll();
    if (!mounted) return;
    setState(() {
      _traces
        ..clear()
        ..addAll(persisted);
      _loading = false;
    });
  }

  String _allAsJsonl() => _traces.map((t) => t.toJsonLine()).join('\n');

  @override
  Widget build(BuildContext context) {
    // Newest first.
    final ordered = _traces.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Model I/O log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy all (JSONL)',
            onPressed: _traces.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: _allAsJsonl()),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied as JSONL')),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: () async {
              await ModelIoLogger.instance.clear();
              if (mounted) setState(() => _traces.clear());
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ordered.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: ordered.length,
                  itemBuilder: (context, index) =>
                      _TraceTile(trace: ordered[index]),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final enabled = ModelIoLogger.instance.enabled;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          enabled
              ? 'No model I/O recorded yet.\nSend a message to capture a trace.'
              : 'Model I/O logging is off.\nEnable it in Settings to record traces.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _TraceTile extends StatelessWidget {
  const _TraceTile({required this.trace});

  final ModelIoTrace trace;

  String _time(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  ({IconData icon, Color color}) _outcomeStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (trace.outcome) {
      TraceOutcome.done => (icon: Icons.check_circle, color: Colors.green),
      TraceOutcome.error => (icon: Icons.error, color: scheme.error),
      TraceOutcome.timeout => (icon: Icons.timer_off, color: Colors.orange),
      TraceOutcome.stopped => (icon: Icons.stop_circle, color: scheme.outline),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _outcomeStyle(context);
    final ttft = trace.timeToFirstTokenMs;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(style.icon, color: style.color, size: 20),
        title: Text(
          '${_time(trace.timestampMs)} · ${trace.modelName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${trace.tokenCount} tokens · ${trace.totalDurationMs} ms'
          '${ttft != null ? ' · TTFT ${ttft}ms' : ''}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy JSON'),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: trace.toJsonLine()),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trace copied')),
                  );
                }
              },
            ),
          ),
          _Section(
            label: 'Details',
            body: [
              'backend: ${trace.backendType}',
              'outcome: ${trace.outcome.label}',
              if (trace.error != null) 'error: ${trace.error}',
              'params: ${trace.generationParams}',
              'RAG: ${trace.ragEnabled ? '${trace.ragChunkCount} chunks' : 'off'}',
            ].join('\n'),
          ),
          if (trace.ragChunks.isNotEmpty)
            _Section(
              label: 'RAG context',
              body: trace.ragChunks
                  .asMap()
                  .entries
                  .map((e) => '[${e.key + 1}] ${e.value}')
                  .join('\n\n'),
            ),
          _Section(label: 'Input prompt', body: trace.inputPrompt),
          _Section(
            label: 'Output',
            body: trace.outputText.isEmpty ? '(empty)' : trace.outputText,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }
}
