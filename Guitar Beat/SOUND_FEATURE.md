# Beat Sound Selection Feature

## What's New

Added the ability to choose between 6 different beat sounds in the metronome app.

## Available Sounds

1. **Kick Drum** (Default)
   - Deep, punchy low-frequency drum (150Hz → 50Hz sweep)
   - 80ms duration with noise attack
   - Great for feeling the beat in your body

2. **Rim Click**
   - Sharp, bright metallic click
   - Multiple frequencies (800Hz, 1200Hz, 2400Hz)
   - 30ms duration
   - Clear and cutting

3. **Wood Block**
   - High-pitched, short woody sound (1800Hz + 3600Hz)
   - Lots of noise for wooden character
   - 25ms duration
   - Traditional and familiar

4. **Cowbell**
   - Metallic bell with long sustain
   - Inharmonic partials (587Hz, 845Hz, 1109Hz, 1312Hz)
   - 150ms duration
   - Fun and distinctive (more cowbell!)

5. **Snare**
   - Crisp drum with snare wires
   - 200Hz tone + noise (simulates snare wires)
   - 60ms duration
   - Bright and articulate

6. **Classic Click**
   - Traditional metronome click
   - Simple 1200Hz sine wave
   - 15ms duration
   - Minimal and precise

## How to Use

1. **Tap the waveform icon** (⚪ with waveform) in the top-right corner
2. **Browse the sound list** with descriptions
3. **Tap any sound** to select it
4. The new sound applies immediately (even while playing)
5. The selected sound name appears below the title

## Technical Implementation

### Code Changes

**MetronomeEngine.swift:**
- Added `BeatSound` enum with 6 cases
- Added `setBeatSound()` method
- Refactored `generateClickSound()` to support multiple sounds
- Created 6 separate sound generators:
  - `generateKickDrum()`
  - `generateRimClick()`
  - `generateWoodBlock()`
  - `generateCowbell()`
  - `generateSnare()`
  - `generateClassicClick()`

**MetronomeViewModel.swift:**
- Added `@Published var beatSound: BeatSound`
- Connected to engine via `didSet`

**ContentView.swift:**
- Added waveform button to open sound picker
- Added sound name display below title
- Created `SoundPickerView` modal sheet
- Shows all sounds with descriptions
- Checkmark indicates current selection

### Sound Generation Details

Each sound is programmatically generated using:
- **Sine waves** at specific frequencies
- **Frequency sweeps** for drum-like pitch bends
- **White noise** for attack and texture
- **Exponential envelopes** for natural decay
- **Multiple harmonics** for complex timbres

All sounds are still generated at runtime—no audio files needed!

## User Experience

- Sound changes apply immediately (no app restart)
- Works while metronome is playing
- Current sound is displayed on main screen
- Sound picker has dark theme matching the app
- Descriptions help users understand each sound

## Future Enhancements

Possible additions:
- Preview button to test sounds before selecting
- Accent sounds for downbeats
- Custom sound upload
- Favorite sounds
- Sound volume balance (if mixing accent + regular beats)
