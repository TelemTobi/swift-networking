import Foundation
import Flux

enum TmdbEndpoint {
    case movieGenres
    case searchMovies(query: String)
    case favorite(body: FavoriteRequstBody)
}

extension TmdbEndpoint: Endpoint {

    var baseURL: URL {
        URL(string: Config.TmdbApi.baseUrl)!
    }
    
    var path: String {
        switch self {
        case .movieGenres: "/genre/movie/list"
        case .searchMovies: "/search/movie"
        case .favorite: "/account/favorite"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .movieGenres: .get
        case .searchMovies: .get
        case .favorite: .post
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .movieGenres:
            .empty
            
        case let .searchMovies(searchQuery):
            .withQueryParameters(["query": searchQuery])
            
        case let .favorite(body):
            .withBody(body)
        }
    }
    
    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        .convertFromSnakeCase
    }
    
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        .tmdbDateDecodingStrategy
    }
    
    var sampleData: Data? {
        nil // TODO
    }
}
