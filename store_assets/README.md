# Kalm Corner: store assets

Everything needed to fill in the Google Play and App Store listings. All images are opaque RGB PNGs (no transparency), sized exactly to each store's spec. The only exception is the Play icon, which is 32-bit as Play requires.

## 01_app_icon
| File | Use |
|---|---|
| `app_store_icon_1024.png` | App Store Connect, 1024×1024, no alpha |
| `play_store_icon_512.png` | Play Console › Store listing › App icon, 512×512 |
| `icon_rounded_preview_1024.png` | Website / socials / press (rounded corners) |
| `icon_16 … icon_256.png` | Favicons and misc. |
| `ios_appiconset/` | The full iOS icon set (same as `ios/Runner/Assets.xcassets/AppIcon.appiconset`) |
| `android_adaptive/` | Adaptive icon layers: background, foreground, monochrome (Android 13 themed) |

## 02_screenshots_plain: raw in-app screens
## 03_screenshots_designed: marketing screenshots with headline and device frame (recommended)

| Folder | Store slot | Size |
|---|---|---|
| `ios/iphone_6.9in_1320x2868` | App Store › iPhone 6.9" Display (required) | 1320×2868 |
| `ios/iphone_6.5in_1242x2688` | App Store › iPhone 6.5" Display (optional fallback) | 1242×2688 |
| `ios/ipad_13in_2064x2752` | App Store › iPad 13" Display (required if the app runs on iPad) | 2064×2752 |
| `android/phone_1080x1920` | Play › Phone screenshots | 1080×1920 (9:16) |
| `android/tablet_7in_1200x1920` | Play › 7-inch tablet screenshots | 1200×1920 |
| `android/tablet_10in_1600x2560` | Play › 10-inch tablet screenshots | 1600×2560 |

Each folder holds 7 shots in upload order:
1. Home: "Your cozy corner to unwind"
2. Still Waters: "Pour soft colours into calm"
3. Garden Streams: "Help the spring reach every flower"
4. Clear Window: "Wipe the glass, find the view"
5. Level map: "156 peaceful levels to explore"
6. Welcome: "No timers. No pressure."
7. Settings: "Made to feel just right"

Limits: App Store takes up to 10 per device size, Play up to 8. All 7 fit both.

## 04_feature_graphic
`play_feature_graphic_1024x500.png` / `.jpg` goes in Play Console › Store listing › Feature graphic (required).

## 05_store_listing_text.md
Title, short and long description, subtitle, keywords, category and rating notes for both stores, all within character limits.

## How these were made
The screens were captured from the Flutter web build (`flutter build web`) in headless Chrome at each device's logical size and pixel ratio, with some saved progress so the app looks lived in. To regenerate them after UI changes, rebuild the web app and re-run the capture.
