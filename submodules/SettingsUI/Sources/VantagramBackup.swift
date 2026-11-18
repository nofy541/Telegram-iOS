import Foundation

/// Export and import of Vantagram settings. All of them live in UserDefaults under the `vantagram.` prefix.
enum VantagramBackup {
    private static let prefix = "vantagram."

    static func exportJSON() -> String? {
        var result: [String: Any] = [:]
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if key.hasPrefix(prefix) && (value is NSNumber || value is String) {
                result[key] = value
            }
        }
        guard JSONSerialization.isValidJSONObject(result) else {
            return nil
        }
        guard let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Returns the number of imported values.
    static func importJSON(_ text: String) -> Int {
        guard let data = text.data(using: .utf8) else {
            return 0
        }
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return 0
        }
        var count = 0
        for (key, value) in object {
            if key.hasPrefix(prefix) && (value is NSNumber || value is String) {
                UserDefaults.standard.set(value, forKey: key)
                count += 1
            }
        }
        return count
    }
}
