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
                dragHandle,
                const SizedBox(width: 8),
                if (title != null) ...[
                  Expanded(child: Text(title!, style: const TextStyle(fontWeight: FontWeight.w600))),
                ] else ...[
                  const Expanded(child: SizedBox.shrink()),
                ],
                PopupMenuButton<String>(
                  onSelected: onMenu,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'up', child: Text('Move up')),
                    PopupMenuItem(value: 'down', child: Text('Move down')),
                    PopupMenuItem(value: 'hide', child: Text('Hide')),
                  ],
                ),
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
