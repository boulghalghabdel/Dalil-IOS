import SwiftUI

@main
struct DalilApp: App {
    @StateObject private var store = ReadingStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                // Toute l'interface se lit de droite à gauche, comme le livre.
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
