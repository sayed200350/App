# Remote Config

## Flags
- `communityEnabled` (bool): shows/hides Community tab
- `challengeDifficulty` (string): reserved for tuning challenge generator
- `aiRecoveryEnabled` (bool): gates AI-powered recovery plan generation

## Client
- `RemoteConfigManager` loads flags on app start and gates `ContentView` tabs.