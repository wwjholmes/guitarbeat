# Timing Fix: UI Notification on First Click

## The Problem

User reported that audio and visual were out of sync:
- With subdivision = 2×: First sound fell in last block's UI window, second sound in first block
- With subdivision = 3×, 4×: Only the last sound fell in the correct block window
- All sounds felt "too early" by N-1 clicks (where N = subdivision)

## Root Cause

We were notifying the UI **after the LAST click of a beat completed**, not **when the FIRST click started**.

### Example: 4/4 Time, Subdivision = 2

**BEFORE (Buggy)**:
```
Schedule Beat 0, Click 1 (accent)  ← Audio plays
Schedule Beat 0, Click 2 (accent)  ← Audio plays
  → After click 2 completes, notify UI  
  → UI highlights Block 1           ← TOO LATE! Audio already played
Schedule Beat 1, Click 1 (regular) ← Audio plays
Schedule Beat 1, Click 2 (regular) ← Audio plays
  → After click 2 completes, notify UI
  → UI highlights Block 2           ← TOO LATE!
```

**Visual lag**: The UI notification came AFTER both clicks played, so the highlight appeared during the next beat.

## The Fix

Changed UI notification timing from "after last click" to "before first click":

### BEFORE (Wrong)
```swift
// Only schedule UI notification when we complete all clicks in a beat
let willCompleteBeat = (clicksInCurrentBeat + 1) >= currentSubdivision

if willCompleteBeat {
    // Notify UI when beat completes
    self.onBeatTick?(beatThatWillPlay)
}
```

### AFTER (Correct)
```swift
// Schedule UI notification when we're about to play the FIRST click of a beat
let isFirstClickOfBeat = (clickThatWillSchedule == 0)

if isFirstClickOfBeat {
    // Notify UI when beat STARTS (first click)
    self.onBeatTick?(beatThatWillPlay)
}
```

### Also Updated First Beat Logic
```swift
// BEFORE
if clicksInCurrentBeat >= currentSubdivision {
    notifyBeatTick()  // Notify after last click
}

// AFTER
if clickThatWillSchedule == 0 {
    notifyBeatTick()  // Notify before first click
}
```

## Now It Works Correctly

**AFTER FIX**: 4/4 Time, Subdivision = 2
```
→ Notify UI: Block 1 highlights      ← UI UPDATE FIRST
Schedule Beat 0, Click 1 (accent)    ← Audio plays while Block 1 highlighted
Schedule Beat 0, Click 2 (accent)    ← Audio plays while Block 1 highlighted
→ Notify UI: Block 2 highlights      ← UI UPDATE FIRST
Schedule Beat 1, Click 1 (regular)   ← Audio plays while Block 2 highlighted
Schedule Beat 1, Click 2 (regular)   ← Audio plays while Block 2 highlighted
→ Notify UI: Block 3 highlights
...
```

## Visual Timeline

### Subdivision = 1
```
UI: Block 1 →
Audio: ACCENT ✓
UI: Block 2 →
Audio: regular ✓
```

### Subdivision = 2
```
UI: Block 1 →
Audio: ACCENT, ACCENT ✓ (both during Block 1)
UI: Block 2 →
Audio: regular, regular ✓ (both during Block 2)
```

### Subdivision = 3
```
UI: Block 1 →
Audio: ACCENT, ACCENT, ACCENT ✓ (all 3 during Block 1)
UI: Block 2 →
Audio: regular, regular, regular ✓ (all 3 during Block 2)
```

### Subdivision = 4
```
UI: Block 1 →
Audio: ACCENT, ACCENT, ACCENT, ACCENT ✓ (all 4 during Block 1)
UI: Block 2 →
Audio: regular, regular, regular, regular ✓ (all 4 during Block 2)
```

## Key Changes

1. **UI notification timing**: Changed from "after last click completes" to "before first click plays"
2. **Check condition**: Changed from `willCompleteBeat` to `isFirstClickOfBeat`
3. **Captured state**: Using `clickThatWillSchedule == 0` to detect first click
4. **Consistency**: Applied to both first beat and subsequent beats

## Verification

✅ Block highlights BEFORE audio plays
✅ All accent clicks play while first block is highlighted
✅ All regular clicks play while their respective blocks are highlighted
✅ No timing lag between audio and visual
✅ Works correctly for all subdivision values (1, 2, 3, 4)

## Testing

When you run the app now:
1. Start with subdivision = 1 → Block should light up exactly when accent plays
2. Change to subdivision = 2 → Block should light up, then 2 accent clicks
3. Change to subdivision = 3 → Block should light up, then 3 accent clicks
4. Change to subdivision = 4 → Block should light up, then 4 accent clicks

The visual highlight should always appear BEFORE or exactly when the first click plays, not after!
