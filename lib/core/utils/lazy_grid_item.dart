import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyGridItem extends StatefulWidget {
  final Widget child;
  final String itemKey;

  const LazyGridItem({super.key, required this.child, required this.itemKey});

  @override
  State<LazyGridItem> createState() => _LazyGridItemState();
}

class _LazyGridItemState extends State<LazyGridItem> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.itemKey),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_isVisible) {
          setState(() => _isVisible = true);
        }
      },
      child:
          _isVisible
              ? widget.child
              : Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
    );
  }
}
