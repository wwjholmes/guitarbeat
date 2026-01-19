# Testing Guide: Subdivision Feature

## Console Log Examples

When the app is working correctly, you should see these patterns in the console:

### Subdivision = 1 (Default, Original Behavior)
```
🎵 Scheduling first click immediately (beat 0, click 1/1, accent: true)
⏱️ Beat 0 click 1/1: ... accent: false
⏱️ Beat 1 click 1/1: ... accent: false
⏱️ Beat 2 click 1/1: ... accent: false
⏱️ Beat 3 click 1/1: ... accent: false
⏱️ Beat 0 click 1/1: ... accent: true  ← ACCENT HERE!
⏱️ Beat 1 click 1/1: ... accent: false
...
```

### Subdivision = 2 (Two Clicks Per Beat)
```
🎵 Scheduling first click immediately (beat 0, click 1/2, accent: true)
⏱️ Beat 0 click 2/2: ... accent: false  ← Same beat, second click
⏱️ Beat 1 click 1/2: ... accent: false  ← Next beat, first click
⏱️ Beat 1 click 2/2: ... accent: false  ← Same beat, second click
⏱️ Beat 2 click 1/2: ... accent: false
⏱️ Beat 2 click 2/2: ... accent: false
⏱️ Beat 3 click 1/2: ... accent: false
⏱️ Beat 3 click 2/2: ... accent: false
⏱️ Beat 0 click 1/2: ... accent: true  ← ACCENT HERE! (after all beats complete)
⏱️ Beat 0 click 2/2: ... accent: false
...
```

### Subdivision = 3 (Three Clicks Per Beat)
```
🎵 Scheduling first click immediately (beat 0, click 1/3, accent: true)
⏱️ Beat 0 click 2/3: ... accent: false
⏱️ Beat 0 click 3/3: ... accent: false
⏱️ Beat 1 click 1/3: ... accent: false
⏱️ Beat 1 click 2/3: ... accent: false
⏱️ Beat 1 click 3/3: ... accent: false
⏱️ Beat 2 click 1/3: ... accent: false
⏱️ Beat 2 click 2/3: ... accent: false
⏱️ Beat 2 click 3/3: ... accent: false
⏱️ Beat 3 click 1/3: ... accent: false
⏱️ Beat 3 click 2/3: ... accent: false
⏱️ Beat 3 click 3/3: ... accent: false
⏱️ Beat 0 click 1/3: ... accent: true  ← ACCENT HERE!
⏱️ Beat 0 click 2/3: ... accent: false
...
```

### Subdivision = 4 (Four Clicks Per Beat)
```
🎵 Scheduling first click immediately (beat 0, click 1/4, accent: true)
⏱️ Beat 0 click 2/4: ... accent: false
⏱️ Beat 0 click 3/4: ... accent: false
⏱️ Beat 0 click 4/4: ... accent: false
⏱️ Beat 1 click 1/4: ... accent: false
⏱️ Beat 1 click 2/4: ... accent: false
⏱️ Beat 1 click 3/4: ... accent: false
⏱️ Beat 1 click 4/4: ... accent: false
⏱️ Beat 2 click 1/4: ... accent: false
⏱️ Beat 2 click 2/4: ... accent: false
⏱️ Beat 2 click 3/4: ... accent: false
⏱️ Beat 2 click 4/4: ... accent: false
⏱️ Beat 3 click 1/4: ... accent: false
⏱️ Beat 3 click 2/4: ... accent: false
⏱️ Beat 3 click 3/4: ... accent: false
⏱️ Beat 3 click 4/4: ... accent: false
⏱️ Beat 0 click 1/4: ... accent: true  ← ACCENT HERE!
⏱️ Beat 0 click 2/4: ... accent: false
...
```

## Visual Verification

### Block Highlighting
Watch the purple blocks at the top of the screen:

#### Subdivision = 1
- Block highlights → moves to next block
- Each highlight = 1 click

#### Subdivision = 2
- Block highlights → (2 clicks) → moves to next block
- First click of each block should sound

#### Subdivision = 3
- Block highlights → (3 clicks) → moves to next block
- Triplet feel: 1-2-3, 1-2-3, 1-2-3...

#### Subdivision = 4
- Block highlights → (4 clicks) → moves to next block
- Fast sixteenth notes: 1-2-3-4, 1-2-3-4, 1-2-3-4...

### Accent Sound
Listen carefully:
- **First block (beat 0)**: Should have ONE higher-pitched click at the start
- **Other blocks**: All regular clicks (lower pitch)
- The accent should NOT shift positions when you change subdivision

## Test Scenarios

### Test 1: Basic Subdivision Change
1. Start metronome with subdivision = 1
2. Listen for accent on beat 0 (first block)
3. Change to subdivision = 2
4. You should hear 2 clicks per block
5. Accent should still be on first block, first click

**Expected Result**: ✅ Accent remains on first block

### Test 2: Full Cycle
1. Set to 4/4 time, subdivision = 4
2. Count: 1-2-3-4 (beat 0), 1-2-3-4 (beat 1), 1-2-3-4 (beat 2), 1-2-3-4 (beat 3)
3. On the first "1" of the cycle, you should hear the accent
4. All other 15 clicks should be regular

**Expected Result**: ✅ Accent only on click 1 of beat 0

### Test 3: Signature + Subdivision
1. Set to 3/4 time, subdivision = 3
2. You should have 3 blocks (beats)
3. Each block gets 3 clicks (9 total clicks per cycle)
4. Accent should be on the first click of the first block

**Expected Result**: ✅ 3 blocks × 3 clicks = 9 clicks per cycle, accent on first

### Test 4: Stop Mid-Subdivision
1. Start with subdivision = 4
2. Stop after hearing 2 clicks (mid-beat)
3. Restart
4. Should start fresh with accent on beat 0

**Expected Result**: ✅ Clean restart with accent

### Test 5: BPM Change with Subdivision
1. Set subdivision = 3
2. Set BPM to 60
3. Each beat = 1 second
4. Each click = 1/3 second
5. Change BPM to 120
6. Each beat = 0.5 seconds
7. Each click = 1/6 second

**Expected Result**: ✅ Clicks get faster, pattern stays correct

## What to Report

If you find issues, please note:
1. **Subdivision value** when the issue occurs
2. **Signature** (e.g., 4/4, 3/4)
3. **What you heard** (e.g., "accent on wrong beat")
4. **What you saw** (e.g., "wrong block highlighted")
5. **Console logs** around the issue

## Success Criteria

✅ **Audio**: Accent plays only on first click of beat 0
✅ **Visual**: Blocks highlight once per beat (not per click)
✅ **Timing**: Clicks are evenly spaced
✅ **Integration**: Works with signature changes, BPM changes, sound changes
✅ **UI**: Subdivision button shows correct value ("♩", "♩ ×2", "♩ ×3", "♩ ×4")
