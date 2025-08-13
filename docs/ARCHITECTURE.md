# Architecture

## Overview
- SwiftUI client with Managers (state/logic), Services (integration), and Models
- Firebase backend: Firestore, Functions, Storage, Auth, Remote Config, FCM, GA4
- Offline-first with Core Data and a background sync queue

## Client layers
- Views (SwiftUI): `Views/*`
- Managers: `Managers/*` (e.g., RejectionManager, CommunityManager, ChallengeManager)
- Services: `Services/*` (FirestoreSyncService, FirebaseConfigurator, ImageUploadService)
- Models: `Models/*`
- Design: `Extensions/DesignSystem.swift`, `Assets`

## Data model (core)
- RejectionEntry: id, type, emotionalImpact, note, timestamp, imageUrl?
- Aggregates: users/{uid}/aggregates/{dayKey}, users/{uid}/aggregates/patterns
- Community: `community/{postId}` with `type`, `content`, `createdAt`, `reactions`, `status`

## Cloud functions
- Rejections: onCreate aggregates + server-side pattern detection + push
- Community: callable `createCommunityPost`, `reactToPost` (dedupe), `reportPost` (hide when reports >= 3)
- Challenges: scheduled `generateDailyChallenges`
- Data lifecycle: callables `requestDataExport` (signed URL), `requestAccountDeletion`
- Maintenance: `cleanupStaleDocs` (rateLimits/userReactions), `backfillCommunityStatus`

## Security
- Firestore: user-owned subtree; community read-only; server-only collections deny client access
- Storage: images path per user; rules allow only owner

## Notifications
- Local: daily check-in, recovery follow-ups; categories and deep-link routing
- Remote: FCM token saved per user; server sends on rejections (if token)

## Analytics & Config
- Screen_view + action events; Remote Config flags (`communityEnabled`, `challengeDifficulty`)