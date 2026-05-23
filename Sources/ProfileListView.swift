import AppKit

final class ProfileListView: NSView {
    var onDeleteProfile: ((String) -> Void)?

    private let savedLabel = NSTextField(labelWithString: "Saved Presets")
    private let listSurface = RoundedSurfaceView(cornerRadius: 9)
    private let scrollView = NSScrollView()
    private let modeDocumentView = FlippedDocumentView()
    private let modeStack = NSStackView()
    private var listHeightConstraint: NSLayoutConstraint?
    private var documentHeightConstraint: NSLayoutConstraint?
    private var profiles: [Profile] = []

    private static let labelHeight: CGFloat = 17
    private static let labelToListSpacing: CGFloat = 7
    private static let maximumVisibleRows = 5

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        nil
    }

    static func visibleListHeight(forProfileCount profileCount: Int) -> CGFloat {
        let rowCount = max(profileCount, 1)
        let visibleRowCount = min(rowCount, maximumVisibleRows)
        return CGFloat(visibleRowCount) * ModeRowView.rowHeight
    }

    static func preferredHeight(forProfileCount profileCount: Int) -> CGFloat {
        labelHeight + labelToListSpacing + visibleListHeight(forProfileCount: profileCount)
    }

    func setProfiles(_ profiles: [Profile]) {
        self.profiles = profiles

        let rowCount = max(profiles.count, 1)
        let visibleHeight = Self.visibleListHeight(forProfileCount: profiles.count)
        listHeightConstraint?.constant = visibleHeight
        documentHeightConstraint?.constant = CGFloat(rowCount) * ModeRowView.rowHeight
        scrollView.hasVerticalScroller = CGFloat(rowCount) * ModeRowView.rowHeight > visibleHeight
        rebuildRows()
        scrollToTop()
    }

    private func configure() {
        configureSectionLabel(savedLabel)
        addSubview(savedLabel)

        listSurface.fillColor = .controlBackgroundColor
        listSurface.borderColor = .separatorColor
        listSurface.translatesAutoresizingMaskIntoConstraints = false
        addSubview(listSurface)

        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScrollElasticity = .automatic
        scrollView.horizontalScrollElasticity = .none
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        listSurface.addSubview(scrollView)

        modeDocumentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = modeDocumentView

        modeStack.orientation = .vertical
        modeStack.alignment = .leading
        modeStack.distribution = .fill
        modeStack.spacing = 0
        modeStack.setAccessibilityLabel("Saved Presets")
        modeStack.translatesAutoresizingMaskIntoConstraints = false
        modeDocumentView.addSubview(modeStack)

        listHeightConstraint = listSurface.heightAnchor.constraint(equalToConstant: 88)
        listHeightConstraint?.isActive = true
        documentHeightConstraint = modeDocumentView.heightAnchor.constraint(equalToConstant: 88)
        documentHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            savedLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            savedLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            savedLabel.topAnchor.constraint(equalTo: topAnchor),
            savedLabel.heightAnchor.constraint(equalToConstant: Self.labelHeight),

            listSurface.leadingAnchor.constraint(equalTo: leadingAnchor),
            listSurface.trailingAnchor.constraint(equalTo: trailingAnchor),
            listSurface.topAnchor.constraint(equalTo: savedLabel.bottomAnchor, constant: Self.labelToListSpacing),
            listSurface.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: listSurface.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: listSurface.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: listSurface.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: listSurface.bottomAnchor),

            modeDocumentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            modeDocumentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            modeDocumentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            modeDocumentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),

            modeStack.leadingAnchor.constraint(equalTo: modeDocumentView.leadingAnchor),
            modeStack.trailingAnchor.constraint(equalTo: modeDocumentView.trailingAnchor),
            modeStack.topAnchor.constraint(equalTo: modeDocumentView.topAnchor),
            modeStack.bottomAnchor.constraint(equalTo: modeDocumentView.bottomAnchor)
        ])
    }

    private func rebuildRows() {
        modeStack.arrangedSubviews.forEach { view in
            modeStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        guard !profiles.isEmpty else {
            let emptyRow = EmptyModeRowView()
            modeStack.addArrangedSubview(emptyRow)
            emptyRow.widthAnchor.constraint(equalTo: modeStack.widthAnchor).isActive = true
            emptyRow.heightAnchor.constraint(equalToConstant: ModeRowView.rowHeight).isActive = true
            return
        }

        for (index, profile) in profiles.enumerated() {
            let row = ModeRowView(
                profile: profile,
                isLast: index == profiles.count - 1,
                onDelete: { [weak self] name in
                    self?.onDeleteProfile?(name)
                }
            )
            modeStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: modeStack.widthAnchor).isActive = true
            row.heightAnchor.constraint(equalToConstant: ModeRowView.rowHeight).isActive = true
        }
    }

    private func scrollToTop() {
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func configureSectionLabel(_ label: NSTextField) {
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
    }
}
