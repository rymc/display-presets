import AppKit

final class DisplayModesView: NSView {
    var onSaveRequested: ((String) -> Void)? {
        get { composerView.onSaveRequested }
        set { composerView.onSaveRequested = newValue }
    }

    var onDeleteProfile: ((String) -> Void)? {
        get { profileListView.onDeleteProfile }
        set { profileListView.onDeleteProfile = newValue }
    }

    private let headerView = HeaderView()
    private let profileListView = ProfileListView()
    private let composerView = ProfileComposerView()
    private var profileListHeightConstraint: NSLayoutConstraint?

    private static let minimumContentHeight: CGFloat = 318
    private static let fixedContentHeight: CGFloat = 230

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureInterface()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setProfiles(_ profiles: [Profile]) {
        profileListView.setProfiles(profiles)
        profileListHeightConstraint?.constant = ProfileListView.preferredHeight(forProfileCount: profiles.count)
    }

    func setStatus(_ text: String, isError: Bool) {
        composerView.setStatus(text, isError: isError)
    }

    func setSaving(_ isSaving: Bool) {
        composerView.setSaving(isSaving)
    }

    func clearProfileName() {
        composerView.clearProfileName()
    }

    func focusProfileName() {
        composerView.focusProfileName()
    }

    static func preferredContentHeight(forProfileCount profileCount: Int) -> CGFloat {
        let height = fixedContentHeight + ProfileListView.visibleListHeight(forProfileCount: profileCount)
        return max(minimumContentHeight, height)
    }

    private func configureInterface() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let root = NSView()
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(headerView)

        profileListView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(profileListView)

        composerView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(composerView)

        profileListHeightConstraint = profileListView.heightAnchor.constraint(
            equalToConstant: ProfileListView.preferredHeight(forProfileCount: 2)
        )
        profileListHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            root.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            root.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            root.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -18),

            headerView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: root.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: HeaderView.preferredHeight),

            profileListView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            profileListView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            profileListView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),

            composerView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            composerView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            composerView.topAnchor.constraint(equalTo: profileListView.bottomAnchor, constant: 20),
            composerView.heightAnchor.constraint(equalToConstant: ProfileComposerView.preferredHeight),
            composerView.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor)
        ])
    }
}
