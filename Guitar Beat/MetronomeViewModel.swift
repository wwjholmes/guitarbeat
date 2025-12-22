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
    
    @Published var bpm: Double = 100.0 {
        didSet {
            engine.setBPM(bpm)
        }
    }
    
    @Published var volume: Float = 0.8 {
        didSet {
            engine.setVolume(volume)
        }
    }
    
    @Published var beatSound: BeatSound = .kickDrum {
        didSet {
            engine.setBeatSound(beatSound)
        }
    }
    
    @Published var signature: RhythmicSignature = .fourFour {
        didSet {
            engine.setSignature(signature)
        }
    }
    
    @Published var isPlaying: Bool = false
    
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
        engine.start()
        isPlaying = true
    }
    
    func stop() {
        engine.stop()
        isPlaying = false
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
            }
            .store(in: &cancellables)
        
        // Note: We intentionally do NOT auto-start when returning to foreground
        // The user must manually start again
    }
}
