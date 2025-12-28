# Swift Networking

A Swift package that makes network requests easier and more maintainable in your iOS, macOS, and other Apple platform applications. It provides a type-safe, clean API with powerful features like environment switching, request interception, and JSON mapping.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- ✨ Type-safe API endpoints using Swift enums
- 🌍 Built-in environment switching (live, test, preview)
- 🔒 Powerful request & response interception
- 🗺️ Flexible JSON mapping and response processing
- 🔁 Retry handling with exponential backoff (opt-in per endpoint)
- 📝 Comprehensive logging for debugging
- 💪 Full async/await support

## Quick Example

Here's how easy it is to define and use API endpoints with **Networking**:

```swift
enum MyEndpoint {
    case getUser(userId: String)
    case updateProfile(name: String, email: String)
    case createPost(threadId: String, post: Post)
}

extension MyEndpoint: Endpoint {
    var baseURL: URL { URL(string: "https://your-api.com/api/v1")! }

    var path: String {
        switch self {
        case let .getUser(userId): "/users/\(userId)"
        case .updateProfile: "/users/me"
        case .createPost: "/posts"
        }
    }

    var method: HttpMethod {
        switch self {
        case .getUser: .get
        case .updateProfile: .put
        case .createPost: .post
        }
    }

    var task: HttpTask {
        switch self {
        case .getUser:
            return .none

        case let .updateProfile(name, email):
            return .rawBody([
                "user_name": name,
                "email_address": email
            ])

        case let .createPost(threadId, post): 
            return .encodableBodyAndQuery(
                body: post,
                queryParameters: ["thread": threadId]
            )
        }
    }
}

// Making requests
let controller = NetworkingController<MyEndpoint, MyError>()

do {
    let user: User = try await controller.request(.getUser(userId: "123"))
    // Handle the user data
} catch {
    // Handle MyError
}
```

## Installation

### Swift Package Manager

Add **Networking** to your project via Swift Package Manager:  
1. In Xcode, go to **File > Swift Packages > Add Package Dependency**.  
2. Enter the repository URL:

   ```
   https://github.com/telemtobi/swift-networking.git
   ```

3. Select your preferred version and finish.

## Usage

### Environment Management

Easily switch between different environments:

```swift
// Configure with different environments
let controller = NetworkingController<MyEndpoint, MyError>(
    environment: .live    // For production
    // or .test          // For unit testing
    // or .preview       // For SwiftUI previews
)

// Works great with PointFree's Dependencies package
extension MyApiClient: DependencyKey {
    static let liveValue = MyApiClient(environment: .live)
    static let testValue = MyApiClient(environment: .test)
    static let previewValue = MyApiClient(environment: .preview)
}
```

### Request Interception

Integrate your request interceptor to handle authentication, modify requests/responses, and process errors:

```swift
class MyInterceptor: Interceptor {
    var authenticationState: AuthenticationState { .reachable }
    
    func authenticate() async throws -> Bool {
        // Your authentication logic
        return true
    }
    
    func intercept(_ request: inout URLRequest) {
        // Add headers, tokens, etc.
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    func intercept(_ data: inout Data) {
        // Process response data before decoding
        // Example: decrypt data, modify response format
    }
    
    func intercept(_ error: DecodableError) {
        // Handle or process errors
        // Example: refresh token on 401, log errors
    }
}

let controller = NetworkingController<MyEndpoint, MyError>(
    interceptor: MyInterceptor()
)
```

### JSON Mapping

Transform API responses before decoding:

```swift
struct User: Decodable, JsonMapper {
    let id: String
    let name: String
    
    static func map(_ data: Data) -> Data {
        // Transform response data if needed
        return data
    }
}
```

### Retry Handling

Control how many times a request should be retried after a failure. Retries apply to any thrown error (network, decoding, or interceptor-related) and use an exponential backoff that starts at `0.2s` and doubles with each retry. The initial request counts separately, so `retryCount` represents additional attempts (`retryCount = 2` -> up to 3 total attempts).

```swift
extension MyEndpoint: Endpoint {
    var retryCount: Int {
        switch self {
        case .getUser: 2   // Allow two retries (3 attempts total)
        case .updateProfile: 0   // No retries
        case .createPost: 1   // One retry (2 attempts total)
        }
    }
}
```

### Logging Control

Configure logging per endpoint or globally:

```swift
// Per endpoint
extension MyEndpoint: Endpoint {
    var shouldPrintLogs: Bool {
        switch self {
        case .sensitiveData: false
        default: true
        }
    }
}

// Global configuration
Networking.DebugConfiguration.shouldPrintLogs = true
```

## Requirements

- Swift 5.9 or later
- Xcode 15.0 or later
- iOS 13.0 / macOS 10.15 / tvOS 13.0 / watchOS 6.0 or later

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
