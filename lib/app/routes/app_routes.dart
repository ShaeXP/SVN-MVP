abstract class Routes {
  Routes._();

  // Top-level
  static const splash = '/splash';
  static const root = '/';
  static const authScreen = '/auth';
  static const login = '/login';
  static const confirmEmail = '/confirm-email';

  // Main app shell
  static const home = '/home';

  // Tabs inside the shell
  static const record = '/record';
  static const recordingLibrary = '/recording-library';
  static const recordingLibraryScreen = '/recording-library';
  static const settings = '/settings';

  // Detail flows (children of main shell)
  static const recordingSummary = '/recording-summary';
  static const recordingSummaryScreen = '/recording-summary';
  static const recordingDetailsScreen = '/recording-details';
  static const recordingReady = '/recording-ready';
  static const activeRecording = '/active-recording';
  static const recordingPaused = '/recording-paused';
  static const uploadRecording = '/upload-recording';
  static const howItWorks = '/how-it-works';
  static const askNotesLabScreen = '/ask-notes-lab';
}