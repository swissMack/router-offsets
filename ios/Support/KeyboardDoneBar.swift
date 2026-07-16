import SwiftUI

extension View {
    /// Floats a "Done" bar just above the keyboard while `isFocused` is true.
    ///
    /// Uses `safeAreaInset` rather than `ToolbarItemGroup(placement: .keyboard)`,
    /// which fails to render on non-first tabs of a `TabView` (iOS 26). A safe-area
    /// inset is plain layout and works identically on every tab.
    func keyboardDoneBar(isFocused: FocusState<Bool>.Binding) -> some View {
        safeAreaInset(edge: .bottom) {
            if isFocused.wrappedValue {
                HStack {
                    Spacer()
                    Button("Done") { isFocused.wrappedValue = false }
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
    }
}
