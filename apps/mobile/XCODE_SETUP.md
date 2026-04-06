# Xcode Project Setup — LumeraAI

## Requirements
- Xcode 15.3+
- iOS 17+ deployment target
- watchOS 10+ deployment target
- Apple Developer account

## Steps

### 1. Create Xcode Project
1. Open Xcode → **File → New → Project**
2. Select **iOS → App**
3. Product Name: `LumeraAI`
4. Bundle ID: `ai.lumera.LumeraAI`
5. Interface: **SwiftUI**
6. Language: **Swift**
7. Save to: `LumeraAI/apps/mobile/`

### 2. Add watchOS Target
1. **File → New → Target**
2. Select **watchOS → App**
3. Product Name: `LumeraAI Watch`
4. Bundle ID: `ai.lumera.LumeraAI.watchkitapp`
5. Select the iOS target as the companion

### 3. Add Source Files

**iOS Target — add all files from:**
```
apps/mobile/LumeraAI/App/
apps/mobile/LumeraAI/Views/
apps/mobile/LumeraAI/Services/
apps/mobile/LumeraAI/Models/
apps/mobile/LumeraAI/StateMachine/
```

**watchOS Target — add all files from:**
```
apps/watch/LumeraAIWatch/App/
apps/watch/LumeraAIWatch/Views/
apps/watch/LumeraAIWatch/Services/
```

### 4. Configure Capabilities (iOS Target)
- HealthKit (read heart rate)
- Location (When In Use)
- Background Modes: Location updates
- WatchKit App

### 5. Configure Capabilities (watchOS Target)
- WatchKit Extension

### 6. Info.plist Keys (iOS)
```xml
<key>NSHealthShareUsageDescription</key>
<string>LumeraAI reads heart rate to provide training guidance.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>LumeraAI uses your location to guide your run.</string>
<key>NSCameraUsageDescription</key>
<string>LumeraAI uses the camera to detect hazards on your route.</string>
```

### 7. Set API Base URL
In `APIClient.swift`, update `baseURLString` to your backend URL.

### 8. Build & Run
- For iPhone simulator: select any iPhone 15+ simulator
- For Apple Watch: pair a Watch simulator with the iPhone simulator
- For device: requires valid provisioning profiles
