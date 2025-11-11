import 'package:lashae_s_application/services/pipeline_tracker.dart';

PipeStage mapStatusToPipeStage(String status) {
  switch (status) {
    case 'uploading':
      return PipeStage.uploading;
    case 'uploaded':
      return PipeStage.transcribing;
    case 'transcribing':
      return PipeStage.transcribing;
    case 'summarizing':
      return PipeStage.summarizing;
    case 'ready':
      return PipeStage.ready;
    default:
      return PipeStage.error;
  }
}

