import SwiftUI

/// Ouverture d'un chapitre, éventuellement à une page donnée (reprise, signet).
struct ReaderRoute: Hashable {
    let chapterDay: Int
    var page: Int = 0
}

/// Accueil : médaillon, « Continuer la lecture », hizb du jour, puis le sommaire.
struct HomeView: View {
    @EnvironmentObject private var store: ReadingStore
    @State private var path: [ReaderRoute] = []

    private let chapters = ChapterRepository.chapters

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    header

                    if let resume = store.resumeTarget(in: chapters) {
                        HighlightCard(
                            label: "متابعة القراءة",
                            title: resume.chapter.title,
                            detail: resumeDetail(resume),
                            filled: true
                        ) {
                            path.append(ReaderRoute(chapterDay: resume.chapter.day, page: resume.page))
                        }
                    }

                    ForEach(ChapterRepository.todaysChapters()) { chapter in
                        HighlightCard(label: "حزب اليوم", title: chapter.title, detail: nil, filled: false) {
                            path.append(ReaderRoute(chapterDay: chapter.day))
                        }
                    }

                    ForEach(chapters) { chapter in
                        ChapterRow(chapter: chapter, bookmarkPage: store.bookmark(for: chapter.day)) { page in
                            path.append(ReaderRoute(chapterDay: chapter.day, page: page))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Theme.pageBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ReaderRoute.self) { route in
                if let chapter = ChapterRepository.chapter(day: route.chapterDay) {
                    ReaderView(chapter: chapter, startPage: route.page)
                } else {
                    Text("Chapitre introuvable.")
                }
            }
        }
        .tint(Theme.titleBrown)
    }

    private var header: some View {
        VStack(spacing: 0) {
            Image("Medallion")
                .resizable()
                .scaledToFill()
                .frame(width: 190, height: 190)
                .clipShape(Circle())
                .padding(.top, 20)
            Text("دلائل الخيرات")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.titleBrown)
                .padding(.top, 14)
            Rectangle()
                .fill(Theme.accentGold)
                .frame(width: 160, height: 1)
                .padding(.top, 10)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
    }

    private func resumeDetail(_ resume: ResumeTarget) -> String? {
        if resume.isNextChapter { return "التالي" }
        if resume.pageCount > 0 { return "\(resume.page + 1) / \(resume.pageCount)" }
        return nil
    }
}

private struct HighlightCard: View {
    let label: String
    let title: String
    let detail: String?
    let filled: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let textColor = filled ? Color.white : Theme.textInk
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundStyle(textColor.opacity(0.8))
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(detail ?? "‹")
                    .font(.system(size: detail != nil ? 14 : 20, weight: .bold))
                    .foregroundStyle(filled ? Color.white.opacity(0.9) : Theme.accentGold)
                    // Le numéro de page « 3 / 30 » garde son ordre latin.
                    .environment(\.layoutDirection, .leftToRight)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(shape.fill(filled ? Theme.accentGreen : Theme.rowBackground))
            .overlay(shape.stroke(filled ? Color.clear : Theme.accentGold, lineWidth: 1.5))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

private struct ChapterRow: View {
    let chapter: Chapter
    let bookmarkPage: Int?
    /// Ouvre le chapitre à la page donnée : 0 pour la ligne, la page du signet pour le ruban.
    let open: (Int) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(String(format: "%02d", chapter.day))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accentGreen))

            Text(chapter.title)
                .font(.system(size: 17))
                .foregroundStyle(Theme.textInk)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let bookmarkPage {
                Button { open(bookmarkPage) } label: {
                    BookmarkRibbon()
                        .frame(width: 14, height: 22)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Signet, page \(bookmarkPage + 1)")
            }

            Text("‹")
                .font(.system(size: 18))
                .foregroundStyle(Theme.accentGold)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.rowBackground))
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { open(0) }
        .accessibilityAddTraits(.isButton)
    }
}
