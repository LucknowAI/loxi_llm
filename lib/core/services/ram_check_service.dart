import 'package:flutter/material.dart';
import 'package:system_info_plus/system_info_plus.dart';
import '../../features/models/domain/model.dart';

/// Model size (base + mmproj, when present) above which a load failure is
/// plausibly memory-related — the same threshold [confirmLoad] uses to
/// decide whether a warning is needed at all.
const int _warnThresholdMb = 2048;

/// Device RAM at or above which no warning is shown regardless of model size.
const int _safeDeviceRamMb = 6144;

// Falls back to 0 when mmprojSizeBytes is unknown (mmprojFilename set but
// the size wasn't recorded, e.g. a sideloaded pairing) — under-counts the
// true footprint in that case, which could skip the warning for a model
// that's borderline once its real (unknown) mmproj size is included. Not a
// concern for today's catalog, which always sets both together.
int _combinedSizeMb(Model model) =>
    (model.sizeBytes + (model.mmprojSizeBytes ?? 0)) ~/ (1024 * 1024);

/// Whether [model]'s on-disk footprint (base model + mmproj, when present)
/// is large enough that a load failure is plausibly memory-related. Shared
/// by [RamCheckService.confirmLoad]'s own warn/skip decision and by callers
/// that want to explain a load *failure* after the fact (see
/// `InferenceNotifier.loadModel`), so the two never drift apart.
bool isLargeModel(Model model) => _combinedSizeMb(model) > _warnThresholdMb;

/// The RAM-warning dialog's body text for [model]. Vision models call out
/// the mmproj vision component's separate contribution and skip the
/// text-only fallback recommendation, since none of the catalog's smaller
/// models support vision — recommending one would defeat the reason the
/// user is loading this model in the first place.
String ramWarningMessage(Model model) {
  final totalGb = _combinedSizeMb(model) / 1024;
  // Gated on isMultimodalModel alone, not on mmprojSizeBytes being known —
  // a vision model with an unrecorded mmproj size (a sideloaded pairing, or
  // a future catalog entry that forgets to set it) must still skip the
  // text-only fallback recommendation below. mmprojBytes only decides
  // whether the *size breakdown* can be shown, not whether this is a vision
  // model at all.
  if (isMultimodalModel(model)) {
    final mmprojBytes = model.mmprojSizeBytes;
    final baseGb = model.sizeBytes / (1024 * 1024 * 1024);
    final sizeSentence = mmprojBytes != null
        ? 'This model (${baseGb.toStringAsFixed(1)} GB) plus its vision '
            'component (${(mmprojBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB) '
            'requires approximately ${totalGb.toStringAsFixed(1)} GB of RAM on this device.'
        : 'This model requires approximately ${totalGb.toStringAsFixed(1)} GB of RAM '
            'on this device.';
    return '$sizeSentence On devices with limited memory, this may cause the app to crash.';
  }
  return 'This model requires approximately ${totalGb.toStringAsFixed(1)} GB of RAM. '
      'On devices with limited memory, this may cause the app to crash.\n\n'
      'Recommended: use Gemma 3 270M (253 MB) on this device.';
}

/// Checks device RAM and shows a warning dialog before loading large models.
class RamCheckService {
  /// Returns `true` if the user confirms they want to load despite the warning,
  /// or if no warning is needed.
  ///
  /// [model]: the model to load — its size (and mmproj size, if any) drives
  /// both the warn/skip decision and the dialog's wording.
  /// [context]: BuildContext for showing dialog.
  static Future<bool> confirmLoad(
    BuildContext context, {
    required Model model,
  }) async {
    if (!isLargeModel(model)) return true; // small model, no warning needed

    // Try to read device RAM — may return null on iOS or some devices
    final int? totalRamMb = await SystemInfoPlus.physicalMemory;
    if (totalRamMb != null && totalRamMb >= _safeDeviceRamMb) return true;

    // Show warning dialog
    if (!context.mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('High Memory Usage'),
        content: Text(ramWarningMessage(model)),
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
