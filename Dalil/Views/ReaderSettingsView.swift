import SwiftUI

/// Paramètres de lecture : couleur de fond, son et vibration du tour de page.
struct ReaderSettingsView: View {
    let feedback: PageTurnFeedback

    @EnvironmentObject private var store: ReadingStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Couleur de fond") {
                    HStack(spacing: 16) {
                        ForEach(ReadingBackground.allCases) { option in
                            let selected = option == store.background
                            Button {
                                store.background = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 48, height: 48)
                                    .overlay(Circle().stroke(selected ? Color.primary : Color.gray, lineWidth: selected ? 3 : 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Son du tour de page", isOn: $store.soundOn)
                    Toggle("Vibration légère", isOn: $store.hapticOn)
                }
            }
            .navigationTitle("Paramètres de lecture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            // On fait entendre ou sentir le réglage au moment où on l'active.
            .onChange(of: store.soundOn) { on in if on { feedback.playSound() } }
            .onChange(of: store.hapticOn) { on in if on { feedback.tick() } }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}
