//
//  RhythmicSignature.swift
//  Guitar Beat
//
//  Created by Wenjing Wang on 12/22/25.
//

import Foundation

/// Represents a rhythmic signature as a fraction (numerator/denominator).
/// Example: 3/8 means three eighth-note beats per measure.
struct RhythmicSignature: Equatable, Hashable {
    /// Number of beats in the pattern (1-16)
    let numerator: Int
    
    /// Note value for each beat (1, 2, 4, 8, or 16)
    /// - 1 = whole note
    /// - 2 = half note
    /// - 4 = quarter note
    /// - 8 = eighth note
    /// - 16 = sixteenth note
    let denominator: Int
    
    // MARK: - Initialization
    
    init(numerator: Int = 4, denominator: Int = 4) {
        self.numerator = max(1, min(16, numerator))
        
        // Validate denominator is one of the allowed values
        let validDenominators = [1, 2, 4, 8, 16]
        if validDenominators.contains(denominator) {
            self.denominator = denominator
        } else {
            self.denominator = 4 // Default to quarter note
        }
    }
    
    // MARK: - Computed Properties
    
    /// Display string for the signature (e.g., "4/4", "3/8")
    var displayString: String {
        "\(numerator)/\(denominator)"
    }
    
    /// Calculate the interval multiplier relative to a quarter note.
    /// BPM is assumed to be in quarter notes per minute.
    ///
    /// Formula: multiplier = 4 / denominator
    /// - Quarter note (4): multiplier = 1.0
    /// - Eighth note (8): multiplier = 0.5 (twice as fast)
    /// - Half note (2): multiplier = 2.0 (twice as slow)
    /// - Sixteenth note (16): multiplier = 0.25 (four times as fast)
    var intervalMultiplier: Double {
        return 4.0 / Double(denominator)
    }
    
    /// Calculate the actual interval in seconds for one beat at a given BPM.
    /// - Parameter bpm: Beats per minute (quarter note = 1 beat)
    /// - Returns: Time in seconds between clicks
    func intervalSeconds(at bpm: Double) -> Double {
        // Base interval for quarter note
        let quarterNoteInterval = 60.0 / bpm
        
        // Apply denominator multiplier
        return quarterNoteInterval * intervalMultiplier
    }
    
    // MARK: - Common Signatures
    
    static let fourFour = RhythmicSignature(numerator: 4, denominator: 4)
    static let threeFour = RhythmicSignature(numerator: 3, denominator: 4)
    static let sixEight = RhythmicSignature(numerator: 6, denominator: 8)
    static let twoFour = RhythmicSignature(numerator: 2, denominator: 4)
    static let fiveFour = RhythmicSignature(numerator: 5, denominator: 4)
    static let sixteenFour = RhythmicSignature(numerator: 16, denominator: 4)
    
    // MARK: - Picker Values
    
    /// Valid numerator values (1-16)
    static let validNumerators = Array(1...16)
    
    /// Valid denominator values (whole, half, quarter, eighth, sixteenth)
    static let validDenominators = [1, 2, 4, 8, 16]
}
