import 'package:flutter/material.dart';
import 'package:system_info_plus/system_info_plus.dart';

/// Checks device RAM and shows a warning dialog before loading large models.
class RamCheckService {
  /// Returns `true` if the user confirms they want to load despite the warning,
  /// or if no warning is needed.
  ///
  /// [modelSizeBytes]: size of the model to load.
  /// [context]: BuildContext for showing dialog.
  static Future<bool> confirmLoad(
    BuildContext context, {
    required int modelSizeBytes,
  }) async {
    final modelSizeMb = modelSizeBytes ~/ (1024 * 1024);
    if (modelSizeMb <= 2048) return true; // small model, no warning needed

    // Try to read device RAM — may return null on iOS or some devices
    final int? totalRamMb = await SystemInfoPlus.physicalMemory;
    if (totalRamMb != null && totalRamMb >= 6144) return true; // >=6GB RAM, no warning

    // Show warning dialog
    if (!context.mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('High Memory Usage'),
        content: Text(
          'This model requires approximately ${(modelSizeMb / 1024).toStringAsFixed(1)} GB of RAM. '
          'On devices with limited memory, this may cause the app to crash.\n\n'
          'Recommended: use Gemma 3 270M (253 MB) on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Load Anyway'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
