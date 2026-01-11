import Foundation

struct BookTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let structure: FolderTemplate
    
    static func == (lhs: BookTemplate, rhs: BookTemplate) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FolderTemplate: Hashable {
    let title: String
    let description: String
    let order: Int
    let subfolders: [FolderTemplate]
    let documents: [DocumentTemplate]
}

struct DocumentTemplate: Hashable {
    let title: String
    let description: String
    let outlinePrompt: String
    let outline: String
    let notes: String
    let content: String
    let order: Int
}

extension BookTemplate {
    static let heroJourney = BookTemplate(
        name: "Hero's Journey",
        description: "The classic monomyth structure popularized by Joseph Campbell",
        structure: FolderTemplate(
            title: "Story",
            description: "The hero's journey structure",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "Act 1: Departure",
                    description: "The hero's ordinary world and the call to adventure",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "The Ordinary World",
                            description: "Introduce the hero in their familiar environment",
                            outlinePrompt: "# The Ordinary World\n\nThis chapter establishes your protagonist's normal life before the adventure begins. Consider:\n\n- What is their daily routine?\n- What are their relationships like?\n- What are their unfulfilled desires?\n- What are the flaws they need to overcome?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "The Call to Adventure",
                            description: "Present the hero with a challenge or problem",
                            outlinePrompt: "# The Call to Adventure\n\nThis is where your protagonist first encounters the problem, adventure, or challenge that will change their life. Consider:\n\n- What disrupts their normal world?\n- How do they first learn about the challenge?\n- What's at stake if they don't accept?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Refusal of the Call",
                            description: "The hero initially resists the adventure",
                            outlinePrompt: "# Refusal of the Call\n\nYour protagonist's initial resistance to change. Consider:\n\n- What fears hold them back?\n- What excuses do they make?\n- What comfortable patterns are they clinging to?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Meeting the Mentor",
                            description: "The hero gains guidance from a wise figure",
                            outlinePrompt: "# Meeting the Mentor\n\nThe guide who helps prepare your protagonist for the journey. Consider:\n\n- What wisdom do they offer?\n- What tools or knowledge do they provide?\n- How do they help overcome the refusal?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 3
                        ),
                        DocumentTemplate(
                            title: "Crossing the Threshold",
                            description: "The hero leaves their ordinary world",
                            outlinePrompt: "# Crossing the Threshold\n\nThe point of no return where your protagonist commits to the journey. Consider:\n\n- What final event pushes them to act?\n- What do they leave behind?\n- What are their first steps into the unknown?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 4
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act 2: Initiation",
                    description: "The hero faces trials and transforms",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Tests, Allies, and Enemies",
                            description: "The hero faces challenges and meets new characters",
                            outlinePrompt: "# Tests, Allies, and Enemies\n\nYour protagonist's first experiences in the new world. Consider:\n\n- What initial challenges do they face?\n- Who helps them adapt?\n- Who opposes them?\n- What new rules must they learn?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Approach to the Inmost Cave",
                            description: "The hero prepares for the major challenge",
                            outlinePrompt: "# Approach to the Inmost Cave\n\nThe preparation for the major challenge. Consider:\n\n- What final preparations are needed?\n- What last-minute doubts arise?\n- What plan do they make?\n- What raises the stakes?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "The Ordeal",
                            description: "The hero faces their greatest fear",
                            outlinePrompt: "# The Ordeal\n\nThe central crisis of the story. Consider:\n\n- What is their greatest challenge?\n- How do they face their deepest fear?\n- What do they lose or sacrifice?\n- How are they changed by this experience?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "The Reward",
                            description: "The hero achieves their goal",
                            outlinePrompt: "# The Reward\n\nThe aftermath of the ordeal. Consider:\n\n- What do they gain?\n- How have they changed?\n- What new understanding do they have?\n- What price did they pay?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 3
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act 3: Return",
                    description: "The hero returns transformed",
                    order: 2,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "The Road Back",
                            description: "The hero begins their journey home",
                            outlinePrompt: "# The Road Back\n\nThe beginning of the return journey. Consider:\n\n- What calls them to return?\n- What follows them from the ordeal?\n- What final challenges remain?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "The Resurrection",
                            description: "The hero faces a final test",
                            outlinePrompt: "# The Resurrection\n\nThe final test that proves their transformation. Consider:\n\n- How do they prove they've changed?\n- What final challenge must they overcome?\n- How do they use what they've learned?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Return with the Elixir",
                            description: "The hero returns with something to improve the ordinary world",
                            outlinePrompt: "# Return with the Elixir\n\nThe resolution and return home. Consider:\n\n- What do they bring back?\n- How do they help others?\n- How has their world changed?\n- What is their new normal?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 2
                        )
                    ]
                )
            ],
            documents: []
        )
    )
    
    static let romanceOutline = BookTemplate(
        name: "Romance Outline",
        description: "A classic romance structure focusing on character relationships and emotional development",
        structure: FolderTemplate(
            title: "Story",
            description: "The romance story structure",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "Act 1: Setup",
                    description: "Establish the characters and their initial connection",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Ordinary World",
                            description: "Introduce the main characters and their everyday life",
                            outlinePrompt: "# Ordinary World\n\nEstablish your characters' normal lives before they meet. Consider:\n\n- What are their daily routines?\n- What are their unfulfilled desires or emotional needs?\n- What past relationships or experiences shape them?\n- What beliefs do they hold about love and relationships?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "First Encounter",
                            description: "The protagonists meet in a unique or meaningful way",
                            outlinePrompt: "# First Encounter\n\nThe crucial first meeting between your protagonists. Consider:\n\n- What makes their meeting memorable or unique?\n- What are their first impressions of each other?\n- What subtle hints of attraction or conflict emerge?\n- What circumstances bring them together?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Emotional Stir",
                            description: "The encounter creates tension, attraction, or conflict",
                            outlinePrompt: "# Emotional Stir\n\nThe initial emotional impact of their meeting. Consider:\n\n- What unexpected feelings arise?\n- What internal conflicts does this create?\n- What makes them think about each other afterward?\n- What misconceptions might they have?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Inciting Incident",
                            description: "A moment that forces them together",
                            outlinePrompt: "# Inciting Incident\n\nThe event that truly begins their story. Consider:\n\n- What circumstances force them to interact?\n- What stakes are involved?\n- How do they each feel about being thrown together?\n- What complications does this create in their lives?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 3
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act 2: Rising Tension & Conflict",
                    description: "Develop the romance and introduce complications",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Growing Closeness",
                            description: "The romance develops with small, meaningful moments",
                            outlinePrompt: "# Growing Closeness\n\nThe development of their connection. Consider:\n\n- What small moments bring them closer?\n- How do they begin to trust each other?\n- What vulnerabilities do they share?\n- What habits or inside jokes develop between them?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Romantic Gesture",
                            description: "A turning point where one character shows affection",
                            outlinePrompt: "# Romantic Gesture\n\nA significant moment of connection. Consider:\n\n- What meaningful action does one character take?\n- How does the other character respond?\n- What risks are involved?\n- How does this change their dynamic?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Obstacle Arises",
                            description: "A problem threatens their developing relationship",
                            outlinePrompt: "# Obstacle Arises\n\nThe midpoint conflict that challenges their connection. Consider:\n\n- What external or internal conflict emerges?\n- How does it threaten their relationship?\n- What fears or insecurities does it trigger?\n- What misunderstandings arise?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Doubt and Despair",
                            description: "Characters question if the relationship is possible",
                            outlinePrompt: "# Doubt and Despair\n\nThe emotional low point. Consider:\n\n- What makes them question their relationship?\n- What personal demons resurface?\n- What sacrifices seem too great?\n- What seems to be lost?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 3
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act 3: Climax & Resolution",
                    description: "Resolve the conflict and achieve emotional satisfaction",
                    order: 2,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Grand Romantic Declaration",
                            description: "Characters realize they must fight for love",
                            outlinePrompt: "# Grand Romantic Declaration\n\nThe emotional climax. Consider:\n\n- What realization spurs them to action?\n- How do they demonstrate their love?\n- What risks do they take?\n- What truths must they face?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Happy Resolution",
                            description: "The conflict is resolved with an emotional moment",
                            outlinePrompt: "# Happy Resolution\n\nThe resolution of all conflicts. Consider:\n\n- How are external conflicts resolved?\n- How do they overcome their internal barriers?\n- What compromises or changes do they make?\n- What emotional payoff is delivered?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Ever After",
                            description: "A satisfying conclusion to their story",
                            outlinePrompt: "# Ever After\n\nThe final state of their relationship. Consider:\n\n- What does their future look like?\n- How have they grown and changed?\n- What loose ends need tying up?\n- What final romantic moment caps their story?",
                            outline: "",
                            notes: "",
                            content: "",
                            order: 2
                        )
                    ]
                )
            ],
            documents: []
        )
    )
    
    static let templates: [BookTemplate] = [
        .heroJourney,
        .romanceOutline
    ]
} 