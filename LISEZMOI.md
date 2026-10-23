# دلائل الخيرات — version iOS (SwiftUI)

Réécriture iOS de l'app Android qui se trouve dans `D:\PJ\PROJET1`. Le projet Android n'a pas été modifié.

## Ce qui est porté

| Android (Kotlin / Compose) | iOS (Swift / SwiftUI) |
|---|---|
| `CalendarScreen.kt` (accueil, sommaire) | `Dalil/Views/HomeView.swift` |
| `ChapterScreen.kt` (lecteur, curseur de pages) | `Dalil/Views/ReaderView.swift` |
| Dialogue « Paramètres de lecture » | `Dalil/Views/ReaderSettingsView.swift` |
| Bibliothèque PageCurl (page qui se courbe) | `Dalil/Reader/PageCurlView.swift` (UIPageViewController, style pageCurl) |
| `ZoomablePageImage` | `Dalil/Reader/PageContentController.swift` (UIScrollView) |
| `PdfPageRenderer.kt` (PdfRenderer) | `Dalil/Reader/PdfPageRenderer.swift` (PDFKit) |
| `ChapterRepository.kt`, `Chapter.kt` | `Dalil/Model/Chapter.swift` |
| `Bookmarks`, `ReadingProgress`, `ReadingSettings` (SharedPreferences) | `Dalil/Model/ReadingStore.swift` (UserDefaults) |
| `PageTurnFeedback.kt` | `Dalil/Reader/PageTurnFeedback.swift` |
| `assets/chapters/*.pdf` | `Chapters/*.pdf` (copiés tels quels) |

Fonctionnalités :

- Sommaire des 19 chapitres dans le même ordre (Taha, Yassin, Al-Fath, Al-Waqi'a, Iftitah, les hizb de la semaine, Khatm, etc.).
- « متابعة القراءة » (reprendre là où on s'est arrêté, ou passer au chapitre suivant) et « حزب اليوم ».
- Lecteur PDF avec page qui se courbe dans le sens arabe : on soulève le bord gauche de la page vers la droite.
- Zoom en pinçant (jusqu'à 6×), double-tap pour zoomer ou revenir. On ne tourne pas la page pendant un zoom.
- Couleur de fond : blanc, sépia, vert doux, sombre. Sur fond sombre la page est inversée (texte clair), ce qui corrige le fond sombre illisible de la version Android.
- Les pages gardent leurs proportions (pas d'étirement) et les marges blanches sont recadrées.
- Signet par chapitre (ruban rouge), curseur de pages « 3 / 30 », son et vibration du tour de page (désactivés par défaut), écran qui reste allumé pendant la lecture.

Pas encore porté : la lecture à voix haute (`SpeechReader.kt`). Elle se fera avec `AVSpeechSynthesizer`, qui a une voix arabe intégrée sur iPhone.

## Il faut un Mac pour compiler

Une app iOS ne se compile qu'avec Xcode, qui n'existe que sur macOS. Depuis Windows, trois possibilités :

1. **Un Mac** (le vôtre, celui d'un proche, ou un Mac mini d'occasion). C'est le plus simple pour tester sur un iPhone.
2. **Un Mac loué dans le cloud** (MacinCloud, AWS EC2 Mac, Scaleway Mac mini…), utilisé à distance depuis Windows.
3. **Un service de build cloud** : GitHub Actions (le fichier `.github/workflows/ios-build.yml` est déjà en place ; `ci/` en est une simple copie), Codemagic ou Bitrise. Ils compilent sans Mac, mais pour installer l'app sur un iPhone ou la publier il faut un compte Apple Developer (99 $/an) et configurer la signature.

## Ouvrir le projet sur un Mac

1. Copier le dossier `DALIL-iOS` sur le Mac.
2. Installer Xcode (App Store) puis XcodeGen : `brew install xcodegen`.
3. Dans le dossier : `xcodegen generate`. Cela crée `Dalil.xcodeproj` à partir de `project.yml`.
4. Ouvrir `Dalil.xcodeproj`, choisir un simulateur iPhone, puis ▶︎ (Cmd+R).
5. Pour un vrai iPhone : onglet *Signing & Capabilities*, choisir votre équipe (un identifiant Apple gratuit suffit pour tester 7 jours).

L'identifiant de l'app est `com.dalil.alkhayrat` (dans `project.yml`). Changez-le avant de publier sur l'App Store si vous voulez un autre nom.

## À vérifier au premier lancement

Le code a été écrit sans pouvoir être compilé (pas de Mac de ce côté). Points à regarder en priorité :

- le sens du tour de page (le doigt de gauche vers la droite fait avancer) ;
- le zoom puis le retour à 1×, et le fait que la page ne tourne pas pendant le zoom ;
- le fond sombre ;
- le curseur de pages en bas.

S'il y a une erreur de compilation, copiez le message d'Xcode tel quel : il se corrige vite.
