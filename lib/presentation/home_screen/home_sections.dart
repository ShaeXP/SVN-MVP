import 'package:flutter/material.dart';
import 'widgets/processing_summary_card.dart';
import 'widgets/recent_summaries_card.dart';
import 'widgets/action_items_card.dart';
import 'widgets/welcome_card.dart';
import 'widgets/quick_tabs_row.dart';

enum HomeSection { 
  welcome, 
  quickTabs, 
  processingSummary, 
  recentSummaries, 
  actionItems 
}

typedef SectionBuilder = Widget Function(BuildContext ctx);

class HomeSectionRegistry {
  static final Map<HomeSection, String> titles = {
    HomeSection.welcome: 'Welcome',
    HomeSection.quickTabs: 'Quick',
    HomeSection.processingSummary: 'Background processing',
    HomeSection.recentSummaries: 'Recent summaries',
    HomeSection.actionItems: 'Action items',
  };

  static Map<HomeSection, SectionBuilder> builders = {
    HomeSection.welcome: (c) => const WelcomeCard(),
    HomeSection.quickTabs: (c) => const QuickTabsRow(),
    HomeSection.processingSummary: (c) => const ProcessingSummaryCard(),
    HomeSection.recentSummaries: (c) => const RecentSummariesCard(),
    HomeSection.actionItems: (c) => const ActionItemsCard(),
  };
}
