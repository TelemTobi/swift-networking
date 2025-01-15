import Foundation

struct GenresResponse: Decodable {
    let genres: [Genre]?
}

struct Genre: Codable, Identifiable {
    let id: Int
    let name: String?
}

struct MovieList: Decodable {
    
    let results: [Movie]?
    let page: Int?
    let totalPages: Int?
    let totalResults: Int?
}

struct Movie: Codable, Identifiable {
    
    let id: Int
    var adult: Bool?
    var backdropPath: String?
    var budget: Int?
    var genres: [Genre]?
    var homepage: String?
    var imdbId: String?
    var originalLanguage: String?
    var originalTitle: String?
    var overview: String?
    var popularity: Float?
    var posterPath: String?
    var releaseDate: Date?
    var revenue: Int?
    var runtime: Int?
    var status: String?
    var tagline: String?
    var title: String?
    var video: Bool?
    var voteAverage: Float?
    var voteCount: Int?
}

struct EmptyResponse: Decodable {
    
}
