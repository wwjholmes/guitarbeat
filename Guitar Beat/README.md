# Guitar Beat - Minimal Metronome App

A clean, minimal metronome app for guitar practice built with Swift and SwiftUI.

## Features

- **Tempo Control**: 40-240 BPM range with slider and step buttons (+1/-1)
- **Start/Stop**: Single button to toggle playback
- **Volume Control**: Adjustable volume slider (0-1)
- **Precise Timing**: Audio-time-based scheduling for drift-free accuracy
- **Clean UI**: Dark mode friendly, minimal design
- **Lifecycle Management**: Automatically stops when backgrounded

## Architecture

The app follows MVVM architecture:

- **MetronomeEngine.swift**: Core audio and scheduling logic
- **MetronomeViewModel.swift**: State management and SwiftUI bindings
- **ContentView.swift**: User interface
- **Guitar_BeatApp.swift**: App entry point

## Technical Implementation

### Audio Engine

The metronome uses **AVAudioEngine** with **AVAudioPlayerNode** for precise, drift-free timing:

1. **Click Sound**: Programmatically generated using a brief sine wave (1200 Hz) with exponential decay envelope
2. **Scheduling**: Buffers are scheduled using audio sample time, not wall-clock time
3. **Precision**: Audio-time-based scheduling prevents drift accumulation
4. **Low Latency**: Direct buffer scheduling on the audio thread

### Timing Approach

The engine uses a callback-based scheduling pattern:
- Each click buffer schedules the next buffer in its completion callback
- Timing is calculated in audio sample frames, not seconds
- The interval between beats is: `sampleTime + (60.0 / BPM) * sampleRate`
- This approach is immune to system scheduling variations

### BPM Changes

When BPM changes while running:
- New tempo is picked up naturally on the next scheduled beat
- No timer reset required, no crashes
- Smooth transition without drift

### Thread Safety

- `MetronomeEngine` uses a dedicated serial queue for scheduling
- `MetronomeViewModel` is `@MainActor` isolated
- Weak references prevent retain cycles

## Setup Instructions

### Requirements
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Installation

1. **Add Files to Project**
   - All Swift files are already in your project
   - No additional assets or resources needed

2. **Build and Run**
   - Open `Guitar Beat.xcodeproj` in Xcode
   - Select your target device or simulator
   - Press Cmd+R to build and run

3. **Audio Permissions**
   - No special permissions needed for playback
   - The app configures AVAudioSession automatically

### Project Structure

```
Guitar Beat/
├── Guitar_BeatApp.swift          # App entry point
├── ContentView.swift              # UI
├── MetronomeViewModel.swift       # View model
└── MetronomeEngine.swift          # Audio engine
```

## Usage

1. **Set Tempo**: Use the slider or +/- buttons to adjust BPM (40-240)
2. **Adjust Volume**: Use the volume slider at the bottom
3. **Start**: Tap the green "Start" button
4. **Stop**: Tap the red "Stop" button
5. **Change Tempo While Playing**: Adjust BPM anytime - changes apply smoothly

## Implementation Notes

### Why AVAudioEngine?

- **Precision**: Audio-time scheduling is immune to system scheduling jitter
- **No Drift**: Using sample-accurate timing prevents error accumulation
- **Low Latency**: Direct buffer scheduling on audio thread
- **Simple**: No external dependencies or audio files needed

### Alternative Approaches Considered

1. **DispatchSourceTimer**: 
   - Pros: Simpler code
   - Cons: Subject to system scheduling delays, can accumulate drift
   - Mitigation: Would require drift compensation logic

2. **CADisplayLink**:
   - Pros: Tied to display refresh
   - Cons: Wrong synchronization domain for audio
   - Not suitable for audio timing

3. **Timer**:
   - Cons: Not precise enough, accumulates drift
   - Not recommended for audio applications

### Code Quality

- ✅ Compiles on latest Xcode
- ✅ Swift Concurrency with @MainActor
- ✅ No retain cycles (weak self in closures)
- ✅ Thread-safe scheduling
- ✅ Proper lifecycle management
- ✅ Commented timing-critical sections

## Future Enhancements

Possible additions for v2:
- Time signatures (4/4, 3/4, 6/8, etc.)
- Accent on first beat
- Subdivision clicks (8th notes, triplets)
- Visual beat indicator with animation
- Haptic feedback on beats
- Preset tempos (Largo, Andante, Allegro, etc.)
- Tap tempo to set BPM
- Background audio playback

## License

Created by Wenjing Wang on 12/22/25.
