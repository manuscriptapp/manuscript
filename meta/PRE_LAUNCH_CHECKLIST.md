# Pre-Launch Checklist

Everything needed before Manuscript's initial App Store launch.

**Status:** 🔴 Not Started | 🟡 In Progress | 🟢 Complete

---

## Critical Bug Fixes

| Task | Status | Notes |
|------|:------:|-------|
| Test document save/load cycle | 🔴 | Verify ManuscriptDocument FileDocument implementation |
| Validate CloudKit sync | 🔴 | Test across devices |
| Test all navigation paths | 🔴 | Sidebar, detail views, sheets |
| Memory leak audit | 🔴 | Profile with Instruments |
| Crash-free cold start | 🔴 | No crashes on fresh install |

---

## Essential Features for MVP

Based on FEATURE_PARITY.md, these are required for a viable writing app:

### Must Have (Before Launch)

| Feature | Status | File(s) |
|---------|:------:|---------|
| Create new document | 🟢 | AddDocumentSheet.swift |
| Create new folder | 🟢 | AddFolderSheet.swift |
| Edit document content | 🟢 | DocumentDetailView.swift |
| Auto-save documents | 🟢 | ManuscriptDocument.swift |
| Dark mode support | 🟢 | System-supported |
| Sidebar navigation | 🟢 | ProjectSidebar.swift |
| Character management | 🟢 | CharactersView.swift |
| Location management | 🟢 | LocationsView.swift |
| Export to Markdown | 🟢 | ExportView.swift |
| Onboarding flow | 🟢 | OnboardingView.swift |

### Should Have (Launch Window)

| Feature | Status | Priority |
|---------|:------:|:--------:|
| Live word count | 🟢 | High |
| Rich text editing | 🟢 | High |
| Formatting toolbar | 🟢 | High |
| Comments system | 🟢 | High |
| Drag & drop reorder | 🟢 | High |
| Move between folders | 🟢 | High |
| Inline renaming | 🟢 | High |
| Scrivener import | 🟢 | High |
| Compile to single doc | 🟢 | Medium |
| Export to PDF | 🟢 | Medium |
| Find & replace | 🟢 | High |
| Read mode | 🟢 | Medium |
| Trash folder | 🟢 | High |

### Nice to Have (Post-Launch)

- ~~Split editor~~ ✅
- Typewriter scrolling
- ~~Corkboard view~~ ✅
- ~~Outliner view~~ ✅
- ~~Import DOCX~~ ✅ (macOS-only)
- ~~Export EPUB~~ ✅
- ~~Writing goals/targets~~ ✅
- ~~Import Markdown/TXT~~ ✅
- ~~Import PDF/HTML~~ ✅
- ~~Export HTML~~ ✅
- ~~Export Scrivener 3~~ ✅
- ~~Favorites collection~~ ✅
- ~~Keywords & collections~~ ✅
- ~~Media attachments~~ ✅
- ~~Native print~~ ✅
- ~~Backup management~~ ✅
- ~~Text-to-speech~~ ✅
- ~~On-device AI~~ ✅
- Version comparison (diff view)
- Typewriter scrolling

---

## App Store Requirements

### App Icons

| Asset | Size | Status |
|-------|------|:------:|
| iOS App Icon | 1024x1024 (single source) | 🟢 |
| macOS App Icon | 1024x1024 (single source) | 🟢 |

*Using Xcode 15+ single-source icon format — individual sizes auto-generated.*

### Screenshots

| Platform | Sizes Needed | Status |
|----------|--------------|:------:|
| iPhone 6.7" | 1290 x 2796 | 🔴 |
| iPhone 6.5" | 1242 x 2688 | 🔴 |
| iPhone 5.5" | 1242 x 2208 | 🔴 |
| iPad Pro 12.9" | 2048 x 2732 | 🔴 |
| Mac | 1280 x 800 minimum | 🔴 |

### App Store Metadata

| Item | Status | Notes |
|------|:------:|-------|
| App name | 🟢 | "Manuscript" |
| Subtitle | 🟢 | "Your Story, Your Files" (22 chars) |
| Description | 🟢 | Finalized in APP_STORE_REVIEW.md |
| Keywords | 🟢 | writing,novel,screenplay,markdown,scrivener,author,manuscript,book,editor,export (100 chars) |
| Privacy policy URL | 🟢 | manuscriptapp.github.io/manuscript/privacy |
| Support URL | 🟢 | manuscriptapp.github.io/manuscript/support |
| Marketing URL | 🟢 | manuscriptapp.github.io/manuscript |
| Category | 🟢 | Primary: Productivity, Secondary: Reference |
| Age rating | 🔴 | Complete questionnaire in App Store Connect |
| Copyright | 🟢 | "© 2026 Manuscript" |
| Release notes | 🟢 | See meta/RELEASE_NOTES.md |

---

## Technical Requirements

### Build Configuration

| Task | Status | Notes |
|------|:------:|-------|
| Set bundle identifier | 🟢 | com.dahlsjoo.manuscript |
| Configure App Groups | 🔴 | For CloudKit sync |
| Enable iCloud capability | 🟢 | CloudKit container enabled |
| Set minimum deployment | 🟢 | iOS 18.0 / macOS 15.0 |
| Configure entitlements | 🟢 | App sandbox, iCloud, network client |
| Archive builds | 🔴 | Test release builds |
| Xcode Cloud CI | 🟢 | ci_scripts configured next to xcodeproj |

### Code Signing

| Task | Status | Notes |
|------|:------:|-------|
| Apple Developer account | 🔴 | Required for distribution |
| App Store provisioning | 🔴 | Distribution profile |
| Mac Developer ID | 🔴 | For direct distribution |

### Testing

| Task | Status | Notes |
|------|:------:|-------|
| Unit tests passing | 🟡 | Basic import tests added |
| UI tests for critical paths | 🔴 | Document creation, editing |
| Test on physical devices | 🔴 | iPhone, iPad, Mac |
| Test on oldest supported OS | 🔴 | iOS 18.0, macOS 15.0 |
| TestFlight beta | 🔴 | External testing |

---

## Documentation

| Document | Status | Location |
|----------|:------:|----------|
| README.md | 🟢 | Root |
| CONTRIBUTING.md | 🟢 | Root |
| LICENSE | 🟢 | Root (MPL-2.0) |
| Privacy Policy | 🟢 | docs/privacy.html |
| Terms of Service | 🟢 | docs/terms.html |
| Support page | 🟢 | docs/support.html |
| User guide/Help | 🔴 | In-app or docs/ |
| Release notes | 🟢 | meta/RELEASE_NOTES.md |

---

## Marketing Website

| Task | Status | Notes |
|------|:------:|-------|
| Landing page | 🟢 | docs/index.html — live with feature showcase and comparison table |
| Feature showcase | 🟢 | Included in landing page |
| Download links | 🔴 | App Store badges (pending submission) |
| Press kit | 🔴 | Logos, screenshots |

---

## Pre-Submission Checklist

Before clicking "Submit for Review":

- [ ] All crashes resolved
- [ ] No placeholder content
- [x] All URLs working (privacy, terms, support)
- [x] Privacy policy accessible
- [x] App icon finalized
- [ ] Screenshots capture actual app
- [ ] Metadata complete
- [ ] Test account provided (if needed)
- [x] Export compliance answered
- [ ] Content rights confirmed
- [ ] AI transparency disclosure completed (on-device default + opt-in cloud with user API key)

---

## Launch Day

| Task | Notes |
|------|-------|
| Monitor crash reports | App Store Connect |
| Respond to reviews | Within 24 hours |
| Social media announcement | Twitter, Reddit, Discord |
| Update website | Add download buttons |
| Monitor analytics | Track downloads, retention |

---

## Priority Order

1. **Week 1-2**: Bug fixes, essential features
2. **Week 3**: App icons, screenshots
3. **Week 4**: Metadata, documentation
4. **Week 5**: TestFlight beta
5. **Week 6**: Submit for review

---

*Last updated: February 17, 2026*
