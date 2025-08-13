# Security & Privacy

## Firestore rules
- `users/{userId}/{document=**}`: allow if `request.auth.uid == userId`
- `community/{postId}`: allow read; deny all client writes (Functions only)
- `userReactions`, `communityReports`, `rateLimits`: deny client read/write

## Storage rules
- `rejection_images/{userId}/{allPaths=**}`: allow if `request.auth.uid == userId`

## Functions
- Sanitizes text input for community posts
- Rate-limits callables (per user/window) via `rateLimits`
- Deletes Storage images on entry/account deletion

## Privacy Manifest
- `ios/ResilientMe/PrivacyInfo.xcprivacy`: no tracking; data types include User ID, Device ID, Product Interaction, Email Address; purposes are App Functionality, Analytics, Account Management