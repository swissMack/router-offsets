import SwiftUI

extension Color {
    /// Hex like "#e7cf9f" or "e7cf9f".
    init(hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let v = UInt64(h, radix: 16) ?? 0
        self.init(.sRGB,
                  red:   Double((v >> 16) & 0xff) / 255,
                  green: Double((v >> 8) & 0xff) / 255,
                  blue:  Double(v & 0xff) / 255)
    }
}
