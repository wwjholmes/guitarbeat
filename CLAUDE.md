# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Guitar Beat is an iOS/iPadOS metronome app built with SwiftUI and AVFoundation. Target: iOS 18.6+, Swift 5.0, Xcode required.

## Build & Run

Open `Guitar Beat.xcodeproj` in Xcode, select a device or simulator, and press Cmd+R. There is no CLI build workflow — all builds go through Xcode. There are no unit tests currently in the project.

Audio files (`select-button-sfx.wav`, `fish_bowl_sound.wav`) live in the `Sounds/` directory at the repo root; they must be included in the app bundle.

## Architecture

Strict MVVM with no cross-layer shortcuts:

```
ContentView (SwiftUI View)
    ↓ user actions
MetronomeViewModel (@MainActor ObservableObject)
    ↓ engine calls / ↑ onBeatTick callback
MetronomeEngine (audio + timing, no SwiftUI imports)
    uses
RhythmicSignature (pure struct, no audio or UI)
```

**Layer rules:**
- View never touches `MetronomeEngine` directly
- `MetronomeEngine` never imports SwiftUI or references UI state
- Engine-to-ViewModel communication happens only through the `onBeatTick: ((Int) -> Void)?` callback, dispatched to `@MainActor` via `Task { @MainActor in … }`

## Audio Timing (Critical)

The engine uses **sample-accurate scheduling** via `AVAudioPlayerNode.scheduleBuffer(_:at:options:)` with `AVAudioTime(sampleTime:atRate:)`. Never use `Date`, `Timer`, or `DispatchSourceTimer` for beat scheduling — they accumulate drift.

Beat interval: `60.0 / BPM` seconds. Click interval with subdivision: `beatInterval / subdivision`. Converted to `AVAudioFramePosition` using `sampleRate = 44100.0`.

The engine keeps `maxScheduledBeats = 1` ahead to allow fast sound switching. A `DispatchSourceTimer` at 50 ms refills the queue.

## Subdivision & Accent Logic

**State must be captured before any mutation in the scheduling loop:**
```swift
let beatThatWillSchedule = currentBeatInPattern
let clickThatWillSchedule = clicksInCurrentBeat
```

**Accent rule:** Use `accentBuffer` for ALL clicks of beat 0 (not just the first click).
```swift
let isAccentBeat = (beatThatWillSchedule == 0)
let buffer = isAccentBeat ? (accentBuffer ?? clickBuffer) : clickBuffer
```

**UI notification:** Fire `onBeatTick` before the first click of a beat plays (not after the last), so the visualization block lights up in sync with audio.

**Beat advancement:** Increment `clicksInCurrentBeat`; only advance `currentBeatInPattern` after all subdivision clicks are done.

## Adding Features

**New engine parameter** — add `private var current…`, a `set…(_ value:)` method that restarts the engine if running (with a 50 ms `asyncAfter` delay and `resetBeatPosition: false`), and a read-only computed property.

**New ViewModel property** — `@Published var … { didSet { engine.set…(…) } }`, initialize it in `init`, call the engine setter.

**New UI control** — `@State private var showPicker = false`, a button that toggles it, a `.sheet` binding to a picker `View` that follows the `Cancel`/`Apply` pattern already used for `SignaturePickerView` and `SubdivisionPickerView`.

## Logging Convention

Use emoji prefixes consistently:
- `🚀` start/stop events
- `🎵` audio/beat events
- `🎯` timing calculations
- `✅` success, `❌` error, `⚠️` warning
- `✂️` trimming, `🔊` sound/volume
