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
- Import DOCX
- ~~Export EPUB~~ ✅
- ~~Writing goals/targets~~ ✅
- Version comparison (diff view)

---

## App Store Requirements

### App Icons

| Asset | Size | Status |
|-------|------|:------:|
| iOS App Icon | 1024x1024 | 🔴 |
| macOS App Icon | 1024x1024 (with transparency) | 🔴 |
| iOS Spotlight | 120x120 | 🔴 |
| iOS Settings | 87x87 | 🔴 |
| macOS 16pt - 512pt set | All sizes | 🔴 |

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
| Subtitle | 🔴 | Max 30 characters |
| Description | 🔴 | Full App Store description |
| Keywords | 🔴 | 100 characters max |
| Privacy policy URL | 🔴 | Required |
| Support URL | 🔴 | Required |
| Marketing URL | 🟡 | manuscriptapp.github.io |
| Category | 🔴 | Productivity or Reference |
| Age rating | 🔴 | Complete questionnaire |
| Copyright | 🔴 | "© 2026 Manuscript" |

---

## Technical Requirements

### Build Configuration

| Task | Status | Notes |
|------|:------:|-------|
| Set bundle identifier | 🔴 | com.dahlsjoo.manuscript |
| Configure App Groups | 🔴 | For CloudKit sync |
| Enable iCloud capability | 🔴 | CloudKit container |
| Set minimum deployment | 🟢 | iOS 17.0 / macOS 14.0 |
| Configure entitlements | 🔴 | App sandbox, iCloud |
| Archive builds | 🔴 | Test release builds |

### Code Signing

| Task | Status | Notes |
|------|:------:|-------|
| Apple Developer account | 🔴 | Required for distribution |
| App Store provisioning | 🔴 | Distribution profile |
| Mac Developer ID | 🔴 | For direct distribution |

### Testing

| Task | Status | Notes |
|------|:------:|-------|
| Unit tests passing | 🔴 | Create basic test suite |
| UI tests for critical paths | 🔴 | Document creation, editing |
| Test on physical devices | 🔴 | iPhone, iPad, Mac |
| Test on oldest supported OS | 🔴 | iOS 17.0, macOS 14.0 |
| TestFlight beta | 🔴 | External testing |

---

## Documentation

| Document | Status | Location |
|----------|:------:|----------|
| README.md | 🟢 | Root |
| CONTRIBUTING.md | 🟢 | Root |
| LICENSE | 🟢 | Root (MPL-2.0) |
| Privacy Policy | 🔴 | docs/ or external |
| Terms of Service | 🔴 | docs/ or external |
| User guide/Help | 🔴 | In-app or docs/ |

---

## Marketing Website

| Task | Status | Notes |
|------|:------:|-------|
| Landing page | 🟡 | docs/index.html |
| Feature showcase | 🔴 | Screenshots, descriptions |
| Download links | 🔴 | App Store badges |
| Press kit | 🔴 | Logos, screenshots |

---

## Pre-Submission Checklist

Before clicking "Submit for Review":

- [ ] All crashes resolved
- [ ] No placeholder content
- [ ] All URLs working
- [ ] Privacy policy accessible
- [ ] App icon finalized
- [ ] Screenshots capture actual app
- [ ] Metadata complete
- [ ] Test account provided (if needed)
- [ ] Export compliance answered
- [ ] Content rights confirmed

---

## Launch Day

| Task | Notes |
|------|-------|
| Monitor crash reports | App Store Connect |
| Respond to reviews | Within 24 hours |
| Social media announcement | Twitter, Reddit |
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

*Last updated: January 27, 2026*
