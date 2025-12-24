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
    case cowbell = "Cowbell"
    case kickDrum = "Kick Drum"
    case rimClick = "Rim Click"
    case woodBlock = "Wood Block"
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
    private let maxScheduledBeats = 1  // Keep only 1 beat scheduled ahead for faster sound switching
    
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
    
    // Track timing for signature changes
    private var lastBeatTime: Date = Date()
    
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
            
            // Calculate audio file duration
            let fileDuration = Double(audioFile.length) / fileFormat.sampleRate
            print("📁 Audio file: \(fileFormat.channelCount)ch, \(fileFormat.sampleRate)Hz, duration: \(String(format: "%.3f", fileDuration))s")
            
            // Limit audio duration to max 150ms to work at high BPMs
            // At 240 BPM, interval is 250ms, so 150ms leaves 100ms gap for clean separation
            let maxDuration: Double = 0.15  // 150ms
            let maxFrames = AVAudioFrameCount(maxDuration * fileFormat.sampleRate)
            let framesToRead = min(AVAudioFrameCount(audioFile.length), maxFrames)
            
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: fileFormat,
                frameCapacity: framesToRead
            ) else {
                print("❌ Failed to create buffer for audio file")
                generateFallbackClickSound()
                return
            }
            
            // Read only the first portion of the file (up to maxDuration)
            buffer.frameLength = framesToRead
            try audioFile.read(into: buffer, frameCount: framesToRead)
            
            // First, try to trim silence from the audio
            var processedBuffer = buffer
            if let trimmedBuffer = trimSilence(from: buffer) {
                processedBuffer = trimmedBuffer
            }
            
            // Then check if we still need to trim for length (after silence removal)
            let currentDuration = Double(processedBuffer.frameLength) / fileFormat.sampleRate
            if currentDuration > maxDuration {
                let trimmedDuration = Double(framesToRead) / fileFormat.sampleRate
                print("✂️ Audio still too long after silence removal: \(String(format: "%.3f", currentDuration))s → \(String(format: "%.3f", trimmedDuration))s")
                
                // Need to trim further and apply fade-out
                applyFadeOut(to: processedBuffer, fadeOutDurationMs: 20)
            }
            
            // Convert to engine's format (stereo, 44.1kHz)
            let targetFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            
            if fileFormat.channelCount != targetFormat.channelCount || 
               fileFormat.sampleRate != targetFormat.sampleRate {
                guard let convertedBuffer = convertBuffer(processedBuffer, to: targetFormat) else {
                    print("❌ Failed to convert buffer to target format")
                    generateFallbackClickSound()
                    return
                }
                self.clickBuffer = convertedBuffer
                print("✅ Converted audio: \(fileFormat.channelCount)ch@\(fileFormat.sampleRate)Hz -> \(targetFormat.channelCount)ch@\(targetFormat.sampleRate)Hz")
            } else {
                self.clickBuffer = processedBuffer
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
    
    /// Detects and removes leading/trailing silence from an audio buffer
    /// Returns a new trimmed buffer, or nil if trimming fails
    private func trimSilence(from buffer: AVAudioPCMBuffer, silenceThreshold: Float = 0.01) -> AVAudioPCMBuffer? {
        let format = buffer.format
        let frameLength = Int(buffer.frameLength)
        
        guard let channelData = buffer.floatChannelData else { return nil }
        
        // Find first non-silent frame (scan all channels)
        var firstSoundFrame = frameLength
        for frame in 0..<frameLength {
            var isSilent = true
            for channel in 0..<Int(format.channelCount) {
                if abs(channelData[channel][frame]) > silenceThreshold {
                    isSilent = false
                    break
                }
            }
            if !isSilent {
                firstSoundFrame = frame
                break
            }
        }
        
        // Find last non-silent frame (scan backwards)
        var lastSoundFrame = 0
        for frame in stride(from: frameLength - 1, through: 0, by: -1) {
            var isSilent = true
            for channel in 0..<Int(format.channelCount) {
                if abs(channelData[channel][frame]) > silenceThreshold {
                    isSilent = false
                    break
                }
            }
            if !isSilent {
                lastSoundFrame = frame
                break
            }
        }
        
        // Calculate padding (5ms on each side)
        let paddingSamples = Int(0.005 * format.sampleRate)
        
        // Apply padding but stay within bounds
        let trimStart = max(0, firstSoundFrame - paddingSamples)
        let trimEnd = min(frameLength - 1, lastSoundFrame + paddingSamples)
        
        // If nothing to trim, return original
        if trimStart == 0 && trimEnd == frameLength - 1 {
            return nil
        }
        
        // Calculate new length
        let newLength = trimEnd - trimStart + 1
        
        guard newLength > 0 else { return nil }
        
        // Create new buffer with trimmed length
        guard let trimmedBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(newLength)
        ) else {
            return nil
        }
        
        trimmedBuffer.frameLength = AVAudioFrameCount(newLength)
        
        guard let trimmedChannelData = trimmedBuffer.floatChannelData else {
            return nil
        }
        
        // Copy trimmed audio data
        for channel in 0..<Int(format.channelCount) {
            let sourceData = channelData[channel]
            let destData = trimmedChannelData[channel]
            
            for frame in 0..<newLength {
                destData[frame] = sourceData[trimStart + frame]
            }
        }
        
        let originalDuration = Double(frameLength) / format.sampleRate
        let trimmedDuration = Double(newLength) / format.sampleRate
        let savedMs = (originalDuration - trimmedDuration) * 1000.0
        
        print("✂️ Trimmed silence: \(String(format: "%.3f", originalDuration))s → \(String(format: "%.3f", trimmedDuration))s (saved \(String(format: "%.0f", savedMs))ms)")
        
        return trimmedBuffer
    }
    
    /// Applies a fade-out envelope to prevent clicks when audio is trimmed
    private func applyFadeOut(to buffer: AVAudioPCMBuffer, fadeOutDurationMs: Double) {
        let format = buffer.format
        let frameLength = Int(buffer.frameLength)
        let sampleRate = format.sampleRate
        let fadeOutSamples = Int(fadeOutDurationMs / 1000.0 * sampleRate)
        
        // Start fade-out from this frame index
        let fadeStartFrame = max(0, frameLength - fadeOutSamples)
        
        guard let channelData = buffer.floatChannelData else { return }
        
        // Apply fade-out to all channels
        for channel in 0..<Int(format.channelCount) {
            let data = channelData[channel]
            
            for frame in fadeStartFrame..<frameLength {
                let fadePosition = Float(frame - fadeStartFrame) / Float(fadeOutSamples)
                let envelope = 1.0 - fadePosition  // Linear fade from 1.0 to 0.0
                data[frame] *= envelope
            }
        }
        
        print("🎚️ Applied \(String(format: "%.0f", fadeOutDurationMs))ms fade-out to audio")
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
    
    func start(resetBeatPosition: Bool = true) {
        guard !isRunning else { return }
        isRunning = true
        isFirstBeat = true
        
        // Only reset beat position if explicitly requested (default for user start/stop)
        // Don't reset when restarting after signature change (smart remapping already handled it)
        if resetBeatPosition {
            currentBeatInPattern = 0
        }
        
        nextBeatSampleTime = 0  // Reset timing
        scheduledBeatsCount = 0  // Reset scheduled count
        lastBeatTime = Date()  // Initialize beat timing
        
        print("🚀 Starting metronome: BPM=\(currentBPM), Signature=\(currentSignature.numerator)/\(currentSignature.denominator), Beat position: \(currentBeatInPattern)")
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
        
        // Generate new sound buffers
        generateClickSound(for: sound)
        generateAccentSound(for: sound)
        
        // That's it! No restart needed.
        // The scheduling loop will pick up the new buffers on the next iteration
        // because it reads clickBuffer/accentBuffer dynamically each time
        print("🔊 Sound changed to \(sound.rawValue) - new sound will be used for next scheduled beats")
    }
    
    func setSignature(_ signature: RhythmicSignature) {
        let oldSignature = currentSignature
        currentSignature = signature
        
        // Smart beat position remapping:
        // 1. If new signature has more beats, keep current position
        // 2. If new signature has fewer beats and current position is out of bounds, use modulo
        let oldPosition = currentBeatInPattern
        
        if signature.numerator >= oldSignature.numerator {
            // New signature has same or more beats - keep position as-is
            // (currentBeatInPattern stays the same)
            print("✨ Keeping beat position \(currentBeatInPattern) (new signature has \(signature.numerator) beats)")
        } else if currentBeatInPattern >= signature.numerator {
            // New signature has fewer beats and current position is out of bounds
            // Remap using modulo to land on a valid position
            currentBeatInPattern = currentBeatInPattern % signature.numerator
            print("✨ Remapped beat position from \(oldPosition) to \(currentBeatInPattern) (new signature has \(signature.numerator) beats)")
        } else {
            // New signature has fewer beats but current position is still valid
            print("✨ Keeping beat position \(currentBeatInPattern) (still valid in new signature with \(signature.numerator) beats)")
        }
        
        // If running, restart to apply new signature immediately
        if isRunning {
            // Stop current playback
            stop()
            
            // Smart delay calculation: only wait for the remaining time until next beat
            let beatInterval = oldSignature.intervalSeconds(at: currentBPM)
            let timeSinceLastBeat = Date().timeIntervalSince(lastBeatTime)
            let timeUntilNextBeat = beatInterval - timeSinceLastBeat
            
            // If we're past 75% of the beat interval, restart immediately to avoid long pause
            // Otherwise wait for the natural next beat time
            let delaySeconds = max(0.05, min(timeUntilNextBeat, beatInterval * 0.75))
            
            print("⏸️ Signature changed from \(oldSignature.displayString) to \(signature.displayString)")
            print("⏱️ Time since last beat: \(String(format: "%.3f", timeSinceLastBeat))s")
            print("⏳ Waiting \(String(format: "%.3f", delaySeconds))s before starting new rhythm")
            
            // Schedule restart after calculated delay
            // IMPORTANT: Pass resetBeatPosition: false to preserve our smart remapping
            DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) { [weak self] in
                guard let self = self else { return }
                // Only restart if we're not running (user didn't stop manually)
                if !self.isRunning {
                    self.start(resetBeatPosition: false)
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
                // Schedule first beat immediately (uses currentBeatInPattern, not necessarily beat 0)
                let beatThatWillPlay = currentBeatInPattern
                print("🎵 Scheduling first beat immediately (beat \(beatThatWillPlay))")
                
                // Use a weak self to avoid retain cycle
                playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                    print("✅ Beat \(beatThatWillPlay) completion handler called")
                    self?.scheduleQueue.async {
                        self?.scheduledBeatsCount -= 1
                        print("📉 Scheduled count after beat \(beatThatWillPlay): \(self?.scheduledBeatsCount ?? -1)")
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
                
                // Track when this beat fires for signature change timing
                lastBeatTime = Date()
                
                // Notify UI immediately with the ACTUAL current beat (not always 0)
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
                    
                    // Track when this beat fires for signature change timing
                    self.lastBeatTime = Date()
                    
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
