import Foundation

enum DisplayModeWorkflow {
    static func apply(_ profile: Profile, completion: @escaping (Result<Profile, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try DisplayplacerService.apply(profile)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    completion(.success(profile))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    static func captureCurrentMode(
        named name: String,
        allowOverwrite: Bool = false,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let normalizedName = ProfileStore.safeName(name)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let arguments = try DisplayplacerService.captureCurrentArguments()
                try ProfileStore.saveProfile(
                    name: normalizedName,
                    arguments: arguments,
                    allowOverwrite: allowOverwrite
                )

                DispatchQueue.main.async {
                    completion(.success(normalizedName))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
