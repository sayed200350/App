# Testing

## Functions
- Install deps: `cd functions && npm i`
- Build: `npm run build`
- Run tests: `npm test`
  - Rules tests cover users/community/server-only collections
  - Storage tests cover user image paths

## iOS UI Tests
- `ResilientMeUITests` includes Quick Log flow and Community tab presence
- CI runs fastlane test on simulator (see GitHub Actions)