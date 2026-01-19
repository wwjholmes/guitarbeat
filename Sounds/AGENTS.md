# AGENTS.md - AI Agent Instructions

**Guitar Beat - Metronome Application**  
**Last Updated:** January 18, 2026  
**For:** AI coding assistants working on this repository

---

## Table of Contents
1. [Repository Overview](#repository-overview)
2. [Project Structure](#project-structure)
3. [Core Features](#core-features)
4. [Development Guidelines](#development-guidelines)
5. [Testing Requirements](#testing-requirements)
6. [Documentation Standards](#documentation-standards)
7. [Common Patterns](#common-patterns)
8. [Code Style](#code-style)

---

## Repository Overview

### What is Guitar Beat?
A professional metronome app for iOS/iPadOS built with SwiftUI and AVFoundation. Designed for musicians to practice with precise timing, customizable rhythms, and visual feedback.

### Tech Stack
- **Language:** Swift (latest version)
- **UI Framework:** SwiftUI
- **Audio:** AVFoundation (AVAudioEngine, AVAudioPlayerNode)
- **Architecture:** MVVM (Model-View-ViewModel)
- **Platforms:** iOS 17+, iPadOS 17+

### Key Principles
1. **Precision First:** Drift-free audio timing using AVAudioEngine's sample-accurate scheduling
2. **Visual Clarity:** Clean, dark-themed UI with purple accent highlighting
3. **Musician-Focused:** Features align with real practice needs
4. **Performance:** Smooth UI, no audio glitches, efficient battery usage

---

## Project Structure

```
Guitar Beat/
├── Guitar Beat/              # Source code
│   ├── ContentView.swift     # Main UI (MVVM View)
│   ├── MetronomeViewModel.swift  # State management (MVVM ViewModel)
│   ├── MetronomeEngine.swift     # Audio engine (Model)
│   └── RhythmicSignature.swift   # Time signature model
│
├── Resources/
│   └── Sounds/               # Audio files (.wav)
│       ├── select-button-sfx.wav
│       └── fish_bowl_sound.wav
│
└── Docs/                     # Feature documentation
    ├── Subdivision/          # Subdivision feature docs
    ├── Signature/            # Time signature docs
    ├── Visualization/        # UI visualization docs
    ├── Audio/               # Sound system docs
    └── Performance/         # Performance optimization docs
```

### Key Files

#### ContentView.swift
- **Role:** SwiftUI views and UI logic
- **Contains:** Main UI, pickers, beat visualization, controls
- **Pattern:** SwiftUI declarative UI with @StateObject for ViewModel
- **DO NOT:** Put business logic here - delegate to ViewModel

#### MetronomeViewModel.swift
- **Role:** State management and UI/Engine bridge
- **Contains:** Published properties, user action handlers
- **Pattern:** @MainActor, ObservableObject, bindings to UI
- **DO NOT:** Put audio logic here - delegate to Engine

#### MetronomeEngine.swift
- **Role:** Audio playback and precise timing
- **Contains:** AVAudioEngine, buffer scheduling, timing calculations
- **Pattern:** Sample-accurate scheduling with callbacks
- **DO NOT:** Reference UI or SwiftUI here - pure audio logic

#### RhythmicSignature.swift
- **Role:** Time signature model
- **Contains:** Numerator/denominator, interval calculations
- **Pattern:** Struct with computed properties
- **DO NOT:** Add audio or UI logic here

---

## Core Features

### 1. BPM Control (Beats Per Minute)
- **Range:** 40-240 BPM
- **Controls:** Slider, +/- buttons, direct input
- **Behavior:** Real-time updates while playing
- **Implementation:** 60/BPM = seconds per beat

### 2. Time Signature (Rhythmic Signature)
- **Format:** Numerator/Denominator (e.g., 4/4, 3/4, 6/8)
- **Numerator:** 1-16 beats per measure
- **Denominator:** 1, 2, 4, 8, or 16 (note values)
- **UI:** Wheel picker with common presets
- **Behavior:** 
  - Changes block count (visual)
  - BPM always represents beats per minute (denominator is display only)
  - Smart beat position remapping on signature change

### 3. Subdivision ⭐ (Latest Feature)
- **Purpose:** Control clicks per beat for practice
- **Range:** 1-4 clicks per beat
- **Values:**
  - 1 = Quarter notes (default)
  - 2 = Eighth notes
  - 3 = Triplets
  - 4 = Sixteenth notes
- **UI:** Button shows "♩" or "♩ ×N", wheel picker
- **Critical Behaviors:**
  - **Accent Rule:** Accent sound plays on ALL clicks of beat 0 (first beat)
  - **UI Timing:** Block highlights BEFORE first click plays (not after last)
  - **Beat Advancement:** After all subdivision clicks complete
  - **Block Count:** Unchanged by subdivision (always = signature numerator)

### 4. Beat Visualization
- **Design:** Horizontal blocks with 3 bars each
- **Count:** Equals signature numerator (e.g., 4 blocks for 4/4)
- **Structure:** Each block has 3 horizontal pill-shaped bars
- **Highlighting:** Purple glow on active beat
- **Timing:** Highlights on first click of beat, stays lit during all subdivision clicks

### 5. Sound Pairs (Accent System)
- **Concept:** Two sounds per pair (HIGH for downbeat, LOW for other beats)
- **Available Pairs:**
  1. Select Button / Fish Bowl (default)
  2. Cowbell / Kick Drum
  3. Rim Click / Wood Block
  4. Snare / Classic Click
- **Accent Logic:** 
  - HIGH sound: ALL clicks of beat 0
  - LOW sound: ALL clicks of beats 1, 2, 3, etc.
- **With Subdivision:** Accent repeats per subdivision value

### 6. Volume Control
- **Range:** 0.0 - 1.0
- **UI:** Slider with speaker icons
- **Behavior:** Real-time adjustment

### 7. Start/Stop Control
- **States:** Playing (red "Stop" button) / Stopped (green "Start" button)
- **Behavior on Stop:**
  - Resets beat position to 0
  - Resets subdivision click counter
  - Clears scheduled audio buffers
  - Re-enables idle timer
- **Behavior on Start:**
  - Disables idle timer (keeps screen awake)
  - Begins audio scheduling
  - Starts beat visualization

---

## Development Guidelines

### Architecture Rules

#### MVVM Pattern
```
View (ContentView)
  ↓ User actions
ViewModel (MetronomeViewModel)
  ↓ State changes
Model (MetronomeEngine)
  ↑ Callbacks (onBeatTick)
```

**Key Rules:**
1. **View → ViewModel:** UI events trigger ViewModel methods
2. **ViewModel → Engine:** ViewModel calls Engine methods
3. **Engine → ViewModel:** Engine uses callbacks (NOT direct access)
4. **NO:** View → Engine direct communication

#### Separation of Concerns

**ContentView Responsibilities:**
- ✅ Display UI
- ✅ Handle user input
- ✅ Observe ViewModel @Published properties
- ❌ NO audio logic
- ❌ NO timing calculations
- ❌ NO business logic

**MetronomeViewModel Responsibilities:**
- ✅ Manage app state
- ✅ Bridge UI and Engine
- ✅ Validate user input
- ❌ NO SwiftUI views
- ❌ NO audio buffer management
- ❌ NO AVAudioEngine access

**MetronomeEngine Responsibilities:**
- ✅ Audio playback
- ✅ Timing precision
- ✅ Buffer scheduling
- ❌ NO UI references
- ❌ NO SwiftUI imports
- ❌ NO view state management

### Critical Implementation Details

#### 1. Subdivision Timing Logic

**State Capture (CRITICAL):**
```swift
// ALWAYS capture state BEFORE modifications
let beatThatWillSchedule = currentBeatInPattern
let clickThatWillSchedule = clicksInCurrentBeat

// Use captured values for logic
let isAccentBeat = (beatThatWillSchedule == 0)
```

**Why:** Prevents timing bugs when state changes during scheduling loop.

**Accent Selection:**
```swift
// CORRECT: Accent ALL clicks of beat 0
let isAccentBeat = (beatThatWillSchedule == 0)
let buffer = isAccentBeat ? (accentBuffer ?? clickBuffer) : clickBuffer

// WRONG: Only accent first click
// let isAccentClick = (beat == 0 && click == 0)  // DON'T DO THIS
```

**UI Notification Timing:**
```swift
// CORRECT: Notify BEFORE first click plays
let isFirstClickOfBeat = (clickThatWillSchedule == 0)
if isFirstClickOfBeat {
    self.onBeatTick?(beatThatWillPlay)
}

// WRONG: Notify after last click completes
// if clicksInCurrentBeat >= currentSubdivision { ... }  // DON'T DO THIS
```

**Beat Advancement:**
```swift
// Increment click counter
clicksInCurrentBeat += 1

// Advance beat ONLY after all subdivision clicks
if clicksInCurrentBeat >= currentSubdivision {
    currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
    clicksInCurrentBeat = 0
}
```

#### 2. Audio Timing Precision

**Use Sample-Accurate Scheduling:**
```swift
// Calculate click interval
let beatIntervalSeconds = currentSignature.intervalSeconds(at: currentBPM)
let clickIntervalSeconds = beatIntervalSeconds / Double(currentSubdivision)
let intervalSamples = AVAudioFramePosition(clickIntervalSeconds * sampleRate)

// Schedule at specific sample time
let nextBeatTime = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: sampleRate)
playerNode.scheduleBuffer(buffer, at: nextBeatTime, options: [])

// Increment for next click
nextBeatSampleTime += intervalSamples
```

**Never Use:** Date/time-based scheduling (causes drift)

#### 3. UI Thread Safety

**ViewModel:**
```swift
@MainActor
final class MetronomeViewModel: ObservableObject {
    // All @Published properties run on main thread
}
```

**Engine Callbacks:**
```swift
// Engine callback to ViewModel must dispatch to main thread
Task { @MainActor in
    self?.currentBeatIndex = beatIndex
}
```

#### 4. State Resets

**When stopping:**
```swift
func stop() {
    isRunning = false
    schedulingTimer?.cancel()
    playerNode.stop()
    clicksInCurrentBeat = 0  // CRITICAL: Reset subdivision counter
}
```

**When changing subdivision:**
```swift
func setSubdivision(_ subdivision: Int) {
    currentSubdivision = min(max(subdivision, 1), 4)  // Validate range
    clicksInCurrentBeat = 0  // CRITICAL: Reset counter
    // Restart if running
}
```

---

## Testing Requirements

### Behavior Verification Checklist

When implementing or modifying features, verify:

#### Subdivision Feature
- [ ] Subdivision = 1: Behavior identical to original (1 click per beat)
- [ ] Subdivision = 2: 2 clicks per beat, block advances every 2 clicks
- [ ] Subdivision = 3: 3 clicks per beat, block advances every 3 clicks
- [ ] Subdivision = 4: 4 clicks per beat, block advances every 4 clicks
- [ ] Accent plays on ALL clicks of beat 0 (count matches subdivision)
- [ ] UI block highlights BEFORE first click (not after last)
- [ ] Clicks are evenly spaced (no timing drift)
- [ ] Works with all signatures (3/4, 4/4, 5/4, 6/8, etc.)
- [ ] Works at all BPMs (40-240)
- [ ] Changing subdivision while playing restarts cleanly
- [ ] Stop/start resets click counter correctly

#### Time Signature
- [ ] Block count equals numerator (4 blocks for 4/4, 3 for 3/4, etc.)
- [ ] Each block contains exactly 3 horizontal bars
- [ ] Beat position remaps intelligently on signature change
- [ ] Works with subdivision (independent features)
- [ ] Presets work correctly (4/4, 3/4, 6/8, 5/4)

#### Audio Timing
- [ ] No drift over long periods (test 5+ minutes)
- [ ] BPM changes apply immediately
- [ ] Volume changes apply immediately
- [ ] Sound changes apply immediately
- [ ] No audio glitches or clicks
- [ ] Works in background (audio continues)
- [ ] Works with interruptions (phone calls, etc.)

#### UI Behavior
- [ ] Beat visualization syncs with audio
- [ ] Controls responsive during playback
- [ ] Picker values update correctly
- [ ] Button labels update correctly
- [ ] Screen stays awake during playback
- [ ] Screen can sleep when stopped

#### Edge Cases
- [ ] Rapid start/stop cycles
- [ ] Changing all parameters while playing
- [ ] Extreme BPMs (40 BPM and 240 BPM)
- [ ] All signature combinations with all subdivisions
- [ ] Memory stable (no leaks over time)
- [ ] App backgrounding/foregrounding

### Unit Testing Strategy

While this project doesn't currently have unit tests, here's the recommended approach if adding them:

#### Test Targets

**MetronomeEngine Tests:**
```swift
@Test("Subdivision timing calculation")
func testSubdivisionTiming() {
    let engine = MetronomeEngine()
    let bpm = 120.0
    let subdivision = 4
    
    let beatInterval = 60.0 / bpm  // 0.5 seconds
    let expectedClickInterval = beatInterval / Double(subdivision)  // 0.125 seconds
    
    #expect(expectedClickInterval == 0.125)
}

@Test("Beat advancement with subdivision")
func testBeatAdvancement() async throws {
    let engine = MetronomeEngine()
    engine.setSubdivision(2)
    
    // After 2 clicks, beat should advance
    // Test would need to mock the scheduling loop
}
```

**RhythmicSignature Tests:**
```swift
@Test("Interval calculation")
func testIntervalCalculation() {
    let signature = RhythmicSignature(numerator: 4, denominator: 4)
    let bpm = 120.0
    
    let interval = signature.intervalSeconds(at: bpm)
    
    #expect(interval == 0.5)  // 60/120 = 0.5 seconds per beat
}

@Test("Common signatures")
func testCommonSignatures() {
    #expect(RhythmicSignature.fourFour.numerator == 4)
    #expect(RhythmicSignature.fourFour.denominator == 4)
    #expect(RhythmicSignature.threeFour.numerator == 3)
}
```

**ViewModel Tests:**
```swift
@Test("Subdivision validation")
@MainActor
func testSubdivisionRange() {
    let viewModel = MetronomeViewModel()
    
    viewModel.subdivision = 1
    #expect(viewModel.subdivision == 1)
    
    viewModel.subdivision = 4
    #expect(viewModel.subdivision == 4)
}
```

#### Testing Philosophy
1. **Timing Logic:** Test calculations, not AVAudioEngine (mock when needed)
2. **State Management:** Test ViewModel property updates
3. **Edge Cases:** Test boundary conditions (min/max BPM, signatures)
4. **Integration:** Test feature interactions (signature + subdivision)

---

## Documentation Standards

### When to Create Documentation

**Always document when:**
1. Adding a new feature
2. Fixing a significant bug
3. Changing architecture or patterns
4. Modifying timing-critical code

### Documentation Structure

**Feature Documentation Template:**
```markdown
# [Feature Name]

## Overview
Brief description and purpose

## Implementation
- Modified files
- Key code changes
- Important patterns

## Behavior
- How it works
- Examples
- Edge cases

## Testing
- Verification steps
- Expected results
```

### Where to Put Documentation

```
Docs/
├── [FeatureName]/
│   ├── 01_FEATURE_SPEC.md      # Complete implementation details
│   ├── 02_BEHAVIOR.md          # How it works
│   ├── 03_TESTING.md           # Verification steps
│   └── [NN_FIX_NAME.md]        # Bug fixes (if any)
```

### Documentation Best Practices

1. **Use Examples:** Show concrete examples with numbers
2. **Include Console Logs:** Show expected log output
3. **Explain Why:** Not just what changed, but why
4. **Update on Changes:** Keep docs in sync with code
5. **Cross-Reference:** Link related documentation
6. **Use Master Docs:** Create comprehensive guides for major features

### Current Documentation

**Primary References:**
- `SUBDIVISION_MASTER_DOC.md` - Complete subdivision guide
- `Docs/Subdivision/03_CORRECTED_BEHAVIOR.md` - Accent fix
- `Docs/Subdivision/04_TIMING_FIX.md` - UI timing fix

**Note:** Files prefixed with `DEPRECATED_` are outdated - do not reference them.

---

## Common Patterns

### Pattern 1: Adding a New UI Control

```swift
// 1. Add state to ContentView
@State private var showNewPicker = false

// 2. Add button to UI
Button(action: { showNewPicker.toggle() }) {
    // Button content
}

// 3. Add sheet modifier
.sheet(isPresented: $showNewPicker) {
    NewPickerView(selectedValue: $viewModel.newProperty)
}

// 4. Create picker view
struct NewPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedValue: SomeType
    
    var body: some View {
        // Picker UI with Cancel/Apply
    }
}
```

### Pattern 2: Adding a New ViewModel Property

```swift
// 1. Add published property
@Published var newProperty: SomeType = defaultValue {
    didSet {
        engine.setNewProperty(newProperty)
    }
}

// 2. Add to ViewModel init
init(engine: MetronomeEngine = MetronomeEngine()) {
    self.engine = engine
    engine.setNewProperty(newProperty)
    // ... other initialization
}

// 3. Add getter to Engine (if needed)
var newProperty: SomeType {
    currentNewProperty
}
```

### Pattern 3: Adding Engine Functionality

```swift
// 1. Add private property
private var currentNewProperty: SomeType = defaultValue

// 2. Add setter method
func setNewProperty(_ value: SomeType) {
    currentNewProperty = value
    
    // If running, restart to apply change
    if isRunning {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            if !self.isRunning {
                self.start(resetBeatPosition: false)
            }
        }
    }
}

// 3. Use in scheduling logic
func scheduleNextClick() {
    // Use currentNewProperty in calculations
}
```

### Pattern 4: Audio Buffer Scheduling

```swift
// Always use sample-accurate timing
let nextBeatTime = AVAudioTime(
    sampleTime: nextBeatSampleTime,
    atRate: sampleRate
)

playerNode.scheduleBuffer(buffer, at: nextBeatTime, options: []) { [weak self] in
    // Completion handler
    // Use weak self to avoid retain cycles
}

// Increment for next click
nextBeatSampleTime += intervalSamples
```

---

## Code Style

### Swift Conventions

**Naming:**
- Types: `PascalCase` (e.g., `MetronomeEngine`)
- Properties/Methods: `camelCase` (e.g., `currentBeatInPattern`)
- Constants: `camelCase` (e.g., `maxScheduledBeats`)
- Private properties: prefix with `private` (e.g., `private var isRunning`)

**Organization:**
```swift
// MARK: - Properties
// Public properties first
// Private properties after

// MARK: - Initialization
// Init methods

// MARK: - Public Methods
// Public interface

// MARK: - Private Methods
// Implementation details
```

**Comments:**
```swift
// Use /// for documentation comments
/// Schedules the next click buffer at the appropriate audio time.
/// This approach uses the audio engine's time system for drift-free precision.
func scheduleNextClick() { }

// Use // for inline comments
// Capture state BEFORE modifications
let beatThatWillSchedule = currentBeatInPattern
```

### SwiftUI Style

**View Structure:**
```swift
struct MyView: View {
    // MARK: - Properties
    @StateObject private var viewModel = MetronomeViewModel()
    @State private var showPicker = false
    
    // MARK: - Body
    var body: some View {
        // Main view hierarchy
    }
    
    // MARK: - Private Methods
    private func helperMethod() { }
}
```

**Modifiers:**
```swift
// Group related modifiers
Text("Hello")
    .font(.title)
    .foregroundColor(.white)
    .padding()
    .background(Color.blue)
```

### Error Handling

**Logging:**
```swift
// Use emoji for log visibility
print("🚀 Starting metronome")  // Info
print("⚠️ Warning message")     // Warning
print("❌ Error occurred")       // Error
print("✅ Success")              // Success
print("🎵 Audio event")          // Audio-related
print("🎯 Timing event")         // Timing-related
```

**Validation:**
```swift
// Always validate user input
func setSubdivision(_ subdivision: Int) {
    let validSubdivision = min(max(subdivision, 1), 4)  // Clamp to range
    currentSubdivision = validSubdivision
}
```

---

## Agent Workflow

### Before Making Changes

1. **Read this document** - Understand the architecture
2. **Review relevant docs** - Check `Docs/` folder for feature documentation
3. **Check existing patterns** - Follow established code patterns
4. **Understand dependencies** - Know what affects what

### While Making Changes

1. **Follow MVVM** - Respect layer boundaries
2. **Maintain timing precision** - Don't break audio accuracy
3. **Test thoroughly** - Verify behavior checklist
4. **Add logging** - Include debug output for timing-critical code

### After Making Changes

1. **Update documentation** - Keep docs in sync
2. **Verify all features** - Ensure nothing broke
3. **Check integration** - Test feature interactions
4. **Document decisions** - Explain why, not just what

### Creating Documentation

1. **Use templates** - Follow existing doc structure
2. **Be specific** - Include examples and console logs
3. **Explain timing** - Critical for this app
4. **Cross-reference** - Link related docs

---

## Quick Reference

### Key Files to Check First
- `MetronomeEngine.swift` - Audio timing and scheduling
- `MetronomeViewModel.swift` - State and bindings
- `ContentView.swift` - UI and user interaction
- `SUBDIVISION_MASTER_DOC.md` - Latest feature documentation

### Critical Concepts
- **Sample-accurate scheduling** - Never use Date/Timer for audio
- **State capture** - Capture before modifying in loops
- **Accent rule** - ALL clicks of beat 0
- **UI timing** - Highlight BEFORE first click
- **MVVM boundaries** - No View→Engine communication

### When in Doubt
- **Check existing patterns** - Code consistency matters
- **Read feature docs** - Comprehensive guides exist
- **Test extensively** - Audio timing is unforgiving
- **Ask clarifying questions** - Better than assumptions

---

## Version History

- **v1.0** (Jan 18, 2026) - Initial AGENTS.md creation
  - Documented subdivision feature
  - Established development guidelines
  - Created testing requirements

---

## Questions?

If this document doesn't answer your question:
1. Check `Docs/` folder for feature-specific documentation
2. Review existing code for patterns
3. Ask the human developer for clarification

**Remember:** This is a musician's tool. Precision, reliability, and clarity are paramount! 🎵
