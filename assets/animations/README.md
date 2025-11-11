# Lottie Animations

Place your Lottie animation files here with these exact names:

## Required Files

- `record_button_idle.lottie` or `record_button_idle.json` - Record button in idle state
- `record_button_active.lottie` or `record_button_active.json` - Record button while recording
- `pipeline_ring.lottie` or `pipeline_ring.json` - Pipeline progress ring animation
- `success_toast.lottie` or `success_toast.json` - Success toast animation

## File Format Support

The Lottie package supports both `.lottie` (binary) and `.json` formats. Use whichever format you prefer.

## Fallback Behavior

If any animation file is missing, the app will show a loud fallback UI with "Lottie OFF" text and colored borders to make it obvious that animations are disabled.
