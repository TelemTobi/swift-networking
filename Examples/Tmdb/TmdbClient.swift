import Foundation
import Networking

struct TmdbClient {
    
    private let authenticator: Authenticator
    private let controller: NetworkingController<TmdbEndpoint, TmdbError>
    
    init(environment: Networking.Environment = .live) {
        authenticator = TmdbAuthenticator()
        controller = NetworkingController(authenticator: authenticator, environment: environment)
    }
    
    func fetchGenres() async throws(TmdbError) -> GenresResponse {
        try await controller.request(.movieGenres)
    }
    
    func searchMovies(query: String) async -> Result<MovieList, TmdbError> {
        await controller.request(.searchMovies(query: query))
    }
}
