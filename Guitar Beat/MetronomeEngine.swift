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
    case selectButton = "Select Button"
    case kickDrum = "Kick Drum"
    case rimClick = "Rim Click"
    case woodBlock = "Wood Block"
    case cowbell = "Cowbell"
    case snare = "Snare"
    case classicClick = "Classic Click"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .selectButton:
            return "Clean, modern UI button sound"
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
    private var currentSound: BeatSound = .selectButton  // Default to select button sound
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
    
    // Track pending UI notifications for cancellation
    private var pendingUINotifications: [DispatchWorkItem] = []
    private let notificationLock = NSLock()
    
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
        
        // Use stereo format to support both mono and stereo audio files
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
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
    /// For audio files, loads from bundle instead of generating.
    private func generateClickSound(for sound: BeatSound) {
        // For select button, load from audio file
        if sound == .selectButton {
            loadAudioFile(named: "select-button-sfx", extension: "wav")
            return
        }
        
        // For other sounds, generate programmatically in stereo
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        // Duration varies by sound type
        let clickDuration: Double
        switch sound {
        case .selectButton: return  // Already handled above
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
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            print("Failed to get channel data")
            return
        }
        
        // Generate sound based on type (same for both channels - mono content in stereo format)
        switch sound {
        case .selectButton: break  // Already handled
        case .kickDrum:
            generateKickDrum(channelData: leftChannel, frameCount: frameCount)
            generateKickDrum(channelData: rightChannel, frameCount: frameCount)
        case .rimClick:
            generateRimClick(channelData: leftChannel, frameCount: frameCount)
            generateRimClick(channelData: rightChannel, frameCount: frameCount)
        case .woodBlock:
            generateWoodBlock(channelData: leftChannel, frameCount: frameCount)
            generateWoodBlock(channelData: rightChannel, frameCount: frameCount)
        case .cowbell:
            generateCowbell(channelData: leftChannel, frameCount: frameCount)
            generateCowbell(channelData: rightChannel, frameCount: frameCount)
        case .snare:
            generateSnare(channelData: leftChannel, frameCount: frameCount)
            generateSnare(channelData: rightChannel, frameCount: frameCount)
        case .classicClick:
            generateClassicClick(channelData: leftChannel, frameCount: frameCount)
            generateClassicClick(channelData: rightChannel, frameCount: frameCount)
        }
        
        self.clickBuffer = buffer
    }
    
    /// Loads an audio file from the bundle and converts it to a PCM buffer
    private func loadAudioFile(named filename: String, extension fileExtension: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("❌ Failed to find audio file: \(filename).\(fileExtension)")
            // Fallback to generated classic click sound
            generateFallbackClickSound()
            return
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let fileFormat = audioFile.processingFormat
            
            print("📁 Audio file format: \(fileFormat.channelCount) channels, \(fileFormat.sampleRate) Hz")
            
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: fileFormat,
                frameCapacity: AVAudioFrameCount(audioFile.length)
            ) else {
                print("❌ Failed to create buffer for audio file")
                generateFallbackClickSound()
                return
            }
            
            try audioFile.read(into: buffer)
            
            // Convert to engine's format (stereo, 44.1kHz)
            let targetFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            
            if fileFormat.channelCount != targetFormat.channelCount || 
               fileFormat.sampleRate != targetFormat.sampleRate {
                guard let convertedBuffer = convertBuffer(buffer, to: targetFormat) else {
                    print("❌ Failed to convert buffer to target format")
                    generateFallbackClickSound()
                    return
                }
                self.clickBuffer = convertedBuffer
                print("✅ Converted audio: \(fileFormat.channelCount)ch@\(fileFormat.sampleRate)Hz -> \(targetFormat.channelCount)ch@\(targetFormat.sampleRate)Hz")
            } else {
                self.clickBuffer = buffer
            }
            
            print("✅ Loaded audio file: \(filename).\(fileExtension)")
            
        } catch {
            print("❌ Error loading audio file: \(error)")
            generateFallbackClickSound()
        }
    }
    
    /// Generates a fallback click sound when audio file loading fails
    private func generateFallbackClickSound() {
        print("⚠️ Using fallback classic click sound")
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let clickDuration: Double = 0.015
        let frameCount = AVAudioFrameCount(sampleRate * clickDuration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            print("❌ Failed to create fallback buffer")
            return
        }
        
        buffer.frameLength = frameCount
        generateClassicClick(channelData: leftChannel, frameCount: frameCount)
        generateClassicClick(channelData: rightChannel, frameCount: frameCount)
        self.clickBuffer = buffer
    }
    
    /// Converts an audio buffer to a different format (sample rate and/or channels)
    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        let inputFormat = buffer.format
        
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            print("❌ Failed to create audio converter")
            return nil
        }
        
        // Calculate output buffer capacity
        let ratio = targetFormat.sampleRate / inputFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCapacity
        ) else {
            print("❌ Failed to create output buffer")
            return nil
        }
        
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if let error = error {
            print("❌ Conversion error: \(error)")
            return nil
        }
        
        if status == .error {
            print("❌ Converter returned error status")
            return nil
        }
        
        return outputBuffer
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
        // For select button, use the same sound with volume boost (applied via player)
        if sound == .selectButton {
            // Use the same click buffer, accent will be handled by volume
            self.accentBuffer = self.clickBuffer
            return
        }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        // Use same duration as regular click
        let clickDuration: Double
        switch sound {
        case .selectButton: return  // Already handled above
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
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            print("Failed to get accent channel data")
            return
        }
        
        // Generate the base sound for both channels
        switch sound {
        case .selectButton: break  // Already handled
        case .kickDrum:
            generateKickDrum(channelData: leftChannel, frameCount: frameCount)
            generateKickDrum(channelData: rightChannel, frameCount: frameCount)
        case .rimClick:
            generateRimClick(channelData: leftChannel, frameCount: frameCount)
            generateRimClick(channelData: rightChannel, frameCount: frameCount)
        case .woodBlock:
            generateWoodBlock(channelData: leftChannel, frameCount: frameCount)
            generateWoodBlock(channelData: rightChannel, frameCount: frameCount)
        case .cowbell:
            generateCowbell(channelData: leftChannel, frameCount: frameCount)
            generateCowbell(channelData: rightChannel, frameCount: frameCount)
        case .snare:
            generateSnare(channelData: leftChannel, frameCount: frameCount)
            generateSnare(channelData: rightChannel, frameCount: frameCount)
        case .classicClick:
            generateClassicClick(channelData: leftChannel, frameCount: frameCount)
            generateClassicClick(channelData: rightChannel, frameCount: frameCount)
        }
        
        // Apply accent to both channels: increase volume by 30% and add subtle high-frequency ping
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            let normalizedTime = Float(frame) / Float(frameCount)
            
            // Add a brief high-frequency "ping" for accent clarity
            let pingEnvelope = exp(-normalizedTime * 60.0)
            let ping = sin(2.0 * .pi * 2400.0 * time) * pingEnvelope * 0.15
            
            // Apply to left channel
            let boostedLeft = leftChannel[frame] * 1.3
            leftChannel[frame] = min(max(boostedLeft + ping, -1.0), 1.0)
            
            // Apply to right channel
            let boostedRight = rightChannel[frame] * 1.3
            rightChannel[frame] = min(max(boostedRight + ping, -1.0), 1.0)
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
        
        // Cancel all pending UI notifications
        cancelPendingUINotifications()
        
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
        let oldSignature = currentSignature
        currentSignature = signature
        
        // Reset beat pattern counter
        currentBeatInPattern = 0
        
        // If running, restart to apply new signature immediately
        if isRunning {
            // Stop current playback
            stop()
            
            // Calculate delay: wait one beat interval of the OLD signature before starting new one
            // This prevents two consecutive beats from firing
            let delaySeconds = oldSignature.intervalSeconds(at: currentBPM)
            
            print("⏸️ Signature changed from \(oldSignature.displayString) to \(signature.displayString)")
            print("⏳ Waiting \(String(format: "%.3f", delaySeconds))s before starting new rhythm")
            
            // Schedule restart after one beat interval
            DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) { [weak self] in
                guard let self = self else { return }
                // Only restart if we're not running (user didn't stop manually)
                if !self.isRunning {
                    self.start()
                }
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
    
    /// Cancels all pending UI notification work items
    private func cancelPendingUINotifications() {
        notificationLock.lock()
        defer { notificationLock.unlock() }
        
        print("🚫 Cancelling \(pendingUINotifications.count) pending UI notifications")
        
        // Cancel all pending work items
        for workItem in pendingUINotifications {
            workItem.cancel()
        }
        
        // Clear the array
        pendingUINotifications.removeAll()
    }
    
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
                
                // Create a unique ID for this work item
                let workItemID = UUID()
                
                // Schedule UI notification when beat plays using DispatchWorkItem for cancellation
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    
                    // Notify the UI
                    self.onBeatTick?(beatThatWillPlay)
                    
                    // Clean up: remove completed work items from the array
                    self.notificationLock.lock()
                    // Only remove the first item since we process in order (FIFO)
                    if !self.pendingUINotifications.isEmpty {
                        self.pendingUINotifications.removeFirst()
                    }
                    self.notificationLock.unlock()
                }
                
                // Store work item so it can be cancelled if needed
                notificationLock.lock()
                pendingUINotifications.append(workItem)
                notificationLock.unlock()
                
                // Schedule the work item
                DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds, execute: workItem)
                
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
