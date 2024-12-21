## Flux: A Streamlined Network Client for Swift ⚡

**Flux** simplifies network requests in your Swift projects, taking the burden off your shoulders. <br/>
Focus on building awesome features, and let Flux handle the network communication with a clear and organized approach.


## Features

- [x] **Organized API Calls:** Define your API endpoints in a single, well-structured Endpoint enum. Keep your code clean and maintainable by focusing on the logic of your application, not URL construction.
- [x] **Environment Handling:** Seamlessly switch between live, test, and preview environments. Make realistic test data with ease in the test environment, and provide sample data for SwiftUI previews without actual network calls.
- [x] **Authentication (Optional):** Integrate your authentication provider with Flux for a smooth user experience. Flux handles authentication checks and errors for you.
- [x] **JSON Mapping (Optional):** Process, validate, or transform incoming JSON data before decoding using JsonMapper. Ideal for cases where the raw response needs adjustments.
- [x] **Error Handling:** Flux gracefully handles network errors and provides informative error messages. Spend less time debugging network issues and more time building!
- [x] **Logging Control:** Control logging verbosity for specific endpoints with the shouldPrintLogs parameter.


## Installation
### Swift Package Manager

You can use Swift Package Manager to integrate **Flux** into your Xcode project. 

In Xcode, go to `File` > `Swift Packages` > `Add Package Dependency` and enter the repository URL:

```
https://github.com/TelemTobi/Flux.git
```


## Usage

**For a complete example, refer to the example project in the exaples folder of this repo.**

### 1. Define Your Endpoints:

Flux utilizes the power of Swift enums to define your API endpoints. Here's an example:

```swift
enum MyAPI {
  case getUser(userId: String)
  case updateProfile(name: String, email: String)
}

extension MyAPI: Endpoint {
  
  var baseURL: URL {
    return URL(string: "https://your-api.com/api/v1")!
  }
  
  var path: String {
    switch self {
    case let .getUser(userId): "/users/\(userId)"
    case .updateProfile: "/users/me"
    }
  }
  
  var method: HttpMethod {
    switch self {
    case .getUser: .get
    case .updateProfile: .put
    }
  }
  
  var task: HttpTask {
    switch self {
    case .getUser:
      .empty

    case let .updateProfile(name, email):
      .withBody(["name": name, "email": email]) // Alternatively, an encodable object can be provided
    }
  }
}
  
  // You can set other optional properties here if needed
```

### 2. Construct a URLRequest (Optional):

Flux provides the flexibility to construct a URLRequest directly using the Endpoint enum. This approach gives you full control over the request configuration.

```swift
let userEndpoint = MyAPI.getUser(userId: "123")
var urlRequest = URLRequest(userEndpoint)

try await URLSession.shared.data(for: urlRequest)
```

### 3. Use the FluxController (Convenience):

Flux also offers a convenient FluxController class that handles common network tasks for you. The FluxController takes care of authentication, environment handling, and error management.

```swift
let controller = FluxController<MyAPI, MyError>()

// Make a network request with async/await
do {
    let result = try await controller.request(.getUser(userId: "123"))
} catch {
    // Handle `MyError`
}

// Make a network request with completion handler
controller.request(.getUser(userId: "123")) { result in
    switch result {
    case let .success(user):
        // Handle success
    case let .failure(error):
        // Handle error
    }
}
```

**Remember: Using FluxController is entirely optional. You can still construct your own URLRequest using the Endpoint enum if you prefer more control over the network layer.**


## Requirements

Swift 5.x
Xcode 12.x or later


## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/TelemTobi/Flux/blob/main/LICENSE.txt) file for more details.

## Contributing

We welcome contributions to Flux! Feel free to open issues or pull requests to improve the library. Please follow these guidelines:

- Adhere to the existing code style and conventions.
- Write clear and concise code with documentation.
- Include unit tests for your changes.
- Open an issue to discuss any significant changes before submitting a pull request.

We hope you enjoy using Flux! ✨
