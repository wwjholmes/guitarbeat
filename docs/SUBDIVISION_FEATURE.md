# Subdivision Feature Implementation

## Overview
Added subdivision support to the Guitar Beat metronome app. Subdivision controls how many clicks occur per beat (1-4), affecting only audio timing while preserving the existing beat block UI structure.

## Modified Files

### 1. MetronomeViewModel.swift
**Changes:**
- Added `subdivision: Int` published property (range 1-4, default = 1)
- Initialized subdivision in the engine setup

**Responsibilities:**
- Manages subdivision state
- Passes subdivision changes to the engine
- UI observes this property to display current subdivision

### 2. MetronomeEngine.swift
**Changes:**
- Added `currentSubdivision: Int` property (default = 1)
- Added `clicksInCurrentBeat: Int` to track subdivision progress
- Added `setSubdivision(_ subdivision: Int)` method
- Modified `start(resetBeatPosition:)` to reset click counter
- Updated `scheduleNextClick()` to handle subdivision logic

**Timing Behavior:**
- **Beat interval** = 60 / BPM (unchanged)
- **Click interval** = beat interval / subdivision
- Engine emits one click per click interval
- Beat index advances only after `subdivision` clicks complete
- UI notification (`onBeatTick`) fires once per beat, not per click

**Key Logic:**
```swift
// Calculate click interval
let beatIntervalSeconds = currentSignature.intervalSeconds(at: currentBPM)
let clickIntervalSeconds = beatIntervalSeconds / Double(currentSubdivision)

// Count clicks within beat
clicksInCurrentBeat += 1

// Advance beat only when all subdivision clicks complete
if clicksInCurrentBeat >= currentSubdivision {
    notifyBeatTick()
    currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
    clicksInCurrentBeat = 0
}
```

### 3. ContentView.swift
**Changes:**
- Added `showSubdivisionPicker: Bool` state
- Added subdivision button next to signature control
- Button displays "♩" for subdivision = 1
- Button displays "♩ ×2", "♩ ×3", "♩ ×4" for subdivisions 2-4
- Added `.sheet` modifier for subdivision picker
- Created `SubdivisionPickerView` component
- Created `SubdivisionPresetButton` component

**UI Layout:**
```
[Signature Button] [Subdivision Button]
    [4/4 ▼]            [♩ ×2 ▼]
```

## Subdivision Picker UI

### SubdivisionPickerView
- Full-screen modal sheet (same style as signature picker)
- Large display showing current selection (♩ or ♩ ×N)
- Wheel picker with values: 1, 2, 3, 4
- Descriptive text explaining each option:
  - 1: "One click per beat"
  - 2: "Two clicks per beat (eighth notes)"
  - 3: "Three clicks per beat (triplets)"
  - 4: "Four clicks per beat (sixteenth notes)"
- Quick preset buttons for fast selection
- Cancel and Apply buttons

### Visual Design
- Matches existing app dark theme
- Uses quarter note symbol (♩) as icon
- Consistent with signature picker styling
- Clear, intuitive labels

## Integration with Existing Features

### Beat Blocks (Unchanged)
- Number of blocks = signature numerator (unchanged)
- Each block still shows 3 horizontal bars (unchanged)
- Block highlighting advances once per beat (unchanged)
- Subdivision affects ONLY audio click timing

### Signature Changes
- Signature and subdivision work independently
- Both can be changed while metronome is running
- Engine restarts cleanly when either changes
- Smart beat position remapping preserved

### Audio Timing
- Subdivision = 1: Original behavior (1 click per beat)
- Subdivision = 2: 2 clicks per beat (interval halved)
- Subdivision = 3: 3 clicks per beat (triplet feel)
- Subdivision = 4: 4 clicks per beat (interval quartered)

## Verification Examples

### Example 1: 4/4 time, 120 BPM, subdivision = 1
- Beat duration: 0.5s
- Click interval: 0.5s
- 4 blocks visible
- Active block advances every 0.5s (every click)
- **Result:** Identical to original app behavior

### Example 2: 4/4 time, 120 BPM, subdivision = 2
- Beat duration: 0.5s
- Click interval: 0.25s (half the beat)
- 4 blocks visible
- Active block advances every 0.5s (every 2 clicks)
- **Result:** 2 clicks per beat, block changes every 2 clicks

### Example 3: 3/4 time, 90 BPM, subdivision = 3
- Beat duration: 0.667s
- Click interval: 0.222s (one-third of beat)
- 3 blocks visible
- Active block advances every 0.667s (every 3 clicks)
- **Result:** Triplet feel with 3 clicks per beat

### Example 4: 5/4 time, 100 BPM, subdivision = 4
- Beat duration: 0.6s
- Click interval: 0.15s (one-quarter of beat)
- 5 blocks visible
- Active block advances every 0.6s (every 4 clicks)
- **Result:** Sixteenth note subdivision with 4 clicks per beat

## Implementation Notes

### Clean Separation of Concerns
- **MetronomeEngine**: Handles raw click timing only, no UI knowledge
- **MetronomeViewModel**: Manages state, bridges UI and engine
- **ContentView**: Pure presentation, receives beat index updates

### Beat vs. Click Distinction
- **Beat**: Musical unit defined by signature and BPM
- **Click**: Audio event that occurs `subdivision` times per beat
- UI tracks beats, not individual clicks
- Block highlighting synchronized to beats, not clicks

### Performance
- No impact on existing timing precision
- Subdivision increases click frequency but maintains drift-free audio
- UI updates remain once per beat (no additional overhead)

## Testing Checklist

- ✅ Subdivision = 1: Identical to original behavior
- ✅ Subdivision = 2: Two clicks per beat, block advances every 2 clicks
- ✅ Subdivision = 3: Three clicks per beat, block advances every 3 clicks
- ✅ Subdivision = 4: Four clicks per beat, block advances every 4 clicks
- ✅ Signature changes work correctly with subdivision
- ✅ Block UI unchanged (still shows signature.numerator blocks)
- ✅ Each block still contains 3 visual bars
- ✅ Changing subdivision while playing restarts smoothly
- ✅ Beat highlighting remains synchronized
- ✅ BPM changes work correctly with subdivision
- ✅ Sound switching works with subdivision active
