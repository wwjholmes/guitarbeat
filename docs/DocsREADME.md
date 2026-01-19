# Guitar Beat - Documentation Index

This directory contains all feature implementation documentation and planning files organized by feature.

## Directory Structure

```
Docs/
├── README.md (this file)
├── Subdivision/
│   ├── 01_FEATURE_SPEC.md
│   ├── 02_PRE_BUILD_CHECKLIST.md
│   ├── 03_CORRECTED_BEHAVIOR.md
│   ├── 04_TIMING_FIX.md
│   ├── 05_FINAL_FIX_SUMMARY.md
│   └── 06_TESTING_GUIDE.md
├── Signature/
│   ├── RHYTHMIC_SIGNATURE.md
│   └── QUICK_START_SIGNATURES.md
├── Visualization/
│   ├── BEAT_VISUALIZATION.md
│   └── VISUALIZATION_FIX.md
├── Audio/
│   ├── SOUND_PAIRS_FEATURE.md
│   └── SOUND_PAIRS_TEST_PLAN.md
└── Performance/
    └── REALTIME_BPM.md
```

## Feature Documentation

### Subdivision Feature (Latest)
The subdivision feature allows users to control how many clicks play per beat.

**Quick Links:**
- [Feature Specification](Subdivision/01_FEATURE_SPEC.md) - Complete implementation details
- [Pre-Build Checklist](Subdivision/02_PRE_BUILD_CHECKLIST.md) - Verification before building
- [Corrected Behavior](Subdivision/03_CORRECTED_BEHAVIOR.md) - Accent sound requirements
- [Timing Fix](Subdivision/04_TIMING_FIX.md) - UI synchronization fix
- [Final Summary](Subdivision/05_FINAL_FIX_SUMMARY.md) - Quick reference
- [Testing Guide](Subdivision/06_TESTING_GUIDE.md) - How to test all scenarios

**Key Points:**
- Supports 1, 2, 3, or 4 clicks per beat
- Accent sound plays on ALL clicks of beat 0
- UI block highlights synchronized with first click of each beat
- Block UI structure unchanged

### Rhythmic Signature
Documentation for the time signature feature.

**Quick Links:**
- [Signature Implementation](Signature/RHYTHMIC_SIGNATURE.md)
- [Quick Start Guide](Signature/QUICK_START_SIGNATURES.md)

### Beat Visualization
Documentation for the visual beat blocks.

**Quick Links:**
- [Visualization Spec](Visualization/BEAT_VISUALIZATION.md)
- [Visualization Fix](Visualization/VISUALIZATION_FIX.md)

### Sound Pairs
Documentation for the accent/regular sound system.

**Quick Links:**
- [Sound Pairs Feature](Audio/SOUND_PAIRS_FEATURE.md)
- [Test Plan](Audio/SOUND_PAIRS_TEST_PLAN.md)

### Performance
Documentation for performance optimizations.

**Quick Links:**
- [Real-time BPM Updates](Performance/REALTIME_BPM.md)

## How to Use This Documentation

1. **For New Features**: Start with the feature spec document
2. **Before Building**: Review the pre-build checklist
3. **For Bug Fixes**: Check the fix documentation for that feature
4. **For Testing**: Use the testing guides

## Modified Source Files

### Subdivision Feature
- `MetronomeViewModel.swift` - Added subdivision state management
- `MetronomeEngine.swift` - Added subdivision timing logic
- `ContentView.swift` - Added subdivision picker UI
- `RhythmicSignature.swift` - (No changes, but used by subdivision)

### Other Features
- See individual feature documentation for file modifications

## Version History

### Subdivision Feature
- **v1.0**: Initial implementation (basic subdivision support)
- **v1.1**: Accent fix (accent plays on all clicks of beat 0)
- **v1.2**: Timing fix (UI notification on first click, not last)

## Notes

All documentation is maintained by the development agent during feature implementation. Each feature has its own subdirectory to keep related docs together.
