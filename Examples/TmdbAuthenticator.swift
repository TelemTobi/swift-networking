import Foundation
import Flux

struct TmdbAuthenticator: Authenticator {
    
    var state: AuthenticationStatee {
        // Check network connection
        return .reachable
    }
    
    func authenticate() async throws -> Bool {
        // Authenticate the user if needed
        return true
    }
    
    func mapRequest(_ request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(Config.TmdbApi.accessToken, forHTTPHeaderField: "Authorization")
        request.url?.append(queryParameters: ["language": "en_us" /*user preferred language*/])
        // ...other global settings / credentials
    }
}
