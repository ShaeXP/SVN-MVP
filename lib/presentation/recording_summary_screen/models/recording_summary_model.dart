import 'package:get/get.dart';
import '../../../core/app_export.dart';

/// This class is used in the [RecordingSummaryScreen] screen with GetX.

class RecordingSummaryModel {
  Rx<String>? recordingDate;
  Rx<String>? recordingTime;
  Rx<String>? duration;
  Rx<String>? summaryText;
  Rx<int>? selectedSummaryLength;

  RecordingSummaryModel({
    this.recordingDate,
    this.recordingTime,
    this.duration,
    this.summaryText,
    this.selectedSummaryLength,
  }) {
    recordingDate = recordingDate ?? 'Recording 8/6/2025 10:47 PM'.obs;
    recordingTime = recordingTime ?? '2m 03s'.obs;
    duration = duration ?? '01:53 PM'.obs;
    summaryText = summaryText ??
        'In the quarterly review meeting, the team reported a 15% increase in sales for Q3, surpassing projections due to enhanced marketing strategies and improved customer acquisition. The mobile app launch was highlighted as a significant success, achieving over 50,000 downloads in the first month, well above the expected 30,000, and receiving an average rating of 4.2 stars. However, user feedback indicated that the onboarding process was complicated, with many users finding the registration flow confusing and time-consuming. To address this, the team plans to simplify the onboarding experience in the next update and allocate additional budget for user experience improvements, alongside more user testing sessions to ensure the platform remains user-friendly.'
            .obs;
    selectedSummaryLength = selectedSummaryLength ?? 1.obs;
  }
}

class ActionItemModel {
  Rx<String>? text;

  ActionItemModel({
    this.text,
  });
}

class KeyPointModel {
  Rx<String>? text;

  KeyPointModel({
    this.text,
  });
}

class ActionChipModel {
  Rx<String>? text;
  Rx<String>? iconPath;

  ActionChipModel({
    this.text,
    this.iconPath,
  });
}
