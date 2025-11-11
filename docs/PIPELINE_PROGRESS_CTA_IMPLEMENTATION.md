# Pipeline Progress CTA Implementation

## Summary

Implemented lightweight, non-blocking progress indicators with smooth transitions for pipeline stages across Record and Upload flows. The CTA area morphs into progress state during processing, with auto-navigation to summary on completion.

## Files Changed

1. **lib/widgets/pipeline_progress_cta.dart** (NEW)
   - Reusable progress widget with debounce, transitions, and error handling
   - ~320 lines

2. **lib/presentation/record_screen/record_screen.dart**
   - Integrated `PipelineProgressCTA` into upload section
   - Replaced static button with progress-aware widget

3. **lib/presentation/active_recording_screen/active_recording_screen.dart**
   - Integrated `PipelineProgressCTA` into upload button area
   - Removed static "Uploading..." text button

4. **lib/presentation/active_recording_screen/recording_controller.dart**
   - Added `PipelineTracker.I.start()` call in `save()` method for progress tracking

## Key Features

### Progress States
- **Idle**: Shows button with custom label/icon
- **Loading**: Shows stage label, progress indicator (determinate/indeterminate), and subtext
- **Error**: Shows error chip with retry button

### Transitions
- Uses `AnimatedSwitcher` with scale + fade for smooth cross-fades
- 250ms debounce to prevent flicker on fast completions (<250ms)
- Layout-stable (fixed height container prevents sibling shifts)

### Stage Labels & Subtexts
- Uploading → "Uploading your recording"
- Transcribing → "Turning speech into text"
- Summarizing → "Creating summary"
- Ready → "Complete!" (brief, then auto-navigates)
- Error → Shows error message from tracker

### Auto-Navigation
- On `PipeStage.ready`, automatically navigates to summary screen
- Uses `openRecordingSummary()` helper for consistent routing
- Prevents double navigation with `_hasNavigated` flag
- Resets navigation flag when tracking starts for new recording

### Error Handling
- Shows error state when `PipeStage.error` is reached
- Displays error message from `PipelineTracker.message`
- "Try again" button resets tracking and retries upload

## Integration Points

### Upload Flow (Record Screen)
```dart
PipelineProgressCTA(
  idleLabel: 'Choose Audio File',
  idleIcon: Icons.upload_file,
  onStartAction: () async {
    final result = await uploadService.pickAndUploadAudioFile();
    if (result['success'] && result['recording_id'] != null) {
      PipelineTracker.I.start(result['recording_id']);
    }
  },
)
```

### Upload Flow (Active Recording Screen)
```dart
PipelineProgressCTA(
  idleLabel: 'Upload file',
  idleIcon: Icons.upload_file,
  autoNavigate: true,
  onStartAction: () => c.onUploadFilePressed(context),
)
```

## Pipeline Tracking Integration

The widget listens to `PipelineTracker.I` observables:
- `status`: Current pipeline stage
- `recordingId`: Active recording ID (null when idle)
- `message`: Error message (when stage is error)
- `progressPercentage`: 0.0-1.0 progress value

Tracking is started automatically by:
- `FileUploadService.pickAndUploadAudioFile()` → `AuthoritativeUploadService.uploadWithAuthoritativeFlow()`
- `RecordingController.save()` → after creating recording row

## Debounce Logic

- Tracks `_activeStartTime` when pipeline becomes active
- Only shows progress UI after 250ms elapsed
- Prevents flicker on fast uploads (<250ms)
- Timer is cancelled if stage changes to idle/ready/error before debounce completes

## Accessibility

- Stage labels have semantic labels: `"Processing stage: $label"`
- Progress indicators have semantic labels: `"Progress: ${(progress * 100).toInt()}%"`
- Error buttons meet 44dp minimum touch target
- Error containers use appropriate contrast colors

## Testing Checklist

### Fast Complete (<250ms)
- [ ] Upload completes quickly → no spinner appears
- [ ] Button transitions directly to idle or navigates to summary

### Normal Multi-Second Flow
- [ ] Upload button → Progress appears after 250ms
- [ ] Stages transition: Uploading → Transcribing → Summarizing
- [ ] Progress percentage increments smoothly
- [ ] Auto-navigates to summary on ready

### Error Scenario
- [ ] Error occurs → Error chip appears with message
- [ ] "Try again" button visible and functional
- [ ] Retry resets state and restarts upload
- [ ] Error state clears after retry

### Resume/Retry
- [ ] Retry resets tracking state
- [ ] Navigation flag resets
- [ ] New upload can start tracking fresh

## Acceptance Criteria

✅ Compiles with zero warnings  
✅ No nested Scaffolds introduced  
✅ Uses existing theme/colors  
✅ Bottom nav shell remains intact  
✅ Auto-navigation uses Material transitions  
✅ 250ms debounce prevents flicker  
✅ Layout-stable transitions  
✅ Error state with retry  
✅ Accessibility labels present  

## Known Limitations

1. The widget only shows progress for upload flows. The "Save" button in recording controls doesn't use this widget (different flow).
2. If an error occurs before tracking starts (during file pick), error state won't show (snackbar handles this).
3. Very fast transitions (<100ms) may briefly show previous state before debounce completes.

## Future Enhancements

- Add progress percentage callbacks from upload service for more accurate determinate progress
- Consider adding progress widget to Save button area for recorded files
- Add haptic feedback on stage transitions
- Add analytics events for stage transitions

