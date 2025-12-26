import Foundation

public extension NetworkingController {
    func logRequest(_ endpoint: Endpoint, _ request: URLRequest, _ response: URLResponse?, _ data: Data) {
        guard endpoint.shouldPrintLogs else { return }
        
        loggingQueue.async {
            var endpointName = String(describing: endpoint)
                .components(separatedBy: "(").first ?? String(describing: endpoint)
            endpointName.append(response == nil ? " (Mock)" : "")
            
            let statusCode = response?.status ?? .ok
            
            print()
            
            if statusCode.group == .success {
                print("✅ Success - \(endpointName)")
            } else {
                print("💔 Failure - \(endpointName)")
            }
            
            print(request.url?.absoluteString ?? "Unknown URL")
            print("‣ Http Method: \(request.httpMethod ?? "Unknown HTTPMethod")")
            print("‣ Status Code: \(statusCode.rawValue) (\(String(describing: statusCode)))")
            print("‣ Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            if let httpBody = request.httpBody?.prettyPrintedJson {
                print("‣ Request Body: \n\(httpBody)")
            }
            
            if let responseBody = data.prettyPrintedJson {
                print("‣ Response: \n\(responseBody)")
            }
        }
    }
    
    func logError(_ endpoint: Endpoint, _ error: Networking.Error, _ attempt: Int = .zero) {
        guard endpoint.shouldPrintLogs else { return }
        
        loggingQueue.async {
            var endpointName = String(describing: endpoint)
                .components(separatedBy: "(").first ?? String(describing: endpoint)
            
            #if DEBUG
            endpointName.append(endpoint.shouldUseSampleData ? " (Mock)" : "")
            #endif
            
            if endpoint.retryCount > .zero {
                let totalAttempts = endpoint.retryCount + 1
                endpointName.append(" (Attempt \(attempt + 1) of \(totalAttempts))")
            }
            
            print()
            print("⚠️ Error - \(endpointName)")
            print(error.debugDescription)
        }
    }
}
