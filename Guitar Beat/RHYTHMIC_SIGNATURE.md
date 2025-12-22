# Rhythmic Signature Feature Documentation

## Overview

Added support for rhythmic signatures (time signatures) to the metronome, allowing musicians to practice with different subdivisions and patterns.

## What is a Rhythmic Signature?

A rhythmic signature is expressed as a fraction: **numerator / denominator**

- **Numerator** (1-16): Number of beats in the pattern
- **Denominator** (1, 2, 4, 8, 16): Note value that gets one beat

### Examples

| Signature | Meaning | Usage |
|-----------|---------|-------|
| **4/4** | 4 quarter notes per measure | Most common time signature |
| **3/4** | 3 quarter notes per measure | Waltz time |
| **6/8** | 6 eighth notes per measure | Compound meter |
| **1/8** | 1 eighth note beat | Fast subdivision practice |
| **3/16** | 3 sixteenth notes | Very fast patterns |

## How Timing Works

### BPM Reference
BPM is always relative to **quarter notes** (denominator = 4).

### Interval Calculation
The metronome calculates click intervals using:

```
interval = (60 / BPM) × (4 / denominator)
```

### Examples at 120 BPM

**Quarter note interval** = 60 / 120 = 0.5 seconds

| Signature | Calculation | Interval | Speed |
|-----------|-------------|----------|-------|
| **4/4** | 0.5 × (4/4) = 0.5 | 500ms | Normal |
| **4/8** | 0.5 × (4/8) = 0.25 | 250ms | 2x faster |
| **4/16** | 0.5 × (4/16) = 0.125 | 125ms | 4x faster |
| **4/2** | 0.5 × (4/2) = 1.0 | 1000ms | 2x slower |

## Audio Features

### Accent on First Beat
When numerator > 1, the first beat of each measure is **accented**:

- **Volume boost**: 30% louder
- **High-frequency ping**: Subtle 2400 Hz tone added for clarity
- **Same duration**: Keeps timing consistent

This helps you feel where "beat 1" is in patterns like:
- **4/4**: LOUD-soft-soft-soft-LOUD-soft-soft-soft...
- **3/4**: LOUD-soft-soft-LOUD-soft-soft...
- **6/8**: LOUD-soft-soft-soft-soft-soft-LOUD-soft-soft...

### Pattern Looping
The metronome continuously loops the pattern:
- Beat counter: 0, 1, 2, ..., (numerator-1), 0, 1, 2...
- First beat (0) always gets accent
- Pattern repeats seamlessly

## User Interface

### Main Screen
Shows current signature in a tappable button:
```
🎵 4 / 4 ▼
```

### Signature Picker (Sheet Modal)

**Large Display**
- Shows selected signature in giant numbers (72pt)
- Updates in real-time as you scroll

**Wheel Pickers**
- Left wheel: Numerator (1-16)
- Divider: "/"
- Right wheel: Denominator (1, 2, 4, 8, 16)
- iOS-style scroll wheels (smooth, familiar)

**Description**
- Dynamic text explaining the signature
- "4 quarter notes per measure"
- "One eighth note per beat"

**Common Presets**
- Quick tap buttons: 4/4, 3/4, 6/8, 5/4
- Instantly sets both values

**Actions**
- Cancel: Close without changing
- Apply: Save and restart metronome

## Code Architecture

### RhythmicSignature.swift
```swift
struct RhythmicSignature {
    let numerator: Int      // 1-16
    let denominator: Int    // 1, 2, 4, 8, 16
    
    var intervalMultiplier: Double {
        return 4.0 / Double(denominator)
    }
    
    func intervalSeconds(at bpm: Double) -> Double {
        let quarterNoteInterval = 60.0 / bpm
        return quarterNoteInterval * intervalMultiplier
    }
}
```

**Key methods:**
- `intervalMultiplier`: Calculates speed relative to quarter notes
- `intervalSeconds(at:)`: Actual interval in seconds for given BPM
- `displayString`: Formatted "4/4" string

### MetronomeEngine Updates

**New Properties:**
```swift
private var currentSignature = RhythmicSignature.fourFour
private var currentBeatInPattern: Int = 0
private var accentBuffer: AVAudioPCMBuffer?
```

**New Methods:**
```swift
func setSignature(_ signature: RhythmicSignature)
private func generateAccentSound(for sound: BeatSound)
```

**Updated Scheduling:**
- Uses `currentSignature.intervalSeconds(at: currentBPM)`
- Tracks beat position in pattern
- Selects accent buffer for beat 0, regular buffer for others
- Loops pattern continuously

### MetronomeViewModel Updates

**New Property:**
```swift
@Published var signature: RhythmicSignature = .fourFour {
    didSet {
        engine.setSignature(signature)
    }
}
```

### ContentView Updates

**New UI Elements:**
- Signature display button below sound name
- Sheet presentation for `SignaturePickerView`

**SignaturePickerView:**
- Two-column wheel picker
- Real-time preview
- Dynamic descriptions
- Preset buttons
- Dark-themed

## Behavior Details

### When Signature Changes
1. Engine stops current playback
2. Resets beat counter to 0
3. Regenerates accent buffer if needed
4. Restarts with new timing
5. First beat plays with accent

### Timing Stability
- Uses same sample-accurate scheduling as before
- No drift introduced by signature changes
- Accent buffer pre-generated (no runtime overhead)
- Pattern loops without gaps

### Thread Safety
- All scheduling on dedicated queue
- ViewModel updates on MainActor
- No race conditions with beat counter

## Practice Use Cases

### Subdivision Practice
**Goal**: Feel faster note values

1. Set BPM to comfortable tempo (e.g., 80 BPM)
2. Start with 4/4 (quarter notes)
3. Switch to 4/8 (eighth notes) - twice as fast
4. Switch to 4/16 (sixteenth notes) - four times as fast
5. Practice scales/riffs at each level

### Odd Time Signatures
**Goal**: Internalize unusual patterns

1. Set 5/4 or 7/8
2. Accent on beat 1 helps you feel where measure starts
3. Practice riffs that fit the signature
4. Common in prog rock, jazz

### Compound Meter
**Goal**: Feel grouped beats

1. Set 6/8 or 9/8
2. Accent helps group beats (strong-weak-weak pattern)
3. Different feel than simple meters

### Speed Building
**Goal**: Gradually increase tempo with subdivisions

1. Start: 60 BPM, 4/4
2. Step 1: 60 BPM, 4/8 (practice at double speed)
3. Step 2: 70 BPM, 4/4 (increase actual tempo)
4. Step 3: 70 BPM, 4/8 (double speed again)
5. Continue pattern

## Technical Notes

### Why This Formula?
```
interval = (60 / BPM) × (4 / denominator)
```

**Reasoning:**
- BPM = quarter notes per minute (standard)
- 60 / BPM = seconds per quarter note
- 4 / denominator = ratio of this note to quarter note
  - 4/4 = 1.0 (same speed)
  - 4/8 = 0.5 (half the time, twice as fast)
  - 4/16 = 0.25 (quarter time, 4x as fast)
  - 4/2 = 2.0 (double time, half as fast)

### Accent Generation
Accent buffer is created by:
1. Generating base sound
2. Boosting volume by 30%
3. Adding brief 2400 Hz sine wave ping
4. Clamping to prevent clipping

This makes accents **clear but not jarring**.

### Pattern Counter
```swift
currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
```

Uses modulo to loop: 0 → 1 → 2 → 3 → 0 → 1...

## Future Enhancements

Possible additions:
- **Visual beat indicator**: Circles that pulse on each beat
- **Secondary accent**: Stronger accent every N measures
- **Custom accent patterns**: e.g., 3+3+2 grouping in 8/8
- **Polyrhythms**: Multiple simultaneous patterns
- **Subdivision display**: Show note values graphically
- **Tap tempo with auto-detect**: Detect time signature from taps

## Testing Recommendations

### Basic Functionality
1. Try all common signatures (4/4, 3/4, 6/8)
2. Verify accent sounds on beat 1
3. Check timing at various BPMs
4. Ensure smooth looping

### Edge Cases
1. 1/1 (whole notes) - very slow
2. 1/16 (sixteenth notes) - very fast
3. 16/16 - long pattern
4. Change signature while playing
5. Change BPM and signature together

### Audio Quality
1. Verify no clicks/pops between beats
2. Check accent is audible but not harsh
3. Test all sound types with accents
4. Verify timing accuracy with external metronome

## Summary

The rhythmic signature feature transforms this from a simple metronome into a **comprehensive practice tool** for musicians who need to work with different time signatures, subdivisions, and rhythmic patterns. The implementation maintains timing accuracy while adding musical expressiveness through accented downbeats.
