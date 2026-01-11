import Foundation

enum APIEnvironment {
    case production
    case local
    
    var baseURL: URL {
        switch self {
        case .production:
            return URL(string: "https://www.literati.tools/api")!
        case .local:
            return URL(string: "http://localhost:3000/api")!
        }
    }
}

enum APIError: Error {
    case invalidResponse
    case httpError(Int, String?)
    case decodingError(Error)
    case networkError(Error)
}

actor APIService {
    static let shared = APIService()
    private let logger = LoggingService.shared
    
    #if DEBUG
    private var environment: APIEnvironment = .production
    #else
    private let environment: APIEnvironment = .production
    #endif
    
    private init() {}
    
    #if DEBUG
    func setEnvironment(_ env: APIEnvironment) {
        self.environment = env
    }
    #endif
    
    private func extractErrorMessage(from data: Data) -> String? {
        // Try to decode error message from common API error response formats
        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Check common error message fields
            if let message = errorJson["message"] as? String {
                return message
            } else if let error = errorJson["error"] as? String {
                return error
            } else if let errors = errorJson["errors"] as? [String] {
                return errors.joined(separator: ", ")
            }
        }
        return String(data: data, encoding: .utf8)
    }
    
    func post<Request: Encodable, Response: Decodable>(
        endpoint: String,
        payload: Request
    ) async throws -> Response {
        let url = environment.baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            let apiError = APIError.networkError(error)
            logger.logAPIError(apiError, endpoint: endpoint, context: ["payload": String(describing: payload)])
            throw apiError
        }
        
        logger.logAPIRequest(endpoint: endpoint, context: ["payload": String(describing: payload)])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = APIError.invalidResponse
                logger.logAPIError(error, endpoint: endpoint)
                throw error
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = extractErrorMessage(from: data)
                let error = APIError.httpError(httpResponse.statusCode, errorMessage)
                logger.logAPIError(error, endpoint: endpoint, context: [
                    "statusCode": httpResponse.statusCode,
                    "errorMessage": errorMessage ?? "No error message",
                    "responseData": String(data: data, encoding: .utf8) ?? ""
                ])
                throw error
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
                logger.logAPIResponse(endpoint: endpoint)
                return decodedResponse
            } catch {
                let apiError = APIError.decodingError(error)
                logger.logAPIError(apiError, endpoint: endpoint, context: ["responseData": String(data: data, encoding: .utf8) ?? ""])
                throw apiError
            }
        } catch let error as APIError {
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            logger.logAPIError(apiError, endpoint: endpoint)
            throw apiError
        }
    }
    
    func get<Response: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Response {
        var urlComponents = URLComponents(url: environment.baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        logger.logAPIRequest(endpoint: endpoint, context: ["queryItems": queryItems ?? []])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = APIError.invalidResponse
                logger.logAPIError(error, endpoint: endpoint)
                throw error
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = extractErrorMessage(from: data)
                let error = APIError.httpError(httpResponse.statusCode, errorMessage)
                logger.logAPIError(error, endpoint: endpoint, context: [
                    "statusCode": httpResponse.statusCode,
                    "errorMessage": errorMessage ?? "No error message",
                    "responseData": String(data: data, encoding: .utf8) ?? ""
                ])
                throw error
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
                logger.logAPIResponse(endpoint: endpoint)
                return decodedResponse
            } catch {
                let apiError = APIError.decodingError(error)
                logger.logAPIError(apiError, endpoint: endpoint, context: ["responseData": String(data: data, encoding: .utf8) ?? ""])
                throw apiError
            }
        } catch let error as APIError {
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            logger.logAPIError(apiError, endpoint: endpoint)
            throw apiError
        }
    }
} 
