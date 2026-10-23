import SwiftUI
import UIKit

/// Lecteur à pages qui se courbent (UIPageViewController, style pageCurl), dans le sens arabe.
///
/// UIPageViewController tourne les pages comme un livre latin : on tire le bord droit vers la gauche.
/// On le retourne donc en miroir, puis chaque page est retournée à nouveau pour rester lisible :
/// on soulève ainsi le bord gauche de la page vers la droite, comme dans un livre arabe.
struct PageCurlView: UIViewControllerRepresentable {
    let renderer: PdfPageRenderer
    @Binding var currentPage: Int
    let background: ReadingBackground
    let bookmarkPage: Int?
    var onPageTurnStart: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CurlHostController {
        let host = CurlHostController()
        let coordinator = context.coordinator
        coordinator.host = host
        host.pageViewController.dataSource = coordinator
        host.pageViewController.delegate = coordinator
        coordinator.show(page: currentPage)
        return host
    }

    func updateUIViewController(_ host: CurlHostController, context: Context) {
        let coordinator = context.coordinator
        let backgroundChanged = coordinator.parent.background != background
        coordinator.parent = self

        if backgroundChanged || currentPage != coordinator.displayedPage {
            // Saut avec le curseur de pages, ou nouvelle couleur : la page est refaite sans animation.
            coordinator.show(page: currentPage)
        } else {
            coordinator.visiblePage?.isBookmarked = coordinator.displayedPage == bookmarkPage
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlView
        weak var host: CurlHostController?
        private(set) var displayedPage = -1

        init(parent: PageCurlView) {
            self.parent = parent
        }

        var visiblePage: PageContentController? {
            host?.pageViewController.viewControllers?.first as? PageContentController
        }

        func show(page: Int) {
            guard let host else { return }
            let index = min(max(page, 0), parent.renderer.pageCount - 1)
            displayedPage = index
            host.setPageTurnEnabled(true)
            host.pageViewController.setViewControllers([makePage(index)], direction: .forward, animated: false)
            parent.renderer.prefetch(around: index, background: parent.background)
        }

        private func makePage(_ index: Int) -> PageContentController {
            let background = parent.background
            let page = PageContentController(pageIndex: index, background: background)
            page.isBookmarked = index == parent.bookmarkPage
            // On ne tourne pas la page pendant un zoom : le doigt sert alors à se déplacer dans la page.
            page.onZoomChanged = { [weak self] zoomed in
                self?.host?.setPageTurnEnabled(!zoomed)
            }
            parent.renderer.image(for: index, background: background) { [weak page] image in
                page?.setImage(image)
            }
            return page
        }

        // MARK: UIPageViewControllerDataSource

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let page = viewController as? PageContentController, page.pageIndex > 0 else { return nil }
            return makePage(page.pageIndex - 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let page = viewController as? PageContentController,
                  page.pageIndex < parent.renderer.pageCount - 1 else { return nil }
            return makePage(page.pageIndex + 1)
        }

        // MARK: UIPageViewControllerDelegate

        func pageViewController(_ pageViewController: UIPageViewController,
                                willTransitionTo pendingViewControllers: [UIViewController]) {
            parent.onPageTurnStart()
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard completed, let page = visiblePage else { return }
            displayedPage = page.pageIndex
            host?.setPageTurnEnabled(true)
            parent.renderer.prefetch(around: page.pageIndex, background: parent.background)
            // displayedPage est déjà à jour : la mise à jour qui suit ne refait pas la page.
            parent.currentPage = page.pageIndex
        }
    }
}

/// Contient le UIPageViewController retourné en miroir.
final class CurlHostController: UIViewController {
    let pageViewController = UIPageViewController(
        transitionStyle: .pageCurl,
        navigationOrientation: .horizontal,
        options: [.spineLocation: NSNumber(value: UIPageViewController.SpineLocation.min.rawValue)]
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.isDoubleSided = false
        pageViewController.view.transform = CGAffineTransform(scaleX: -1, y: 1)

        // Pas de changement de page au simple toucher : le double-tap sert au zoom.
        for recognizer in pageViewController.gestureRecognizers where recognizer is UITapGestureRecognizer {
            recognizer.isEnabled = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // bounds et center (et non frame) : la vue porte une transformation.
        pageViewController.view.bounds = view.bounds
        pageViewController.view.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    func setPageTurnEnabled(_ enabled: Bool) {
        for recognizer in pageViewController.gestureRecognizers where recognizer is UIPanGestureRecognizer {
            recognizer.isEnabled = enabled
        }
    }
}
