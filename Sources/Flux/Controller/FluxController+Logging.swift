import Foundation

public extension FluxController {
    
    #if DEBUG
    func logRequest(_ endpoint: Endpoint, _ request: URLRequest, _ response: URLResponse, _ data: Data) {
        loggingQueue.async {
            let endpointName = String(describing: endpoint)
                .components(separatedBy: "(").first ?? String(describing: endpoint)
            
            print()
            
            if response.status.group == .success {
                print("✅ Success - \(String(describing: endpointName))")
            } else {
                print("💔 Failure - \(String(describing: endpointName))")
            }
            
            print(request.url?.absoluteString ?? "Unknown URL")
            print("‣ Http Method: \(request.httpMethod ?? "Unknown HTTPMethod")")
            print("‣ Status Code: \(response.status.rawValue) (\(String(describing: response.status)))")
            print("‣ Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            if let httpBody = request.httpBody?.prettyPrintedJson {
                print("‣ Request Body: \n\(httpBody)")
            }
            
            if let responseBody = data.prettyPrintedJson {
                print("‣ Response: \n\(responseBody)")
            }
        }
    }
    #endif
}
