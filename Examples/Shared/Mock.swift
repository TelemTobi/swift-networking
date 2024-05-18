import Foundation

enum Mock: String {
    case movieGenres = "MovieGenresStub"
    case searchMovies = "SearchMoviesStub"
    
    var fileName: String {
        switch self {
        default:
            return self.rawValue
        }
    }
    
    var stringFromFile: String {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "json") else {
            fatalError("Stub Json file named: \(fileName) was not found.")
        }
        
        do {
            return try String(contentsOfFile: filePath)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    var dataEncoded: Data {
        stringFromFile.data(using: .utf8)!
    }
}
