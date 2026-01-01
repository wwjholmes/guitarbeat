# Sound Pairs Testing Plan

## Pre-Test Setup

### ✅ Verify Audio Files in Bundle
- [ ] `select-button-sfx.wav` exists in project
- [ ] `fish_bowl_sound.wav` exists in project
- [ ] Both files are added to target (check Target Membership)

## Feature Tests

### Test 1: Sound Picker UI
- [ ] Open sound picker (tap waveform icon)
- [ ] Verify only 4 options appear (not 8)
- [ ] Options displayed:
  - [ ] "Select Button / Fish Bowl"
  - [ ] "Cowbell / Kick Drum"
  - [ ] "Rim Click / Wood Block"
  - [ ] "Snare / Classic Click"
- [ ] Each option shows description explaining HIGH/LOW usage
- [ ] Current selection shows checkmark

### Test 2: Default Sound on Launch
- [ ] App launches with "Select Button / Fish Bowl" selected
- [ ] Sound name displays correctly below title
- [ ] No crashes or errors in console

### Test 3: Select Button / Fish Bowl Pair (Audio Files)
**4/4 Time Signature:**
- [ ] Start metronome at 80 BPM
- [ ] Beat 1: Hear "Select Button" (sharp, modern click)
- [ ] Beat 2: Hear "Fish Bowl" (resonant water tone)
- [ ] Beat 3: Hear "Fish Bowl"
- [ ] Beat 4: Hear "Fish Bowl"
- [ ] Pattern repeats correctly
- [ ] Visual indicator highlights correct beat

**3/4 Time Signature:**
- [ ] Beat 1: Select Button (HIGH)
- [ ] Beat 2: Fish Bowl (LOW)
- [ ] Beat 3: Fish Bowl (LOW)

**2/4 Time Signature:**
- [ ] Beat 1: Select Button (HIGH)
- [ ] Beat 2: Fish Bowl (LOW)

**1/4 Time Signature:**
- [ ] Beat 1: Select Button (HIGH) only
- [ ] Repeats correctly
- [ ] **This is the critical test for the 1/4 fix!**

### Test 4: Cowbell / Kick Drum Pair (Generated)
**4/4 Time Signature:**
- [ ] Beat 1: Cowbell (bright, metallic, ~150ms)
- [ ] Beat 2: Kick Drum (deep, low frequency)
- [ ] Beat 3: Kick Drum
- [ ] Beat 4: Kick Drum
- [ ] Distinct difference between HIGH and LOW

**1/4 Time Signature:**
- [ ] Cowbell plays on every beat

### Test 5: Rim Click / Wood Block Pair (Generated)
**4/4 Time Signature:**
- [ ] Beat 1: Rim Click (sharp, metallic)
- [ ] Beat 2: Wood Block (high-pitched, woody)
- [ ] Beat 3: Wood Block
- [ ] Beat 4: Wood Block

**1/4 Time Signature:**
- [ ] Rim Click plays on every beat

### Test 6: Snare / Classic Click Pair (Generated)
**4/4 Time Signature:**
- [ ] Beat 1: Snare (crisp with snare wires)
- [ ] Beat 2: Classic Click (simple sine wave)
- [ ] Beat 3: Classic Click
- [ ] Beat 4: Classic Click

**1/4 Time Signature:**
- [ ] Snare plays on every beat

### Test 7: Sound Switching While Playing
- [ ] Start metronome with "Select Button / Fish Bowl"
- [ ] While playing, switch to "Cowbell / Kick Drum"
- [ ] Sound changes immediately (within 1 beat)
- [ ] No audio glitches or pops
- [ ] No crashes
- [ ] Repeat for all pairs

### Test 8: BPM Variation
For each pair:
- [ ] Test at 40 BPM (slow) - sounds don't overlap
- [ ] Test at 120 BPM (medium) - clear separation
- [ ] Test at 208 BPM (fast) - no audio artifacts
- [ ] Test at 240 BPM (maximum) - still works

### Test 9: Volume Control
- [ ] Increase volume - both HIGH and LOW sounds get louder
- [ ] Decrease volume - both sounds get quieter
- [ ] Volume balance between HIGH and LOW is reasonable
- [ ] No clipping or distortion at max volume

### Test 10: Audio Session Interruptions
- [ ] Start metronome
- [ ] Receive phone call - audio pauses
- [ ] End call - can resume metronome
- [ ] Play/pause music in another app - metronome handles correctly

### Test 11: Console Output Verification
Check console logs:
- [ ] "✅ Loaded audio file: select-button-sfx.wav into accent buffer"
- [ ] "✅ Loaded audio file: fish_bowl_sound.wav into click buffer"
- [ ] No "❌ Failed to find audio file" errors
- [ ] Beat scheduling logs show correct HIGH/LOW pattern
- [ ] No crashes or exceptions

### Test 12: Time Signature Changes While Playing
- [ ] Start in 4/4 with any pair
- [ ] Switch to 3/4 - pattern adjusts correctly
- [ ] Switch to 2/4 - pattern adjusts correctly
- [ ] Switch to 1/4 - HIGH sound plays continuously
- [ ] Switch back to 4/4 - pattern returns to HIGH-LOW-LOW-LOW

## Edge Cases

### Test 13: Missing Audio Files
- [ ] Temporarily remove `fish_bowl_sound.wav` from bundle
- [ ] Select "Select Button / Fish Bowl"
- [ ] Verify fallback sound is used
- [ ] Console shows: "⚠️ Using fallback classic click sound"
- [ ] No crash

### Test 14: Rapid Sound Switching
- [ ] Start metronome
- [ ] Quickly switch between all 4 pairs
- [ ] No audio glitches
- [ ] No memory leaks
- [ ] App remains responsive

### Test 15: Background/Foreground
- [ ] Start metronome
- [ ] Send app to background
- [ ] Audio continues playing
- [ ] Bring app to foreground
- [ ] Visual indicator still synced with audio

## Performance Tests

### Test 16: CPU Usage
- [ ] Start metronome at 120 BPM
- [ ] Monitor CPU usage in Xcode Instruments
- [ ] Should be < 5% CPU on modern devices
- [ ] No memory leaks

### Test 17: Audio Latency
- [ ] Start metronome at 120 BPM
- [ ] Visual indicator should be perfectly synced with audio
- [ ] No drift over 5 minutes of playback
- [ ] HIGH and LOW sounds are rhythmically precise

## Regression Tests

### Test 18: Existing Features Still Work
- [ ] BPM slider works correctly
- [ ] Start/Stop button works
- [ ] Visual beat indicator animates correctly
- [ ] Time signature selector works
- [ ] All UI elements responsive

## Sign-Off

| Test Category | Status | Notes |
|--------------|--------|-------|
| Audio File Loading | ☐ Pass / ☐ Fail | |
| Sound Pair Logic | ☐ Pass / ☐ Fail | |
| 1/4 Time Fix | ☐ Pass / ☐ Fail | |
| UI Display | ☐ Pass / ☐ Fail | |
| Sound Switching | ☐ Pass / ☐ Fail | |
| Performance | ☐ Pass / ☐ Fail | |

**Tester:** _____________  
**Date:** _____________  
**Device/OS:** _____________  

## Known Issues to Watch For

1. **Volume imbalance**: HIGH and LOW sounds might have different perceived loudness
   - Solution: May need to normalize audio levels

2. **Audio file format issues**: WAV files might need specific format
   - Solution: Ensure 44.1kHz, 16-bit PCM, mono or stereo

3. **Timing drift**: At very high BPMs, scheduling might drift
   - Solution: Already handled by sample-accurate scheduling

4. **Memory pressure**: Loading multiple audio files
   - Solution: Files are small, should be fine

## Success Criteria

✅ All 4 pairs produce distinct HIGH/LOW sounds  
✅ 1/4 time plays HIGH sound only (not silent)  
✅ Sound switching works while playing  
✅ No audio glitches or crashes  
✅ Visual indicator synced with audio  
✅ Performance is acceptable (< 5% CPU)  
