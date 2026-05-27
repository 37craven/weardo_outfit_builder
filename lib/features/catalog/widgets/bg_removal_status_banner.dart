import 'package:flutter/material.dart';
import 'package:weardo_outfit_builder/services/background_removal/bg_removal_status.dart';

class BgRemovalStatusBanner extends StatelessWidget {
  final BgRemovalStatus status;

  const BgRemovalStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == BgRemovalStatus.idle) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            _icon,
            const SizedBox(width: 8),
            Expanded(
              child: Text(_text, style: TextStyle(color: _color, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Color get _color {
    switch (status) {
      case BgRemovalStatus.idle:
        return Colors.transparent;
      case BgRemovalStatus.processing:
        return Colors.orange;
      case BgRemovalStatus.done:
        return Colors.green;
      case BgRemovalStatus.failed:
        return Colors.red;
    }
  }

  Widget get _icon {
    switch (status) {
      case BgRemovalStatus.idle:
        return const SizedBox.shrink();
      case BgRemovalStatus.processing:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case BgRemovalStatus.done:
        return const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case BgRemovalStatus.failed:
        return const Icon(Icons.error, size: 16, color: Colors.red);
    }
  }

  String get _text {
    switch (status) {
      case BgRemovalStatus.idle:
        return '';
      case BgRemovalStatus.processing:
        return 'Removing background...';
      case BgRemovalStatus.done:
        return 'Background removed';
      case BgRemovalStatus.failed:
        return 'Background removal failed. Using original image.';
    }
  }
}
