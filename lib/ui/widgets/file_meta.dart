// lib/ui/widgets/file_meta.dart
import 'package:flutter/material.dart';
import '../theme/svn_theme.dart';

class SupportedTypesChips extends StatelessWidget {
  const SupportedTypesChips({super.key, required this.types});
  final List<String> types;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: types.map((t) => Chip(
        label: Text(t.toLowerCase()),
        side: const BorderSide(color: SVNTheme.border),
        backgroundColor: SVNTheme.surfaceAlt,
      )).toList(),
    );
  }
}

String humanSize(int bytes) {
  const units = ['B','KB','MB','GB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}

