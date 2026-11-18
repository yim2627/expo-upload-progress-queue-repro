# Network inspector sends upload progress off the session's delegate queue (iOS)

In a Debug development build with the network inspector on, `ExpoRequestInterceptorProtocol` sends `urlSession(_:task:didSendBodyData:...)` to the original session's delegate on the interceptor's own queue (`com.apple.NSURLSession-delegate`). `URLSession` calls delegate methods on the session's `delegateQueue`, and delegates that check this crash. Alamofire checks it in `Session.request(for:)`, so the first Alamofire request with a body crashes the app.

This app uses no third-party library. `modules/upload-queue-probe` is a local Expo module. It owns its delegate queue the way Alamofire does and makes the same `dispatchPrecondition` check.

## Steps

1. `npm install`
2. `npx expo run:ios` (Debug, iOS Simulator). The network inspector is on by default.
3. The app sends one `POST` with a 7-byte body to the dev server when it opens.

## Result

The app crashes with `EXC_BREAKPOINT` on queue `com.apple.NSURLSession-delegate`:

```
_dispatch_assert_queue_fail
dispatch_assert_queue
_dispatchPreconditionTest(_:)
UploadQueueProbeClient.urlSession(_:task:didSendBodyData:...)   UploadQueueProbeModule.swift:54
...
ExpoRequestInterceptorProtocol.urlSession(_:task:didSendBodyData:...)   ExpoRequestInterceptorProtocol.swift:202
```

## Expected

No crash. The screen shows:

```
{
  "uploadProgressCallbacks": 1,
  "statusCode": 200,
  "error": ""
}
```

## Testing a fix

SDK 58 links a precompiled `ExpoModulesCore` by default, so an edit in `node_modules/expo-modules-core` has no effect. Build Expo modules from source to test one:

```sh
cd ios && EXPO_USE_PRECOMPILED_MODULES=0 pod install && cd ..
EXPO_USE_PRECOMPILED_MODULES=0 npx expo run:ios
```

## Environment

- expo 58.0.26, expo-modules-core 58.1.0, expo-dev-client 58.0.21, react-native 0.88.1
- Xcode 27.2 (27B52), iPhone 18 Pro simulator, iOS 27.2
- npm
