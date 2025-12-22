# Beat Visualization Feature

## Overview

Added a professional-style beat visualization that displays upcoming beats as a horizontal sequence of animated blocks, similar to high-end metronome apps. This helps with rhythmic awareness and makes practice more engaging.

## Visual Design

### Beat Block States

The visualization shows beats in three distinct states:

1. **Current Beat** (Purple, Large)
   - Width: 32pt
   - Height: 32pt
   - Color: Purple (0.9 opacity)
   - Border: 2pt purple border
   - Scale: 1.1x (slightly enlarged)
   - Shadow: 8pt purple glow
   - Centered in viewport

2. **Upcoming Beats** (White, Medium)
   - Width: 24pt
   - Height: 24pt
   - Color: White (0.15 opacity)
   - Border: 1pt white border
   - Scale: 1.0x
   - Visible ahead of current beat

3. **Past Beats** (Dimmed, Small)
   - Width: 20pt
   - Height: 20pt
   - Color: White (0.05 opacity)
   - No border
   - Scale: 0.8x (shrunk)
   - Faded behind current beat

### Layout

```
[past] [past] [past] [CURRENT] [upcoming] [upcoming] [upcoming]
  •      •      •        ◆          ○          ○          ○
```

- Horizontal scrolling container
- 12 visible blocks at once
- 8pt spacing between blocks
- Smooth auto-scroll keeps current beat centered
- Blocks loop based on rhythmic signature numerator

## Behavior

### Beat Advancement

**On each metronome tick:**
1. Engine plays audio
2. Engine calls `onBeatTick(beatIndex)` callback
3. ViewModel updates `currentBeatIndex`
4. View re-renders with new highlighted block
5. Auto-scrolls to keep current beat centered

### Looping

The visualization loops based on the rhythmic signature:
- **4/4**: Blocks cycle 0 → 1 → 2 → 3 → 0...
- **3/4**: Blocks cycle 0 → 1 → 2 → 0...
- **6/8**: Blocks cycle 0 → 1 → 2 → 3 → 4 → 5 → 0...

### Animation

All transitions are animated:
- **Opacity**: Fades in/out smoothly
- **Scale**: Grows/shrinks with easeInOut
- **Color**: Transitions between states
- **Scroll**: Smooth centering with easeOut
- **Duration**: 150ms for state changes, 100ms for scroll

### Visibility

The visualization:
- ✅ Appears when metronome starts
- ✅ Disappears when metronome stops
- ✅ Uses fade + scale transition
- ✅ Resets to beat 0 on start/stop
- ✅ Resets when signature changes

## Architecture

### MetronomeEngine.swift

**New Property:**
```swift
var onBeatTick: ((Int) -> Void)?
```

**Beat Notification:**
```swift
private func notifyBeatTick() {
    let beatIndex = currentBeatInPattern
    DispatchQueue.main.async { [weak self] in
        self?.onBeatTick?(beatIndex)
    }
}
```

Called after scheduling each beat buffer. Ensures UI updates happen on main thread.

### MetronomeViewModel.swift

**New Property:**
```swift
@Published var currentBeatIndex: Int = 0
```

**Beat Callback Setup:**
```swift
engine.onBeatTick = { [weak self] beatIndex in
    Task { @MainActor in
        self?.currentBeatIndex = beatIndex
    }
}
```

**Reset on Start/Stop:**
```swift
func start() {
    currentBeatIndex = 0  // Reset visualization
    engine.start()
    isPlaying = true
}

func stop() {
    engine.stop()
    isPlaying = false
    currentBeatIndex = 0  // Reset visualization
}
```

### ContentView.swift

**Integration:**
```swift
if viewModel.isPlaying {
    BeatVisualizationView(
        currentBeat: viewModel.currentBeatIndex,
        totalBeats: viewModel.signature.numerator
    )
    .transition(.opacity.combined(with: .scale(scale: 0.8)))
}
```

Shows only when playing, with fade + scale transition.

### BeatVisualizationView

**Structure:**
- `ScrollViewReader` for programmatic scrolling
- `ScrollView(.horizontal)` for block container
- `HStack` of `BeatBlock` views
- `onChange(of: currentBeat)` triggers scroll

**Key Logic:**
```swift
ForEach(0..<max(visibleBlocks, totalBeats), id: \.self) { index in
    BeatBlock(...)
}
```

Creates enough blocks to fill viewport or complete one cycle (whichever is larger).

### BeatBlock

**State Calculation:**
```swift
private var beatInCycle: Int {
    index % totalBeats  // Maps block index to beat position
}

private var blockState: BlockState {
    if beatInCycle == currentBeat {
        return .current
    } else if isUpcoming {
        return .upcoming
    } else {
        return .past
    }
}
```

**BlockState Enum:**
Defines all visual properties for each state:
- Color
- Size (width/height)
- Border (color/width)
- Scale
- Shadow

## User Experience

### Practice Benefits

1. **Visual Feedback**
   - See exactly where you are in the measure
   - Anticipate upcoming beats
   - Track beat position without counting

2. **Rhythmic Awareness**
   - Train internal clock
   - Feel the pulse visually
   - Understand beat groupings

3. **Time Signature Clarity**
   - Visual representation of numerator
   - See patterns (4 beats vs 3 beats vs 6 beats)
   - Understand odd meters (5/4, 7/8)

4. **Practice Engagement**
   - More interactive than just audio
   - Modern, professional appearance
   - Satisfying animation

### Example: 4/4 Practice

```
Playing at 100 BPM in 4/4:
┌─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  4  │  (repeat)
└─────┴─────┴─────┴─────┘
  ◆     ○     ○     ○    → beat 1 (highlighted)
  ○     ◆     ○     ○    → beat 2 (highlighted)
  ○     ○     ◆     ○    → beat 3 (highlighted)
  ○     ○     ○     ◆    → beat 4 (highlighted)
```

### Example: 3/4 Waltz

```
Playing at 80 BPM in 3/4:
┌─────┬─────┬─────┐
│  1  │  2  │  3  │  (repeat)
└─────┴─────┴─────┘
  ◆     ○     ○    → beat 1 (accented, highlighted)
  ○     ◆     ○    → beat 2
  ○     ○     ◆    → beat 3
```

## Technical Implementation

### Thread Safety

- Engine callback runs on audio thread
- `DispatchQueue.main.async` moves to main thread
- `@MainActor` ensures ViewModel updates on main thread
- No race conditions

### Performance

- Efficient block rendering (reuses views)
- Smooth 60fps animations
- Minimal CPU usage (only updates on beat)
- No layout recalculation per frame

### Memory

- Fixed number of blocks (12-16 typical)
- No memory leaks (weak self in callbacks)
- Views automatically released when stopped

### Accessibility

- Visual-only feature (supplements audio)
- Does not interfere with audio timing
- Can be hidden if needed (automatically on stop)

## Design Choices

### Why Purple?

- **High contrast** against dark background
- **Professional** appearance (used in many music apps)
- **Not too bright** (easy on eyes during practice)
- **Distinct** from other UI elements (green/red button)

### Why Auto-Scroll?

- **Keeps current beat centered** for easy tracking
- **Smooth motion** feels natural
- **Shows past and future** beats simultaneously
- **No manual scrolling** needed (hands-free)

### Why Fade Past Beats?

- **De-emphasizes history** (focus on now and ahead)
- **Visual hierarchy** (current > upcoming > past)
- **Reduces clutter** in viewport
- **Creates flow** sensation

### Why Different Sizes?

- **Current beat stands out** (largest)
- **Upcoming beats readable** (medium)
- **Past beats recede** (smallest)
- **Progressive sizing** creates depth

## Future Enhancements

Possible additions:

1. **Color Themes**
   - User-selectable accent colors
   - Match with beat sound type

2. **Subdivision Display**
   - Show 8th/16th note subdivisions
   - Smaller blocks between main beats

3. **Beat Numbers**
   - Display "1 2 3 4" on blocks
   - Helpful for beginners

4. **Downbeat Indicator**
   - Different color for beat 1
   - Match audio accent

5. **Vertical Layout Option**
   - Circular/radial visualization
   - Clock-style display

6. **Customization**
   - Block size slider
   - Opacity settings
   - Animation speed

7. **Practice Mode**
   - Predict next beat game
   - Hide visualization randomly
   - Test internal timing

## Summary

The beat visualization transforms the metronome from an audio-only tool into a **multi-sensory practice aid**. It provides immediate visual feedback, helps internalize rhythm patterns, and makes practice more engaging. The implementation is performant, thread-safe, and seamlessly integrated with the existing architecture.
