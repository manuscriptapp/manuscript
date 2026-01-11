import Foundation

enum AIPromptTemplates {
    enum Chapter {
        static func generateOutline(guidelines: String, style: GenerationStyle? = nil, customPrompt: String? = nil) -> String {
            var prompt = """
            Based on these chapter guidelines, create a detailed chapter outline with 4-6 major scenes. Include specific details about:
            - Key events and their sequence
            - Character emotions and development
            - Setting descriptions
            - Important dialogue moments or interactions
            
            Guidelines:
            \(guidelines)
            """
            
            if let customPrompt = customPrompt {
                prompt += "\n\nAdditional Instructions:\n\(customPrompt)"
            }
            
            if let style = style {
                prompt += "\n\nStyle: \(styleDescription(for: style))"
            }
            
            return prompt
        }
        
        static func generateContent(outline: String, guidelines: String, style: GenerationStyle? = nil, customPrompt: String? = nil) -> String {
            var prompt = """
            Write a detailed chapter following this outline and guidelines. Focus on:
            - Rich, immersive descriptions
            - Natural dialogue and character interactions
            - Clear scene transitions
            - Emotional depth and character development
            
            Chapter Outline:
            \(outline)
            
            Additional Guidelines:
            \(guidelines)
            """
            
            if let customPrompt = customPrompt {
                prompt += "\n\nAdditional Instructions:\n\(customPrompt)"
            }
            
            if let style = style {
                prompt += "\n\nStyle: \(styleDescription(for: style))"
            }
            
            return prompt
        }
        
        private static func styleDescription(for style: GenerationStyle) -> String {
            switch style {
            case .formal:
                return "Write in a formal, professional tone with sophisticated vocabulary and structured pacing."
            case .casual:
                return "Write in a casual, conversational tone with natural dialogue and relaxed pacing."
            case .fastPaced:
                return "Write with high energy and momentum, using shorter sentences and dynamic action."
            case .detailed:
                return "Write with rich, vivid descriptions and deep attention to sensory details and atmosphere."
            }
        }
        
        static func modifyStyle(text: String, style: ChapterStyle) -> String {
            switch style {
            case .formal:
                return "Rewrite this text in a more formal tone: \(text)"
            case .casual:
                return "Rewrite this text in a more casual tone: \(text)"
            case .fastPaced:
                return "Rewrite this text with a faster pace: \(text)"
            case .detailed:
                return "Rewrite this text with more descriptive details: \(text)"
            }
        }
    }
    
    enum ChapterStyle {
        case formal
        case casual
        case fastPaced
        case detailed
    }
} 