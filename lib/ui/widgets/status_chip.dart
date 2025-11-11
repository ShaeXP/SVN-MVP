// lib/ui/widgets/status_chip.dart
import 'package:flutter/material.dart';
import '../theme/svn_theme.dart';

@Deprecated('Use StatusChip from presentation/recording_library_screen/widgets/status_chip.dart (named params).')
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color c;
    switch (s) {
      case 'ready':
        c = SVNTheme.ok;
        break;
      case 'summarizing':
        c = SVNTheme.warn;
        break;
      case 'transcribing':
        c = SVNTheme.info;
        break;
      case 'uploaded':
        c = SVNTheme.ok;
        break;
      case 'processing':
        c = SVNTheme.neutral;
        break;
      case 'error':
        c = SVNTheme.error;
        break;
      default:
        c = SVNTheme.neutral;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: c.withOpacity(0.10),
        shape: StadiumBorder(side: BorderSide(color: c)),
      ),
      child: Text(status, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c, fontWeight: FontWeight.w600)),
    );
  }
}

