import SwiftUI
import UIKit

extension View {
    /// Selects a text field's entire contents the moment it begins editing, so
    /// tapping in to change the value replaces it instead of appending — no need
    /// to delete the existing number first.
    ///
    /// SwiftUI `TextField` is backed by `UITextField`, so we listen for the
    /// begin-editing notification and set the selection. The `async` hop lets the
    /// system finish placing its own cursor first, otherwise it overrides ours.
    func selectAllOnEditing() -> some View {
        onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { note in
            guard let field = note.object as? UITextField else { return }
            // Small delay so our selection lands AFTER SwiftUI's formatter
            // re-positions the cursor on begin-editing; without it the select-all
            // is immediately overridden on formatted number fields.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                field.selectedTextRange = field.textRange(from: field.beginningOfDocument,
                                                          to: field.endOfDocument)
            }
        }
    }
}
