# Subdivision Feature - Complete & Accurate Documentation

**Status:** ✅ Fully Implemented and Working  
**Last Updated:** January 18, 2026  
**Version:** 1.2 (Timing Fix Applied)

---

## Table of Contents
1. [Overview](#overview)
2. [Implementation Details](#implementation-details)
3. [How It Works](#how-it-works)
4. [Testing & Verification](#testing--verification)
5. [Known Issues](#known-issues)

---

## Overview

The Subdivision feature allows users to control how many audio clicks occur per beat, enabling practice with different note values (quarter notes, eighth notes, triplets, sixteenth notes).

### Key Characteristics
- **Range:** 1-4 clicks per beat
- **Default:** 1 (quarter notes)
- **Affects:** Audio timing ONLY
- **Does NOT affect:** Block count, block structure, or visual layout

### User Interface
- Button next to Signature control
- Displays: "♩" for subdivision=1, "♩ ×N" for subdivision=2/3/4
- Tapping opens a picker with values 1-4
- Includes quick preset buttons

---

## Implementation Details

### Modified Files

#### 1. MetronomeViewModel.swift
```swift
@Published var subdivision: Int = 1 {
    didSet {
        engine.setSubdivision(subdivision)
    }
}
```

**What it does:**
- Adds subdivision state management
- Binds to UI controls
- Passes changes to engine

#### 2. MetronomeEngine.swift

**New Properties:**
```swift
private var currentSubdivision: Int = 1
private var clicksInCurrentBeat: Int = 0
```

**New Method:**
```swift
func setSubdivision(_ subdivision: Int) {
    let validSubdivision = min(max(subdivision, 1), 4)
    currentSubdivision = validSubdivision
    clicksInCurrentBeat = 0
    // Restarts if running
}
```

**Modified Logic:**

1. **Accent Sound Selection:**
```swift
// Accent ALL clicks of beat 0
let isAccentBeat = (beatThatWillSchedule == 0)
let buffer = isAccentBeat ? (accentBuffer ?? clickBuffer) : clickBuffer
```

2. **Click Interval Calculation:**
```swift
let beatIntervalSeconds = currentSignature.intervalSeconds(at: currentBPM)
let clickIntervalSeconds = beatIntervalSeconds / Double(currentSubdivision)
```

3. **UI Notification (CRITICAL - Timing Fix):**
```swift
// Notify BEFORE first click plays, not after last click
let isFirstClickOfBeat = (clickThatWillSchedule == 0)

if isFirstClickOfBeat {
    self.onBeatTick?(beatThatWillPlay)  // Highlight block NOW
}
```

4. **Beat Advancement:**
```swift
clicksInCurrentBeat += 1

if clicksInCurrentBeat >= currentSubdivision {
    currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
    clicksInCurrentBeat = 0
}
```

5. **State Capture (Bug Prevention):**
```swift
// Capture state BEFORE modifications
let beatThatWillSchedule = currentBeatInPattern
let clickThatWillSchedule = clicksInCurrentBeat
```

#### 3. ContentView.swift

**New UI Components:**
- `showSubdivisionPicker: Bool` state
- Subdivision button (displays ♩ or ♩ ×N)
- `SubdivisionPickerView` (full-screen modal)
- `SubdivisionPresetButton` (quick selection)

**Picker Features:**
- Wheel picker with values 1-4
- Descriptive labels for each value
- Cancel/Apply buttons
- Preset buttons for quick access

---

## How It Works

### Audio Timing

#### Subdivision = 1 (Quarter Notes)
```
Beat 0: ACCENT        (block 1 highlights)
Beat 1: regular       (block 2 highlights)
Beat 2: regular       (block 3 highlights)
Beat 3: regular       (block 4 highlights)
[REPEAT]
```
- 4 clicks per cycle (4/4 time)
- 1 accent per cycle

#### Subdivision = 2 (Eighth Notes)
```
Beat 0: ACCENT, ACCENT     (block 1 highlights during both)
Beat 1: regular, regular   (block 2 highlights during both)
Beat 2: regular, regular   (block 3 highlights during both)
Beat 3: regular, regular   (block 4 highlights during both)
[REPEAT]
```
- 8 clicks per cycle (4/4 time)
- 2 accents per cycle (both during first block)

#### Subdivision = 3 (Triplets)
```
Beat 0: ACCENT × 3    (block 1 highlights during all 3)
Beat 1: regular × 3   (block 2 highlights during all 3)
Beat 2: regular × 3   (block 3 highlights during all 3)
Beat 3: regular × 3   (block 4 highlights during all 3)
[REPEAT]
```
- 12 clicks per cycle (4/4 time)
- 3 accents per cycle (all during first block)

#### Subdivision = 4 (Sixteenth Notes)
```
Beat 0: ACCENT × 4    (block 1 highlights during all 4)
Beat 1: regular × 4   (block 2 highlights during all 4)
Beat 2: regular × 4   (block 3 highlights during all 4)
Beat 3: regular × 4   (block 4 highlights during all 4)
[REPEAT]
```
- 16 clicks per cycle (4/4 time)
- 4 accents per cycle (all during first block)

### Visual Synchronization

**Critical Timing:**
1. ✅ Block highlights **BEFORE** first click plays
2. ✅ Block stays highlighted during **ALL** subdivision clicks
3. ✅ Block advances **AFTER** all clicks complete

**Why This Matters:**
- Users see the block light up, then hear the clicks
- Perfect audio/visual sync
- No lag or "too early" feeling

### Accent Sound Rule

**IMPORTANT:** Accent sound plays on **ALL** clicks of beat 0, not just the first click.

**Examples:**
- Subdivision = 2: You hear **2 high-pitched clicks** when block 1 is highlighted
- Subdivision = 3: You hear **3 high-pitched clicks** when block 1 is highlighted
- Subdivision = 4: You hear **4 high-pitched clicks** when block 1 is highlighted

### Timing Calculation

Given:
- BPM = 120
- Signature = 4/4
- Subdivision = 3

Calculations:
```
Beat duration = 60 / 120 = 0.5 seconds
Click interval = 0.5 / 3 = 0.167 seconds
Clicks per cycle = 4 beats × 3 clicks = 12 clicks
Cycle duration = 4 × 0.5 = 2 seconds
```

---

## Testing & Verification

### Test Case 1: Default Behavior (Subdivision = 1)
**Setup:** 4/4 time, 120 BPM, subdivision = 1

**Expected:**
- 1 click every 0.5 seconds
- 1 accent per cycle (4 clicks total)
- Block advances every click
- Identical to original app behavior

**Verify:**
- ✅ Accent on beat 0 only
- ✅ Regular sound on beats 1, 2, 3
- ✅ 4 blocks visible
- ✅ No timing issues

### Test Case 2: Eighth Notes (Subdivision = 2)
**Setup:** 4/4 time, 120 BPM, subdivision = 2

**Expected:**
- 2 clicks every 0.5 seconds (1 click every 0.25s)
- 2 accents per cycle (8 clicks total)
- Block advances every 2 clicks

**Verify:**
- ✅ 2 high-pitched clicks during block 1
- ✅ 2 low-pitched clicks during blocks 2, 3, 4
- ✅ Block highlights before first click
- ✅ No visual lag

### Test Case 3: Triplets (Subdivision = 3)
**Setup:** 3/4 time, 90 BPM, subdivision = 3

**Expected:**
- 3 clicks every 0.667 seconds
- 3 accents per cycle (9 clicks total)
- 3 blocks visible

**Verify:**
- ✅ 3 high-pitched clicks during block 1
- ✅ 3 low-pitched clicks during blocks 2, 3
- ✅ Triplet feel (1-2-3, 1-2-3, 1-2-3)
- ✅ Perfect timing

### Test Case 4: Sixteenth Notes (Subdivision = 4)
**Setup:** 4/4 time, 60 BPM, subdivision = 4

**Expected:**
- 4 clicks every 1 second
- 4 accents per cycle (16 clicks total)
- Fast subdivision feel

**Verify:**
- ✅ 4 high-pitched clicks during block 1
- ✅ 4 low-pitched clicks during blocks 2, 3, 4
- ✅ All clicks evenly spaced
- ✅ Block timing correct

### Test Case 5: Integration Tests

**Changing Subdivision While Playing:**
- ✅ Smoothly restarts with new subdivision
- ✅ Maintains beat position
- ✅ No audio glitches

**Changing Signature With Subdivision:**
- ✅ Both settings work independently
- ✅ Block count updates correctly
- ✅ Clicks per beat unchanged

**Changing BPM With Subdivision:**
- ✅ Click timing updates correctly
- ✅ Subdivision ratio maintained
- ✅ No drift

**Changing Sound With Subdivision:**
- ✅ New sounds apply immediately
- ✅ Accent/regular distinction preserved
- ✅ No audio artifacts

### Console Log Verification

**Subdivision = 2 (Expected Output):**
```
🎵 Scheduling first click immediately (beat 0, click 1/2, accent: true)
⏱️ Beat 0 click 2/2: ... accent: true
⏱️ Beat 1 click 1/2: ... accent: false
⏱️ Beat 1 click 2/2: ... accent: false
⏱️ Beat 2 click 1/2: ... accent: false
⏱️ Beat 2 click 2/2: ... accent: false
⏱️ Beat 3 click 1/2: ... accent: false
⏱️ Beat 3 click 2/2: ... accent: false
⏱️ Beat 0 click 1/2: ... accent: true
⏱️ Beat 0 click 2/2: ... accent: true
```

**Key Observations:**
- `accent: true` appears ONLY for beat 0
- `accent: true` appears for EVERY click of beat 0
- `accent: false` for all other beats

---

## Known Issues

### None! ✅

All major issues have been resolved:
- ✅ Accent sound plays correct number of times
- ✅ Accent sound plays at correct time (synchronized with block)
- ✅ UI notification timing fixed (no lag)
- ✅ State capture prevents timing bugs
- ✅ Works with all signatures, BPMs, and sounds

---

## Summary

The Subdivision feature is **fully implemented and working correctly**. Key points:

1. **Accent Rule:** ALL clicks of beat 0 use high-pitched sound
2. **Timing:** UI highlights BEFORE clicks play (perfect sync)
3. **Beat Logic:** Advances after all subdivision clicks complete
4. **Integration:** Works seamlessly with signatures, BPM, sounds
5. **Performance:** No audio glitches, no timing drift

**Status:** Ready for production! 🎉
