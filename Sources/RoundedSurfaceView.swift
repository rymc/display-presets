import AppKit

final class RoundedSurfaceView: NSView {
    var fillColor = NSColor.controlBackgroundColor {
        didSet { updateLayerAppearance() }
    }

    var borderColor = NSColor.separatorColor {
        didSet { updateLayerAppearance() }
    }

    var cornerRadius: CGFloat {
        didSet { updateLayerAppearance() }
    }

    init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        wantsLayer = true
        updateLayerAppearance()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateLayerAppearance()
    }

    private func updateLayerAppearance() {
        layer?.cornerRadius = cornerRadius
        layer?.backgroundColor = fillColor.cgColor
        layer?.borderColor = borderColor.cgColor
        layer?.borderWidth = borderColor == .clear ? 0 : 1
    }
}
