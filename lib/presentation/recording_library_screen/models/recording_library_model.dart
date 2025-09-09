import 'package:get/get.dart';
import '../../../core/app_export.dart';
import '../../../data/models/recording_item.dart';

class RecordingItemModel {
  String id;
  String title;
  String date; // plain text like "8/6/2025 10:47 PM"
  String duration; // e.g. "0:14"

  RecordingItemModel(
      {required this.id,
      required this.title,
      required this.date,
      required this.duration});
}

class RecordingLibraryModel {
  Rx<String>? title;
  Rx<String>? recordingsCount;
  Rx<String>? searchPlaceholder;
  RxList<RecordingItem> recordingItemList = <RecordingItem>[].obs;

  RecordingLibraryModel({
    this.title,
    this.recordingsCount,
    this.searchPlaceholder,
  });
}
