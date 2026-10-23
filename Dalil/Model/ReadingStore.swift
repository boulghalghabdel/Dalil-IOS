import SwiftUI
import UIKit

/// Couleurs de fond proposées pour la lecture (même ordre que sur Android).
enum ReadingBackground: Int, CaseIterable, Identifiable {
    case white, sepia, softGreen, dark

    var id: Int { rawValue }

    var uiColor: UIColor {
        switch self {
        case .white: return UIColor(hex: 0xFFFFFF)
        case .sepia: return UIColor(hex: 0xF4ECD8)
        case .softGreen: return UIColor(hex: 0xDCEBD9)
        case .dark: return UIColor(hex: 0x2B2B2B)
        }
    }

    var color: Color { Color(uiColor) }

    /// Sur fond sombre, la page est inversée (texte clair) au lieu d'être simplement teintée.
    var isDark: Bool { self == .dark }
}

struct ReadingPosition: Equatable {
    let chapterDay: Int
    let page: Int
    let pageCount: Int
}

/// « Continuer la lecture » sur l'accueil : la page où l'on s'est arrêté, ou le chapitre suivant.
struct ResumeTarget {
    let chapter: Chapter
    let page: Int
    let pageCount: Int
    let isNextChapter: Bool
}

/// Réglages, signets et dernière position de lecture, gardés dans UserDefaults.
final class ReadingStore: ObservableObject {
    private enum Keys {
        static let background = "reading_background_color_index"
        static let sound = "page_turn_sound"
        static let haptic = "page_turn_haptic"
        static let bookmarks = "bookmarks"
        static let lastChapter = "last_chapter"
        static let lastPage = "last_page"
        static let lastCount = "last_page_count"
    }

    private let defaults: UserDefaults

    @Published var background: ReadingBackground {
        didSet { defaults.set(background.rawValue, forKey: Keys.background) }
    }

    // Son et vibration sont désactivés par défaut : ils se proposent, ils ne s'imposent pas.
    @Published var soundOn: Bool {
        didSet { defaults.set(soundOn, forKey: Keys.sound) }
    }

    @Published var hapticOn: Bool {
        didSet { defaults.set(hapticOn, forKey: Keys.haptic) }
    }

    /// Un seul signet par chapitre : numéro du chapitre → page (à partir de 0).
    @Published private(set) var bookmarks: [Int: Int]

    @Published private(set) var lastPosition: ReadingPosition?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        background = ReadingBackground(rawValue: defaults.integer(forKey: Keys.background)) ?? .white
        soundOn = defaults.bool(forKey: Keys.sound)
        hapticOn = defaults.bool(forKey: Keys.haptic)

        let stored = defaults.dictionary(forKey: Keys.bookmarks) as? [String: Int] ?? [:]
        bookmarks = Dictionary(uniqueKeysWithValues: stored.compactMap { key, page in
            Int(key).map { ($0, page) }
        })

        if defaults.object(forKey: Keys.lastChapter) != nil {
            lastPosition = ReadingPosition(
                chapterDay: defaults.integer(forKey: Keys.lastChapter),
                page: defaults.integer(forKey: Keys.lastPage),
                pageCount: defaults.integer(forKey: Keys.lastCount)
            )
        }
    }

    // MARK: Signets

    func bookmark(for chapterDay: Int) -> Int? {
        bookmarks[chapterDay]
    }

    func toggleBookmark(chapterDay: Int, page: Int) {
        if bookmarks[chapterDay] == page {
            bookmarks[chapterDay] = nil
        } else {
            bookmarks[chapterDay] = page
        }
        let stored = Dictionary(uniqueKeysWithValues: bookmarks.map { (String($0.key), $0.value) })
        defaults.set(stored, forKey: Keys.bookmarks)
    }

    // MARK: Position de lecture

    func saveProgress(chapterDay: Int, page: Int, pageCount: Int) {
        let position = ReadingPosition(chapterDay: chapterDay, page: page, pageCount: pageCount)
        guard position != lastPosition else { return }
        lastPosition = position
        defaults.set(chapterDay, forKey: Keys.lastChapter)
        defaults.set(page, forKey: Keys.lastPage)
        defaults.set(pageCount, forKey: Keys.lastCount)
    }

    /// Si la dernière page d'un chapitre a été atteinte, on propose le chapitre suivant.
    func resumeTarget(in chapters: [Chapter]) -> ResumeTarget? {
        guard let position = lastPosition,
              let index = chapters.firstIndex(where: { $0.day == position.chapterDay }) else { return nil }
        let finished = position.pageCount > 0 && position.page >= position.pageCount - 1
        if finished, index + 1 < chapters.count {
            return ResumeTarget(chapter: chapters[index + 1], page: 0, pageCount: 0, isNextChapter: true)
        }
        return ResumeTarget(chapter: chapters[index], page: position.page, pageCount: position.pageCount, isNextChapter: false)
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
