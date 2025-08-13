# ResilientMe (iOS + Firebase)

Turn rejection into resilience. ResilientMe helps Gen Z log rejections in seconds, surface patterns, and bounce back with actionable recovery tools and community support.

## Highlights
- 30-sec Quick Log with types, impact slider, optional note/screenshot, and haptics
- Smart Dashboard with resilience score, weekly stats, trends, and pattern alerts
- Recovery Hub with contextual plans, quick actions, and response templates
- Daily Challenges with server-side generation and streaks
- Anonymous Community feed with reactions, moderation/reporting, and callables
- Offline-first logging with Core Data and background sync queue
- Push notifications (daily check-in, recovery follow-ups) and deep-links to tabs
- Privacy-first: anonymous by default, biometric lock, export/delete data
- CI/CD with GitHub Actions + Fastlane; Firestore/Storage rules + tests

## Repo structure
```
functions/               # Firebase Cloud Functions (TypeScript)
ios/ResilientMe/         # iOS SwiftUI app
ios/fastlane/            # Fastlane lanes for test/beta
.github/workflows/       # CI (functions tests, iOS build, fastlane)
firestore.rules          # Firestore security rules
firestore.indexes.json   # Firestore indexes
storage.rules            # Storage rules
ios/ResilientMe/PrivacyInfo.xcprivacy  # Privacy Manifest
ios/AppStorePrivacy.json # App Store privacy summary (reference)
```

## Architecture (quick)
- Client (SwiftUI): Views → Managers (state/logic) → Services (integration) → Models
- Local: Core Data (offline queue), plus transient in-memory state
- Cloud: Firestore (users/*, community, aggregates), Functions (callables, triggers, schedulers), Storage (images), FCM; GA4 analytics; Remote Config flags

Details: see `docs/ARCHITECTURE.md` and `docs/API.md`.

## Getting started (local)
- iOS: open `ios/ResilientMe.xcodeproj` (SwiftUI, iOS 15+). Build and run on simulator.
- Firebase emulators (optional): `cd functions && npm i && npm run serve`
- Functions build/test: `cd functions && npm i && npm run build && npm test`

Note: You can run CI-only paths without local builds. See CI and release below.

## Security
- Firestore rules enforce least privilege. `users/{uid}/**` only by owner. `community` is read-only for clients. Server-only collections (`userReactions`, `communityReports`, `rateLimits`) deny all client access.
- Storage rules: `rejection_images/{uid}/**` only by owner.
- Functions: input sanitization (content), rate limiting (per user/window), moderation/report flow.

More: `docs/SECURITY_PRIVACY.md`.

## Analytics & Remote Config
- GA4 events wired (screen views, core actions). See `docs/ANALYTICS.md`.
- Remote Config: `communityEnabled`, `challengeDifficulty`. See `docs/CONFIG.md`.

## CI/CD
- GitHub Actions: functions tests, iOS simulator build, fastlane test; optional manual TestFlight (`beta=true`).
- Fastlane lanes (in `ios/fastlane`): `test` and `beta`.

See `docs/RELEASE.md` for secrets and steps.

## Development standards
- Code style: SwiftUI + managers/services, meaningful naming, accessible UI (44pt targets, labels), skeletons and empty states.
- Design tokens: Dark theme, brand colors/typography.
- Docs: see `/docs/*` for deep dives.

## Documentation map
- Architecture: `docs/ARCHITECTURE.md`
- Cloud APIs: `docs/API.md`
- Security & Privacy: `docs/SECURITY_PRIVACY.md`
- Analytics taxonomy: `docs/ANALYTICS.md`
- Config & flags: `docs/CONFIG.md`
- Testing: `docs/TESTING.md`
- Release & App Store: `docs/RELEASE.md`
- UX & design system: `docs/UX.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`

## License
Proprietary. All rights reserved.