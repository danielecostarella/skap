import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    @Published private(set) var availableVersion: String?

    private let repoOwner = "danielecostarella"
    private let repoName  = "skap"

    func checkInBackground() {
        Task {
            // Small delay so it doesn't slow app startup
            try? await Task.sleep(for: .seconds(3))
            await check()
        }
    }

    private func check() async {
        guard let current = currentVersion(),
              let latest  = await fetchLatestTag(),
              isNewer(latest, than: current)
        else { return }

        availableVersion = latest
    }

    private func currentVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private func fetchLatestTag() async -> String? {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String
        else { return nil }

        return tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    // Returns true if `candidate` is a higher semver than `current`.
    private func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").compactMap { Int($0) }
        let b = current.split(separator: ".").compactMap { Int($0) }
        for i in 0 ..< max(a.count, b.count) {
            let av = i < a.count ? a[i] : 0
            let bv = i < b.count ? b[i] : 0
            if av != bv { return av > bv }
        }
        return false
    }
}
