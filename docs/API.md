# Cloud API

## Callables
- `createCommunityPost({ type: 'dating'|'job'|'social'|'other', content: string })` → `{ id }`
  - Sanitizes input, rate-limits, sets `status: 'visible'`
- `reactToPost({ postId, reaction: '💪'|'😔'|'🎉'|'🫂' })` → `{ ok: true }`
  - Dedupe per user via `userReactions` and atomic increment
- `reportPost({ postId })` → `{ ok: true }`
  - Increments `reports`, hides at threshold
- `requestDataExport()` → `{ url }`
  - Bundles user data to Storage, returns 1h signed URL; rate-limited
- `requestAccountDeletion()` → `{ ok: true }`
  - Deletes user subcollections, images, user doc, Auth user
- `backfillCommunityStatus()` [admin]
  - Sets `status: 'visible'` on recent posts lacking it
- `generateRecoveryPlan({ type: 'dating'|'job'|'social'|'academic'|'other', impact: 0..10, note?: string, tone?: 'gentle'|'direct' })` → `{ steps: {title, detail}[], affirmations: string[], templates: {label, text}[] }`
  - Uses Vertex AI (Gemini) with safety filters and rate-limiting

## Triggers & schedules
- Firestore: `onRejectionCreate` aggregates, server patterns, optional FCM
- Firestore: `onRejectionDelete` removes Storage image
- Pub/Sub: `generateDailyChallenges` daily at 05:00 UTC
- Pub/Sub: `cleanupStaleDocs` every 24h