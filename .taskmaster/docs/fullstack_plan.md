# ResilientMe Full-Stack Production Plan

## Overview
Goal: Move from MVP to a secure, scalable, offline-first app with fully functional frontend and backend, delivered in 5 sprints with CI/CD and compliance.

## Backend Platform
- Firebase: Auth, Firestore, Storage, Cloud Functions, FCM, Remote Config, Emulator Suite
- Environments: dev, staging, prod (separate Firebase projects)
- Per-env `GoogleService-Info.plist`; app selects env at build-time

## Data Model (Firestore)
- `users/{uid}`: profile, settings (anonymous mode, notification prefs), resilience_level, counters
- `users/{uid}/rejections/{id}`: type, impact, note, location, imageRef, createdAt, recoveredAt
- `users/{uid}/aggregates/{period}`: daily/weekly aggregates (counts, avgImpact, streaks)
- `users/{uid}/challenges/{yyyyMMdd}`: challenge, status, completedAt, pointsAwarded
- `community/{postId}`: type, content, createdAt, reactions map, flagsCount, status (active/hidden), authorUid (optional/null for anonymity)
- `community/{postId}/reports/{reportId}`: reason, reporterUid, createdAt
- `patterns/{uid}/{patternId}` or embed in aggregates
- Indexes: community.createdAt desc; user rejections.createdAt desc; reactions updates

## Security Rules (High-Level)
- Only owner read/write in `users/{uid}/...`
- Community
  - Create: authenticated; content length limits; profanity check flag set by Function
  - Read: public
  - React: authenticated; field-level updates to `reactions.{emoji}`; rate-limit via Function/App Check
  - Report: authenticated; one-per-user-per-post
- Storage: owner-only `rejection_images/{uid}/*` read/write

## Cloud Functions
- onCreate `users/{uid}/rejections/{id}`: update aggregates, enqueue follow-up, recompute resilience score, pattern detection
- onWrite `community/{postId}`: moderation check (e.g., Perspective API), set `status`
- callable `reactToPost(postId, reaction)`: atomic inc, dedupe per user
- scheduled `generateDailyChallenges`: create today’s challenge per user (patterns + level)
- callable `requestDataExport` / `requestAccountDeletion`: export or scrub PII
- Rate limiting via callables + App Check

## Mobile App (SwiftUI)
- Auth: anonymous + email link sign-in; upgrade anon → permanent; Profile view
- Data layer: repository pattern (Firestore + Core Data cache), offline queue, last-write-wins for notes; merges for reactions
- Rejections: attach image → Storage; optional location (permissioned)
- Dashboard: server aggregates (local fallback offline)
- Patterns: server-detected (client fallback only)
- Recovery Hub: server-issued daily challenge; completion reported to backend
- Community: infinite scroll, post, react, report, delete own, moderation aware
- Notifications: FCM token registration; Function-scheduled reminders; in-app center
- Remote Config: feature flags (community on/off, difficulty), copy tweaks

## Observability & Quality
- Analytics (GA4): `rejection_log`, `challenge_complete`, `community_post`, `reaction_add`, `notification_open`
- Crash/Error: Sentry SDK
- Performance: os_signpost; cold start <2s; log flow <30s E2E including upload
- Tests: unit (repos, analyzer), UI (log flow, challenge, community), integration (Emulator Suite in CI)

## Compliance & Privacy
- Age gate 18+
- Data export/delete via callables; archive to Cloud Storage; scrub PII
- Updated Privacy/Terms; consent for notifications & analytics

## CI/CD & Release
- Fastlane: build, test (emulators), sign, TestFlight upload
- GitHub Actions: PR checks (lint, unit, UI smoke); main → TestFlight; tags → App Store Connect
- Remote Config for staged rollouts

## Timeline (5 Sprints)
1. Auth completion, repositories, offline queue, Storage upload, Rules v1, Functions: rejections aggregate
2. Community (post/react/report), moderation Function, pagination, Rules v2
3. Challenges server-gen + client UI, FCM notifications & schedule
4. Analytics taxonomy, Sentry, performance tuning, Accessibility completion
5. Data export/delete, staging/prod cutover, TestFlight, ASO basics

## Acceptance Criteria (Samples)
- Offline logs sync within 5s when online; images visible in History
- Community posts visible to others <2s; moderation hides unsafe
- Daily challenge for every user at 08:00 local; completion increments streak server-verified
- Data export delivered <24h; deletion removes PII <24h

## Migration from MVP
- Create staging Firebase; deploy rules/functions
- Point app to staging plist; smoke test
- Migrate local Core Data entries on first run after sign-in (batch upload)

## Dependencies
- Functions: `firebase-functions`, `firebase-admin`, moderation API client
- iOS: Sentry, App Check, Inter font bundle (optional)

## Risks & Mitigation
- Moderation costs/latency → cache decisions, limit text length
- Abuse → callable rate limits, App Check, heuristic blocks client & server

## Next Steps (This Week)
- Set up staging Firebase + Emulator Suite
- Implement Functions: rejections aggregate + notifications; deploy
- Wire repositories to server aggregates; remove client-only calcs when server present
- Harden Rules v1 and add tests
