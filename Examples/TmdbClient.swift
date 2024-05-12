import Foundation
import Flux

struct TmdbClient {
    
    private let authenticator: Authenticator
    private let provider: FluxProvider<TmdbEndpoint, TmdbError>
    
    init(environment: Flux.Environment = .live) {
        authenticator = TmdbAuthenticator()
        provider = FluxProvider(authenticator: authenticator, environment: environment)
    }
    
    func fetchGenres() async -> Result<GenresResponse, TmdbError> {
        await provider.request(.movieGenres)
    }
    
    func searchMovies(query: String) async -> Result<MovieList, TmdbError> {
        await provider.request(.searchMovies(query: query))
    }
    
    func addFavorite(movieId: Int, isFavorite: Bool) async -> Result<EmptyResponse, TmdbError> {
        let body = FavoriteRequstBody(movieId: movieId, isFavorite: isFavorite)
        return await provider.request(.favorite(body: body))
    }
}
