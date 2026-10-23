import UIKit

/// Une page du livre : image zoomable (pincer, double-tap) et ruban si la page porte le signet.
final class PageContentController: UIViewController, UIScrollViewDelegate {
    let pageIndex: Int
    private let background: ReadingBackground

    var isBookmarked = false {
        didSet { ribbon.isHidden = !isBookmarked }
    }

    var onZoomChanged: ((Bool) -> Void)?

    private static let maxZoom: CGFloat = 6
    private static let zoomThreshold: CGFloat = 1.02

    /// Annule le miroir du lecteur, pour que la page se lise à l'endroit.
    private let mirror = UIView()
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let ribbon = RibbonView()
    private var image: UIImage?
    private var zoomed = false

    init(pageIndex: Int, background: ReadingBackground) {
        self.pageIndex = pageIndex
        self.background = background
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) n'est pas utilisé")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Fond opaque : sans lui, la page suivante se verrait à travers la page courante.
        view.backgroundColor = background.uiColor
        mirror.transform = CGAffineTransform(scaleX: -1, y: 1)
        view.addSubview(mirror)

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = Self.maxZoom
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        // Déplacement à un doigt seulement une fois zoomé, pour laisser le geste de tourner la page.
        scrollView.panGestureRecognizer.isEnabled = false
        mirror.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        spinner.color = background.isDark ? .lightGray : .darkGray
        mirror.addSubview(spinner)

        ribbon.isHidden = !isBookmarked
        mirror.addSubview(ribbon)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        applyImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mirror.bounds = view.bounds
        mirror.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        if scrollView.frame != mirror.bounds {
            scrollView.zoomScale = 1
            scrollView.frame = mirror.bounds
            imageView.frame = scrollView.bounds
            scrollView.contentSize = scrollView.bounds.size
        }
        spinner.center = CGPoint(x: mirror.bounds.midX, y: mirror.bounds.midY)
        ribbon.frame = CGRect(x: mirror.bounds.width - 22 - 24, y: 0, width: 24, height: 46)
    }

    func setImage(_ image: UIImage) {
        self.image = image
        if isViewLoaded { applyImage() }
    }

    private func applyImage() {
        imageView.image = image
        if image == nil {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    // MARK: Zoom

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let nowZoomed = scrollView.zoomScale > Self.zoomThreshold
        guard nowZoomed != zoomed else { return }
        zoomed = nowZoomed
        scrollView.panGestureRecognizer.isEnabled = nowZoomed
        onZoomChanged?(nowZoomed)
    }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if zoomed {
            scrollView.setZoomScale(1, animated: true)
        } else {
            let scale: CGFloat = 2.5
            let point = recognizer.location(in: imageView)
            let size = CGSize(width: scrollView.bounds.width / scale, height: scrollView.bounds.height / scale)
            let rect = CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                              width: size.width, height: size.height)
            scrollView.zoom(to: rect, animated: true)
        }
    }
}

/// Ruban rouge du signet, posé en haut de la page, avec une petite ombre.
final class RibbonView: UIView {
    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        shape.fillColor = UIColor(hex: 0xB3261E).cgColor
        shape.shadowColor = UIColor.black.cgColor
        shape.shadowOpacity = 0.28
        shape.shadowOffset = CGSize(width: 1.5, height: 1.5)
        shape.shadowRadius = 0
        layer.addSublayer(shape)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) n'est pas utilisé")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width, h = bounds.height
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w / 2, y: h * 0.76))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.close()
        shape.frame = bounds
        shape.path = path.cgPath
    }
}
