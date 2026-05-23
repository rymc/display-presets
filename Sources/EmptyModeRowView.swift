import AppKit

final class EmptyModeRowView: NSView {
    private let label = NSTextField(labelWithString: "No saved presets")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }
}
