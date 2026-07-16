# Router Offsets — iOS app

Native SwiftUI port of the web calculator. Regenerate the Xcode project after
any file add/remove:

```bash
brew install xcodegen        # once
xcodegen generate            # creates RouterOffsets.xcodeproj
```

## Run tests (no simulator needed)

```bash
swift test
```

## Run on your iPhone (free Apple ID)

1. `open RouterOffsets.xcodeproj`
2. Select the **RouterOffsets** target → **Signing & Capabilities**.
3. Set **Team** to your personal Apple ID (add it in Xcode ▸ Settings ▸ Accounts).
   Xcode auto-manages the signing certificate.
4. If the bundle ID `com.tarik.routeroffsets` is taken, change it to something unique.
5. Plug in the iPhone, pick it as the run destination, press **⌘R**.
6. First launch: on the phone, **Settings ▸ General ▸ VPN & Device Management** →
   trust your developer certificate, then reopen the app.

> Free Apple ID builds expire after 7 days; re-run from Xcode to refresh.
