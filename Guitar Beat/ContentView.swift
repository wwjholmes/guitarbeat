//
//  ContentView.swift
//  Guitar Beat
//
//  Created by Wenjing Wang on 12/22/25.
//

import SwiftUI 

struct ContentView: View {
    @StateObject private var viewModel = MetronomeViewModel()
    @State private var showSoundPicker = false
    @State private var showSignaturePicker = false
    @State private var localBPM: Double = 60.0
    @State private var bpmUpdateTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(white: 0.1), Color(white: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title and Sound Selector
                HStack {
                    // Sound picker button (left)
                    Button(action: { showSoundPicker.toggle() }) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Guitar Beat")
                            .font(.title)
                            .fontWeight(.light)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Settings or future button placeholder (right)
                    Color.clear
                        .frame(width: 44, height: 44)
                        .padding(.trailing, 20)
                }
                .padding(.top, 30)
                
                // Sound type display
                Text(viewModel.beatSound.rawValue)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
                
                // Rhythmic signature display with tap to change
                Button(action: { showSignaturePicker.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "music.note.list")
                            .font(.caption2)
                        
                        Text(viewModel.signature.displayString)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                // Beat visualization (always visible)
                BeatVisualizationView(
                    currentBeat: viewModel.currentBeatIndex,
                    totalBeats: viewModel.signature.numerator,
                    isPlaying: viewModel.isPlaying
                )
                
                Spacer()
                
                // BPM Display
                VStack(spacing: 8) {
                    Text("\(Int(localBPM))")
                        .font(.system(size: 80, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    
                    Text("BPM")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                }
                
                // BPM Step Controls
                HStack(spacing: 20) {
                    StepButton(symbol: "minus", action: {
                        updateBPM(max(localBPM - 1, viewModel.minBPM))
                    })
                    
                    Spacer()
                    
                    StepButton(symbol: "plus", action: {
                        updateBPM(min(localBPM + 1, viewModel.maxBPM))
                    })
                }
                .padding(.horizontal, 100)
                
                // BPM Slider
                VStack(spacing: 8) {
                    Slider(
                        value: $localBPM,
                        in: viewModel.minBPM...viewModel.maxBPM,
                        step: 1,
                        onEditingChanged: { editing in
                            if !editing {
                                // When user releases slider, apply immediately
                                applyBPMImmediately()
                            }
                        }
                    )
                    .tint(.white.opacity(0.8))
                    .onChange(of: localBPM) { oldValue, newValue in
                        // Debounce while dragging
                        debounceBPMUpdate(newValue)
                    }
                    
                    HStack {
                        Text("\(Int(viewModel.minBPM))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.maxBPM))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Volume Control
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.white.opacity(0.6))
                        
                        Slider(value: $viewModel.volume, in: 0...1)
                            .tint(.white.opacity(0.6))
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 40)
                }
                
                // Start/Stop Button
                Button(action: viewModel.togglePlayback) {
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                            .font(.title2)
                        
                        Text(viewModel.isPlaying ? "Stop" : "Start")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: 200)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.isPlaying ? Color.red.opacity(0.9) : Color.green.opacity(0.9))
                    )
                    .foregroundColor(.white)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView(selectedSound: $viewModel.beatSound)
        }
        .sheet(isPresented: $showSignaturePicker) {
            SignaturePickerView(selectedSignature: $viewModel.signature)
        }
        .onAppear {
            localBPM = viewModel.bpm
        }
    }
    
    // MARK: - BPM Update Methods
    
    private func updateBPM(_ newBPM: Double) {
        localBPM = newBPM
        applyBPMImmediately()
    }
    
    private func applyBPMImmediately() {
        bpmUpdateTask?.cancel()
        viewModel.bpm = localBPM
    }
    
    private func debounceBPMUpdate(_ newBPM: Double) {
        // Cancel previous task
        bpmUpdateTask?.cancel()
        
        // Create new debounced task
        bpmUpdateTask = Task {
            // Wait for user to stop dragging for a moment
            try? await Task.sleep(for: .milliseconds(300))
            
            // Check if task wasn't cancelled
            guard !Task.isCancelled else { return }
            
            // Apply the BPM change
            await MainActor.run {
                viewModel.bpm = newBPM
            }
        }
    }
}

// MARK: - Step Button

struct StepButton: View {
    let symbol: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                )
        }
    }
}

// MARK: - Sound Picker View

struct SoundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSound: BeatSound
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()
                
                List {
                    ForEach(BeatSound.allCases) { sound in
                        Button(action: {
                            selectedSound = sound
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sound.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(sound.description)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                if selectedSound == sound {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Beat Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(white: 0.1), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Signature Picker View

struct SignaturePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSignature: RhythmicSignature
    
    @State private var selectedNumerator: Int
    @State private var selectedDenominator: Int
    
    init(selectedSignature: Binding<RhythmicSignature>) {
        self._selectedSignature = selectedSignature
        self._selectedNumerator = State(initialValue: selectedSignature.wrappedValue.numerator)
        self._selectedDenominator = State(initialValue: selectedSignature.wrappedValue.denominator)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.08).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Title and explanation
                    VStack(spacing: 8) {
                        Text("Rhythmic Signature")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Choose the time signature for your practice")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    // Large display of current selection
                    HStack(spacing: 0) {
                        Text("\(selectedNumerator)")
                            .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .frame(width: 100)
                        
                        Text("/")
                            .font(.system(size: 72, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("\(selectedDenominator)")
                            .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .frame(width: 100)
                    }
                    .padding(.vertical, 20)
                    
                    // Description
                    Text(signatureDescription)
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .frame(height: 50)
                    
                    // Wheel-style picker
                    HStack(spacing: 0) {
                        // Numerator picker
                        Picker("Numerator", selection: $selectedNumerator) {
                            ForEach(RhythmicSignature.validNumerators, id: \.self) { num in
                                Text("\(num)")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .tag(num)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                        
                        Text("/")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 40)
                        
                        // Denominator picker
                        Picker("Denominator", selection: $selectedDenominator) {
                            ForEach(RhythmicSignature.validDenominators, id: \.self) { denom in
                                Text("\(denom)")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .tag(denom)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                    }
                    .frame(height: 180)
                    
                    Spacer()
                    
                    // Common presets
                    VStack(spacing: 12) {
                        Text("Common Signatures")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)
                        
                        HStack(spacing: 12) {
                            PresetButton(signature: .fourFour) {
                                applyPreset(.fourFour)
                            }
                            
                            PresetButton(signature: .threeFour) {
                                applyPreset(.threeFour)
                            }
                            
                            PresetButton(signature: .sixEight) {
                                applyPreset(.sixEight)
                            }
                            
                            PresetButton(signature: .fiveFour) {
                                applyPreset(.fiveFour)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applySignature()
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color(white: 0.1), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var signatureDescription: String {
        let signature = RhythmicSignature(numerator: selectedNumerator, denominator: selectedDenominator)
        let noteType = denominatorName(selectedDenominator)
        
        if selectedNumerator == 1 {
            return "One \(noteType) per beat"
        } else {
            return "\(selectedNumerator) \(noteType)s per measure"
        }
    }
    
    private func denominatorName(_ denom: Int) -> String {
        switch denom {
        case 1: return "whole note"
        case 2: return "half note"
        case 4: return "quarter note"
        case 8: return "eighth note"
        case 16: return "sixteenth note"
        default: return "note"
        }
    }
    
    private func applyPreset(_ signature: RhythmicSignature) {
        selectedNumerator = signature.numerator
        selectedDenominator = signature.denominator
    }
    
    private func applySignature() {
        selectedSignature = RhythmicSignature(numerator: selectedNumerator, denominator: selectedDenominator)
        dismiss()
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let signature: RhythmicSignature
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(signature.displayString)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 70, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.15))
                )
        }
    }
}

// MARK: - Beat Visualization View

struct BeatVisualizationView: View {
    let currentBeat: Int
    let totalBeats: Int
    let isPlaying: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 40 // Account for horizontal padding
            
            // Tight spacing for many beats to fit on screen
            let beatContainerSpacing: CGFloat = {
                if totalBeats > 12 {
                    return 5  // Very tight for 13-16 beats
                } else if totalBeats > 10 {
                    return 6  // Tight for 11-12 beats
                } else if totalBeats > 8 {
                    return 8  // Medium for 9-10 beats
                } else {
                    return 14 // Comfortable for 8 or fewer
                }
            }()
            
            let totalSpacing = beatContainerSpacing * CGFloat(totalBeats - 1)
            
            // Much narrower containers for many beats
            let minContainerWidth: CGFloat = {
                if totalBeats > 12 {
                    return 18  // Very narrow for 13-16 beats
                } else if totalBeats > 10 {
                    return 22  // Narrow for 11-12 beats
                } else {
                    return 28  // Normal minimum for 10 or fewer
                }
            }()
            
            let maxContainerWidth: CGFloat = 65  // Maximum width for fewer beats
            let minContainerHeight: CGFloat = 48 // Minimum height
            let maxContainerHeight: CGFloat = 70 // Maximum height
            
            let idealContainerWidth = (availableWidth - totalSpacing) / CGFloat(totalBeats)
            let containerWidth = min(max(idealContainerWidth, minContainerWidth), maxContainerWidth)
            let containerHeight = min(max(containerWidth * 1.2, minContainerHeight), maxContainerHeight) // Slightly taller than wide
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: beatContainerSpacing) {
                    // Render exactly totalBeats containers (one per beat in the cycle)
                    ForEach(0..<totalBeats, id: \.self) { beatIndex in
                        BeatContainer(
                            beatIndex: beatIndex,
                            currentBeat: currentBeat,
                            totalBeats: totalBeats,
                            isPlaying: isPlaying,
                            containerWidth: containerWidth,
                            containerHeight: containerHeight
                        )
                        .id(beatIndex)
                    }
                }
                .padding(.horizontal, 20)
                .frame(minWidth: geometry.size.width)
            }
        }
        .frame(height: 95) // Increased to accommodate taller tiles
    }
}

// MARK: - Beat Container (3 Horizontal Pill Bars)

struct BeatContainer: View {
    let beatIndex: Int        // Which beat this container represents (0 to totalBeats-1)
    let currentBeat: Int      // The currently playing beat
    let totalBeats: Int       // Total beats in the cycle
    let isPlaying: Bool       // Whether metronome is playing
    let containerWidth: CGFloat  // Width of the container
    let containerHeight: CGFloat // Height of the container
    
    private let slicesPerBeat = 3
    private let sliceSpacing: CGFloat = 3 // Keep vertical spacing tight
    private let pillCornerRadius: CGFloat = 8
    
    // Determine if this beat is active
    private var isActive: Bool {
        isPlaying && beatIndex == currentBeat
    }
    
    // Determine if this is the first beat (emphasized)
    private var isFirstBeat: Bool {
        beatIndex == 0
    }
    
    var body: some View {
        // Just the 3 horizontal pill bars - no background container
        VStack(spacing: sliceSpacing) {
            ForEach(0..<slicesPerBeat, id: \.self) { sliceIndex in
                HorizontalPill(
                    isActive: isActive,
                    isFirstBeat: isFirstBeat,
                    isBottomBar: sliceIndex == slicesPerBeat - 1,
                    cornerRadius: pillCornerRadius
                )
            }
        }
        .frame(width: containerWidth, height: containerHeight)
    }
}

// MARK: - Horizontal Pill (One Bar Inside Container)

struct HorizontalPill: View {
    let isActive: Bool
    let isFirstBeat: Bool
    let isBottomBar: Bool
    let cornerRadius: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(pillColor)
            .frame(height: pillHeight)
    }
    
    // MARK: - Colors & Sizing
    
    private var pillColor: Color {
        if isActive {
            // Active beat: all bars fully purple
            return Color.purple.opacity(0.95)
        } else {
            // Inactive beat: purple-tinted with low opacity
            // Bottom bar slightly more opaque for grounded look
            if isBottomBar {
                return Color.purple.opacity(0.35)
            } else {
                return Color.purple.opacity(0.22)
            }
        }
    }
    
    private var pillHeight: CGFloat {
        return 10 // Increased from 8 for more solid appearance
    }
}

#Preview {
    ContentView()
}
