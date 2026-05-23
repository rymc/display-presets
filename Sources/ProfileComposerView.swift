import AppKit

final class ProfileComposerView: NSView {
    static let preferredHeight: CGFloat = 77

    var onSaveRequested: ((String) -> Void)?

    private let composerLabel = NSTextField(labelWithString: "Save Current Preset")
    private let profileNameField = NSTextField()
    private let captureButton = NSButton(title: "Save", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setStatus(_ text: String, isError: Bool) {
        statusLabel.stringValue = text
        statusLabel.textColor = isError ? .systemRed : .secondaryLabelColor
    }

    func setSaving(_ isSaving: Bool) {
        profileNameField.isEnabled = !isSaving
        captureButton.isEnabled = !isSaving
    }

    func clearProfileName() {
        profileNameField.stringValue = ""
    }

    func focusProfileName() {
        window?.makeFirstResponder(profileNameField)
    }

    private func configure() {
        configureSectionLabel(composerLabel)
        addSubview(composerLabel)

        profileNameField.placeholderString = "Name this preset"
        profileNameField.controlSize = .regular
        profileNameField.bezelStyle = .roundedBezel
        profileNameField.font = .systemFont(ofSize: 13)
        profileNameField.setAccessibilityLabel("Preset name")
        profileNameField.target = self
        profileNameField.action = #selector(saveRequested)
        profileNameField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileNameField)

        captureButton.bezelStyle = .rounded
        captureButton.controlSize = .regular
        captureButton.keyEquivalent = "\r"
        captureButton.target = self
        captureButton.action = #selector(saveRequested)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(captureButton)

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)

        NSLayoutConstraint.activate([
            composerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            composerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            composerLabel.topAnchor.constraint(equalTo: topAnchor),
            composerLabel.heightAnchor.constraint(equalToConstant: 17),

            profileNameField.leadingAnchor.constraint(equalTo: leadingAnchor),
            profileNameField.topAnchor.constraint(equalTo: composerLabel.bottomAnchor, constant: 7),
            profileNameField.heightAnchor.constraint(equalToConstant: 28),

            captureButton.leadingAnchor.constraint(equalTo: profileNameField.trailingAnchor, constant: 10),
            captureButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            captureButton.centerYAnchor.constraint(equalTo: profileNameField.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalTo: profileNameField.heightAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: profileNameField.bottomAnchor, constant: 8),
            statusLabel.heightAnchor.constraint(equalToConstant: 17),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func saveRequested() {
        onSaveRequested?(profileNameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func configureSectionLabel(_ label: NSTextField) {
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
    }
}
