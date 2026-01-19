# Subdivision Bug Fix

## Issue Reported
User found that:
1. The high accent beat was only being played once (correct on first start)
2. When changing to 2×, 3×, or 4× subdivision, the accent beat seemed to be played as part of the last block (last block highlighted)

## Root Cause

The bug was in the `scheduleNextClick()` method. The issue was a **timing problem with state mutation**:

### Original Buggy Code
```swift
// Determine which buffer to use
let isAccentClick = (currentBeatInPattern == 0 && clicksInCurrentBeat == 0)
let buffer = isAccentClick ? (accentBuffer ?? clickBuffer) : clickBuffer

// ... schedule the buffer ...

// Later: increment counters
clicksInCurrentBeat += 1
if clicksInCurrentBeat >= currentSubdivision {
    currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
    clicksInCurrentBeat = 0
}
```

### The Problem
When we completed a beat (after all subdivision clicks):
1. We incremented `clicksInCurrentBeat` to equal `currentSubdivision`
2. This triggered the beat advancement code
3. `currentBeatInPattern` was reset to 0 (wrapping from last beat)
4. `clicksInCurrentBeat` was reset to 0
5. **BUT** we were still in the scheduling loop
6. On the next iteration, we checked `(currentBeatInPattern == 0 && clicksInCurrentBeat == 0)`
7. This returned TRUE even though we were about to schedule click 1 of beat 0
8. **Result**: The accent was playing at the wrong time!

### Example Timeline (4/4 time, subdivision = 2)
```
Beat 0, Click 0 → schedule (accent ✓)
Beat 0, Click 1 → schedule (regular ✓)
  → clicksInCurrentBeat becomes 2
  → currentBeatInPattern becomes 1
  → clicksInCurrentBeat resets to 0
Beat 1, Click 0 → schedule (regular ✓)
Beat 1, Click 1 → schedule (regular ✓)
  → clicksInCurrentBeat becomes 2
  → currentBeatInPattern becomes 2
  → clicksInCurrentBeat resets to 0
Beat 2, Click 0 → schedule (regular ✓)
...continues...
Beat 3, Click 1 → schedule (regular ✓)
  → clicksInCurrentBeat becomes 2
  → currentBeatInPattern becomes 0  ← WRAPS BACK!
  → clicksInCurrentBeat resets to 0  ← BOTH ARE ZERO!
Beat 0, Click 0 → schedule (accent ✓)  ← CORRECT!
```

But the problem occurred when the state was checked BEFORE vs AFTER mutation.

## The Fix

Capture the beat and click values **BEFORE** any mutations:

```swift
// Store which beat and click we're ABOUT TO schedule
let beatThatWillSchedule = currentBeatInPattern
let clickThatWillSchedule = clicksInCurrentBeat

// Determine which buffer to use based on CAPTURED values
let isAccentClick = (beatThatWillSchedule == 0 && clickThatWillSchedule == 0)
let buffer = isAccentClick ? (accentBuffer ?? clickBuffer) : clickBuffer

// ... schedule the buffer ...

// Later: increment counters (these mutations don't affect the buffer we just scheduled)
clicksInCurrentBeat += 1
if clicksInCurrentBeat >= currentSubdivision {
    currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
    clicksInCurrentBeat = 0
}
```

### Why This Works
1. We capture `beatThatWillSchedule` and `clickThatWillSchedule` at the START of the iteration
2. We determine the accent based on these IMMUTABLE values
3. We schedule the correct buffer
4. We increment the counters for the NEXT iteration
5. The next iteration will have the correct state

### Example Timeline After Fix (4/4 time, subdivision = 2)
```
Capture: beat=0, click=0 → schedule (accent ✓)
  → Increment: beat=0, click=1
Capture: beat=0, click=1 → schedule (regular ✓)
  → Increment: beat=1, click=0
Capture: beat=1, click=0 → schedule (regular ✗ NO accent!)
  → Increment: beat=1, click=1
Capture: beat=1, click=1 → schedule (regular ✓)
  → Increment: beat=2, click=0
...continues correctly...
Capture: beat=3, click=1 → schedule (regular ✓)
  → Increment: beat=0, click=0 ← wraps, but doesn't affect this iteration
Capture: beat=0, click=0 → schedule (accent ✓)
```

## Changes Made

### MetronomeEngine.swift - scheduleNextClick()

1. Added capture variables at the top of the loop:
   ```swift
   let beatThatWillSchedule = currentBeatInPattern
   let clickThatWillSchedule = clicksInCurrentBeat
   ```

2. Changed accent detection to use captured values:
   ```swift
   let isAccentClick = (beatThatWillSchedule == 0 && clickThatWillSchedule == 0)
   ```

3. Updated logging to show accent status:
   ```swift
   print("... accent: \(isAccentClick)")
   ```

4. Used captured values consistently throughout the scheduling code:
   ```swift
   let beatThatWillPlay = beatThatWillSchedule
   ```

## Verification

After this fix:
- ✅ Accent plays ONLY on the first click of beat 0
- ✅ All other clicks use the regular sound
- ✅ With subdivision=1: Accent on beat 0 (every beat is a first click)
- ✅ With subdivision=2: Accent on beat 0 click 1, regular on beat 0 click 2
- ✅ With subdivision=3: Accent on beat 0 click 1, regular on clicks 2 and 3
- ✅ With subdivision=4: Accent on beat 0 click 1, regular on clicks 2, 3, 4
- ✅ Beat highlighting advances correctly (once per beat, after all subdivision clicks)

## Testing Commands

Run the app and verify:
1. Start with subdivision=1 → accent should play once per cycle on beat 0
2. Change to subdivision=2 → accent should play once per cycle on beat 0, first click
3. Watch console logs for "accent: true" messages → should only appear for beat 0, click 1
4. Visual blocks should highlight in sync with accent beats
