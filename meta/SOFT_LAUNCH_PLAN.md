# Soft Launch Plan

Strategy for launching Manuscript with minimal risk and maximum learning.

---

## Overview

A soft launch allows us to:
- Identify critical bugs before wide release
- Gather early user feedback
- Test App Store mechanics
- Build initial reviews and ratings

---

## Phase 1: Internal Testing (Week 1-2)

### Goals
- Validate core functionality works
- Identify obvious bugs
- Test on multiple device configurations

### Actions
| Task | Owner | Status |
|------|-------|:------:|
| Test document creation/editing | Internal | 🟡 |
| Test save/load cycle | Internal | 🟡 |
| Test on iPhone (multiple sizes) | Internal | 🔴 |
| Test on iPad | Internal | 🔴 |
| Test on Mac (Intel + Apple Silicon) | Internal | 🔴 |
| Test CloudKit sync between devices | Internal | 🔴 |
| Create bug tracking system | Internal | ✅ |

### Success Criteria
- [ ] No crashes in 24 hours of normal use
- [ ] Documents save and load correctly
- [ ] Sync works across 2+ devices
- [ ] All navigation paths work

---

## Phase 2: TestFlight Beta (Week 3-4)

### Goals
- Get feedback from real users
- Test with diverse use cases
- Identify UX issues

### Beta Tester Recruitment
| Source | Target Count | Notes |
|--------|:------------:|-------|
| Personal network | 5-10 | Friends, family who write |
| Twitter/X | 10-20 | Writing community |
| Reddit r/writing | 10-20 | Writers looking for tools |
| Indie dev community | 5-10 | Technical feedback |

**Total target: 30-60 beta testers**

### TestFlight Setup
| Task | Status |
|------|:------:|
| Create TestFlight group | 🟡 |
| Write beta tester invitation | 🟡 |
| Create Discord server for beta community | 🔴 |
| Create feedback survey | 🔴 |
| Set up crash reporting | 🟡 |
| Define beta version numbering | ✅ |

### Feedback Collection
- In-app feedback button (FeedbackView.swift exists)
- TestFlight feedback mechanism
- Short survey (Google Forms/Typeform)
- Discord or Slack channel for discussion

### Discord Server Setup (for Soft Launch)

If Discord is chosen over Slack, set up the server before inviting beta users.

| Task | Status |
|------|:------:|
| Create server `Manuscript Beta` | 🔴 |
| Add channels (`#announcements`, `#bug-reports`, `#feature-feedback`, `#general`) | 🔴 |
| Add channel guidelines and bug report template | 🔴 |
| Create roles (`Maintainer`, `Beta Tester`) | 🔴 |
| Post invite link in TestFlight onboarding email | 🔴 |

### Beta Duration
- **Minimum**: 2 weeks
- **Ideal**: 4 weeks
- **Extend if**: Critical bugs found, low tester engagement

### Success Criteria
- [ ] 20+ active testers
- [ ] <5 crash reports
- [ ] Net Promoter Score > 7
- [ ] Core features rated "useful" by 80%+

---

## Phase 3: Limited Launch (Week 5-6)

### Strategy: Single Market First

Launch in a smaller English-speaking market before worldwide:

| Market | Population | Pros | Cons |
|--------|------------|------|------|
| **New Zealand** | 5M | English, small, early timezone | Small market |
| Australia | 26M | English, manageable size | Larger than NZ |
| Canada | 40M | English/French, similar to US | Larger |

**Recommendation**: New Zealand first

### Limited Launch Goals
- Test App Store submission process
- Validate App Store listing
- Get initial reviews (even if few)
- Final bug check in production

### Actions
| Task | Status |
|------|:------:|
| Submit to App Store (NZ only) | 🔴 |
| Monitor crash reports | 🔴 |
| Respond to any reviews | 🔴 |
| Track download numbers | 🔴 |
| Gather feedback via support email | 🔴 |

### Duration
- 1-2 weeks minimum
- Extend if issues found

### Go/No-Go for Worldwide
- [ ] <1% crash rate
- [ ] No critical bugs reported
- [ ] Rating above 3.5 stars (if any ratings)
- [ ] App Store listing looks correct

---

## Phase 4: Worldwide Launch (Week 7+)

### Pre-Launch (1 week before)

| Task | Status |
|------|:------:|
| Update App Store listing for all regions | 🔴 |
| Prepare press release | 🔴 |
| Schedule social media posts | 🔴 |
| Notify beta testers of launch | 🔴 |
| Update website with download links | 🔴 |

### Launch Day

| Task | When |
|------|------|
| Flip availability to worldwide | Morning |
| Post on Twitter/X | After store updates |
| Post on Reddit (r/writing, r/macapps, r/iosapps) | Midday |
| Post on Hacker News | Afternoon |
| Send email to beta testers | Afternoon |
| Monitor crash reports | All day |

### Launch Week

| Task | Frequency |
|------|-----------|
| Monitor crash reports | Daily |
| Respond to reviews | Daily |
| Track download metrics | Daily |
| Social media engagement | Daily |
| Bug fix releases if needed | As needed |

---

## Metrics to Track

### App Store Metrics
| Metric | Target | Tool |
|--------|--------|------|
| Downloads | 100 first week | App Store Connect |
| Crash rate | <1% | App Store Connect |
| Rating | >4.0 stars | App Store Connect |
| Retention D1 | >30% | App Store Connect |
| Retention D7 | >15% | App Store Connect |

### Website Metrics
| Metric | Target | Tool |
|--------|--------|------|
| Page views | 500 first week | GitHub Pages analytics |
| Download clicks | 50% of views | Custom tracking |

### Engagement Metrics
| Metric | Target | Tool |
|--------|--------|------|
| Documents created | >2 per user | Analytics (if added) |
| Session length | >5 minutes | Analytics (if added) |
| Return rate | >20% | Analytics (if added) |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| App rejection | Review guidelines early, prepare appeal |
| Critical bug post-launch | Have hotfix release ready |
| Negative reviews | Respond quickly, fix issues |
| Low downloads | Adjust marketing, consider Product Hunt |
| Server issues (CloudKit) | Monitor Apple System Status |

---

## Budget

| Item | Cost | Notes |
|------|------|-------|
| Apple Developer Program | $99/year | Required |
| Domain (if needed) | $12/year | manuscriptapp.com |
| Analytics (optional) | $0-50/month | TelemetryDeck, Mixpanel |
| Marketing (optional) | $0-200 | Twitter/Reddit ads |

**Minimum budget**: $99 (Developer Program only)

---

## Timeline Summary

| Week | Phase | Key Milestone |
|------|-------|---------------|
| 1-2 | Internal Testing | Bug-free internal build |
| 3-4 | TestFlight Beta | 30+ testers, feedback collected |
| 5-6 | Limited Launch (NZ) | App Store approved, live |
| 7+ | Worldwide Launch | Global availability |

---

## Post-Launch Priorities

After successful launch:

1. **Week 1**: Bug fixes only
2. **Week 2-3**: Quick wins from feedback
3. **Month 2**: First feature update
4. **Month 3+**: Roadmap features

---

## Success Definition

The soft launch is successful if:

- [ ] App approved on first submission
- [ ] <1% crash rate in production
- [ ] 100+ downloads in first month
- [ ] Average rating > 4.0 stars
- [ ] At least 5 reviews
- [ ] No critical security issues

---

*Last updated: February 17, 2026*
