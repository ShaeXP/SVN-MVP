// lib/models/summary_style_option.dart
// Summary style model with key/label mapping

import 'package:flutter/foundation.dart';

class SummaryStyleOption {
  final String key;    // machine key used across client + edge + DB
  final String label;  // human label

  const SummaryStyleOption(this.key, this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryStyleOption &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          label == other.label;

  @override
  int get hashCode => key.hashCode ^ label.hashCode;

  @override
  String toString() => 'SummaryStyleOption(key=$key, label=$label)';
}

class SummaryStyles {
  static const quickRecapActionItems = SummaryStyleOption(
    'quick_recap_action_items',
    'Quick Recap + Action Items',
  );

  static const decisionsNextSteps = SummaryStyleOption(
    'decisions_next_steps',
    'Decisions & Next Steps',
  );

  static const organizedByTopic = SummaryStyleOption(
    'organized_by_topic',
    'Organized by Topic',
  );

  static const all = <SummaryStyleOption>[
    quickRecapActionItems,
    decisionsNextSteps,
    organizedByTopic,
  ];

  static SummaryStyleOption byKey(String? key) {
    if (key == null || key.isEmpty) {
      return SummaryStyles.quickRecapActionItems;
    }
    
    final normalizedKey = key.trim();
    for (final option in all) {
      if (option.key == normalizedKey) {
        return option;
      }
    }
    
    // Handle legacy keys for backward compatibility
    switch (normalizedKey) {
      case 'quick_recap':
        return SummaryStyles.quickRecapActionItems;
      case 'decisions_next_steps':
        return SummaryStyles.decisionsNextSteps;
      case 'organized_by_topic':
        return SummaryStyles.organizedByTopic;
      default:
        return SummaryStyles.quickRecapActionItems;
    }
  }

  static String labelFromKey(String? key) {
    return byKey(key).label;
  }
}

