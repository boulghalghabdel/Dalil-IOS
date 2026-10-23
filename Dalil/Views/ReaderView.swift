import SwiftUI
import UIKit

/// Lecture d'un chapitre : le PDF page par page, signet, curseur de pages et réglages.
struct ReaderView: View {
    let chapter: Chapter

    @EnvironmentObject private var store: ReadingStore
    @State private var currentPage: Int
    @State private var renderer: PdfPageRenderer?
    @State private var loadFailed = false
    @State private var showSettings = false
    @State private var feedback = PageTurnFeedback()

    init(chapter: Chapter, startPage: Int) {
        self.chapter = chapter
        _currentPage = State(initialValue: startPage)
    }

    private var bookmarkPage: Int? { store.bookmark(for: chapter.day) }

    var body: some View {
        ZStack(alignment: .bottom) {
            store.background.color.ignoresSafeArea()

            if let renderer {
                PageCurlView(
                    renderer: renderer,
                    currentPage: $currentPage,
                    background: store.background,
                    bookmarkPage: bookmarkPage,
                    onPageTurnStart: pageTurnStarted
                )
                .ignoresSafeArea(edges: .bottom)

                PageScrubber(current: $currentPage, total: renderer.pageCount, bookmarkPage: bookmarkPage)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
            } else if loadFailed {
                Text("Chapitre introuvable.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Le lecteur gère lui-même le sens arabe (voir PageCurlView) : pas de retournement ici.
        .environment(\.layoutDirection, .leftToRight)
        .navigationTitle(chapter.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    store.toggleBookmark(chapterDay: chapter.day, page: currentPage)
                } label: {
                    BookmarkRibbon(
                        color: bookmarkPage == currentPage ? Theme.bookmarkRed : .primary,
                        filled: bookmarkPage == currentPage
                    )
                    .frame(width: 15, height: 22)
                }
                .accessibilityLabel(bookmarkPage == currentPage ? "Retirer le signet" : "Poser un signet")

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Paramètres")
            }
        }
        .sheet(isPresented: $showSettings) {
            ReaderSettingsView(feedback: feedback)
                .environmentObject(store)
                .presentationDetents([.medium])
        }
        .task { openDocument() }
        .onChange(of: currentPage) { page in
            saveProgress(page)
        }
        // L'écran reste allumé pendant la lecture : un hizb se récite souvent sans toucher l'écran.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func openDocument() {
        guard renderer == nil else { return }
        guard let url = chapter.pdfURL,
              let opened = PdfPageRenderer(url: url, screenWidthPx: Self.screenWidthPx) else {
            loadFailed = true
            return
        }
        currentPage = min(max(currentPage, 0), opened.pageCount - 1)
        renderer = opened
        saveProgress(currentPage)
    }

    private func saveProgress(_ page: Int) {
        guard let renderer else { return }
        store.saveProgress(chapterDay: chapter.day, page: page, pageCount: renderer.pageCount)
    }

    private func pageTurnStarted() {
        if store.soundOn { feedback.playSound() }
        if store.hapticOn { feedback.tick() }
    }

    private static var screenWidthPx: CGFloat {
        let screen = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen }
            .first
        guard let screen else { return 1200 }
        return screen.bounds.width * screen.scale
    }
}

/// Curseur de pages : la pastille « 3 / 30 » se fait glisser le long d'un rail pour aller à une page.
/// Sens arabe : la première page est à droite, la dernière à gauche. Le curseur s'estompe
/// quand on ne s'en sert pas, et reprend toute son opacité quand la page change.
struct PageScrubber: View {
    @Binding var current: Int
    let total: Int
    let bookmarkPage: Int?

    @State private var dragging = false
    @State private var dragFraction: CGFloat = 0
    @State private var active = true

    private let pillWidth: CGFloat = 70

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let span = max(width - pillWidth, 1)
            let fraction: CGFloat = dragging ? dragFraction : (total > 1 ? CGFloat(current) / CGFloat(total - 1) : 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.25))
                    .frame(height: 3)

                if let bookmarkPage, total > 1 {
                    let mark = CGFloat(bookmarkPage) / CGFloat(total - 1)
                    BookmarkRibbon()
                        .frame(width: 8, height: 14)
                        .offset(x: (1 - mark) * span + pillWidth / 2 - 4, y: -9)
                }

                Text("\(current + 1) / \(total)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .frame(width: pillWidth)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(dragging ? 0.8 : 0.6)))
                    .offset(x: (1 - fraction) * span)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragging = true
                        let f = min(max(1 - (value.location.x - pillWidth / 2) / span, 0), 1)
                        dragFraction = f
                        let page = Int((f * CGFloat(total - 1)).rounded())
                        if page != current { current = page }
                    }
                    .onEnded { _ in dragging = false }
            )
        }
        .frame(height: 44)
        .opacity(active || dragging ? 1 : 0.4)
        .animation(.easeOut(duration: 0.3), value: active || dragging)
        .task(id: "\(current)-\(dragging)") {
            active = true
            guard !dragging else { return }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if !Task.isCancelled { active = false }
        }
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) sur \(total)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: current = min(current + 1, total - 1)
            case .decrement: current = max(current - 1, 0)
            @unknown default: break
            }
        }
    }
}
