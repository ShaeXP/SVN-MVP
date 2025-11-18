import 'package:flutter/material.dart';

class EditableCardShell extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget dragHandle;
  final void Function(String action) onMenu;
  
  const EditableCardShell({
    super.key, 
    this.title, 
    required this.child, 
    required this.dragHandle, 
    required this.onMenu
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
            Row(
              children: [
                if (title != null) ...[
                  Expanded(child: Text(title!, style: const TextStyle(fontWeight: FontWeight.w600))),
                ] else ...[
                  const Expanded(child: SizedBox.shrink()),
                ],
                dragHandle,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
