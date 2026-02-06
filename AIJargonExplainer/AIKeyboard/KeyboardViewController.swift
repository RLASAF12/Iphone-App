import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let keyboardView = KeyboardView(
            onNextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            },
            hasFullAccess: self.hasFullAccess,
            getClipboard: {
                UIPasteboard.general.string
            }
        )

        let hostingController = UIHostingController(rootView: keyboardView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Set keyboard height
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 280)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
}
