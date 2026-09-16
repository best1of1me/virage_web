import 'package:flutter/material.dart';

class PageContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PageContent({super.key, required this.child, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: const EdgeInsets.all(16.0), child: child),
      ),
    );
  }
}
