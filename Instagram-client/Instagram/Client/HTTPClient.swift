//
//  HTTPClient.swift
//  Amazon
//
//  Created by Riptik Jhajhria on 23/03/25.
//

import Foundation

//error handling
enum NetworkError: Error {
    case badRequest
    case decodingError(Error)
    case invalidResponse
    case errorResponse(ErrorResponse)
}

extension NetworkError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .badRequest:
            return NSLocalizedString("Bad Request (400): Unable to perform the request.", comment: "badRequestError")
        case .decodingError(let error):
            return NSLocalizedString("Unable to decode successfully. \(error)", comment: "decodingError")
        case .invalidResponse:
            return NSLocalizedString("Invalid response.", comment: "invalidResponse")
        case .errorResponse(let errorResponse):
            return NSLocalizedString("Error \(errorResponse.message ?? "")", comment: "Error Response")
        }
    }
}

enum HTTPMethod {
    case get([URLQueryItem])
    case post (Data?)
    case delete
    case put(Data?)
    
    var name: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .delete:
            return "DELETE"
        case .put:
            return "PUT"
        }
    }
}

struct Resource<T: Codable> {
    let url: URL
    var method: HTTPMethod = .get([])
    var headers: [String: String]? = nil
    var modelType: T.Type
}

struct HTTPClient {
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Content-Type": "application/json"]
        self.session = URLSession(configuration: configuration)
        
        // Use our configured JSON decoder
        self.jsonDecoder = HTTPClient.configuredJSONDecoder()
    }
    
    func load<T: Codable>(_ resource: Resource<T>) async throws -> T {
        var request = URLRequest(url: resource.url)
        
        var headers: [String: String] = resource.headers ?? [: ]
        if let token = Keychain<String>.get("jwttoken") {
            headers["Authorization"] = "Bearer \(token)"
        }
        //add headers to the request
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // set HTTP method and body if needed
        switch resource.method {
        case .get(let queryItems):
            var components = URLComponents(url: resource.url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            guard let url = components?.url else { throw NetworkError.badRequest }
            request.url = url
        case .post(let data), .put(let data):
            request.httpMethod = resource.method.name
            request.httpBody = data
        case .delete:
            request.httpMethod = resource.method.name
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        
        //check for specific HTTP errors
        switch httpResponse.statusCode {
        case 200...299:
            break
        default:
            // For debugging - print the raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error response: \(responseString)")
            }
            
            let errorResponse = try jsonDecoder.decode(ErrorResponse.self, from: data)
            throw NetworkError.errorResponse(errorResponse)
        }
        
        do {
            // Add this for debugging when decoding fails
            if T.self == PostResponse.self || T.self == PostListResponse.self {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
            }
            
            let result = try jsonDecoder.decode(resource.modelType, from: data)
            return result
        } catch {
            print("Decoding error details: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
}

extension HTTPClient {
    static var development: HTTPClient {
        HTTPClient()
    }
}
