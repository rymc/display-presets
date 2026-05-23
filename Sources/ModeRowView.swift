import AppKit

final class ModeRowView: NSView {
    static let rowHeight: CGFloat = 44

    private let nameLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let deleteButton = NSButton(title: "", target: nil, action: nil)
    private let separator = NSBox()
    private let profileName: String
    private let onDelete: (String) -> Void

    init(profile: Profile, isLast: Bool, onDelete: @escaping (String) -> Void) {
        self.profileName = profile.name
        self.onDelete = onDelete
        super.init(frame: .zero)
        configure(profile: profile, isLast: isLast)
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func configure(profile: Profile, isLast: Bool) {
        nameLabel.stringValue = profile.name
        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        detailLabel.stringValue = "\(profile.arguments.count) display\(profile.arguments.count == 1 ? "" : "s")"
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .left
        detailLabel.setContentHuggingPriority(.required, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailLabel)

        deleteButton.target = self
        deleteButton.action = #selector(deleteRequested)
        deleteButton.bezelStyle = .accessoryBarAction
        deleteButton.controlSize = .regular
        deleteButton.contentTintColor = .secondaryLabelColor
        deleteButton.identifier = NSUserInterfaceItemIdentifier(profile.name)
        deleteButton.toolTip = "Delete \(profile.name)"
        deleteButton.setAccessibilityLabel("Delete \(profile.name)")
        deleteButton.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete")
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(deleteButton)

        separator.boxType = .custom
        separator.borderWidth = 0
        separator.fillColor = .separatorColor
        separator.isHidden = isLast
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -0.5),
            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 12),

            detailLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -16),

            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28),

            separator.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    @objc private func deleteRequested() {
        onDelete(profileName)
    }
}
