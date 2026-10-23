import AVFoundation
import UIKit

/// Bruit de papier et vibration très brève au tour de page.
final class PageTurnFeedback {
    private var player: AVAudioPlayer?
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    init() {
        // « Ambient » : le son respecte le bouton silencieux et n'interrompt pas une autre lecture audio.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        if let url = Bundle.main.url(forResource: "page_turn", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        }
    }

    func playSound() {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    func tick() {
        haptic.impactOccurred()
        haptic.prepare()
    }
}
