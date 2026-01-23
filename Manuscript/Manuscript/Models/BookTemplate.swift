import Foundation

struct TemplateSource: Hashable, Codable {
    let title: String
    let author: String?
    let url: String?
    let type: SourceType

    enum SourceType: String, Hashable, Codable {
        case book
        case website
        case video
        case podcast

        var icon: String {
            switch self {
            case .book: return "book.closed.fill"
            case .website: return "globe"
            case .video: return "play.rectangle.fill"
            case .podcast: return "mic.fill"
            }
        }
    }
}

struct TemplateExample: Hashable, Codable {
    let title: String
    let creator: String?
    let year: Int?
    let medium: Medium

    enum Medium: String, Hashable, Codable {
        case novel
        case film
        case tvSeries
        case play
        case manga
        case animation

        var icon: String {
            switch self {
            case .novel: return "book.fill"
            case .film: return "film"
            case .tvSeries: return "tv"
            case .play: return "theatermasks.fill"
            case .manga: return "text.book.closed.fill"
            case .animation: return "sparkles.rectangle.stack.fill"
            }
        }
    }
}

struct BookTemplate: Identifiable, Hashable {
    let id: String  // Stable identifier for referencing from projects
    let name: String
    let description: String
    let structure: FolderTemplate
    let sources: [TemplateSource]
    let examples: [TemplateExample]

    static func == (lhs: BookTemplate, rhs: BookTemplate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Find a template by its stable ID
    static func find(byId id: String) -> BookTemplate? {
        templates.first { $0.id == id }
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
    let synopsis: String
    let notes: String
    let content: String
    let order: Int
}

extension BookTemplate {
    static let heroJourney = BookTemplate(
        id: "heros-journey",
        name: "Hero's Journey",
        description: "The classic monomyth structure popularized by Joseph Campbell",
        structure: FolderTemplate(
            title: "Story",
            description: "The heros journey structure",
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
                            synopsis: "Introduce the hero in their familiar environment",
                            notes: "# The Ordinary World\n\nThis chapter establishes your protagonist's normal life before the adventure begins. Consider:\n\n- What is their daily routine?\n- What are their relationships like?\n- What are their unfulfilled desires?\n- What are the flaws they need to overcome?",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "The Call to Adventure",
                            synopsis: "Present the hero with a challenge or problem",
                            notes: "# The Call to Adventure\n\nThis is where your protagonist first encounters the problem, adventure, or challenge that will change their life. Consider:\n\n- What disrupts their normal world?\n- How do they first learn about the challenge?\n- What's at stake if they don't accept?",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Refusal of the Call",
                            synopsis: "The hero initially resists the adventure",
                            notes: "# Refusal of the Call\n\nYour protagonist's initial resistance to change. Consider:\n\n- What fears hold them back?\n- What excuses do they make?\n- What comfortable patterns are they clinging to?",
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Meeting the Mentor",
                            synopsis: "The hero gains guidance from a wise figure",
                            notes: "# Meeting the Mentor\n\nThe guide who helps prepare your protagonist for the journey. Consider:\n\n- What wisdom do they offer?\n- What tools or knowledge do they provide?\n- How do they help overcome the refusal?",
                            content: "",
                            order: 3
                        ),
                        DocumentTemplate(
                            title: "Crossing the Threshold",
                            synopsis: "The hero leaves their ordinary world",
                            notes: "# Crossing the Threshold\n\nThe point of no return where your protagonist commits to the journey. Consider:\n\n- What final event pushes them to act?\n- What do they leave behind?\n- What are their first steps into the unknown?",
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
                            synopsis: "The hero faces challenges and meets new characters",
                            notes: "# Tests, Allies, and Enemies\n\nYour protagonist's first experiences in the new world. Consider:\n\n- What initial challenges do they face?\n- Who helps them adapt?\n- Who opposes them?\n- What new rules must they learn?",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Approach to the Inmost Cave",
                            synopsis: "The hero prepares for the major challenge",
                            notes: "# Approach to the Inmost Cave\n\nThe preparation for the major challenge. Consider:\n\n- What final preparations are needed?\n- What last-minute doubts arise?\n- What plan do they make?\n- What raises the stakes?",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "The Ordeal",
                            synopsis: "The hero faces their greatest fear",
                            notes: "# The Ordeal\n\nThe central crisis of the story. Consider:\n\n- What is their greatest challenge?\n- How do they face their deepest fear?\n- What do they lose or sacrifice?\n- How are they changed by this experience?",
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "The Reward",
                            synopsis: "The hero achieves their goal",
                            notes: "# The Reward\n\nThe aftermath of the ordeal. Consider:\n\n- What do they gain?\n- How have they changed?\n- What new understanding do they have?\n- What price did they pay?",
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
                            synopsis: "The hero begins their journey home",
                            notes: "# The Road Back\n\nThe beginning of the return journey. Consider:\n\n- What calls them to return?\n- What follows them from the ordeal?\n- What final challenges remain?",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "The Resurrection",
                            synopsis: "The hero faces a final test",
                            notes: "# The Resurrection\n\nThe final test that proves their transformation. Consider:\n\n- How do they prove they've changed?\n- What final challenge must they overcome?\n- How do they use what they've learned?",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Return with the Elixir",
                            synopsis: "The hero returns with something to improve the ordinary world",
                            notes: "# Return with the Elixir\n\nThe resolution and return home. Consider:\n\n- What do they bring back?\n- How do they help others?\n- How has their world changed?\n- What is their new normal?",
                            content: "",
                            order: 2
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "The Hero with a Thousand Faces",
                author: "Joseph Campbell",
                url: "https://www.goodreads.com/book/show/588138",
                type: .book
            ),
            TemplateSource(
                title: "The Writer's Journey: Mythic Structure for Writers",
                author: "Christopher Vogler",
                url: "https://www.goodreads.com/book/show/104367",
                type: .book
            ),
            TemplateSource(
                title: "Joseph Campbell Foundation - The Hero's Journey",
                author: nil,
                url: "https://www.jcf.org/learn/joseph-campbell-heros-journey",
                type: .website
            )
        ],
        examples: [
            TemplateExample(title: "Star Wars: A New Hope", creator: "George Lucas", year: 1977, medium: .film),
            TemplateExample(title: "The Matrix", creator: "The Wachowskis", year: 1999, medium: .film),
            TemplateExample(title: "The Lord of the Rings", creator: "J.R.R. Tolkien", year: 1954, medium: .novel),
            TemplateExample(title: "Harry Potter and the Philosopher's Stone", creator: "J.K. Rowling", year: 1997, medium: .novel),
            TemplateExample(title: "The Lion King", creator: "Disney", year: 1994, medium: .film),
            TemplateExample(title: "The Odyssey", creator: "Homer", year: nil, medium: .novel)
        ]
    )

    static let romanceOutline = BookTemplate(
        id: "romance-outline",
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
                            synopsis: "Introduce the main characters and their everyday life",
                            notes: "# Ordinary World\n\nEstablish your characters' normal lives before they meet. Consider:\n\n- What are their daily routines?\n- What are their unfulfilled desires or emotional needs?\n- What past relationships or experiences shape them?\n- What beliefs do they hold about love and relationships?",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "First Encounter",
                            synopsis: "The protagonists meet in a unique or meaningful way",
                            notes: "# First Encounter\n\nThe crucial first meeting between your protagonists. Consider:\n\n- What makes their meeting memorable or unique?\n- What are their first impressions of each other?\n- What subtle hints of attraction or conflict emerge?\n- What circumstances bring them together?",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Emotional Stir",
                            synopsis: "The encounter creates tension, attraction, or conflict",
                            notes: "# Emotional Stir\n\nThe initial emotional impact of their meeting. Consider:\n\n- What unexpected feelings arise?\n- What internal conflicts does this create?\n- What makes them think about each other afterward?\n- What misconceptions might they have?",
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Inciting Incident",
                            synopsis: "A moment that forces them together",
                            notes: "# Inciting Incident\n\nThe event that truly begins their story. Consider:\n\n- What circumstances force them to interact?\n- What stakes are involved?\n- How do they each feel about being thrown together?\n- What complications does this create in their lives?",
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
                            synopsis: "The romance develops with small, meaningful moments",
                            notes: "# Growing Closeness\n\nThe development of their connection. Consider:\n\n- What small moments bring them closer?\n- How do they begin to trust each other?\n- What vulnerabilities do they share?\n- What habits or inside jokes develop between them?",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Romantic Gesture",
                            synopsis: "A turning point where one character shows affection",
                            notes: "# Romantic Gesture\n\nA significant moment of connection. Consider:\n\n- What meaningful action does one character take?\n- How does the other character respond?\n- What risks are involved?\n- How does this change their dynamic?",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Obstacle Arises",
                            synopsis: "A problem threatens their developing relationship",
                            notes: "# Obstacle Arises\n\nThe midpoint conflict that challenges their connection. Consider:\n\n- What external or internal conflict emerges?\n- How does it threaten their relationship?\n- What fears or insecurities does it trigger?\n- What misunderstandings arise?",
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Doubt and Despair",
                            synopsis: "Characters question if the relationship is possible",
                            notes: "# Doubt and Despair\n\nThe emotional low point. Consider:\n\n- What makes them question their relationship?\n- What personal demons resurface?\n- What sacrifices seem too great?\n- What seems to be lost?",
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
                            synopsis: "Characters realize they must fight for love",
                            notes: "# Grand Romantic Declaration\n\nThe emotional climax. Consider:\n\n- What realization spurs them to action?\n- How do they demonstrate their love?\n- What risks do they take?\n- What truths must they face?",
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Happy Resolution",
                            synopsis: "The conflict is resolved with an emotional moment",
                            notes: "# Happy Resolution\n\nThe resolution of all conflicts. Consider:\n\n- How are external conflicts resolved?\n- How do they overcome their internal barriers?\n- What compromises or changes do they make?\n- What emotional payoff is delivered?",
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Ever After",
                            synopsis: "A satisfying conclusion to their story",
                            notes: "# Ever After\n\nThe final state of their relationship. Consider:\n\n- What does their future look like?\n- How have they grown and changed?\n- What loose ends need tying up?\n- What final romantic moment caps their story?",
                            content: "",
                            order: 2
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "Romancing the Beat: Story Structure for Romance Novels",
                author: "Gwen Hayes",
                url: "https://www.goodreads.com/book/show/29954217",
                type: .book
            ),
            TemplateSource(
                title: "Writing Romance: The Top 100 Best Strategies",
                author: "Kathy Ide",
                url: nil,
                type: .book
            ),
            TemplateSource(
                title: "First Draft Pro - Romancing the Beat Guide",
                author: nil,
                url: "https://www.firstdraftpro.com/blog/gwen-hayes-romancing-the-beat",
                type: .website
            )
        ],
        examples: [
            TemplateExample(title: "Pride and Prejudice", creator: "Jane Austen", year: 1813, medium: .novel),
            TemplateExample(title: "The Notebook", creator: "Nicholas Sparks", year: 1996, medium: .novel),
            TemplateExample(title: "Outlander", creator: "Diana Gabaldon", year: 1991, medium: .novel),
            TemplateExample(title: "When Harry Met Sally", creator: "Nora Ephron", year: 1989, medium: .film),
            TemplateExample(title: "Bridgerton", creator: "Julia Quinn", year: 2000, medium: .novel),
            TemplateExample(title: "The Hating Game", creator: "Sally Thorne", year: 2016, medium: .novel)
        ]
    )

    static let saveTheCat = BookTemplate(
        id: "save-the-cat",
        name: "Save the Cat",
        description: "Blake Snyder's 15-beat story structure for compelling, well-paced narratives",
        structure: FolderTemplate(
            title: "Story",
            description: "The Save the Cat beat sheet structure",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "Act 1: The Setup",
                    description: "Establish the protagonist's world and set the story in motion",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Opening Image",
                            synopsis: "A visual snapshot of the protagonist's world before transformation",
                            notes: """
                            # Opening Image

                            **Position:** 0-1% of your story (first scene or chapter)

                            This is your reader's first impression—a visual "before" snapshot that will contrast with your Final Image. It sets the tone, mood, and stakes of your story.

                            ## What This Beat Accomplishes
                            - Establishes the protagonist's current state and world
                            - Sets up the visual/emotional contrast for the ending
                            - Hooks the reader with an intriguing opening

                            ## Questions to Consider
                            - What does your protagonist's life look like right now?
                            - What mood or atmosphere defines their current existence?
                            - What visual or sensory details capture their "before" state?
                            - What's missing or broken in their life (even if they don't know it)?

                            ## Examples
                            - A lonely character eating dinner alone
                            - A workaholic missing their child's event
                            - Someone trapped in a dead-end situation
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Theme Stated",
                            synopsis: "A character hints at the story's central truth or lesson",
                            notes: """
                            # Theme Stated

                            **Position:** Around 5% of your story

                            Someone (usually not the protagonist) states the theme or lesson of the story, often in a way the protagonist doesn't fully understand yet.

                            ## What This Beat Accomplishes
                            - Plants the thematic seed for readers
                            - Gives the protagonist advice they'll need later
                            - Creates dramatic irony when they ignore it

                            ## Questions to Consider
                            - What is the core truth your protagonist needs to learn?
                            - Who in their life might casually mention this truth?
                            - How can you state it subtly so it doesn't feel preachy?
                            - Why would the protagonist dismiss or ignore this advice?

                            ## Examples
                            - "You can't run from your problems forever"
                            - "Family is more important than success"
                            - "Sometimes the thing we fear most is what we need"
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Set-Up",
                            synopsis: "Introduce the hero, their world, flaws, and supporting cast",
                            notes: """
                            # Set-Up

                            **Position:** 1-10% of your story

                            This section establishes everything the reader needs to know: who the protagonist is, what they want, what's holding them back, and who populates their world.

                            ## What This Beat Accomplishes
                            - Introduces the protagonist and makes readers care about them
                            - Shows their flaws and internal need (what they must learn)
                            - Establishes the stakes and what they stand to lose
                            - Introduces key supporting characters

                            ## Questions to Consider
                            - What does your protagonist want externally (their goal)?
                            - What do they need internally (their flaw to overcome)?
                            - What "stasis = death" situation are they stuck in?
                            - Who are the key people in their life right now?
                            - What makes the reader root for them despite their flaws?

                            ## The "Save the Cat" Moment
                            Have your protagonist do something likeable early on—literally or figuratively "save a cat"—to build reader empathy.
                            """,
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Catalyst",
                            synopsis: "An event that disrupts the protagonist's world",
                            notes: """
                            # Catalyst

                            **Position:** Around 10% of your story

                            The Catalyst is the moment that sets the story in motion—a life-changing event that disrupts the protagonist's ordinary world and presents them with a choice.

                            ## What This Beat Accomplishes
                            - Disrupts the status quo dramatically
                            - Presents the protagonist with a problem or opportunity
                            - Makes it impossible to continue as before
                            - Starts the clock ticking on the story

                            ## Questions to Consider
                            - What event shatters your protagonist's normal life?
                            - Is it positive (an opportunity) or negative (a problem)?
                            - How does this event relate to their internal need?
                            - Why can't they simply ignore this and continue as before?

                            ## Examples
                            - Receiving unexpected news (death, inheritance, diagnosis)
                            - Meeting someone who changes everything
                            - Discovering a secret or truth
                            - Losing something or someone important
                            """,
                            content: "",
                            order: 3
                        ),
                        DocumentTemplate(
                            title: "Debate",
                            synopsis: "The protagonist wrestles with doubts about taking action",
                            notes: """
                            # Debate

                            **Position:** 10-20% of your story

                            The protagonist questions whether they should accept the challenge. This beat shows their reluctance and the stakes of their decision.

                            ## What This Beat Accomplishes
                            - Shows the protagonist is human with real fears
                            - Raises the stakes by exploring consequences
                            - Builds tension before the commitment
                            - Allows readers to understand the risks

                            ## Questions to Consider
                            - What fears hold your protagonist back?
                            - What would they lose by taking action?
                            - What would they lose by NOT taking action?
                            - Who advises them for or against the journey?
                            - What internal conflict do they wrestle with?

                            ## The Key Question
                            The Debate often centers on one question: "Should I do this?" The answer must ultimately be yes—but getting there should feel earned.
                            """,
                            content: "",
                            order: 4
                        ),
                        DocumentTemplate(
                            title: "Break Into Two",
                            synopsis: "The hero commits to action and crosses the threshold",
                            notes: """
                            # Break Into Two

                            **Position:** Around 20% of your story

                            This is the moment of decision—the protagonist actively chooses to enter the "upside-down world" of Act 2. This must be their choice, not something that happens to them.

                            ## What This Beat Accomplishes
                            - Marks the end of the setup and beginning of the journey
                            - Shows the protagonist taking decisive action
                            - Transitions from the ordinary world to the special world
                            - Demonstrates character agency

                            ## Questions to Consider
                            - What specific action does the protagonist take?
                            - What pushes them to finally commit?
                            - What are they leaving behind?
                            - How does this moment show they've changed (even slightly)?
                            - What does the "new world" of Act 2 look like?

                            ## Important
                            The protagonist must CHOOSE to enter Act 2. If they're pushed, the story loses its power. Make this an active decision that shows growth.
                            """,
                            content: "",
                            order: 5
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act 2: The Confrontation",
                    description: "The protagonist faces challenges, gains allies, and approaches their greatest test",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "B Story",
                            synopsis: "A secondary subplot that deepens and reflects the theme",
                            notes: """
                            # B Story

                            **Position:** Around 22% of your story

                            The B Story introduces a secondary plot—often a love interest or mentor relationship—that carries the theme and helps the protagonist learn their lesson.

                            ## What This Beat Accomplishes
                            - Provides thematic depth and reflection
                            - Introduces a character who helps the protagonist grow
                            - Offers a break from the main plot tension
                            - Often delivers the final piece needed for the climax

                            ## Questions to Consider
                            - Who is your B Story character? (love interest, friend, mentor)
                            - How do they embody or reflect the theme?
                            - What does the protagonist learn from this relationship?
                            - How will this relationship help in the finale?

                            ## Examples
                            - A romance that teaches the protagonist about trust
                            - A friendship that shows them the value of connection
                            - A mentor who challenges their worldview
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Fun and Games",
                            synopsis: "The promise of the premise—explore the core hook of your story",
                            notes: """
                            # Fun and Games

                            **Position:** 20-50% of your story

                            This is the "promise of the premise"—the reason readers picked up your book. It's where you deliver on the concept and let readers enjoy the core experience of your story.

                            ## What This Beat Accomplishes
                            - Delivers the entertainment value readers expect
                            - Explores the new world and its possibilities
                            - Shows the protagonist trying to solve their problem
                            - Provides set pieces and memorable moments

                            ## Questions to Consider
                            - What scenes would appear in the trailer for your story?
                            - What's the "fun" part of your concept?
                            - How does the protagonist explore their new situation?
                            - What early victories or interesting failures occur?
                            - Are you delivering on the promise of your premise?

                            ## Examples
                            - In a heist story: planning and executing early scores
                            - In a romance: the dating montage and getting to know each other
                            - In a thriller: investigating clues and following leads
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Midpoint",
                            synopsis: "A major twist that raises the stakes—false victory or false defeat",
                            notes: """
                            # Midpoint

                            **Position:** Around 50% of your story

                            The Midpoint is a major shift—either a "false victory" where things seem great (but aren't) or a "false defeat" where all seems lost (but isn't). Stakes are raised and the clock starts ticking.

                            ## What This Beat Accomplishes
                            - Raises the stakes dramatically
                            - Shifts from "fun and games" to serious consequences
                            - Often reveals new information that changes everything
                            - Moves protagonist from reactive to proactive (or vice versa)

                            ## Questions to Consider
                            - Is your midpoint a false victory or false defeat?
                            - What new information or event changes everything?
                            - How do the stakes increase?
                            - What makes this the point of no return?
                            - How does this connect to both the A and B stories?

                            ## False Victory vs. False Defeat
                            - **False Victory:** Everything seems to be going well, but danger lurks
                            - **False Defeat:** All seems lost, but seeds of victory are planted
                            """,
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Bad Guys Close In",
                            synopsis: "External threats intensify while internal doubts mount",
                            notes: """
                            # Bad Guys Close In

                            **Position:** 50-75% of your story

                            After the midpoint, things get worse. External enemies (literal or figurative) tighten their grip while internal demons—doubt, jealousy, fear—tear at the protagonist from within.

                            ## What This Beat Accomplishes
                            - Increases pressure from all sides
                            - Tests the protagonist's resolve and relationships
                            - Exposes flaws that haven't been addressed
                            - Sets up the coming crisis

                            ## Questions to Consider
                            - What external forces are closing in?
                            - What internal flaws are sabotaging the protagonist?
                            - How is the team or support system fracturing?
                            - What mistakes from the past are catching up?
                            - What's the protagonist doing wrong?

                            ## Remember
                            "Bad guys" can be literal villains, but also:
                            - Failing relationships
                            - Self-destructive behavior
                            - Consequences of earlier choices
                            - Internal fears and doubts
                            """,
                            content: "",
                            order: 3
                        ),
                        DocumentTemplate(
                            title: "All Is Lost",
                            synopsis: "The lowest point—something or someone dies (literally or figuratively)",
                            notes: """
                            # All Is Lost

                            **Position:** Around 75% of your story

                            This is the lowest point of the story—the opposite of the Midpoint. There's often a "whiff of death" here: someone or something dies, literally or figuratively.

                            ## What This Beat Accomplishes
                            - Brings the protagonist to their absolute lowest
                            - Destroys their original plan completely
                            - Often involves loss of a mentor, ally, or hope
                            - Sets up the transformation to come

                            ## Questions to Consider
                            - What is the worst thing that could happen? Make it happen.
                            - Who or what "dies" (literally or symbolically)?
                            - How does this connect to the protagonist's flaw?
                            - What false belief is completely shattered?
                            - Why does it seem impossible to continue?

                            ## The "Whiff of Death"
                            Something should die or seem to die:
                            - A character (mentor, ally, hope)
                            - A dream or goal
                            - A relationship
                            - The old self
                            """,
                            content: "",
                            order: 4
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act 3: The Resolution",
                    description: "The protagonist transforms and resolves the conflict",
                    order: 2,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Dark Night of the Soul",
                            synopsis: "The protagonist reflects, processes, and prepares to transform",
                            notes: """
                            # Dark Night of the Soul

                            **Position:** 75-80% of your story

                            This is the darkness before the dawn—the protagonist sits with their failure, processes their loss, and prepares (unconsciously) for transformation.

                            ## What This Beat Accomplishes
                            - Allows the protagonist to fully feel their defeat
                            - Creates space for reflection and realization
                            - Shows the moment before transformation
                            - Builds emotional weight for the comeback

                            ## Questions to Consider
                            - Where does your protagonist go to process their defeat?
                            - What do they reflect on? Who do they think about?
                            - What memory or realization starts to shift things?
                            - How does the B Story character factor in?
                            - What must they finally accept or let go of?

                            ## The Transformation Seed
                            Somewhere in this darkness, a seed is planted—a memory, a phrase, a realization—that will bloom into the Break Into Three.
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Break Into Three",
                            synopsis: "An epiphany sparks renewed resolve—the protagonist sees the solution",
                            notes: """
                            # Break Into Three

                            **Position:** Around 80% of your story

                            The eureka moment! The protagonist finally gets it—they understand what they need to do, combining what they've learned from both the A and B stories.

                            ## What This Beat Accomplishes
                            - Provides the "aha!" moment of realization
                            - Combines lessons from main plot and B Story
                            - Shows the protagonist's internal transformation
                            - Launches them into the finale with renewed purpose

                            ## Questions to Consider
                            - What does the protagonist finally realize?
                            - How does the B Story provide the missing piece?
                            - How does this connect to the Theme Stated?
                            - What new approach will they take?
                            - How is this different from their approach in Act 2?

                            ## The Synthesis
                            This beat often synthesizes:
                            - A Story (external problem) + B Story (internal lesson)
                            - What they want + what they need
                            - The theme they ignored + the lesson they've learned
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Finale",
                            synopsis: "The climax where the protagonist applies everything they've learned",
                            notes: """
                            # Finale

                            **Position:** 80-99% of your story

                            The protagonist executes their new plan, applying everything they've learned. This is where they prove they've truly changed by facing their greatest challenge.

                            ## What This Beat Accomplishes
                            - Resolves the main conflict
                            - Demonstrates the protagonist's transformation
                            - Pays off setups from throughout the story
                            - Provides emotional and narrative satisfaction

                            ## The Five-Point Finale
                            1. **Gathering the Team:** Protagonist rallies allies (or goes alone)
                            2. **Executing the Plan:** They put their new approach into action
                            3. **High Tower Surprise:** An unexpected obstacle or twist
                            4. **Dig Deep Down:** Protagonist must use their new self to overcome
                            5. **Execution of New Plan:** Victory through transformation

                            ## Questions to Consider
                            - How does the protagonist prove they've changed?
                            - What's the final confrontation with the antagonist/problem?
                            - How do earlier setups pay off?
                            - What's the "high tower surprise" that tests them one last time?
                            - How does their flaw almost defeat them—but doesn't?
                            """,
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Final Image",
                            synopsis: "A mirror of the opening, showing the protagonist's transformation",
                            notes: """
                            # Final Image

                            **Position:** 99-100% of your story (final scene)

                            The Final Image mirrors the Opening Image, showing how much has changed. It's the "after" to the Opening Image's "before."

                            ## What This Beat Accomplishes
                            - Provides visual proof of transformation
                            - Creates satisfying bookend symmetry
                            - Shows the new normal after the journey
                            - Leaves readers with a lasting impression

                            ## Questions to Consider
                            - How does this scene mirror your Opening Image?
                            - What's different now? What's the same?
                            - How is the protagonist's world transformed?
                            - How has the protagonist themselves changed?
                            - What emotion do you want readers to feel?

                            ## The Mirror Effect
                            Compare your opening and closing:
                            - Lonely dinner → dinner with loved ones
                            - Running away → standing firm
                            - Trapped → free
                            - Incomplete → whole

                            The contrast should be clear and emotionally resonant.
                            """,
                            content: "",
                            order: 3
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "Save the Cat! The Last Book on Screenwriting You'll Ever Need",
                author: "Blake Snyder",
                url: "https://www.goodreads.com/book/show/49464",
                type: .book
            ),
            TemplateSource(
                title: "Save the Cat! Goes to the Movies",
                author: "Blake Snyder",
                url: "https://www.goodreads.com/book/show/2117958",
                type: .book
            ),
            TemplateSource(
                title: "Save the Cat - Official Website & Beat Sheets",
                author: nil,
                url: "https://savethecat.com/beat-sheets",
                type: .website
            ),
            TemplateSource(
                title: "StudioBinder - Save the Cat Beat Sheet Explained",
                author: nil,
                url: "https://www.studiobinder.com/blog/save-the-cat-beat-sheet/",
                type: .website
            )
        ],
        examples: [
            TemplateExample(title: "The Matrix", creator: "The Wachowskis", year: 1999, medium: .film),
            TemplateExample(title: "Legally Blonde", creator: "Amanda Brown", year: 2001, medium: .film),
            TemplateExample(title: "Miss Congeniality", creator: "Marc Lawrence", year: 2000, medium: .film),
            TemplateExample(title: "Elf", creator: "David Berenbaum", year: 2003, medium: .film),
            TemplateExample(title: "The Hunger Games", creator: "Suzanne Collins", year: 2008, medium: .novel),
            TemplateExample(title: "Parasite", creator: "Bong Joon-ho", year: 2019, medium: .film)
        ]
    )

    // MARK: - Three-Act Structure

    static let threeActStructure = BookTemplate(
        id: "three-act-structure",
        name: "Three-Act Structure",
        description: "The foundational Western narrative structure - a flexible framework for any genre",
        structure: FolderTemplate(
            title: "Story",
            description: "Classic three-act dramatic structure",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "Act 1: Setup",
                    description: "Establish the world, characters, and central conflict (25%)",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Opening Scene",
                            synopsis: "Hook the reader and establish the protagonist's world",
                            notes: """
                            # Opening Scene

                            Your opening scene sets the tone and introduces readers to your protagonist's ordinary world. This is your chance to hook them.

                            ## Goals
                            - Establish the protagonist and their current situation
                            - Set the tone and genre expectations
                            - Create an immediate hook or question

                            ## Questions to Consider
                            - What is your protagonist's daily life like?
                            - What details establish the world and time period?
                            - What subtle hints foreshadow the coming conflict?
                            - How can you make readers care about this character quickly?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Inciting Incident",
                            synopsis: "An event disrupts the protagonist's normal life",
                            notes: """
                            # Inciting Incident

                            This is the event that sets your story in motion - the moment everything changes for your protagonist.

                            ## Goals
                            - Disrupt the status quo dramatically
                            - Present the protagonist with a problem or opportunity
                            - Make it impossible to return to normal

                            ## Questions to Consider
                            - What event shatters your protagonist's ordinary world?
                            - Why can't they simply ignore this and continue as before?
                            - How does this relate to the story's central theme?
                            - What's at stake if they don't respond?
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "First Plot Point",
                            synopsis: "The protagonist commits to the journey",
                            notes: """
                            # First Plot Point

                            The protagonist makes a decision that propels them into Act 2. This is the point of no return.

                            ## Goals
                            - Show the protagonist actively choosing to engage
                            - Transition from setup to confrontation
                            - Raise the stakes significantly

                            ## Questions to Consider
                            - What decision does the protagonist make?
                            - What are they leaving behind?
                            - What pushes them past their hesitation?
                            - How does this choice reveal character?
                            """,
                            content: "",
                            order: 2
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act 2: Confrontation",
                    description: "The protagonist faces escalating obstacles (50%)",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Rising Action",
                            synopsis: "The protagonist faces initial challenges and adapts",
                            notes: """
                            # Rising Action

                            Your protagonist enters unfamiliar territory and begins facing obstacles. Each challenge should build on the last.

                            ## Goals
                            - Introduce allies and enemies
                            - Test the protagonist's abilities and resolve
                            - Develop subplots and relationships

                            ## Questions to Consider
                            - What new skills must the protagonist learn?
                            - Who helps them? Who opposes them?
                            - How do early victories set up later failures?
                            - What internal conflicts emerge?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Midpoint",
                            synopsis: "A major revelation or reversal changes everything",
                            notes: """
                            # Midpoint

                            The midpoint is a turning point that divides Act 2. Something happens that fundamentally changes the protagonist's approach or understanding.

                            ## Goals
                            - Shift the story's direction dramatically
                            - Raise stakes to a new level
                            - Often: false victory or false defeat

                            ## Questions to Consider
                            - What revelation changes everything?
                            - Does your protagonist shift from reactive to proactive (or vice versa)?
                            - How does this connect to the theme?
                            - What new information emerges?
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Complications",
                            synopsis: "Stakes increase as obstacles multiply",
                            notes: """
                            # Complications

                            After the midpoint, things get harder. The antagonist closes in, allies may falter, and the protagonist's flaws become liabilities.

                            ## Goals
                            - Increase pressure from all directions
                            - Test relationships and alliances
                            - Expose the protagonist's weaknesses

                            ## Questions to Consider
                            - How does the antagonist respond to the protagonist's progress?
                            - What personal flaws threaten to derail the protagonist?
                            - What sacrifices must be made?
                            - How do subplots intersect with the main plot?
                            """,
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Second Plot Point",
                            synopsis: "Crisis moment that leads to the climax",
                            notes: """
                            # Second Plot Point

                            The lowest point of the story. Everything seems lost, but from this darkness comes the path to resolution.

                            ## Goals
                            - Bring the protagonist to their lowest point
                            - Destroy their original plan
                            - Set up the final confrontation

                            ## Questions to Consider
                            - What is the worst thing that could happen? Make it happen.
                            - What does the protagonist lose?
                            - What realization emerges from this crisis?
                            - How does this force them to change their approach?
                            """,
                            content: "",
                            order: 3
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act 3: Resolution",
                    description: "The climax and aftermath (25%)",
                    order: 2,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Climax",
                            synopsis: "The decisive confrontation",
                            notes: """
                            # Climax

                            The climax is the culmination of everything - the protagonist faces their greatest challenge using everything they've learned.

                            ## Goals
                            - Resolve the central conflict
                            - Demonstrate the protagonist's transformation
                            - Pay off major setups from earlier

                            ## Questions to Consider
                            - How does the protagonist prove they've changed?
                            - What's the final confrontation with the antagonist/problem?
                            - How do earlier setups pay off?
                            - What choice defines this moment?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Falling Action",
                            synopsis: "The immediate aftermath of the climax",
                            notes: """
                            # Falling Action

                            The tension releases as the consequences of the climax unfold. Loose ends begin to tie up.

                            ## Goals
                            - Show the immediate results of the climax
                            - Begin resolving subplots
                            - Allow readers to process the climax

                            ## Questions to Consider
                            - What are the immediate consequences of the climax?
                            - How do other characters react?
                            - What unexpected results emerge?
                            - What loose ends need addressing?
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Denouement",
                            synopsis: "The new equilibrium is established",
                            notes: """
                            # Denouement

                            The final state of the story world. Show how things have changed and give readers closure.

                            ## Goals
                            - Establish the new normal
                            - Resolve remaining subplots
                            - Leave readers satisfied

                            ## Questions to Consider
                            - What does the protagonist's life look like now?
                            - How have they changed from the beginning?
                            - What image captures the story's transformation?
                            - What emotion do you want readers to feel?
                            """,
                            content: "",
                            order: 2
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "Screenplay: The Foundations of Screenwriting",
                author: "Syd Field",
                url: "https://www.goodreads.com/book/show/119853",
                type: .book
            ),
            TemplateSource(
                title: "Poetics",
                author: "Aristotle",
                url: "https://www.goodreads.com/book/show/1481055",
                type: .book
            ),
            TemplateSource(
                title: "StudioBinder - Three Act Structure",
                author: nil,
                url: "https://www.studiobinder.com/blog/three-act-structure/",
                type: .website
            )
        ],
        examples: [
            TemplateExample(title: "Star Wars: A New Hope", creator: "George Lucas", year: 1977, medium: .film),
            TemplateExample(title: "The Godfather", creator: "Francis Ford Coppola", year: 1972, medium: .film),
            TemplateExample(title: "Chinatown", creator: "Robert Towne", year: 1974, medium: .film),
            TemplateExample(title: "Toy Story", creator: "Pixar", year: 1995, medium: .film),
            TemplateExample(title: "Die Hard", creator: "Jeb Stuart", year: 1988, medium: .film),
            TemplateExample(title: "The Shawshank Redemption", creator: "Frank Darabont", year: 1994, medium: .film)
        ]
    )

    // MARK: - Story Circle

    static let storyCircle = BookTemplate(
        id: "story-circle",
        name: "Story Circle",
        description: "Dan Harmon's 8-step character-driven structure from Community and Rick & Morty",
        structure: FolderTemplate(
            title: "Story",
            description: "The Story Circle - a character-focused journey",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "The Departure",
                    description: "The protagonist leaves their comfort zone",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "1. You (Comfort Zone)",
                            synopsis: "Establish the protagonist in their familiar world",
                            notes: """
                            # You (Comfort Zone)

                            **Position in the Circle:** Top (12 o'clock)

                            This is where we meet your protagonist in their element. They're comfortable, perhaps too comfortable.

                            ## The Key Idea
                            "A character is in a zone of comfort." They have a status quo, routines, and a way of seeing the world.

                            ## Questions to Consider
                            - What is their daily life like?
                            - What makes them comfortable here?
                            - What are they good at in this world?
                            - What limitation do they not yet recognize?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "2. Need",
                            synopsis: "Something is missing or desired",
                            notes: """
                            # Need

                            **Position in the Circle:** 1:30

                            The protagonist becomes aware that something is lacking. This can be a conscious want or an unconscious need.

                            ## The Key Idea
                            "But they want something." There's a gap between where they are and where they want to be.

                            ## Questions to Consider
                            - What do they consciously want?
                            - What do they actually need (that they may not realize)?
                            - What event triggers this awareness?
                            - How does this need relate to their flaw?
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "3. Go",
                            synopsis: "Cross the threshold into the unknown",
                            notes: """
                            # Go

                            **Position in the Circle:** 3 o'clock

                            The protagonist enters an unfamiliar situation. This is the point of no return.

                            ## The Key Idea
                            "They enter an unfamiliar situation." Comfort is left behind.

                            ## Questions to Consider
                            - What forces them to leave their comfort zone?
                            - What does the unfamiliar situation look like?
                            - What rules are different here?
                            - What do they leave behind?
                            """,
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "4. Search",
                            synopsis: "Adapt to the new situation and learn",
                            notes: """
                            # Search

                            **Position in the Circle:** 4:30

                            The protagonist adapts, struggles, and searches for what they need. This is the road of trials.

                            ## The Key Idea
                            "They adapt to the situation." Learning, failing, growing.

                            ## Questions to Consider
                            - What challenges do they face?
                            - Who do they meet along the way?
                            - What skills do they develop?
                            - What failures teach them important lessons?
                            """,
                            content: "",
                            order: 3
                        )
                    ]
                ),
                FolderTemplate(
                    title: "The Return",
                    description: "The protagonist returns transformed",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "5. Find",
                            synopsis: "Get what they were seeking",
                            notes: """
                            # Find

                            **Position in the Circle:** 6 o'clock (bottom)

                            The protagonist gets what they were looking for. This is the midpoint - the moment of apparent success.

                            ## The Key Idea
                            "They get what they wanted." The goal seems achieved.

                            ## Questions to Consider
                            - What do they find or achieve?
                            - Is this what they truly needed?
                            - What does success look like in this moment?
                            - What price tag comes attached?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "6. Take",
                            synopsis: "Pay the price for what they've gained",
                            notes: """
                            # Take

                            **Position in the Circle:** 7:30

                            There's always a cost. The protagonist must pay the price for what they've achieved.

                            ## The Key Idea
                            "They pay a heavy price for it." Victory is never free.

                            ## Questions to Consider
                            - What is the cost of their success?
                            - What do they lose or sacrifice?
                            - How does this price relate to their original flaw?
                            - What realization comes with this payment?
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "7. Return",
                            synopsis: "Journey back to the familiar world",
                            notes: """
                            # Return

                            **Position in the Circle:** 9 o'clock

                            The protagonist begins the journey back to where they started, but they're not the same person.

                            ## The Key Idea
                            "They return to their familiar situation." The circle begins to close.

                            ## Questions to Consider
                            - What calls them back?
                            - How has their perspective shifted?
                            - What do they bring with them from the journey?
                            - What final challenges remain?
                            """,
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "8. Change",
                            synopsis: "Arrive home transformed",
                            notes: """
                            # Change

                            **Position in the Circle:** 10:30 (approaching 12 again)

                            The protagonist is back where they started, but fundamentally changed. The circle is complete.

                            ## The Key Idea
                            "Having changed." They're in the same place but are a different person.

                            ## Questions to Consider
                            - How have they changed since the beginning?
                            - How does their world respond to the new them?
                            - What do they now understand that they didn't before?
                            - How does this change affect those around them?
                            """,
                            content: "",
                            order: 3
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "Channel 101 Wiki - Story Structure",
                author: "Dan Harmon",
                url: "https://channel101.fandom.com/wiki/Story_Structure_101",
                type: .website
            ),
            TemplateSource(
                title: "StudioBinder - Dan Harmon Story Circle",
                author: nil,
                url: "https://www.studiobinder.com/blog/dan-harmon-story-circle/",
                type: .website
            ),
            TemplateSource(
                title: "The Writer's Journey: Mythic Structure for Writers",
                author: "Christopher Vogler",
                url: "https://www.goodreads.com/book/show/104367",
                type: .book
            )
        ],
        examples: [
            TemplateExample(title: "Community", creator: "Dan Harmon", year: 2009, medium: .tvSeries),
            TemplateExample(title: "Rick and Morty", creator: "Dan Harmon & Justin Roiland", year: 2013, medium: .tvSeries),
            TemplateExample(title: "The Dark Knight", creator: "Christopher Nolan", year: 2008, medium: .film),
            TemplateExample(title: "Finding Nemo", creator: "Pixar", year: 2003, medium: .film),
            TemplateExample(title: "Breaking Bad", creator: "Vince Gilligan", year: 2008, medium: .tvSeries)
        ]
    )

    // MARK: - Seven-Point Story Structure

    static let sevenPoint = BookTemplate(
        id: "seven-point",
        name: "Seven-Point Structure",
        description: "Dan Wells' plot-focused framework emphasizing pivotal moments and reversals",
        structure: FolderTemplate(
            title: "Story",
            description: "Seven key plot points that drive your narrative",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "Beginning",
                    description: "Establish the starting state",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Hook",
                            synopsis: "Show the protagonist's starting state - opposite of the resolution",
                            notes: """
                            # Hook

                            **Tip:** Work backwards from your Resolution. The Hook should be its mirror opposite.

                            The Hook establishes your protagonist in a state that contrasts with where they'll end up. If they end heroic, start them cowardly. If they end connected, start them isolated.

                            ## The Key Principle
                            The Hook is the opposite of the Resolution. This creates maximum character arc.

                            ## Questions to Consider
                            - Where does your story end? Start at the opposite.
                            - What is the protagonist's greatest weakness at the start?
                            - What false belief do they hold?
                            - How can you make this opening state compelling?

                            ## Examples
                            - Resolution: Hero saves the world → Hook: Character is selfish/afraid
                            - Resolution: Character finds love → Hook: Character is emotionally closed off
                            - Resolution: Character stands up for themselves → Hook: Character lets others walk over them
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Plot Point 1",
                            synopsis: "The call to action - the story truly begins",
                            notes: """
                            # Plot Point 1

                            This is the inciting incident that sets your story in motion. The protagonist is called to action and the conflict is introduced.

                            ## The Key Principle
                            Move from reaction to action. This is where the protagonist engages with the conflict.

                            ## Questions to Consider
                            - What event disrupts the protagonist's world?
                            - What conflict is introduced?
                            - Why can't the protagonist ignore this?
                            - What is at stake?
                            """,
                            content: "",
                            order: 1
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Middle",
                    description: "The journey of transformation",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Pinch Point 1",
                            synopsis: "Apply pressure - something goes wrong",
                            notes: """
                            # Pinch Point 1

                            Pinch points apply pressure to your protagonist. This is the first major obstacle that forces them to step up.

                            ## The Key Principle
                            Introduce the antagonist's power and the true nature of the conflict. Show why this won't be easy.

                            ## Questions to Consider
                            - What obstacle blocks the protagonist's path?
                            - How does the antagonist demonstrate their threat?
                            - What does the protagonist lack that they need?
                            - How does this failure push them forward?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Midpoint",
                            synopsis: "The shift from reactive to proactive",
                            notes: """
                            # Midpoint

                            The Midpoint is a major turning point. The protagonist shifts from reacting to events to actively pursuing their goal.

                            ## The Key Principle
                            Move from reaction to action. The protagonist stops running and starts fighting.

                            ## Questions to Consider
                            - What changes the protagonist's approach?
                            - What do they learn or discover?
                            - How do they shift from defense to offense?
                            - What new determination emerges?

                            ## Common Midpoint Types
                            - A major revelation changes everything
                            - The protagonist commits fully to the cause
                            - A false victory that masks deeper problems
                            - The stakes become personal
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Pinch Point 2",
                            synopsis: "The darkest moment - all seems lost",
                            notes: """
                            # Pinch Point 2

                            This is the "all is lost" moment. The protagonist faces their greatest defeat before the final push.

                            ## The Key Principle
                            Apply maximum pressure. Remove the protagonist's supports and safety nets.

                            ## Questions to Consider
                            - What is the worst thing that could happen?
                            - How does the antagonist seem to win?
                            - What does the protagonist lose?
                            - Why does victory seem impossible?
                            """,
                            content: "",
                            order: 2
                        )
                    ]
                ),
                FolderTemplate(
                    title: "End",
                    description: "The final transformation and resolution",
                    order: 2,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Plot Point 2",
                            synopsis: "Discover the key to victory",
                            notes: """
                            # Plot Point 2

                            The protagonist discovers or obtains the final piece they need to achieve victory. This is often a realization.

                            ## The Key Principle
                            The protagonist must obtain the power/knowledge to become who they need to be.

                            ## Questions to Consider
                            - What final piece of the puzzle falls into place?
                            - What realization changes their approach?
                            - How does this connect to their character flaw?
                            - What power or knowledge do they finally possess?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Resolution",
                            synopsis: "The climax and final outcome",
                            notes: """
                            # Resolution

                            The climax of your story. The protagonist faces the final conflict and either succeeds or fails - but is transformed either way.

                            ## The Key Principle
                            This should be the opposite of your Hook. The character arc is complete.

                            ## Questions to Consider
                            - How has the protagonist changed from the Hook?
                            - How do they face the final conflict differently than they would have at the start?
                            - What is the final confrontation?
                            - How does the resolution reflect the theme?

                            ## Remember
                            - Tragedy: The protagonist fails to change and is destroyed
                            - Comedy/Drama: The protagonist changes and succeeds
                            - The ending should feel both surprising and inevitable
                            """,
                            content: "",
                            order: 1
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "Writing Excuses 7.41: Seven-Point Story Structure",
                author: "Dan Wells",
                url: "https://writingexcuses.com/writing-excuses-7-41-seven-point-story-structure/",
                type: .podcast
            ),
            TemplateSource(
                title: "Dan Wells' Seven Point Story Structure (YouTube)",
                author: "Dan Wells",
                url: "https://www.youtube.com/watch?v=KcmiqQ9NpPE",
                type: .video
            ),
            TemplateSource(
                title: "Reedsy - Seven-Point Story Structure",
                author: nil,
                url: "https://blog.reedsy.com/guide/story-structure/seven-point-story-structure/",
                type: .website
            )
        ],
        examples: [
            TemplateExample(title: "Harry Potter and the Sorcerer's Stone", creator: "J.K. Rowling", year: 1997, medium: .novel),
            TemplateExample(title: "The Hunger Games", creator: "Suzanne Collins", year: 2008, medium: .novel),
            TemplateExample(title: "I Am Not a Serial Killer", creator: "Dan Wells", year: 2009, medium: .novel),
            TemplateExample(title: "Ender's Game", creator: "Orson Scott Card", year: 1985, medium: .novel),
            TemplateExample(title: "The Princess Bride", creator: "William Goldman", year: 1973, medium: .novel)
        ]
    )

    // MARK: - Freytag's Pyramid

    static let freytagsPyramid = BookTemplate(
        id: "freytags-pyramid",
        name: "Freytag's Pyramid",
        description: "The classical five-act dramatic structure ideal for literary and theatrical storytelling",
        structure: FolderTemplate(
            title: "Story",
            description: "Classical five-act dramatic structure",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "Act I: Exposition",
                    description: "Introduction of characters, setting, and situation",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Introduction",
                            synopsis: "Establish the world, characters, and initial situation",
                            notes: """
                            # Introduction (Exposition)

                            The foundation of your story. Introduce readers to the world, the main characters, and the status quo that will soon be disrupted.

                            ## Goals
                            - Establish setting and time period
                            - Introduce protagonist and key characters
                            - Show the existing order/balance
                            - Plant seeds of the coming conflict

                            ## Questions to Consider
                            - Who is your protagonist and what defines them?
                            - What is the world like before conflict arrives?
                            - What relationships and dynamics exist?
                            - What details foreshadow the coming change?
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act II: Rising Action",
                    description: "Conflict introduced and tension builds",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Complication",
                            synopsis: "The conflict is introduced and engaged",
                            notes: """
                            # Complication

                            The inciting incident and its immediate aftermath. The conflict enters the story and the protagonist must respond.

                            ## Goals
                            - Introduce the central conflict
                            - Force the protagonist into action
                            - Establish stakes and consequences

                            ## Questions to Consider
                            - What event disrupts the established order?
                            - How is the protagonist drawn into the conflict?
                            - What are the initial stakes?
                            - What choices must be made?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Rising Tension",
                            synopsis: "Obstacles mount and stakes increase",
                            notes: """
                            # Rising Tension

                            The conflict intensifies. Each scene should raise the stakes and increase tension as we approach the climax.

                            ## Goals
                            - Escalate the conflict through complications
                            - Develop character relationships
                            - Build toward the inevitable confrontation

                            ## Questions to Consider
                            - What obstacles does the protagonist face?
                            - How do relationships complicate matters?
                            - What internal conflicts emerge?
                            - How do small victories lead to larger problems?
                            """,
                            content: "",
                            order: 1
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act III: Climax",
                    description: "The turning point - peak dramatic tension",
                    order: 2,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Turning Point",
                            synopsis: "The moment of highest tension and irreversible change",
                            notes: """
                            # Turning Point (Climax)

                            The peak of the pyramid. This is the moment of highest dramatic tension, where the protagonist's fate hangs in the balance.

                            ## Key Concept
                            In classical tragedy, this is often where the hero makes a fateful decision or where fortune turns against them. In comedy, it's where the knots become most tangled before unraveling.

                            ## Goals
                            - Reach maximum dramatic tension
                            - Create a moment of irreversible change
                            - Force the protagonist to make a crucial decision

                            ## Questions to Consider
                            - What is the moment of greatest tension?
                            - What decision or action changes everything?
                            - How does fortune turn (for better or worse)?
                            - What makes this moment inevitable yet surprising?
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act IV: Falling Action",
                    description: "Consequences unfold",
                    order: 3,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Reversal",
                            synopsis: "The consequences of the climax begin to unfold",
                            notes: """
                            # Reversal (Falling Action)

                            The aftermath of the climax. Events move toward their conclusion as consequences unfold.

                            ## Key Concept
                            In tragedy, the hero's fortunes decline. In comedy, the tangles begin to resolve. The reversal shows the new direction fate has taken.

                            ## Goals
                            - Show consequences of the climactic choice
                            - Move decisively toward resolution
                            - Resolve secondary conflicts

                            ## Questions to Consider
                            - What are the immediate consequences of the climax?
                            - How does the protagonist respond to this new reality?
                            - What secondary plots resolve here?
                            - How does tension release but maintain interest?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Moment of Suspense",
                            synopsis: "Final tension before the resolution",
                            notes: """
                            # Moment of Suspense

                            A final beat of uncertainty before the resolution. This is the last chance for hope or fear before the ending.

                            ## Goals
                            - Create one final moment of uncertainty
                            - Give readers a chance to hope (or fear)
                            - Set up the emotional payoff of the resolution

                            ## Questions to Consider
                            - What final obstacle or question remains?
                            - How can you create uncertainty even as the end approaches?
                            - What does the audience hope/fear will happen?
                            - How does this moment enhance the coming resolution?
                            """,
                            content: "",
                            order: 1
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Act V: Denouement",
                    description: "Resolution and final outcome",
                    order: 4,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Resolution",
                            synopsis: "The final outcome - catastrophe or catharsis",
                            notes: """
                            # Resolution (Denouement/Catastrophe)

                            The final act brings closure. In tragedy, this is the catastrophe - the hero's downfall. In comedy, this is the resolution - order restored.

                            ## Key Concept
                            - **Tragedy:** The hero meets their fate (death, ruin, or loss)
                            - **Comedy:** Order is restored, often with marriages or reconciliations
                            - **Drama:** A new equilibrium is established

                            ## Goals
                            - Resolve all major plot threads
                            - Deliver the emotional payoff
                            - Leave readers with the intended feeling

                            ## Questions to Consider
                            - What is the final fate of the protagonist?
                            - How does this ending reflect the theme?
                            - What feeling should readers be left with?
                            - What has changed from the beginning?
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "Freytag's Technique of the Drama",
                author: "Gustav Freytag",
                url: "https://books.google.com/books?id=oLxinAdZ_IMC",
                type: .book
            ),
            TemplateSource(
                title: "MasterClass - Freytag's Pyramid",
                author: nil,
                url: "https://www.masterclass.com/articles/freytags-pyramid",
                type: .website
            ),
            TemplateSource(
                title: "The Write Practice - Freytag's Pyramid Examples",
                author: nil,
                url: "https://thewritepractice.com/freytags-pyramid/",
                type: .website
            )
        ],
        examples: [
            TemplateExample(title: "Hamlet", creator: "William Shakespeare", year: 1600, medium: .play),
            TemplateExample(title: "Macbeth", creator: "William Shakespeare", year: 1606, medium: .play),
            TemplateExample(title: "Romeo and Juliet", creator: "William Shakespeare", year: 1597, medium: .play),
            TemplateExample(title: "Oedipus Rex", creator: "Sophocles", year: nil, medium: .play),
            TemplateExample(title: "Death of a Salesman", creator: "Arthur Miller", year: 1949, medium: .play),
            TemplateExample(title: "A Streetcar Named Desire", creator: "Tennessee Williams", year: 1947, medium: .play)
        ]
    )

    // MARK: - Fichtean Curve

    static let fichteanCurve = BookTemplate(
        id: "fichtean-curve",
        name: "Fichtean Curve",
        description: "A crisis-driven structure that starts in action - perfect for thrillers and mysteries",
        structure: FolderTemplate(
            title: "Story",
            description: "Crisis-driven narrative with minimal exposition",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "Rising Action",
                    description: "A series of escalating crises (65-70% of story)",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Crisis 1: The Hook",
                            synopsis: "Open with immediate tension - start in media res",
                            notes: """
                            # Crisis 1: The Hook

                            Start in the middle of the action. No lengthy exposition - drop readers into tension immediately.

                            ## The Fichtean Approach
                            Unlike traditional structures, the Fichtean Curve begins with a crisis. Backstory and character development are woven in through subsequent crises, not front-loaded.

                            ## Goals
                            - Open with immediate tension or conflict
                            - Hook readers with a compelling situation
                            - Introduce protagonist through action, not description

                            ## Questions to Consider
                            - What crisis can you open with?
                            - How do you reveal character through action?
                            - What backstory can be withheld and revealed later?
                            - What question compels readers to continue?
                            """,
                            content: "",
                            order: 0
                        ),
                        DocumentTemplate(
                            title: "Crisis 2: Escalation",
                            synopsis: "The situation worsens - stakes increase",
                            notes: """
                            # Crisis 2: Escalation

                            The second crisis builds on the first. Stakes rise, complications emerge, and the protagonist faces greater challenges.

                            ## Goals
                            - Escalate tension from the opening crisis
                            - Reveal more about the protagonist's situation
                            - Introduce or deepen complications

                            ## Questions to Consider
                            - How does this crisis raise the stakes?
                            - What new information emerges?
                            - What does the protagonist learn or fail to learn?
                            - How does this connect to the larger conflict?
                            """,
                            content: "",
                            order: 1
                        ),
                        DocumentTemplate(
                            title: "Crisis 3: Complications",
                            synopsis: "New obstacles emerge - the problem deepens",
                            notes: """
                            # Crisis 3: Complications

                            Each crisis should reveal new layers of the problem. What seemed simple becomes complex.

                            ## Goals
                            - Add unexpected complications
                            - Deepen the central mystery or conflict
                            - Test the protagonist's resources and allies

                            ## Questions to Consider
                            - What unexpected complication emerges?
                            - How does this crisis reveal hidden depths?
                            - What does the protagonist lose or sacrifice?
                            - How do allies or enemies factor in?
                            """,
                            content: "",
                            order: 2
                        ),
                        DocumentTemplate(
                            title: "Crisis 4: Setback",
                            synopsis: "A major defeat or reversal",
                            notes: """
                            # Crisis 4: Setback

                            A significant defeat. The protagonist's approach isn't working, forcing them to adapt.

                            ## Goals
                            - Deal the protagonist a major blow
                            - Force a change in approach
                            - Reveal the antagonist's true power

                            ## Questions to Consider
                            - What defeat forces the protagonist to change tactics?
                            - What does this crisis cost them?
                            - How does failure reveal character?
                            - What must they learn from this setback?
                            """,
                            content: "",
                            order: 3
                        ),
                        DocumentTemplate(
                            title: "Crisis 5: Darkest Moment",
                            synopsis: "All seems lost before the final push",
                            notes: """
                            # Crisis 5: Darkest Moment

                            The lowest point before the climax. Everything the protagonist has tried has failed or come at too high a cost.

                            ## Goals
                            - Bring the protagonist to their lowest point
                            - Remove their remaining supports
                            - Set up the desperate final push

                            ## Questions to Consider
                            - What makes this the darkest moment?
                            - What has the protagonist lost throughout these crises?
                            - What impossible choice do they face?
                            - What spark of hope or determination remains?
                            """,
                            content: "",
                            order: 4
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Climax",
                    description: "The final crisis (15-20% of story)",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Final Crisis",
                            synopsis: "The decisive confrontation",
                            notes: """
                            # Final Crisis (Climax)

                            The culmination of all previous crises. Everything comes together in the final confrontation.

                            ## Goals
                            - Resolve the central conflict
                            - Pay off setups from earlier crises
                            - Show the protagonist using what they've learned

                            ## Questions to Consider
                            - How do earlier crises inform this final confrontation?
                            - What has the protagonist learned that enables success (or seals their fate)?
                            - How is this crisis different from the others?
                            - What's the ultimate stakes of this moment?
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Falling Action",
                    description: "Brief resolution (10-15% of story)",
                    order: 2,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Resolution",
                            synopsis: "Quick aftermath and closure",
                            notes: """
                            # Resolution

                            The Fichtean Curve keeps falling action brief. Resolve essential threads quickly without lingering.

                            ## Key Principle
                            Less is more. The rapid pace of the Fichtean Curve means readers don't need extensive denouement. Provide closure, not explanation.

                            ## Goals
                            - Resolve the most essential threads
                            - Show the aftermath briefly
                            - End with impact

                            ## Questions to Consider
                            - What absolutely must be resolved?
                            - What can be left to reader imagination?
                            - What final image or moment provides closure?
                            - How can you end with emotional impact?
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "The Art of Fiction: Notes on Craft for Young Writers",
                author: "John Gardner",
                url: "https://www.goodreads.com/book/show/40591",
                type: .book
            ),
            TemplateSource(
                title: "Reedsy - The Fichtean Curve",
                author: nil,
                url: "https://blog.reedsy.com/guide/story-structure/fichtean-curve/",
                type: .website
            ),
            TemplateSource(
                title: "Kindlepreneur - Fichtean Curve Examples",
                author: nil,
                url: "https://kindlepreneur.com/fichtean-curve/",
                type: .website
            )
        ],
        examples: [
            TemplateExample(title: "Gone Girl", creator: "Gillian Flynn", year: 2012, medium: .novel),
            TemplateExample(title: "The Da Vinci Code", creator: "Dan Brown", year: 2003, medium: .novel),
            TemplateExample(title: "Misery", creator: "Stephen King", year: 1987, medium: .novel),
            TemplateExample(title: "The Shining", creator: "Stephen King", year: 1977, medium: .novel),
            TemplateExample(title: "Mad Max: Fury Road", creator: "George Miller", year: 2015, medium: .film),
            TemplateExample(title: "The Girl with the Dragon Tattoo", creator: "Stieg Larsson", year: 2005, medium: .novel)
        ]
    )

    // MARK: - Kishōtenketsu

    static let kishotenketsu = BookTemplate(
        id: "kishotenketsu",
        name: "Kishōtenketsu",
        description: "A Japanese four-act structure emphasizing twist and revelation over conflict",
        structure: FolderTemplate(
            title: "Story",
            description: "Four-act structure focused on revelation rather than conflict",
            order: 0,
            subfolders: [
                FolderTemplate(
                    title: "Ki (起) - Introduction",
                    description: "Establish the characters and setting",
                    order: 0,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Establishment",
                            synopsis: "Introduce the world, characters, and situation",
                            notes: """
                            # Ki (起) - Introduction

                            **The First Act: Establishment**

                            Introduce your characters, world, and situation. Unlike Western structures, there's no need for immediate conflict - focus on establishing who and what this story is about.

                            ## The Kishōtenketsu Approach
                            This structure comes from East Asian storytelling (China, Korea, Japan) and doesn't require conflict as the driving force. Instead, it builds through development, twist, and reconciliation.

                            ## Goals
                            - Establish characters and their world
                            - Set the tone and atmosphere
                            - Create interest through character and situation, not conflict

                            ## Questions to Consider
                            - Who are your characters?
                            - What is their world like?
                            - What details make this world feel alive?
                            - What subtle elements will pay off in the twist?
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Shō (承) - Development",
                    description: "Develop the established elements",
                    order: 1,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Deepening",
                            synopsis: "Explore and develop what was established",
                            notes: """
                            # Shō (承) - Development

                            **The Second Act: Deepening**

                            Build upon what was established in Ki. Develop characters, relationships, and situations without introducing major conflict.

                            ## Goals
                            - Deepen reader understanding of characters
                            - Develop relationships and dynamics
                            - Explore the world and its details
                            - Set up elements that will resonate with the twist

                            ## Questions to Consider
                            - How can you deepen character relationships?
                            - What aspects of the world deserve exploration?
                            - What patterns or routines can you establish?
                            - What seemingly minor details will become significant?
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Ten (転) - Twist",
                    description: "An unexpected shift in perspective or understanding",
                    order: 2,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Turn",
                            synopsis: "A shift in perspective changes everything",
                            notes: """
                            # Ten (転) - Twist

                            **The Third Act: The Turn**

                            This is the heart of Kishōtenketsu. Something shifts - not necessarily a conflict, but a change in perspective, understanding, or situation that recontextualizes what came before.

                            ## The Nature of Ten
                            The twist isn't about antagonists or battles. It's about seeing something differently. It might be:
                            - A revelation that changes understanding
                            - A new perspective on familiar elements
                            - An unexpected connection or parallel
                            - A shift in the world or circumstances

                            ## Goals
                            - Create a meaningful shift or twist
                            - Recontextualize earlier elements
                            - Surprise while remaining true to the story

                            ## Questions to Consider
                            - What shift in perspective would be meaningful?
                            - How does this change how we see Ki and Shō?
                            - What truth is revealed or realized?
                            - How is this both surprising and inevitable?
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                ),
                FolderTemplate(
                    title: "Ketsu (結) - Conclusion",
                    description: "Reconcile all elements into harmony",
                    order: 3,
                    subfolders: [],
                    documents: [
                        DocumentTemplate(
                            title: "Reconciliation",
                            synopsis: "Bring all elements together in a new understanding",
                            notes: """
                            # Ketsu (結) - Conclusion

                            **The Fourth Act: Reconciliation**

                            Bring all the elements together. After the twist of Ten, show how everything fits together in a new harmony or understanding.

                            ## The Nature of Ketsu
                            Rather than "resolution" in the Western sense (defeating an enemy, solving a problem), Ketsu is about reconciliation - finding harmony between the established elements and the new perspective introduced by Ten.

                            ## Goals
                            - Reconcile the twist with earlier elements
                            - Create a sense of completeness
                            - Leave readers with a new understanding

                            ## Questions to Consider
                            - How does the twist integrate with what came before?
                            - What new understanding emerges?
                            - What feeling should readers be left with?
                            - How have the characters (or readers) grown in understanding?

                            ## Examples in Media
                            - Many Ghibli films (My Neighbor Totoro, Spirited Away)
                            - Manga and anime often use this structure
                            - Haiku poetry follows this pattern
                            - Slice-of-life stories often employ Kishōtenketsu
                            """,
                            content: "",
                            order: 0
                        )
                    ]
                )
            ],
            documents: []
        ),
        sources: [
            TemplateSource(
                title: "Animation Obsessive - What Makes Ghibli Storytelling So Different?",
                author: nil,
                url: "https://animationobsessive.substack.com/p/what-makes-ghibli-storytelling-so",
                type: .website
            ),
            TemplateSource(
                title: "Still Eating Oranges - The Significance of Plot Without Conflict",
                author: nil,
                url: "https://stilleatingoranges.tumblr.com/post/25153960313",
                type: .website
            ),
            TemplateSource(
                title: "Writers Write - Kishotenketsu: The Secret Of Plotless Story Structure",
                author: nil,
                url: "https://www.writerswrite.co.za/kishotenketsu-the-secret-of-plotless-story-structure/",
                type: .website
            )
        ],
        examples: [
            TemplateExample(title: "My Neighbor Totoro", creator: "Hayao Miyazaki", year: 1988, medium: .animation),
            TemplateExample(title: "Spirited Away", creator: "Hayao Miyazaki", year: 2001, medium: .animation),
            TemplateExample(title: "Kiki's Delivery Service", creator: "Hayao Miyazaki", year: 1989, medium: .animation),
            TemplateExample(title: "Yotsuba&!", creator: "Kiyohiko Azuma", year: 2003, medium: .manga),
            TemplateExample(title: "Mushishi", creator: "Yuki Urushibara", year: 1999, medium: .manga),
            TemplateExample(title: "Whisper of the Heart", creator: "Yoshifumi Kondō", year: 1995, medium: .animation)
        ]
    )

    static let templates: [BookTemplate] = [
        .heroJourney,
        .romanceOutline,
        .saveTheCat,
        .threeActStructure,
        .storyCircle,
        .sevenPoint,
        .freytagsPyramid,
        .fichteanCurve,
        .kishotenketsu
    ]
} 