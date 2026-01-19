# File Organization Plan

## Current Situation
All documentation files (.md) are in the root `/repo` directory, mixed with source code and sound files.

## Recommended Structure

Create the following folder structure:

```
Guitar Beat/
├── Guitar Beat/              (Source code)
│   ├── ContentView.swift
│   ├── MetronomeEngine.swift
│   ├── MetronomeViewModel.swift
│   └── RhythmicSignature.swift
│
├── Resources/               (Assets)
│   ├── Sounds/
│   │   ├── select-button-sfx.wav
│   │   └── fish_bowl_sound.wav
│   └── Assets.xcassets/
│
└── Docs/                    (Documentation - NEW)
    ├── README.md
    │
    ├── Subdivision/         (Subdivision feature docs)
    │   ├── 01_FEATURE_SPEC.md
    │   ├── 02_PRE_BUILD_CHECKLIST.md
    │   ├── 03_CORRECTED_BEHAVIOR.md
    │   ├── 04_TIMING_FIX.md
    │   ├── 05_FINAL_FIX_SUMMARY.md
    │   └── 06_TESTING_GUIDE.md
    │
    ├── Signature/           (Signature feature docs)
    │   ├── RHYTHMIC_SIGNATURE.md
    │   └── QUICK_START_SIGNATURES.md
    │
    ├── Visualization/       (UI visualization docs)
    │   ├── BEAT_VISUALIZATION.md
    │   └── VISUALIZATION_FIX.md
    │
    ├── Audio/              (Sound feature docs)
    │   ├── SOUND_PAIRS_FEATURE.md
    │   └── SOUND_PAIRS_TEST_PLAN.md
    │
    └── Performance/        (Performance docs)
        └── REALTIME_BPM.md
```

## Files to Move

### Create New Directory: `Docs/Subdivision/`

Move and rename these files:
1. `SUBDIVISION_FEATURE.md` → `Docs/Subdivision/01_FEATURE_SPEC.md`
2. `PRE_BUILD_CHECKLIST.md` → `Docs/Subdivision/02_PRE_BUILD_CHECKLIST.md`
3. `SUBDIVISION_CORRECTED.md` → `Docs/Subdivision/03_CORRECTED_BEHAVIOR.md`
4. `TIMING_FIX.md` → `Docs/Subdivision/04_TIMING_FIX.md`
5. `FINAL_FIX_SUMMARY.md` → `Docs/Subdivision/05_FINAL_FIX_SUMMARY.md`
6. `QUICK_FIX_SUMMARY.md` → (DELETE - superseded by FINAL_FIX_SUMMARY.md)
7. `TESTING_GUIDE.md` → `Docs/Subdivision/06_TESTING_GUIDE.md`

### Create New Directory: `Docs/Signature/`

Move these files:
1. `RHYTHMIC_SIGNATURE.md` → `Docs/Signature/RHYTHMIC_SIGNATURE.md`
2. `QUICK_START_SIGNATURES.md` → `Docs/Signature/QUICK_START_SIGNATURES.md`

### Create New Directory: `Docs/Visualization/`

Move these files:
1. `BEAT_VISUALIZATION.md` → `Docs/Visualization/BEAT_VISUALIZATION.md`
2. `VISUALIZATION_FIX.md` → `Docs/Visualization/VISUALIZATION_FIX.md`

### Create New Directory: `Docs/Audio/`

Move these files:
1. `SOUND_PAIRS_FEATURE.md` → `Docs/Audio/SOUND_PAIRS_FEATURE.md`
2. `SOUND_PAIRS_TEST_PLAN.md` → `Docs/Audio/SOUND_PAIRS_TEST_PLAN.md`

### Create New Directory: `Docs/Performance/`

Move these files:
1. `REALTIME_BPM.md` → `Docs/Performance/REALTIME_BPM.md`

### Create New File: `Docs/README.md`

Use the content from `DocsREADME.md` (which I just created).

## How to Organize (Manual Steps)

### In Xcode:

1. **Create Docs folder group:**
   - Right-click on project root
   - Select "New Group"
   - Name it "Docs"

2. **Create subfolders:**
   - Right-click on "Docs"
   - Create groups: Subdivision, Signature, Visualization, Audio, Performance

3. **Move files:**
   - Drag each .md file from root into its appropriate subfolder
   - Rename files as listed above (use numbered prefixes for Subdivision docs)

4. **Clean up:**
   - Delete `QUICK_FIX_SUMMARY.md` (duplicate/outdated)
   - Delete `DocsREADME.md` from root after creating `Docs/README.md`

### Or Using Finder:

1. **Create folder structure:**
   ```bash
   cd "Guitar Beat"
   mkdir -p Docs/Subdivision
   mkdir -p Docs/Signature
   mkdir -p Docs/Visualization
   mkdir -p Docs/Audio
   mkdir -p Docs/Performance
   ```

2. **Move files:**
   ```bash
   # Subdivision
   mv SUBDIVISION_FEATURE.md Docs/Subdivision/01_FEATURE_SPEC.md
   mv PRE_BUILD_CHECKLIST.md Docs/Subdivision/02_PRE_BUILD_CHECKLIST.md
   mv SUBDIVISION_CORRECTED.md Docs/Subdivision/03_CORRECTED_BEHAVIOR.md
   mv TIMING_FIX.md Docs/Subdivision/04_TIMING_FIX.md
   mv FINAL_FIX_SUMMARY.md Docs/Subdivision/05_FINAL_FIX_SUMMARY.md
   mv TESTING_GUIDE.md Docs/Subdivision/06_TESTING_GUIDE.md
   
   # Signature
   mv RHYTHMIC_SIGNATURE.md Docs/Signature/
   mv QUICK_START_SIGNATURES.md Docs/Signature/
   
   # Visualization
   mv BEAT_VISUALIZATION.md Docs/Visualization/
   mv VISUALIZATION_FIX.md Docs/Visualization/
   
   # Audio
   mv SOUND_PAIRS_FEATURE.md Docs/Audio/
   mv SOUND_PAIRS_TEST_PLAN.md Docs/Audio/
   
   # Performance
   mv REALTIME_BPM.md Docs/Performance/
   
   # Create README
   mv DocsREADME.md Docs/README.md
   
   # Clean up
   rm QUICK_FIX_SUMMARY.md
   ```

3. **Update Xcode project:**
   - Delete references to moved files (don't delete files on disk)
   - Add the new Docs folder structure back to Xcode

## Benefits

✅ **Organized**: Each feature has its own documentation folder
✅ **Readable**: Numbered files in Subdivision show the progression
✅ **Maintainable**: Easy to find and update relevant docs
✅ **Professional**: Cleaner project structure
✅ **Scalable**: Easy to add new feature documentation

## After Organization

Your root directory will only have:
- Source code (.swift files)
- Project files (.xcodeproj, .xcworkspace)
- Config files (Info.plist, etc.)
- README.md (project README)

All documentation will be in the `Docs/` directory, neatly organized by feature!
