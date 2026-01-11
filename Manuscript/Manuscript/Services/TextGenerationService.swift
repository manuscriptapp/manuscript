import Foundation

// Request and Response types
struct TextGenerationRequest: Codable {
    let prompt: String
}

struct TextGenerationResponse: Codable {
    let text: String
}

actor TextGenerationService {
    static let shared = TextGenerationService()
    private let apiService = APIService.shared
    
    private init() {}
    
    func generateText(prompt: String) async throws -> String {
        let request = TextGenerationRequest(prompt: prompt)
        let response: TextGenerationResponse = try await apiService.post(
            endpoint: "generate-text",
            payload: request
        )
        return response.text
    }
}

// Example usage:
/*
 Task {
     do {
         #if DEBUG
         // Optionally switch to production environment in debug mode
         // await APIService.shared.setEnvironment(.production)
         #endif
         
         let generatedText = try await TextGenerationService.shared.generateText(prompt: "Your prompt here")
         print(generatedText)
     } catch {
         print("Error: \(error)")
     }
 }
 */ 