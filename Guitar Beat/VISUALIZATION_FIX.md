# Beat Visualization Bug Fix

## The Problem

The original implementation had a fundamental logic error that caused incorrect highlighting for signatures like 3/8, 3/16, and 1/2.

### What Was Wrong

#### 1. **Too Many Blocks Created**
```swift
// WRONG: Created 12 blocks (or more) regardless of signature
ForEach(0..<max(visibleBlocks, totalBeats), id: \.self) { index in
    // visibleBlocks was hardcoded to 12
}
```

**Result**: Always created at least 12 blocks, even for small cycles.

#### 2. **Incorrect Mapping with Modulo**
```swift
// WRONG: Multiple blocks mapped to same beat
private var beatInCycle: Int {
    index % totalBeats  
}
```

**Why this broke:**

**Example: 3/8 signature (totalBeats = 3)**
- Created 12 blocks (indices 0-11)
- Mapping:
  - Blocks 0, 3, 6, 9 → beat 0 (all % 3 = 0)
  - Blocks 1, 4, 7, 10 → beat 1 (all % 3 = 1)
  - Blocks 2, 5, 8, 11 → beat 2 (all % 3 = 2)
- When currentBeat = 0, blocks 0, 3, 6, 9 all highlighted!

**Example: 1/2 signature (totalBeats = 1)**
- Created 12 blocks
- ALL 12 blocks map to beat 0 (all % 1 = 0)
- Result: Entire strip turns purple!

**Example: 3/16 signature (totalBeats = 3)**
- Same problem as 3/8: every 3rd block highlighted

### Visual Representation of the Bug

**3/8 Signature (should be 3 blocks, got 12):**
```
What we got:
[◆] [○] [○] [◆] [○] [○] [◆] [○] [○] [◆] [○] [○]
 0   1   2   3   4   5   6   7   8   9  10  11
 ↓           ↓           ↓           ↓
All map to beat 0 when highlighted!

What we should have:
[◆] [○] [○]
 0   1   2
Only ONE block highlighted at a time
```

**1/2 Signature (should be 1 block, got 12):**
```
What we got:
[◆] [◆] [◆] [◆] [◆] [◆] [◆] [◆] [◆] [◆] [◆] [◆]
All 12 blocks = beat 0 → SOLID PURPLE BAR

What we should have:
[◆]
Just one block
```

## The Fix

### Key Changes

#### 1. **Create Exactly numerator Blocks**
```swift
// CORRECT: Create one block per beat in the cycle
ForEach(0..<totalBeats, id: \.self) { beatIndex in
    BeatBlock(
        beatIndex: beatIndex,  // Direct 1:1 mapping
        currentBeat: currentBeat,
        totalBeats: totalBeats
    )
}
```

**Result**: 
- 3/8 → exactly 3 blocks
- 1/2 → exactly 1 block
- 4/4 → exactly 4 blocks
- 16/16 → exactly 16 blocks

#### 2. **Direct Mapping (No Modulo)**
```swift
// CORRECT: Each block has a unique beat index
let beatIndex: Int  // 0 to totalBeats-1, no modulo needed

private var blockState: BlockState {
    if beatIndex == currentBeat {
        return .current  // Only ONE block can match
    }
    // ...
}
```

**Why this works:**
- 1:1 relationship between blocks and beats
- No duplicate mappings
- Clear, simple logic

#### 3. **Simplified State Logic**
```swift
// CORRECT: Calculate upcoming/past from circular distance
let distance = (beatIndex - currentBeat + totalBeats) % totalBeats

if distance > 0 && distance <= totalBeats / 2 {
    return .upcoming  // Next half of cycle
} else {
    return .past      // Previous half of cycle
}
```

**Circular distance examples (4/4, currentBeat = 0):**
- beatIndex 1: distance = (1-0+4)%4 = 1 → upcoming ✓
- beatIndex 2: distance = (2-0+4)%4 = 2 → upcoming ✓
- beatIndex 3: distance = (3-0+4)%4 = 3 → past (>2) ✓
- beatIndex 0: distance = (0-0+4)%4 = 0 → current ✓

## Corrected Architecture

### Data Flow

```
MetronomeEngine
    ↓ (audio tick)
    ↓ onBeatTick(beatIndex)
    ↓
MetronomeViewModel
    ↓ updates @Published currentBeatIndex
    ↓
BeatVisualizationView
    ↓ receives currentBeat & totalBeats
    ↓
ForEach 0..<totalBeats  ← EXACTLY numerator blocks
    ↓
BeatBlock
    ↓ beatIndex (0 to totalBeats-1)
    ↓ if beatIndex == currentBeat → current
    ↓ else if ahead → upcoming
    ↓ else → past
```

### ViewModel (Already Correct)

```swift
@Published var currentBeatIndex: Int = 0

engine.onBeatTick = { [weak self] beatIndex in
    Task { @MainActor in
        self?.currentBeatIndex = beatIndex
    }
}
```

✅ ViewModel was already correct - it just passes through the beat index from the engine.

### Engine (Already Correct)

```swift
private var currentBeatInPattern: Int = 0

// After scheduling each beat
currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator

// Notify UI
notifyBeatTick()  // Sends currentBeatInPattern
```

✅ Engine was already correct - it cycles 0 → 1 → 2 → ... → (numerator-1) → 0.

### View (Now Fixed)

**Before (WRONG):**
```swift
ForEach(0..<max(visibleBlocks, totalBeats), id: \.self)
// Creates 12+ blocks with modulo mapping
```

**After (CORRECT):**
```swift
ForEach(0..<totalBeats, id: \.self)
// Creates exactly totalBeats blocks with direct mapping
```

## Verification: All Signatures Work Correctly

### 1/2 Signature
```
Blocks created: 1
Beat sequence: 0 → 0 → 0...
Visualization: [◆] → [◆] → [◆]
One block, always highlighted ✓
```

### 3/8 Signature
```
Blocks created: 3
Beat sequence: 0 → 1 → 2 → 0...
Visualization: 
  [◆] [○] [○] → beat 0
  [○] [◆] [○] → beat 1
  [○] [○] [◆] → beat 2
Only one block highlighted at a time ✓
```

### 3/16 Signature
```
Blocks created: 3
Beat sequence: 0 → 1 → 2 → 0...
Visualization:
  [◆] [○] [○] → beat 0
  [○] [◆] [○] → beat 1
  [○] [○] [◆] → beat 2
Only one block highlighted at a time ✓
```

### 4/4 Signature
```
Blocks created: 4
Beat sequence: 0 → 1 → 2 → 3 → 0...
Visualization:
  [◆] [○] [○] [○] → beat 0
  [○] [◆] [○] [○] → beat 1
  [○] [○] [◆] [○] → beat 2
  [○] [○] [○] [◆] → beat 3
Classic 4/4 pattern ✓
```

### 16/16 Signature
```
Blocks created: 16
Beat sequence: 0 → 1 → 2 → ... → 15 → 0...
Visualization: 16 blocks scrolling horizontally
Only one block highlighted at a time ✓
```

## Code Summary

### BeatVisualizationView
```swift
struct BeatVisualizationView: View {
    let currentBeat: Int   // From ViewModel
    let totalBeats: Int    // signature.numerator
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // KEY FIX: Exactly totalBeats blocks
                    ForEach(0..<totalBeats, id: \.self) { beatIndex in
                        BeatBlock(
                            beatIndex: beatIndex,      // Direct mapping
                            currentBeat: currentBeat,
                            totalBeats: totalBeats
                        )
                        .id(beatIndex)
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(height: 50)
            .onChange(of: currentBeat) { _, newValue in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}
```

### BeatBlock
```swift
struct BeatBlock: View {
    let beatIndex: Int      // Which beat this block is (0 to totalBeats-1)
    let currentBeat: Int    // Currently playing beat
    let totalBeats: Int     // Total beats in cycle
    
    private var blockState: BlockState {
        // KEY FIX: Direct comparison, no modulo
        if beatIndex == currentBeat {
            return .current
        }
        
        // Circular distance for upcoming/past
        let distance = (beatIndex - currentBeat + totalBeats) % totalBeats
        
        if distance > 0 && distance <= totalBeats / 2 {
            return .upcoming
        } else {
            return .past
        }
    }
    
    // ... rest of the block rendering
}
```

## Why This Fix Works

1. **1:1 Block-to-Beat Mapping**
   - Each block represents exactly one beat
   - No duplicate mappings
   - No confusion

2. **Correct Loop Length**
   - Cycle length = numerator
   - Visualization cycles match audio cycles
   - Perfect synchronization

3. **Simple State Logic**
   - Current: `beatIndex == currentBeat`
   - No complex conditions
   - Easy to understand and debug

4. **Scalable**
   - Works for any numerator (1-16)
   - Handles all time signatures correctly
   - No special cases needed

## Testing Checklist

✅ 1/1 - Single block, always highlighted  
✅ 1/2 - Single block, always highlighted  
✅ 3/4 - Three blocks cycling  
✅ 3/8 - Three blocks cycling  
✅ 3/16 - Three blocks cycling  
✅ 4/4 - Four blocks cycling  
✅ 5/4 - Five blocks cycling  
✅ 6/8 - Six blocks cycling  
✅ 7/8 - Seven blocks cycling  
✅ 16/16 - Sixteen blocks scrolling  

All signatures now work correctly! 🎉
