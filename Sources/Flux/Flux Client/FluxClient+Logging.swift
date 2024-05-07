import Foundation

public extension FluxClient {
    
    func logRequest(_ endpoint: Endpoint, _ request: URLRequest, _ response: URLResponse, _ data: Data) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        
        if let statusCode, (200...299) ~= statusCode {
            print("✨ Success - \(String(describing: endpoint))")
        } else {
            print("💔 Failure - \(String(describing: endpoint))")
        }
        
        print("‣ \(request.url?.absoluteString ?? "Unknown URL")")
        print("‣ Http Method: \(request.httpMethod ?? "Unknown HTTPMethod")")
        print("‣ Status Code: \(statusCode?.description ?? "Unknown Status Code")")
        print("‣ Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let httpBody = request.httpBody?.prettyPrintedJSON {
            print("‣ Request Body: \n\(httpBody)")
        }
        
        if let responseBody = data.prettyPrintedJSON {
            print("‣ Response: \n\(responseBody)")
        }
        
        print()
    }
}
