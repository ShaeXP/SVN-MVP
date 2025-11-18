import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../presentation/recording_summary_screen/recording_summary_screen.dart';
import 'debug_routes.dart';
import '../app/navigation/bottom_nav_controller.dart';

/// Standardized navigation helper for opening recording summaries
/// with hard fallback to ensure it always works
Future<void> openRecordingSummary({
  required String recordingId,
  String? summaryId,
}) async {
  const route = Routes.recordingSummaryScreen; // Use the baseline constant
  debugRoutesPing('openRecordingSummary', route);

  final args = {'recordingId': recordingId, 'summaryId': summaryId};

  // Ensure Library tab is the active parent for summary detail
  try {
    final nav = BottomNavController.I;
    await nav.goLibrary();
  } catch (_) {
    // If BottomNavController isn't available for some reason, continue with navigation
  }

  // Preferred: named route
  final registeredRoutes = Get.routeTree.routes.map((r) => r.name).toList();
  if (registeredRoutes.contains(route)) {
    debugPrint('[NAV] toNamed $route args=$args');
    await Get.toNamed(route, arguments: args);
    return;
  }

  // Hard fallback: direct widget push (bypasses bad route registration)
  debugPrint('[NAV] FALLBACK direct → RecordingSummaryScreen args=$args');
  await Get.to(() => RecordingSummaryScreen(), arguments: args);
}

/// Hard guarantee: show Library root with Library tab highlighted.
Future<void> goToLibraryRoot() async {
  // 1) Ensure bottom nav is on Library tab
  try {
    final nav = BottomNavController.I;
    await nav.goLibrary();
  } catch (_) {
    // ignore; we'll still replace the route below
  }

  // 2) Hard reset to the Library root route inside the main shell
  await Get.offAllNamed(Routes.recordingLibraryScreen);
}
