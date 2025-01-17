# Simplified Networking for Swift ⚡

**Networking** makes network requests in Swift easier and more maintainable. 🚀  
With a clean API, environment switching, and optional features like authentication and JSON mapping, you can focus on building great apps while we handle the rest.

---

## Quick Example

Here’s how easy it is to define API endpoints with **Networking**:

```swift
enum MyAPI {
    case getUser(userId: String)
    case updateProfile(name: String, email: String)
    case createPost(threadId: String, post: Post)
}

extension MyAPI: Endpoint {
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
```

That’s it! 💡 You’ve just made an API to work with. For more details, dive into the sections below.

---

## Why Use Networking? 🛠️

- **Organized API Definitions:** Define your endpoints with Swift enums for clarity and reusability.
- **Environment Management:** Easily switch between live, test, and preview environments.
- **Authentication (Optional):** Integrate your auth provider for secure API access and request mapping.
- **JSON Mapping (Optional):** Pre-process responses before decoding to suit your app's needs.
- **Error Handling:** Get meaningful errors to speed up debugging.
- **Flexible Logging:** Adjust verbosity to your needs for better debugging.

---

## Installation 🚀

### Swift Package Manager

Add **Networking** to your project via Swift Package Manager:  
1. In Xcode, go to **File > Swift Packages > Add Package Dependency**.  
2. Enter the repository URL:

   ```
   https://github.com/telemtobi/swift-networking.git
   ```

3. Select your preferred version and finish.

---

## Getting Started 🏁

### 1. Define Your API Endpoints

Use Swift enums to describe your API as seen in the example above ☝️

### 2. Make a Network Request

#### Using `NetworkingController`:

This approach offers authentication handling, environment switching, and error management for you:

```swift
let controller = NetworkingController<MyAPI, MyError>()

do {
    let response = try await controller.request(.getUser(userId: "123"))
    // ...
} catch {
    // Handle `MyError`
}
```

#### Using `URLRequest` Directly (Optional):

For more control, construct a `URLRequest` yourself:

```swift
let userEndpoint = MyAPI.getUser(userId: "123")
let urlRequest = URLRequest(userEndpoint)

let _ = try await URLSession.shared.data(for: urlRequest)
```

---

## Key Features 🔑

### Environment Switching

Set up multiple environments (e.g., live, test, preview) effortlessly:

```swift
struct MyApiClient {
  let controller = NetworkingController<MyAPI, MyError>(
      environment: .live
  )
}
```
These environments integrate nicely with PointFree's [Dependencies](https://github.com/pointfreeco/swift-dependencies) package:
```swift
extension MyApiClient: DependencyKey {
  static let liveValue = MyApiClient(environment: .live)
  static let testValue = MyApiClient(environment: .test)
  static let previewValue = MyApiClient(environment: .preview)
}
```

### Authentication

Plug in your auth provider for seamless integration:

```swift
let controller = NetworkingController<MyAPI, MyError>(
    authenticator: MyAuthenticator()
)
```
Using an authenticator, requests can be seamlessly configured to include general authentication headers, such as tokens or API keys.

### Logging Control

Enable or disable logging for specific endpoints:

```swift
extension MyAPI: Endpoint {
  ...
  var shouldPrintLogs: Bool {
    switch self { ... }
  }
}
```
Alternatively, change the global configuration:
```swift
Networking.DebugConfiguration.shouldPrintLogs = true
```

---

## Requirements 📋

- **Swift**: 5.x or later  
- **Xcode**: 15.x or later  

---

## Contributing 🙌

We’d love to see your ideas! 🧠 Whether it’s fixing bugs, improving documentation, or adding new features, your contributions are welcome.  

### How to Contribute:
1. Fork the repository and create your feature branch.  
2. Write clean, maintainable code with unit tests.  
3. Submit a pull request for review.  

If you encounter an issue or have a feature request, feel free to open a GitHub issue!

---

## License 📄

**Networking** is licensed under the MIT License. See the [LICENSE](https://github.com/TelemTobi/Networking/blob/main/LICENSE.txt) for details.

---

Happy coding with **Networking**! 🚀
