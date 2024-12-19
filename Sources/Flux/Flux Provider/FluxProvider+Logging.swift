import Foundation

public extension FluxController {
    
    func logRequest(_ endpoint: Endpoint, _ request: URLRequest, _ response: URLResponse, _ data: Data) {
        print()
        
        if response.status.group == .success {
            print("✅ Success - \(String(describing: endpoint))")
        } else {
            print("💔 Failure - \(String(describing: endpoint))")
        }
        
        print("‣ \(request.url?.absoluteString ?? "Unknown URL")")
        print("‣ Http Method: \(request.httpMethod ?? "Unknown HTTPMethod")")
        print("‣ Status Code: \(response.status.rawValue) (\(String(describing: response.status)))")
        print("‣ Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let httpBody = request.httpBody?.prettyPrintedJSON {
            print("‣ Request Body: \n\(httpBody)")
        }
        
        if let responseBody = data.prettyPrintedJSON {
            print("‣ Response: \n\(responseBody)")
        }
    }
}
