import 'package:get/get.dart';
import '../../../core/app_export.dart';

class RecordingItemModel {
  Rx<String>? id;
  Rx<String>? date;
  Rx<String>? duration;
  Rx<String>? title;
  Rx<String>? transcript;
  Rx<String>? wordsCount;
  Rx<bool>? hasTranscript;
  Rx<String>? iconPath;
  Rx<String>? buttonPath;
  RxList<String>? additionalIcons;

  RecordingItemModel({
    this.id,
    this.date,
    this.duration,
    this.title,
    this.transcript,
    this.wordsCount,
    this.hasTranscript,
    this.iconPath,
    this.buttonPath,
    this.additionalIcons,
  });
}
