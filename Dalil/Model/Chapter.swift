import Foundation

struct Chapter: Identifiable, Hashable {
    let day: Int
    let title: String
    /// Nom du PDF (sans « .pdf ») dans le dossier Chapters de l'app.
    let fileName: String
    /// Jour de la semaine où ce hizb se lit (1 = dimanche, 2 = lundi … 7 = samedi), ou nil.
    var weekday: Int? = nil

    var id: Int { day }

    var pdfURL: URL? {
        Bundle.main.url(forResource: fileName, withExtension: "pdf", subdirectory: "Chapters")
    }
}

/// Source unique des chapitres du livre, dans le même ordre que l'app Android.
enum ChapterRepository {
    static let chapters: [Chapter] = [
        Chapter(day: 1, title: "سورة طه", fileName: "chapter_1"),
        Chapter(day: 2, title: "سورة يس", fileName: "chapter_2"),
        Chapter(day: 3, title: "سورة الفتح", fileName: "chapter_fath"),
        Chapter(day: 4, title: "سورة الواقعة", fileName: "chapter_waqia"),
        Chapter(day: 5, title: "افتتاح دلائل الخيرات", fileName: "chapter_3"),
        Chapter(day: 6, title: "حزب يوم الإثنين (الأول)", fileName: "chapter_4", weekday: 2),
        Chapter(day: 7, title: "حزب يوم الثلاثاء", fileName: "chapter_5", weekday: 3),
        Chapter(day: 8, title: "حزب يوم الأربعاء", fileName: "chapter_6", weekday: 4),
        Chapter(day: 9, title: "حزب يوم الخميس", fileName: "chapter_7", weekday: 5),
        Chapter(day: 10, title: "حزب يوم الجمعة", fileName: "chapter_8", weekday: 6),
        Chapter(day: 11, title: "حزب يوم السبت", fileName: "chapter_9", weekday: 7),
        Chapter(day: 12, title: "حزب يوم الأحد", fileName: "chapter_10", weekday: 1),
        Chapter(day: 13, title: "حزب يوم الإثنين (الأخير)", fileName: "chapter_11", weekday: 2),
        Chapter(day: 14, title: "ختم", fileName: "chapter_12"),
        Chapter(day: 15, title: "الدعاء الناصري", fileName: "chapter_13"),
        Chapter(day: 16, title: "المنفرجة", fileName: "chapter_14"),
        Chapter(day: 17, title: "الصلاة المشيشية", fileName: "chapter_15"),
        Chapter(day: 18, title: "حزب النصر", fileName: "chapter_16"),
        Chapter(day: 19, title: "البردة", fileName: "chapter_17")
    ]

    static func chapter(day: Int) -> Chapter? {
        chapters.first { $0.day == day }
    }

    /// Hizb à lire aujourd'hui : un seul, sauf le lundi où l'on lit le premier et le dernier.
    static func todaysChapters(on date: Date = Date()) -> [Chapter] {
        let today = Calendar.current.component(.weekday, from: date)
        return chapters.filter { $0.weekday == today }
    }
}
