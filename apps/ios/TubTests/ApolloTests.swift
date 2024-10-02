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
    
    func testGetAllTokensQuery() throws {
        let expectation = self.expectation(description: "Get All Tokens Query")
        
//        apolloClient.fetch(query: GetAllTokensQuery()) { result in
//            switch result {
//            case .success(let graphQLResult):
//                XCTAssertNotNil(graphQLResult.data)
//                if let tokens = graphQLResult.data?.token {
//                    XCTAssertFalse(tokens.isEmpty, "Tokens array should not be empty")
//                    if let firstToken = tokens.first {
//                        XCTAssertNotNil(firstToken.id)
//                        XCTAssertNotNil(firstToken.name)
//                        XCTAssertNotNil(firstToken.symbol)
//                        XCTAssertNotNil(firstToken.updated_at)
//                    }
//                } else {
//                    XCTFail("No tokens data received")
//                }
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Apollo query failed: \(error.localizedDescription)")
//            }
//        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
