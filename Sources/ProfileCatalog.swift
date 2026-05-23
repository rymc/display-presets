import Foundation

enum ProfileCatalog {
    static func loadProfiles() -> [Profile] {
        var profilesByName = ProfileStore.loadProfilesByName()
        var profiles = ProfileStore.loadOrder().compactMap { profilesByName.removeValue(forKey: $0) }

        profiles.append(contentsOf: profilesByName.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        })

        return profiles
    }
}
