import Foundation

extension String {
    
    func ensurePrefix(_ prefix: String) -> String {
        if hasPrefix(prefix) { return self }
        return prefix + self
    }
}
