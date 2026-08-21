import Foundation

/// A human-transcribable representation of a random UUID App User ID.
/// Activation codes are bearer credentials and must be shown only to the
/// customer who is entitled to use them.
public enum ActivationCode {
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    private static let payloadLength = 26

    public static func encode(appUserID: String) -> String? {
        guard let uuid = UUID(uuidString: appUserID) else { return nil }
        let bytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }
        var accumulator = 0, held = 0, symbols: [Int] = []
        for byte in bytes {
            accumulator = (accumulator << 8) | Int(byte); held += 8
            while held >= 5 { held -= 5; symbols.append((accumulator >> held) & 31) }
        }
        if held > 0 { symbols.append((accumulator << (5 - held)) & 31) }
        symbols.append(checksum(symbols))
        return stride(from: 0, to: symbols.count, by: 5).map {
            String(symbols[$0..<min($0 + 5, symbols.count)].map { alphabet[$0] })
        }.joined(separator: "-")
    }

    public static func decode(_ input: String) -> String? {
        let normalized = input.uppercased().reduce(into: "") { result, character in
            switch character { case "I", "L": result.append("1"); case "O": result.append("0"); case "-", " ", "\t", "\n": break; default: result.append(character) }
        }
        guard normalized.count == payloadLength + 1 else { return nil }
        let symbols = normalized.compactMap { alphabet.firstIndex(of: $0) }
        guard symbols.count == payloadLength + 1 else { return nil }
        let payload = Array(symbols.prefix(payloadLength))
        guard symbols.last == checksum(payload) else { return nil }
        var accumulator = 0, held = 0, bytes: [UInt8] = []
        for symbol in payload {
            accumulator = (accumulator << 5) | symbol; held += 5
            if held >= 8 { held -= 8; bytes.append(UInt8((accumulator >> held) & 255)) }
        }
        guard bytes.count == 16 else { return nil }
        return (NSUUID(uuidBytes: bytes) as UUID).uuidString.lowercased()
    }

    // This detects common transcription errors; provider-side created-user
    // handling remains the final safety net for a checksum collision.
    private static func checksum(_ symbols: [Int]) -> Int {
        symbols.enumerated().reduce(0) { ($0 + ($1.offset + 1) * $1.element) % 32 }
    }
}
