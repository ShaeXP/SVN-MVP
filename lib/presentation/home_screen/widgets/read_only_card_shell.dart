import 'package:flutter/material.dart';

class ReadOnlyCardShell extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? menuBuilder;
  
  const ReadOnlyCardShell({
    super.key, 
    this.title, 
    required this.child, 
    this.menuBuilder
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(child: Text(title!, style: const TextStyle(fontWeight: FontWeight.w600))),
                  if (menuBuilder != null) menuBuilder!,
                ],
              ),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
