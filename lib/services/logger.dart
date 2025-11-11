import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

void logx(String msg, {String tag = 'SVN', Object? error, StackTrace? stack}) {
  if (!kReleaseMode) dev.log(msg, name: tag, error: error, stackTrace: stack);
}
