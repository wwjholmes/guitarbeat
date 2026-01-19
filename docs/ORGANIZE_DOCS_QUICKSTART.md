# Quick Start: Organizing Documentation

## TL;DR

Run these commands in Terminal from your project root:

```bash
# Create directories
mkdir -p Docs/Subdivision Docs/Signature Docs/Visualization Docs/Audio Docs/Performance

# Move Subdivision docs
mv SUBDIVISION_FEATURE.md Docs/Subdivision/01_FEATURE_SPEC.md
mv PRE_BUILD_CHECKLIST.md Docs/Subdivision/02_PRE_BUILD_CHECKLIST.md
mv SUBDIVISION_CORRECTED.md Docs/Subdivision/03_CORRECTED_BEHAVIOR.md
mv TIMING_FIX.md Docs/Subdivision/04_TIMING_FIX.md
mv FINAL_FIX_SUMMARY.md Docs/Subdivision/05_FINAL_FIX_SUMMARY.md
mv TESTING_GUIDE.md Docs/Subdivision/06_TESTING_GUIDE.md

# Move other docs
mv RHYTHMIC_SIGNATURE.md Docs/Signature/
mv QUICK_START_SIGNATURES.md Docs/Signature/
mv BEAT_VISUALIZATION.md Docs/Visualization/
mv VISUALIZATION_FIX.md Docs/Visualization/
mv SOUND_PAIRS_FEATURE.md Docs/Audio/
mv SOUND_PAIRS_TEST_PLAN.md Docs/Audio/
mv REALTIME_BPM.md Docs/Performance/
mv DocsREADME.md Docs/README.md

# Clean up
rm QUICK_FIX_SUMMARY.md

# Done!
echo "✅ Documentation organized!"
```

## Then in Xcode:

1. File → Add Files to "Guitar Beat"...
2. Select the new `Docs` folder
3. Check "Create groups"
4. Click Add

## Result:

```
Guitar Beat/
├── Guitar Beat/         (Your code)
└── Docs/               (All documentation)
    ├── Subdivision/    (7 files about subdivision)
    ├── Signature/      (2 files)
    ├── Visualization/  (2 files)
    ├── Audio/         (2 files)
    └── Performance/   (1 file)
```

Clean and organized! 🎉
