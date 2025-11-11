enum PipelineStep {
  uploading,
  transcribing,
  summarizing,
  ready,
  error,
}

PipelineStep mapStatusToStep(String status) {
  switch (status) {
    case 'local':
    case 'uploading':
      return PipelineStep.uploading;
    case 'uploaded':
    case 'transcribing':
      return PipelineStep.transcribing;
    case 'processing':
    case 'summarizing':
      return PipelineStep.summarizing;
    case 'ready':
      return PipelineStep.ready;
    case 'error':
      return PipelineStep.error;
    default:
      return PipelineStep.error;
  }
}

