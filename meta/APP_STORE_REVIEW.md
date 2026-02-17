# App Store Review Requirements & Action Plan

A comprehensive guide for Manuscript's App Store submission, covering Apple's 2025-2026 requirements and specific action items.

**Last Updated:** February 17, 2026
**Target Submission:** TBD
**Current Readiness:** ~50-55%

---

## Executive Summary

Manuscript has solid core functionality but requires significant work on compliance, assets, and metadata before App Store submission. The main blockers are:

1. **Privacy Manifest** - Done
2. **App Icons** - Done (using Xcode 15+ single-source format)
3. **Legal Documents** - Privacy Policy and Terms of Service
4. **App Store Metadata** - Description, keywords, screenshots

---

## Submission Readiness Plan (Updated)

This is the execution plan to move from the current state to "Ready to Submit." Treat each row as a gate for App Store Connect submission.

| Gate | Owner | Deliverable | Status | Exit Criteria |
|------|-------|-------------|:------:|---------------|
| Legal | Team | Public Privacy Policy + Terms URLs | 🟢 | Both pages are live at manuscriptapp.github.io (privacy.html, terms.html, support.html) |
| Product metadata | Team | Final name, subtitle, keywords, description | 🟡 | Copy finalized, reviewed against implemented features |
| Visual assets | Team | iPhone + iPad + Mac screenshots | 🔴 | All required sizes exported with approved marketing captions |
| Review metadata | Team | Age rating, support URL, marketing URL | 🟡 | Support URL live; age rating questionnaire still needed |
| Release quality | Team | Smoke-tested release build | 🟡 | No blocker bugs on iPhone, iPad, macOS |
| Submission operations | Team | TestFlight build + notes | 🔴 | External-ready build uploaded and validated |

### 30-Day Delivery Track

| Week | Focus | Deliverables |
|------|-------|--------------|
| Week 1 | Compliance + legal | Privacy policy, terms, support page, privacy data confirmation |
| Week 2 | Metadata | Finalized description, subtitle, keywords, category, age rating |
| Week 3 | Screenshots + marketing copy | Approved screenshot set and localized captions |
| Week 4 | Release prep | TestFlight round, bug triage, final App Store Connect entry |

---

## Part 1: Apple's 2025-2026 Requirements

### SDK Requirements (Effective April 2026)

| Requirement | Deadline | Status |
|-------------|----------|:------:|
| Build with Xcode 16+ and iOS 18 SDK | Current | 🟢 |
| Build with Xcode 26+ and iOS 26 SDK | April 2026 | N/A |

### Privacy Requirements

| Requirement | Notes | Status |
|-------------|-------|:------:|
| Privacy Manifest (PrivacyInfo.xcprivacy) | Required since Spring 2024 | 🟢 |
| SDK Privacy Manifests | For all third-party SDKs | 🔴 |
| AI Transparency (if applicable) | Effective Nov 13, 2025 | 🔴 |
| Explicit consent for data sharing | If using third-party AI | 🟡 |

### Age Ratings (New as of July 2025)

| Requirement | Deadline | Status |
|-------------|----------|:------:|
| Complete updated age rating questionnaire | January 31, 2026 | 🔴 |
| New ratings available: 13+, 16+, 18+ | Now available | - |

### Account Management

| Requirement | Notes | Status |
|-------------|-------|:------:|
| Account deletion within app | Required if app has accounts | N/A |
| "Restore Purchases" button | Required for IAP | N/A |

### Regional Requirements

| Region | Requirement | Deadline |
|--------|-------------|----------|
| South Korea | Server notification endpoint for Sign in with Apple | Jan 1, 2026 |
| Australia | Block users under 16 from social accounts | Dec 10, 2025 |

**Source:** [Apple Developer - Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)

---

## Part 2: Current State Assessment

### Info.plist Configuration

**File:** `manuscript/Info.plist`

| Item | Status | Notes |
|------|:------:|-------|
| App Category | 🟢 | `public.app-category.productivity` |
| Document Browser Support | 🟢 | `UISupportsDocumentBrowser: YES` |
| Open in Place | 🟢 | `LSSupportsOpeningDocumentsInPlace: YES` |
| Custom Document Type | 🟢 | `.manuscript` extension registered |
| Location Usage Description | 🟢 | Present for map feature |
| Export Compliance | 🟢 | `ITSAppUsesNonExemptEncryption: false` |
| Privacy Manifest | 🟢 | Created PrivacyInfo.xcprivacy |

### Entitlements

**File:** `Manuscript.entitlements`

| Capability | Status | Notes |
|------------|:------:|-------|
| App Sandbox | 🟢 | Enabled |
| iCloud (CloudDocuments) | 🟢 | Enabled |
| File Access | 🟢 | Read/write configured |
| Network Client | 🟢 | Enabled |
| App Groups | 🔴 | Not configured (needed for extensions) |

### Build Configuration

| Setting | Current | Status |
|---------|---------|:------:|
| iOS Deployment Target | 18.0 | ✓ |
| macOS Deployment Target | 15.0 | ✓ |
| Marketing Version | 1.0.2 | ✓ |
| Bundle ID | com.dahlsjoo.manuscript | Needs registration |
| Swift Version | 5.0 | ✓ |
| Code Signing | Automatic | ✓ |

### Dependencies

| Package | Version | Privacy Manifest |
|---------|---------|:----------------:|
| RichTextKit | >= 1.0.0 | 🔴 Needs verification |

---

## Part 3: Action Plan

### Phase 1: Critical Blockers (Week 1)

#### 1.1 Create Privacy Manifest

**Priority:** CRITICAL
**Effort:** 2-4 hours

Create `PrivacyInfo.xcprivacy` in the main app bundle:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Actions:**
- [ ] Create PrivacyInfo.xcprivacy file
- [ ] Add to Xcode project
- [ ] Verify RichTextKit's privacy manifest requirements
- [ ] Test build with privacy manifest

### Phase 2: Legal & Documentation (Week 1-2)

#### 2.1 Create Privacy Policy

**Priority:** CRITICAL (Required by App Store)
**Effort:** 2-4 hours

**Content Requirements:**
- What data is collected (local files only, location for maps)
- iCloud sync disclosure
- No third-party data sharing
- Contact information
- User rights (data deletion, export)

**Actions:**
- [ ] Draft privacy policy
- [ ] Host at manuscriptapp.github.io/privacy
- [ ] Add link to App Store Connect
- [ ] Add link in app Settings

#### 2.2 Create Terms of Service

**Priority:** HIGH
**Effort:** 1-2 hours

**Actions:**
- [ ] Draft terms of service
- [ ] Host at manuscriptapp.github.io/terms
- [ ] Reference open-source license (MPL-2.0)

#### 2.3 Create Support Page

**Priority:** HIGH
**Effort:** 1 hour

**Actions:**
- [ ] Create support page at manuscriptapp.github.io/support
- [ ] Include FAQ section
- [ ] Add contact email
- [ ] Link to GitHub Issues for bug reports

### Phase 3: App Store Metadata (Week 2)

#### 3.1 App Store Description

**Priority:** HIGH
**Effort:** 2-3 hours

**Draft Description:**

```
Manuscript is a native writing app for novelists, screenwriters, and long-form writers who value privacy and file ownership.

WRITE WITH CONFIDENCE
- Your files, your control. Markdown-based format you own forever
- No required accounts, no subscriptions, no cloud lock-in
- iCloud sync keeps your work safe across all your Apple devices
- Automatic backups protect your manuscripts

ORGANIZE YOUR STORY
- Chapters, scenes, and documents in a familiar binder structure
- Character and location databases with custom fields
- Corkboard view for visual story planning
- Outliner for structured organization
- Keywords, collections, and document links for richer connections
- Favorites for instant access to key documents
- Trash folder keeps deleted items recoverable

WRITE DISTRACTION-FREE
- Focus mode hides everything but your words
- Dark mode for late-night writing sessions
- Writing targets to track your daily progress
- Comments and notes without cluttering your manuscript
- Read Aloud with text-to-speech voice support

IMPORT & EXPORT
- Import from Scrivener, Word (DOCX), PDF, HTML, Markdown, and plain text
- Attach images and PDFs directly to your manuscripts
- Export to PDF, EPUB, HTML, Markdown, or Scrivener 3 format
- Print directly from the app

AI WRITING ASSISTANCE
- On-device AI powered by Apple Foundation Models — private by default
- Optional cloud AI with OpenAI and Anthropic Claude models
- Requires your own API key — no hidden data sharing

OPEN SOURCE
Manuscript is open source under the MPL-2.0 license. View the code, contribute, or fork it at github.com/manuscriptapp/manuscript
```

#### 3.2 Keywords (100 characters max)

**Draft:**
```
writing,novel,screenplay,markdown,scrivener,author,manuscript,book,editor,export
```
(100 chars exactly — "distraction-free" swapped for "export" to capture import/export searches)

#### 3.3 Subtitle (30 characters max)

**Options:**
- "Write Without Limits" (19 chars)
- "Native Writing for Authors" (26 chars)
- "Your Story, Your Files" (22 chars)

#### 3.4 Category Selection

**Primary:** Productivity
**Secondary:** Reference

#### 3.5 Age Rating Questionnaire

**Actions:**
- [ ] Complete questionnaire in App Store Connect
- [ ] Expected rating: 4+ (no objectionable content)
- [ ] No user-generated content requiring moderation
- [ ] No violence, gambling, or mature themes

### Phase 4: Screenshots (Week 2-3)

#### 4.1 Required Screenshot Sizes

| Device | Resolution | Orientation |
|--------|------------|-------------|
| iPhone 6.7" | 1290 x 2796 | Portrait |
| iPhone 6.5" | 1242 x 2688 | Portrait |
| iPhone 5.5" | 1242 x 2208 | Portrait |
| iPad Pro 12.9" | 2048 x 2732 | Landscape/Portrait |
| Mac | 2880 x 1800 (or 1280x800 min) | Landscape |

#### 4.2 App Store Screenshot Narrative Plan (Imagery + Copywriting)

Use a consistent visual system across all device classes:
- **Palette:** warm paper tones + Manuscript blue accent
- **Typography:** bold headline + short support line
- **Composition:** app UI should remain primary (no heavy framing)
- **Tone:** calm, ownership-focused, craft-oriented writing workflow
- **Copy style:** 2-6 words headline, optional 6-10 words subline

##### Suggested sequence (iPhone/iPad/Mac variants)

| # | Feature Focus | Imagery Direction | Headline Copy | Optional Supporting Copy |
|---|---------------|-------------------|---------------|--------------------------|
| 1 | Core editor | Open manuscript draft with clean typography and active cursor | **Write without distractions** | Native editor built for long-form writing |
| 2 | Binder organization | Sidebar showing chapters/scenes hierarchy | **Organize every chapter** | Keep projects structured from idea to final draft |
| 3 | Character management | Character sheet with bio, traits, and notes | **Know your characters** | Track people, arcs, and details in one place |
| 4 | Corkboard planning | Card-based scene board with statuses | **Plan visually with corkboard** | Rearrange scenes before you rewrite |
| 5 | Focus mode / dark mode | Minimal UI writing surface in dark theme | **Stay in the writing flow** | Focus mode keeps attention on your words |
| 6 | Export + ownership | Export sheet with Markdown, PDF, EPUB options | **Your files, your format** | Export anytime—no lock-in |

##### Alternate copy variants (A/B options)

- "Your story, your files"
- "Built for serious drafting"
- "From outline to final draft"
- "Native on iPhone, iPad, Mac"
- "Markdown you own forever"
- "Privacy-first writing app"

##### Capture direction by platform

| Platform | Visual Notes |
|----------|--------------|
| iPhone | Prioritize editor readability and one clear UI action per shot |
| iPad | Showcase split view, binder depth, and planning workflows |
| Mac | Highlight dense project management + keyboard-first writing context |

##### Screenshot production checklist

- [ ] Create a single demo project used across all screenshots (same story world and names)
- [ ] Prepare clean sample manuscript text (no lorem ipsum, no placeholder strings)
- [ ] Capture raw screenshots for each required device size
- [ ] Apply approved caption templates and safe margins
- [ ] Verify no system alerts, debug UI, or inconsistent timestamps
- [ ] Review metadata/copy parity with actual implemented features
- [ ] Export final PNG sets by device class for App Store Connect upload

### Phase 5: Testing & Quality (Week 3)

#### 5.1 Expand Test Coverage

**Priority:** MEDIUM
**Current State:** Minimal tests

**Actions:**
- [ ] Add unit tests for document save/load
- [ ] Add unit tests for export functionality
- [ ] Add UI tests for critical user journeys
- [ ] Run tests on CI if available

#### 5.2 Device Testing

**Actions:**
- [ ] Test on physical iPhone
- [ ] Test on physical iPad
- [ ] Test on Mac (both Intel and Apple Silicon if possible)
- [ ] Test oldest supported OS versions

#### 5.3 Performance Audit

**Actions:**
- [ ] Profile with Instruments
- [ ] Check for memory leaks
- [ ] Verify app size is reasonable
- [ ] Test cold launch time

### Phase 6: Pre-Submission (Week 4)

#### 6.1 TestFlight Beta

**Actions:**
- [ ] Archive release build
- [ ] Upload to App Store Connect
- [ ] Internal testing (team)
- [ ] External beta testing (select users)
- [ ] Collect and address feedback

#### 6.2 App Store Connect Setup

**Actions:**
- [ ] Register bundle ID on Apple Developer Portal
- [ ] Create App Store Connect app record
- [ ] Fill in all metadata
- [ ] Upload screenshots
- [ ] Set pricing (Free with optional IAP?)
- [ ] Configure availability (countries)

#### 6.3 Final Checklist

- [ ] All crashes resolved
- [ ] No placeholder content
- [ ] All URLs working (privacy policy, support)
- [ ] App icon finalized and visible
- [ ] Screenshots capture actual app state
- [ ] Metadata complete and accurate
- [ ] Demo account provided (if login required)
- [ ] Export compliance answered
- [ ] Content rights confirmed

---

## Part 4: Common Rejection Reasons to Avoid

### Performance (Guideline 2.1)

| Issue | Prevention |
|-------|------------|
| Crashes | Test all code paths, handle errors gracefully |
| Broken features | Verify every feature works in release build |
| Incomplete UI | Remove or hide unfinished features |

### Metadata (Guideline 2.3)

| Issue | Prevention |
|-------|------------|
| Misleading description | Accurately describe current features |
| Missing privacy policy | Host and link before submission |
| Placeholder content | Review all text in app |

### Privacy (Guideline 5.1)

| Issue | Prevention |
|-------|------------|
| Missing privacy manifest | Create PrivacyInfo.xcprivacy |
| Undisclosed data collection | Document all data usage |
| Missing usage descriptions | Add all required Info.plist keys |

### Design (Guideline 4.0)

| Issue | Prevention |
|-------|------------|
| Non-native UI patterns | Use standard SwiftUI components |
| Poor iPad layout | Test and optimize for larger screens |
| Accessibility issues | Support VoiceOver, Dynamic Type |

---

## Part 5: Timeline Summary

| Week | Focus | Key Deliverables |
|------|-------|------------------|
| 1 | Critical blockers | Privacy manifest (done), app icons (done) |
| 2 | Legal & metadata | Privacy policy, ToS, App Store description |
| 3 | Screenshots & testing | All screenshot sizes, expanded tests |
| 4 | Pre-submission | TestFlight, App Store Connect setup |
| 5 | Buffer/Review | Address any issues, submit |

---

## Resources

### Apple Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)
- [Privacy Manifest Documentation](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

### Third-Party Guides
- [App Store Review Checklist 2025](https://appinstitute.com/app-store-review-checklist/)
- [App Store Review Guidelines Compliance](https://nextnative.dev/blog/app-store-review-guidelines)
- [iOS App Store Review Best Practices](https://crustlab.com/blog/ios-app-store-review-guidelines/)

---

## Notes

- **Manuscript has no accounts** - Account deletion requirement doesn't apply
- **Manuscript has no IAP currently** - Restore Purchases requirement doesn't apply
- **Manuscript has AI features** - On-device via Apple Foundation Models (default) and optional cloud AI (OpenAI, Claude) with user-provided API keys. AI transparency disclosure required.
- **Open source consideration** - Being open source (MPL-2.0) is a marketing advantage

---

*Document created: January 28, 2026*
*Last updated: February 17, 2026*
