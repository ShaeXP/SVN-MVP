import 'package:flutter/material.dart';
import '../../../ui/app_spacing.dart';

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
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null && title!.trim().isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (menuBuilder != null) menuBuilder!,
                ],
              ),
              SizedBox(height: AppSpacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
