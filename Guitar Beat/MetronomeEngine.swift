//
//  MetronomeEngine.swift
//  Guitar Beat
//
//  Created by Wenjing Wang on 12/22/25.
//

import AVFoundation
import Foundation

/// Available beat sound types
enum BeatSound: String, CaseIterable, Identifiable {
    case kickDrum = "Kick Drum"
    case rimClick = "Rim Click"
    case woodBlock = "Wood Block"
    case cowbell = "Cowbell"
    case snare = "Snare"
    case classicClick = "Classic Click"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .kickDrum:
            return "Deep, punchy low-frequency drum"
        case .rimClick:
            return "Sharp, bright metallic click"
        case .woodBlock:
            return "High-pitched, short woody sound"
        case .cowbell:
            return "Metallic bell with long sustain"
        case .snare:
            return "Crisp drum with snare wires"
        case .classicClick:
            return "Traditional metronome click"
        }
    }
}

/// Manages audio playback and timing for the metronome using AVAudioEngine.
/// Uses audio buffer scheduling for precise, drift-free timing.
final class MetronomeEngine {
    
    // MARK: - Properties
    
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    private var clickBuffer: AVAudioPCMBuffer?
    private var accentBuffer: AVAudioPCMBuffer?
    private let sampleRate: Double = 44100.0
    
    private var isRunning = false
    private var currentBPM: Double = 100.0
    private var currentVolume: Float = 0.8
    private var currentSound: BeatSound = .kickDrum
    private var currentSignature = RhythmicSignature.fourFour
    private var currentBeatInPattern: Int = 0
    private var scheduledBeatsCount: Int = 0  // Track how many beats we've scheduled ahead
    private let maxScheduledBeats = 3  // Keep 3 beats scheduled ahead
    
    // Beat callback for UI visualization
    var onBeatTick: ((Int) -> Void)?
    
    // Scheduling state
    private var scheduleQueue = DispatchQueue(label: "com.guitarbeat.metronome.schedule", qos: .userInteractive)
    private var schedulingTimer: DispatchSourceTimer?
    private var nextBeatSampleTime: AVAudioFramePosition = 0
    private var isFirstBeat = true
    
    // MARK: - Initialization
    
    init() {
        setupAudioEngine()
        generateClickSound(for: currentSound)
        generateAccentSound(for: currentSound)
    }
    
    deinit {
        stop()
        audioEngine.stop()
    }
    
    // MARK: - Audio Setup
    
    private func setupAudioEngine() {
        // Attach player node to engine
        audioEngine.attach(playerNode)
        
        // Get the audio format
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Connect player node to main mixer
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        // Prepare and start the engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    /// Generates a drum-like beat sound programmatically based on the selected sound type.
    private func generateClickSound(for sound: BeatSound) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Duration varies by sound type
        let clickDuration: Double
        switch sound {
        case .kickDrum: clickDuration = 0.08
        case .rimClick: clickDuration = 0.03
        case .woodBlock: clickDuration = 0.025
        case .cowbell: clickDuration = 0.15
        case .snare: clickDuration = 0.06
        case .classicClick: clickDuration = 0.015
        }
        
        let frameCount = AVAudioFrameCount(sampleRate * clickDuration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("Failed to create audio buffer")
            return
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else {
            print("Failed to get channel data")
            return
        }
        
        // Generate sound based on type
        switch sound {
        case .kickDrum:
            generateKickDrum(channelData: channelData, frameCount: frameCount)
        case .rimClick:
            generateRimClick(channelData: channelData, frameCount: frameCount)
        case .woodBlock:
            generateWoodBlock(channelData: channelData, frameCount: frameCount)
        case .cowbell:
            generateCowbell(channelData: channelData, frameCount: frameCount)
        case .snare:
            generateSnare(channelData: channelData, frameCount: frameCount)
        case .classicClick:
            generateClassicClick(channelData: channelData, frameCount: frameCount)
        }
        
        self.clickBuffer = buffer
    }
    
    // MARK: - Sound Generators
    
    private func generateKickDrum(channelData: UnsafeMutablePointer<Float>, frameCount: AVAudioFrameCount) {
        // Low frequency drum with frequency sweep
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            let normalizedTime = Float(frame) / Float(frameCount)
            
            let envelope = exp(-normalizedTime * 15.0)
            
            // Frequency sweep from 150Hz down to 50Hz
            let startFreq: Float = 150.0
            let endFreq: Float = 50.0
            let frequency = startFreq + (endFreq - startFreq) * normalizedTime * 2.0
            let kick = sin(2.0 * .pi * frequency * time) * envelope
            
            // Attack noise
            let noiseEnvelope = exp(-normalizedTime * 80.0)
            let noise = (Float.random(in: -1...1) * noiseEnvelope * 0.3)
            
            channelData[frame] = (kick * 0.8 + noise) * 0.6
        }
    }
    
    private func generateRimClick(channelData: UnsafeMutablePointer<Float>, frameCount: AVAudioFrameCount) {
        // Sharp, bright click with mid-high frequency
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            let normalizedTime = Float(frame) / Float(frameCount)
            
            let envelope = exp(-normalizedTime * 40.0)
            
            // Multiple frequencies for metallic sound
            let freq1 = sin(2.0 * .pi * 800.0 * time)
            let freq2 = sin(2.0 * .pi * 1200.0 * time)
            let freq3 = sin(2.0 * .pi * 2400.0 * time)
            
            let tone = (freq1 + freq2 * 0.5 + freq3 * 0.3) / 1.8
            
            // Add noise for stick sound
            let noise = Float.random(in: -1...1) * envelope * 0.4
            
            channelData[frame] = (tone * envelope + noise) * 0.5
        }
    }
    
    private func generateWoodBlock(channelData: UnsafeMutablePointer<Float>, frameCount: AVAudioFrameCount) {
        // High frequency, very short, woody sound
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            let normalizedTime = Float(frame) / Float(frameCount)
            
            let envelope = exp(-normalizedTime * 50.0)
            
            // High frequency with harmonics
            let fundamental = sin(2.0 * .pi * 1800.0 * time)
            let harmonic = sin(2.0 * .pi * 3600.0 * time) * 0.3
            
            // Lots of noise for woody character
            let noise = Float.random(in: -1...1) * 0.6
            
            channelData[frame] = ((fundamental + harmonic) * 0.4 + noise) * envelope * 0.4
        }
    }
    
    private func generateCowbell(channelData: UnsafeMutablePointer<Float>, frameCount: AVAudioFrameCount) {
        // Metallic sound with multiple inharmonic frequencies
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            let normalizedTime = Float(frame) / Float(frameCount)
            
            let envelope = exp(-normalizedTime * 8.0)
            
            // Inharmonic partials typical of cowbell
            let freq1 = sin(2.0 * .pi * 587.0 * time) // D5
            let freq2 = sin(2.0 * .pi * 845.0 * time) // Inharmonic
            let freq3 = sin(2.0 * .pi * 1109.0 * time) // Inharmonic
            let freq4 = sin(2.0 * .pi * 1312.0 * time) // Inharmonic
            
            let metallic = (freq1 + freq2 * 0.7 + freq3 * 0.5 + freq4 * 0.3) / 2.5
            
            // Short noise burst for attack
            let noiseEnvelope = exp(-normalizedTime * 60.0)
            let noise = Float.random(in: -1...1) * noiseEnvelope * 0.2
            
            channelData[frame] = (metallic * envelope + noise) * 0.5
        }
    }
    
    private func generateSnare(channelData: UnsafeMutablePointer<Float>, frameCount: AVAudioFrameCount) {
        // Snare drum with tone and noise
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            let normalizedTime = Float(frame) / Float(frameCount)
            
            let envelope = exp(-normalizedTime * 20.0)
            
            // Drum tone (180-220Hz range)
            let toneFreq: Float = 200.0
            let tone = sin(2.0 * .pi * toneFreq * time) * 0.4
            
            // Snare wires (noise with longer decay)
            let noiseEnvelope = exp(-normalizedTime * 12.0)
            let noise = Float.random(in: -1...1) * noiseEnvelope * 0.7
            
            channelData[frame] = (tone * envelope + noise) * 0.5
        }
    }
    
    private func generateClassicClick(channelData: UnsafeMutablePointer<Float>, frameCount: AVAudioFrameCount) {
        // Original simple click sound
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            let normalizedTime = Float(frame) / Float(frameCount)
            
            let envelope = exp(-normalizedTime * 50.0)
            let sample = sin(2.0 * .pi * 1200.0 * time) * envelope
            
            channelData[frame] = sample * 0.5
        }
    }
    
    /// Generates an accented version of the click sound for the first beat.
    /// The accent is created by increasing volume and adding a higher frequency component.
    private func generateAccentSound(for sound: BeatSound) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Use same duration as regular click
        let clickDuration: Double
        switch sound {
        case .kickDrum: clickDuration = 0.08
        case .rimClick: clickDuration = 0.03
        case .woodBlock: clickDuration = 0.025
        case .cowbell: clickDuration = 0.15
        case .snare: clickDuration = 0.06
        case .classicClick: clickDuration = 0.015
        }
        
        let frameCount = AVAudioFrameCount(sampleRate * clickDuration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("Failed to create accent buffer")
            return
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else {
            print("Failed to get accent channel data")
            return
        }
        
        // Generate the base sound
        switch sound {
        case .kickDrum:
            generateKickDrum(channelData: channelData, frameCount: frameCount)
        case .rimClick:
            generateRimClick(channelData: channelData, frameCount: frameCount)
        case .woodBlock:
            generateWoodBlock(channelData: channelData, frameCount: frameCount)
        case .cowbell:
            generateCowbell(channelData: channelData, frameCount: frameCount)
        case .snare:
            generateSnare(channelData: channelData, frameCount: frameCount)
        case .classicClick:
            generateClassicClick(channelData: channelData, frameCount: frameCount)
        }
        
        // Apply accent: increase volume by 30% and add subtle high-frequency ping
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            let normalizedTime = Float(frame) / Float(frameCount)
            
            // Original sample with volume boost
            let boostedSample = channelData[frame] * 1.3
            
            // Add a brief high-frequency "ping" for accent clarity
            let pingEnvelope = exp(-normalizedTime * 60.0)
            let ping = sin(2.0 * .pi * 2400.0 * time) * pingEnvelope * 0.15
            
            channelData[frame] = min(max(boostedSample + ping, -1.0), 1.0) // Clamp to prevent distortion
        }
        
        self.accentBuffer = buffer
    }
    
    // MARK: - Public Controls
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        isFirstBeat = true
        currentBeatInPattern = 0
        nextBeatSampleTime = 0  // Reset timing
        scheduledBeatsCount = 0  // Reset scheduled count
        
        print("🚀 Starting metronome: BPM=\(currentBPM), Signature=\(currentSignature.numerator)/\(currentSignature.denominator)")
        print("🔊 Volume: \(currentVolume), PlayerNode volume: \(playerNode.volume)")
        print("🎵 Click buffer: \(clickBuffer != nil ? "✅" : "❌"), Accent buffer: \(accentBuffer != nil ? "✅" : "❌")")
        
        // Configure audio session for playback
        configureAudioSession()
        
        // Ensure volume is set
        playerNode.volume = currentVolume
        
        // Start the player node
        playerNode.play()
        
        print("▶️ Player node playing: \(playerNode.isPlaying)")
        
        // Begin scheduling clicks
        startSchedulingLoop()
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        
        // Stop scheduling
        schedulingTimer?.cancel()
        schedulingTimer = nil
        
        // Stop playback
        playerNode.stop()
    }
    
    func setBPM(_ bpm: Double) {
        currentBPM = bpm
        
        // If running, restart the metronome with new tempo for immediate effect
        if isRunning {
            let wasRunning = isRunning
            stop()
            if wasRunning {
                start()
            }
        }
    }
    
    func setVolume(_ volume: Float) {
        currentVolume = min(max(volume, 0.0), 1.0)
        playerNode.volume = currentVolume
    }
    
    func setBeatSound(_ sound: BeatSound) {
        currentSound = sound
        generateClickSound(for: sound)
        generateAccentSound(for: sound)
        
        // If running, the new sound will be used on the next scheduled beat
    }
    
    func setSignature(_ signature: RhythmicSignature) {
        currentSignature = signature
        
        // Reset beat pattern counter
        currentBeatInPattern = 0
        
        // If running, restart to apply new signature immediately
        if isRunning {
            let wasRunning = isRunning
            stop()
            if wasRunning {
                start()
            }
        }
    }
    
    var volume: Float {
        currentVolume
    }
    
    var bpm: Double {
        currentBPM
    }
    
    var running: Bool {
        isRunning
    }
    
    var beatSound: BeatSound {
        currentSound
    }
    
    var signature: RhythmicSignature {
        currentSignature
    }
    
    // MARK: - Audio Session
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Scheduling Logic
    
    /// Schedules the next click buffer at the appropriate audio time.
    /// This approach uses the audio engine's time system for drift-free precision.
    /// Accounts for rhythmic signature to calculate proper intervals.
    private func scheduleNextClick() {
        guard isRunning else { return }
        
        // Keep scheduling until we have enough beats in the queue
        while scheduledBeatsCount < maxScheduledBeats {
            // Determine which buffer to use (accent for first beat, regular for others)
            let isAccentBeat = (currentBeatInPattern == 0) && (currentSignature.numerator > 1)
            let buffer = isAccentBeat ? (accentBuffer ?? clickBuffer) : clickBuffer
            
            guard let buffer = buffer else {
                print("❌ No buffer available for beat \(currentBeatInPattern)")
                return
            }
            
            // Calculate interval between beats in seconds using rhythmic signature
            let intervalSeconds = currentSignature.intervalSeconds(at: currentBPM)
            let intervalSamples = AVAudioFramePosition(intervalSeconds * sampleRate)
            
            // Get the current audio time
            if isFirstBeat {
                // Schedule first beat immediately
                print("🎵 Scheduling first beat immediately (beat 0)")
                
                // Use a weak self to avoid retain cycle
                playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                    print("✅ Beat 0 completion handler called")
                    self?.scheduleQueue.async {
                        self?.scheduledBeatsCount -= 1
                        print("📉 Scheduled count after beat 0: \(self?.scheduledBeatsCount ?? -1)")
                    }
                }
                
                // Initialize timing for subsequent beats
                // Use the player's timeline (playerTime) for scheduling, not render time
                guard let now = playerNode.lastRenderTime,
                      let playerTime = playerNode.playerTime(forNodeTime: now) else {
                    print("⚠️ Cannot get player time after first beat")
                    isFirstBeat = false
                    scheduledBeatsCount += 1
                    notifyBeatTick()
                    currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
                    return
                }
                
                // The next beat should play one interval from NOW in the player's timeline
                nextBeatSampleTime = playerTime.sampleTime + intervalSamples
                
                print("🎯 First beat timing: playerTime=\(playerTime.sampleTime), interval=\(intervalSamples), nextBeat=\(nextBeatSampleTime)")
                
                isFirstBeat = false
                scheduledBeatsCount += 1
                
                // Notify UI immediately for first beat (index 0)
                notifyBeatTick()
                
                // Increment for NEXT scheduling call
                currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
            } else {
                // For subsequent beats, use precise timing
                if nextBeatSampleTime == 0 {
                    // Initialize if needed
                    guard let now = playerNode.lastRenderTime,
                          let playerTime = playerNode.playerTime(forNodeTime: now) else {
                        print("⚠️ Still waiting for player to start rendering...")
                        return
                    }
                    nextBeatSampleTime = playerTime.sampleTime + intervalSamples
                    print("🎯 Initialized timing: playerTime=\(playerTime.sampleTime), nextBeat=\(nextBeatSampleTime), interval=\(intervalSamples)")
                }
                
                // Store which beat INDEX will play when this buffer plays
                let beatThatWillPlay = currentBeatInPattern
                
                // Calculate delay for UI notification
                // We need to convert player time back to real time for the dispatch delay
                guard let now = playerNode.lastRenderTime,
                      let currentPlayerTime = playerNode.playerTime(forNodeTime: now) else {
                    print("⚠️ Cannot get player time for beat \(beatThatWillPlay)")
                    return
                }
                
                let delayInSamples = nextBeatSampleTime - currentPlayerTime.sampleTime
                let delayInSeconds = max(0, Double(delayInSamples) / sampleRate)
                
                print("⏱️ Beat \(beatThatWillPlay): nextBeatSampleTime=\(nextBeatSampleTime), currentPlayerTime=\(currentPlayerTime.sampleTime), delayInSeconds=\(String(format: "%.3f", delayInSeconds))s, scheduled=\(scheduledBeatsCount)")
                
                // Schedule UI notification when beat plays
                DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) { [weak self] in
                    self?.onBeatTick?(beatThatWillPlay)
                }
                
                // Schedule next click at the calculated time in player's timeline
                let nextBeatTime = AVAudioTime(
                    sampleTime: nextBeatSampleTime,
                    atRate: sampleRate
                )
                
                playerNode.scheduleBuffer(buffer, at: nextBeatTime, options: []) { [weak self] in
                    print("✅ Beat \(beatThatWillPlay) completion handler called")
                    self?.scheduleQueue.async {
                        self?.scheduledBeatsCount -= 1
                        print("📉 Scheduled count after beat \(beatThatWillPlay): \(self?.scheduledBeatsCount ?? -1)")
                    }
                }
                
                scheduledBeatsCount += 1
                print("📈 Scheduled beat \(beatThatWillPlay), new count: \(scheduledBeatsCount)")
                
                // Increment for next beat
                nextBeatSampleTime += intervalSamples
                
                // Increment for NEXT scheduling call
                currentBeatInPattern = (currentBeatInPattern + 1) % currentSignature.numerator
            }
        }
    }
    
    /// Schedules a UI notification after a delay to sync with audio playback
    private func scheduleUINotification(after delay: TimeInterval) {
        let beatIndex = currentBeatInPattern
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.onBeatTick?(beatIndex)
        }
    }
    
    /// Notifies the UI about a beat tick on the main thread
    private func notifyBeatTick() {
        let beatIndex = currentBeatInPattern
        DispatchQueue.main.async { [weak self] in
            self?.onBeatTick?(beatIndex)
        }
    }
    
    /// Starts a timer to continuously schedule clicks ahead of time.
    /// This ensures we always have clicks scheduled, preventing gaps.
    private func startSchedulingLoop() {
        let timer = DispatchSource.makeTimerSource(queue: scheduleQueue)
        // Check frequently to keep the queue filled
        timer.schedule(deadline: .now(), repeating: .milliseconds(50))
        
        timer.setEventHandler { [weak self] in
            guard let self = self, self.isRunning else { return }
            
            // Schedule more beats if needed
            self.scheduleNextClick()
        }
        
        timer.resume()
        schedulingTimer = timer
    }
}
