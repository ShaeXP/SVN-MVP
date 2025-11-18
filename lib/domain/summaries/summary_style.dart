// lib/domain/summaries/summary_style.dart
// Summary style enum and helpers for key/label mapping

enum SummaryStyle {
  quickRecap,
  organizedByTopic,
  decisionsNextSteps,
}

extension SummaryStyleKey on SummaryStyle {
  String get key {
    switch (this) {
      case SummaryStyle.quickRecap:
        return 'quick_recap';
      case SummaryStyle.organizedByTopic:
        return 'organized_by_topic';
      case SummaryStyle.decisionsNextSteps:
        return 'decisions_next_steps';
    }
  }

  String get label {
    switch (this) {
      case SummaryStyle.quickRecap:
        return 'Quick Recap + Action Items';
      case SummaryStyle.organizedByTopic:
        return 'Organized by Topic';
      case SummaryStyle.decisionsNextSteps:
        return 'Decisions & Next Steps';
    }
  }
}

SummaryStyle summaryStyleFromKey(String? key) {
  switch ((key ?? '').trim()) {
    case 'organized_by_topic':
      return SummaryStyle.organizedByTopic;
    case 'decisions_next_steps':
      return SummaryStyle.decisionsNextSteps;
    case 'quick_recap':
    default:
      return SummaryStyle.quickRecap;
  }
}

String summaryStyleLabelFromKey(String? key) {
  return summaryStyleFromKey(key).label;
}


