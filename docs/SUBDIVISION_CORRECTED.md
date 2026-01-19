# Subdivision Feature - Corrected Behavior

## Correct Requirement

**The accent sound (high pitch) should play on ALL clicks that occur during beat 0 (first beat).**

Examples:
- **Subdivision = 1**: 1 accent click (beat 0 has 1 click)
- **Subdivision = 2**: 2 accent clicks (beat 0 has 2 clicks)  
- **Subdivision = 3**: 3 accent clicks (beat 0 has 3 clicks)
- **Subdivision = 4**: 4 accent clicks (beat 0 has 4 clicks)

## Implementation

### Accent Logic
```swift
// Accent ALL clicks of beat 0
let isAccentBeat = (beatThatWillSchedule == 0)
let buffer = isAccentBeat ? (accentBuffer ?? clickBuffer) : clickBuffer
```

**NOT** checking individual clicks within the beat - we check the beat number only.

## Expected Behavior

### 4/4 Time, Subdivision = 1 (Default)
```
Beat 0: ACCENT → (block 1 highlights)
Beat 1: regular → (block 2 highlights)
Beat 2: regular → (block 3 highlights)
Beat 3: regular → (block 4 highlights)
Beat 0: ACCENT → (block 1 highlights)
...
```
**Result**: 1 accent per cycle

### 4/4 Time, Subdivision = 2
```
Beat 0 click 1: ACCENT → (block 1 highlights)
Beat 0 click 2: ACCENT → (block 1 still highlighted)
Beat 1 click 1: regular → (block 2 highlights)
Beat 1 click 2: regular → (block 2 still highlighted)
Beat 2 click 1: regular → (block 3 highlights)
Beat 2 click 2: regular → (block 3 still highlighted)
Beat 3 click 1: regular → (block 4 highlights)
Beat 3 click 2: regular → (block 4 still highlighted)
Beat 0 click 1: ACCENT → (block 1 highlights)
Beat 0 click 2: ACCENT → (block 1 still highlighted)
...
```
**Result**: 2 accents per cycle (both during first block highlight)

### 4/4 Time, Subdivision = 3
```
Beat 0: ACCENT, ACCENT, ACCENT → (block 1 highlights during all 3)
Beat 1: regular, regular, regular → (block 2 highlights during all 3)
Beat 2: regular, regular, regular → (block 3 highlights during all 3)
Beat 3: regular, regular, regular → (block 4 highlights during all 3)
Beat 0: ACCENT, ACCENT, ACCENT → (block 1 highlights during all 3)
...
```
**Result**: 3 accents per cycle (all during first block highlight)

### 4/4 Time, Subdivision = 4
```
Beat 0: ACCENT × 4 → (block 1 highlights during all 4 clicks)
Beat 1: regular × 4 → (block 2 highlights during all 4 clicks)
Beat 2: regular × 4 → (block 3 highlights during all 4 clicks)
Beat 3: regular × 4 → (block 4 highlights during all 4 clicks)
Beat 0: ACCENT × 4 → (block 1 highlights during all 4 clicks)
...
```
**Result**: 4 accents per cycle (all during first block highlight)

## Audio/Visual Synchronization

✅ **First block highlights** = All accent clicks play
✅ **Other blocks highlight** = All regular clicks play
✅ **Block advances** = After all subdivision clicks in that beat complete

### Example: 3/4 Time, Subdivision = 3
```
Block 1: ACCENT, ACCENT, ACCENT (3 high-pitched clicks)
Block 2: regular, regular, regular (3 low-pitched clicks)
Block 3: regular, regular, regular (3 low-pitched clicks)
Block 1: ACCENT, ACCENT, ACCENT (3 high-pitched clicks)
...
```

## Console Log Verification

### Subdivision = 2
```
🎵 Scheduling first click immediately (beat 0, click 1/2, accent: true)
⏱️ Beat 0 click 2/2: ... accent: true   ← Still beat 0, still accent!
⏱️ Beat 1 click 1/2: ... accent: false  ← Now beat 1, regular sound
⏱️ Beat 1 click 2/2: ... accent: false
⏱️ Beat 2 click 1/2: ... accent: false
⏱️ Beat 2 click 2/2: ... accent: false
⏱️ Beat 3 click 1/2: ... accent: false
⏱️ Beat 3 click 2/2: ... accent: false
⏱️ Beat 0 click 1/2: ... accent: true   ← Back to beat 0
⏱️ Beat 0 click 2/2: ... accent: true   ← Still beat 0
...
```

### Subdivision = 4
```
Beat 0 click 1/4: accent: true
Beat 0 click 2/4: accent: true
Beat 0 click 3/4: accent: true
Beat 0 click 4/4: accent: true  ← All 4 clicks have accent
Beat 1 click 1/4: accent: false
Beat 1 click 2/4: accent: false
Beat 1 click 3/4: accent: false
Beat 1 click 4/4: accent: false
...
```

## Testing Checklist

When you build and run:

✅ **Subdivision = 1**: 
- Hear 1 high-pitched click when first block highlights
- Hear 1 low-pitched click for each other block

✅ **Subdivision = 2**:
- Hear 2 high-pitched clicks when first block highlights
- Hear 2 low-pitched clicks for each other block
- First block stays highlighted for both accent clicks

✅ **Subdivision = 3**:
- Hear 3 high-pitched clicks when first block highlights
- Hear 3 low-pitched clicks for each other block
- First block stays highlighted for all 3 accent clicks

✅ **Subdivision = 4**:
- Hear 4 high-pitched clicks when first block highlights
- Hear 4 low-pitched clicks for each other block
- First block stays highlighted for all 4 accent clicks

## Key Point

**The accent sound plays for the entire duration of beat 0 (first beat), regardless of how many clicks occur within that beat.**

This means:
- More subdivision = more accent clicks per cycle
- Accent clicks are synchronized with first block highlight
- All accent clicks happen before the block advances to beat 1
