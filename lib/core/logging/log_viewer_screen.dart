import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_logger.dart';

/// Live, filterable view of [AppLogger] output. Reachable from Settings and
/// from the conversation screen, so crash diagnostics can be copied off-device.
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  LogLevel? _minLevel;

  /// When true, show the persisted file (survives crashes/restarts) instead of
  /// the live in-memory buffer. Crash diagnosis needs the file view.
  bool _showFile = false;
  String _fileContents = '';

  bool _passesFilter(LogEntry e) =>
      _minLevel == null || e.level.index >= _minLevel!.index;

  Future<void> _loadFile() async {
    final contents = await AppLogger.instance.readFile();
    if (mounted) setState(() => _fileContents = contents);
  }

  Color _levelColor(BuildContext context, LogLevel level) {
    final scheme = Theme.of(context).colorScheme;
    return switch (level) {
      LogLevel.debug => scheme.outline,
      LogLevel.info => scheme.onSurface,
      LogLevel.warn => Colors.orange.shade800,
      LogLevel.error => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_showFile ? 'Logs (saved file)' : 'Logs (live)'),
        actions: [
          IconButton(
            icon: Icon(_showFile ? Icons.bolt : Icons.history),
            tooltip: _showFile
                ? 'Show live session'
                : 'Show saved file (survives crashes)',
            onPressed: () async {
              if (!_showFile) await _loadFile();
              if (mounted) setState(() => _showFile = !_showFile);
            },
          ),
          if (!_showFile)
            PopupMenuButton<LogLevel?>(
              tooltip: 'Filter level',
              icon: const Icon(Icons.filter_list),
              onSelected: (level) => setState(() => _minLevel = level),
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('All')),
                for (final level in LogLevel.values)
                  PopupMenuItem(value: level, child: Text('${level.label}+')),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy all',
            onPressed: () async {
              final text = _showFile ? _fileContents : AppLogger.instance.dump();
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logs copied to clipboard')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: () async {
              await AppLogger.instance.clear();
              if (mounted) {
                setState(() => _fileContents = '');
              }
            },
          ),
        ],
      ),
      body: _showFile ? _buildFileView(context) : _buildLiveView(context),
    );
  }

  Widget _buildFileView(BuildContext context) {
    if (_fileContents.isEmpty) {
      return const Center(child: Text('Saved log file is empty'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: SelectableText(
        _fileContents,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _buildLiveView(BuildContext context) {
    return StreamBuilder<LogEntry>(
      // Rebuild on every new entry; the buffer is the source of truth.
      stream: AppLogger.instance.stream,
      builder: (context, _) {
        final entries =
            AppLogger.instance.entries.where(_passesFilter).toList();
        if (entries.isEmpty) {
          return const Center(child: Text('No logs yet'));
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            // reverse: show newest at the bottom.
            final entry = entries[entries.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SelectableText(
                entry.format(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: _levelColor(context, entry.level),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
