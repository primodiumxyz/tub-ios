import XCTest
@testable import Tub
import Apollo

class ApolloTests: XCTestCase {
    
    var apolloClient: ApolloClient!
    
    override func setUpWithError() throws {
        // Set up the Apollo client
        let url = URL(string: "https://your-graphql-endpoint.com")!
        apolloClient = ApolloClient(url: url)
    }
    
    override func tearDownWithError() throws {
        apolloClient = nil
    }
    
    // Add tests here
}
