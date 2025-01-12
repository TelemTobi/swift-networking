import Foundation
import Networking

struct TmdbClient {
    
    private let authenticator: Authenticator
    private let controller: FluxController<TmdbEndpoint, TmdbError>
    
    init(environment: Networking.Environment = .live) {
        authenticator = TmdbAuthenticator()
        controller = FluxController(authenticator: authenticator, environment: environment)
    }
    
    func fetchGenres() async -> Result<GenresResponse, TmdbError> {
        await controller.request(.movieGenres)
    }
    
    func searchMovies(query: String) async -> Result<MovieList, TmdbError> {
        await controller.request(.searchMovies(query: query))
    }
    
    func addFavorite(movieId: Int, isFavorite: Bool) async -> Result<EmptyResponse, TmdbError> {
        let body = FavoriteRequstBody(movieId: movieId, isFavorite: isFavorite)
        return await controller.request(.favorite(body: body))
    }
}
