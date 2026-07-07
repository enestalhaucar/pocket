import Foundation
import LocalAuthentication

/// Thin wrapper around Touch ID (with automatic password fallback).
enum Biometrics {
    /// Human-readable name of the available biometric, e.g. "Touch ID".
    static var label: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        default: return "parola"
        }
    }

    /// Prompts for Touch ID. Falls back to the login password if biometrics
    /// are unavailable. Returns true on success.
    static func authenticate(reason: String) async -> Bool {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Parola kullan"

        var error: NSError?
        // .deviceOwnerAuthentication == biometrics OR password fallback.
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
