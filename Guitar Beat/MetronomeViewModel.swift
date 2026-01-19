//
//  MetronomeViewModel.swift
//  Guitar Beat
//
//  Created by Wenjing Wang on 12/22/25.
//

import SwiftUI
import Combine

/// View model for the metronome UI.
/// Manages state and provides bindings for SwiftUI views.
@MainActor
final class MetronomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var bpm: Double = 60.0 {
        didSet {
            engine.setBPM(bpm)
        }
    }
    
    @Published var volume: Float = 0.8 {
        didSet {
            engine.setVolume(volume)
        }
    }
    
    @Published var beatSound: BeatSound = .selectButtonFishBowl {
        didSet {
            engine.setBeatSound(beatSound)
        }
    }
    
    @Published var signature: RhythmicSignature = .threeFour {
        didSet {
            engine.setSignature(signature)
            // Don't reset currentBeatIndex here - let the engine's smart remapping handle it
            // The engine will send the correct beat index via onBeatTick callback
        }
    }
    
    @Published var subdivision: Int = 1 {
        didSet {
            engine.setSubdivision(subdivision)
        }
    }
    
    @Published var isPlaying: Bool = false
    
    // Visualization state
    @Published var currentBeatIndex: Int = 0
    
    // MARK: - Constants
    
    let minBPM: Double = 40.0
    let maxBPM: Double = 240.0
    
    // MARK: - Private Properties
    
    private let engine: MetronomeEngine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(engine: MetronomeEngine = MetronomeEngine()) {
        self.engine = engine
        
        // Initialize engine with default values
        engine.setBPM(bpm)
        engine.setVolume(volume)
        engine.setSignature(signature)  // Set the signature!
        engine.setSubdivision(subdivision)  // Set the subdivision!
        
        // Set up beat tick callback for visualization
        engine.onBeatTick = { [weak self] beatIndex in
            Task { @MainActor in
                print("🎵 Beat tick received: \(beatIndex) at \(Date())")
                self?.currentBeatIndex = beatIndex
            }
        }
        
        // Observe app lifecycle
        setupLifecycleObservers()
    }
    
    // MARK: - Public Methods
    
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }
    
    func start() {
        currentBeatIndex = 0  // Reset visualization
        engine.start()
        isPlaying = true
        
        // Disable idle timer to keep screen awake
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func stop() {
        engine.stop()
        isPlaying = false
        currentBeatIndex = 0  // Reset visualization
        
        // Re-enable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func incrementBPM() {
        bpm = min(bpm + 1, maxBPM)
    }
    
    func decrementBPM() {
        bpm = max(bpm - 1, minBPM)
    }
    
    // MARK: - Lifecycle
    
    private func setupLifecycleObservers() {
        // Stop metronome when app goes to background
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.stop()
                // Ensure idle timer is re-enabled when app goes to background
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .store(in: &cancellables)
        
        // Note: We intentionally do NOT auto-start when returning to foreground
        // The user must manually start again
    }
}
