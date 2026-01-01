# Sound Pairs Feature

## Overview

Implemented HIGH/LOW sound pairs for improved rhythmic clarity. Beat 1 (downbeat) plays the HIGH sound, while beats 2, 3, 4 play the LOW sound.

## Changes Made

### 1. Restructured `BeatSound` Enum
- Changed from 8 individual sounds to **4 sound pairs**
- Each pair has a HIGH sound (downbeat) and LOW sound (other beats)

**The 4 Pairs:**
1. **"Select Button / Fish Bowl"**
   - HIGH: `select-button-sfx.wav` (audio file)
   - LOW: `fish_bowl_sound.wav` (audio file)

2. **"Cowbell / Kick Drum"**
   - HIGH: Cowbell (generated, 150ms)
   - LOW: Kick Drum (generated, 80ms)

3. **"Rim Click / Wood Block"**
   - HIGH: Rim Click (generated, 30ms)
   - LOW: Wood Block (generated, 25ms)

4. **"Snare / Classic Click"**
   - HIGH: Snare (generated, 60ms)
   - LOW: Classic Click (generated, 15ms)

### 2. Updated `generateClickSound(for:)` Method
- Now generates the **LOW sound** (beats 2, 3, 4)
- For `.selectButtonFishBowl`: Loads `fish_bowl_sound.wav`
- For other pairs: Generates the second sound in the pair name
- Stores result in `clickBuffer`

### 3. Updated `generateAccentSound(for:)` Method
- Now generates the **HIGH sound** (beat 1)
- For `.selectButtonFishBowl`: Loads `select-button-sfx.wav`
- For other pairs: Generates the first sound in the pair name
- Stores result in `accentBuffer`
- **Removed** volume boost and ping effects (pairs use genuinely different sounds)

### 4. Enhanced `loadAudioFile()` Method
- Added `isAccent` parameter (default: `false`)
- When `isAccent = true`: Loads into `accentBuffer`
- When `isAccent = false`: Loads into `clickBuffer`
- Supports loading two different audio files for a single pair

### 5. Updated `generateFallbackClickSound()` Method
- Added `isAccent` parameter
- Stores fallback sound in appropriate buffer

### 6. Fixed 1/4 Time Signature Handling
- **Old logic**: `let isAccentBeat = (currentBeatInPattern == 0) && (currentSignature.numerator > 1)`
- **New logic**: `let isAccentBeat = (currentBeatInPattern == 0)`
- Now correctly plays HIGH sound even in 1/4 time

### 7. Updated Default Sound
- Changed from: `.selectButton`
- To: `.selectButtonFishBowl`

## How It Works

### Beat Scheduling Logic
```
Beat 1 (position 0):  accentBuffer (HIGH sound) → Select Button, Cowbell, Rim Click, or Snare
Beat 2 (position 1):  clickBuffer (LOW sound)    → Fish Bowl, Kick Drum, Wood Block, or Classic Click
Beat 3 (position 2):  clickBuffer (LOW sound)    → Fish Bowl, Kick Drum, Wood Block, or Classic Click
Beat 4 (position 3):  clickBuffer (LOW sound)    → Fish Bowl, Kick Drum, Wood Block, or Classic Click
```

### Example: 4/4 Time with "Select Button / Fish Bowl"
- Beat 1: 🔊 **Select Button** (high)
- Beat 2: 🔉 Fish Bowl (low)
- Beat 3: 🔉 Fish Bowl (low)
- Beat 4: 🔉 Fish Bowl (low)
- (repeat)

### Example: 3/4 Time with "Cowbell / Kick Drum"
- Beat 1: 🔊 **Cowbell** (high)
- Beat 2: 🔉 Kick Drum (low)
- Beat 3: 🔉 Kick Drum (low)
- (repeat)

### Example: 1/4 Time with Any Pair
- Beat 1: 🔊 **HIGH sound only** (repeat)

## User Experience

- Sound picker now shows 4 pairs instead of 8 individual sounds
- Each option shows both sound names: "Sound A / Sound B"
- Description explains the pairing: "Sound A for downbeat, Sound B for other beats"
- Clearer rhythmic emphasis with distinct HIGH/LOW sounds
- Immediate sound switching while metronome is running

## Technical Benefits

✅ Clearer musical rhythm with distinct downbeat  
✅ More expressive and musical metronome experience  
✅ Simplified UI (4 options vs 8)  
✅ Proper handling of 1/4 time signatures  
✅ Supports mixing audio files and generated sounds  
✅ No volume boost needed - sounds are genuinely different  

## Testing Checklist

- [x] Enum restructured to 4 pairs
- [x] `generateClickSound()` generates LOW sounds
- [x] `generateAccentSound()` generates HIGH sounds
- [x] Audio file loading supports both buffers
- [x] 1/4 time uses HIGH sound correctly
- [x] Default sound updated to `.selectButtonFishBowl`
- [ ] Test 4/4 time: HIGH, LOW, LOW, LOW pattern
- [ ] Test 3/4 time: HIGH, LOW, LOW pattern
- [ ] Test 2/4 time: HIGH, LOW pattern
- [ ] Test 1/4 time: HIGH only pattern
- [ ] Test all 4 pairs work correctly
- [ ] Test sound switching mid-playback
- [ ] Test audio files load correctly
- [ ] Verify UI shows 4 pairs with correct names

## Files Modified

- `MetronomeEngine.swift`
  - `BeatSound` enum (lines 10-32)
  - `currentSound` default value (line 49)
  - `generateClickSound(for:)` method (lines ~120-162)
  - `loadAudioFile(named:extension:isAccent:)` method (lines ~165-245)
  - `generateFallbackClickSound(isAccent:)` method (lines ~248-265)
  - `generateAccentSound(for:)` method (lines ~540-596)
  - Scheduling logic (line ~811)

## Next Steps

1. Build and test the app
2. Verify both audio files (`select-button-sfx.wav` and `fish_bowl_sound.wav`) are in bundle
3. Test each of the 4 pairs in different time signatures
4. Adjust volume levels if HIGH and LOW sounds are unbalanced
5. Consider adding more pairs in the future (easy to extend)
