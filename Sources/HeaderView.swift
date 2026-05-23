import AppKit

final class HeaderView: NSView {
    static let preferredHeight: CGFloat = 46

    private let iconPlate = RoundedSurfaceView(cornerRadius: 10)
    private let headerIcon = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Display Presets")
    private let subtitleLabel = NSTextField(labelWithString: "Save display arrangements and switch from the menu bar.")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func configure() {
        iconPlate.fillColor = NSColor.controlAccentColor.withAlphaComponent(0.14)
        iconPlate.borderColor = .clear
        iconPlate.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconPlate)

        headerIcon.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: nil)
        headerIcon.contentTintColor = .controlAccentColor
        headerIcon.symbolConfiguration = .init(pointSize: 21, weight: .medium)
        headerIcon.translatesAutoresizingMaskIntoConstraints = false
        iconPlate.addSubview(headerIcon)

        titleLabel.font = .systemFont(ofSize: 21, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconPlate.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconPlate.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            iconPlate.widthAnchor.constraint(equalToConstant: 40),
            iconPlate.heightAnchor.constraint(equalToConstant: 40),

            headerIcon.centerXAnchor.constraint(equalTo: iconPlate.centerXAnchor),
            headerIcon.centerYAnchor.constraint(equalTo: iconPlate.centerYAnchor),
            headerIcon.widthAnchor.constraint(equalToConstant: 24),
            headerIcon.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconPlate.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
}
