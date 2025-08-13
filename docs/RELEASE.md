# Release & CI/CD

## GitHub Actions
- Functions tests, iOS build, Fastlane test
- Manual beta trigger: Actions → Run workflow → set `beta=true`

## Secrets
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY` (base64 .p8)
- (Optional) `FIREBASE_TOKEN` for deploys

## Firebase deploys
- Rules/indexes: `firebase deploy --only firestore:rules,firestore:indexes`
- Functions: `cd functions && npm i && npm run build && npm run deploy`

## TestFlight
- Trigger Fastlane beta after secrets added. Upload occurs via App Store Connect API key.
- Add testers and notes in App Store Connect.