# Font Setup Guide for Daily Dose

## Required Fonts

Daily Dose uses a premium typography system with two custom font families:

### 1. Instrument Sans
- **InstrumentSans-Regular** (weight 400) - Body text and journaling
- **InstrumentSans-Medium** (weight 500) - UI elements and buttons  
- **InstrumentSans-SemiBold** (weight 600) - Headers and displays

### 2. Crimson Pro
- **CrimsonPro-Italic** - Quotes and affirmations (serif companion)

## How to Add Fonts to Xcode Project

### Step 1: Download Font Files
1. **Instrument Sans**: Download from [Google Fonts](https://fonts.google.com/specimen/Instrument+Sans)
   - Download the complete family
   - Extract: `InstrumentSans-Regular.ttf`, `InstrumentSans-Medium.ttf`, `InstrumentSans-SemiBold.ttf`

2. **Crimson Pro**: Download from [Google Fonts](https://fonts.google.com/specimen/Crimson+Pro)
   - Download the complete family
   - Extract: `CrimsonPro-Italic.ttf`

### Step 2: Add to Xcode Project
1. Drag and drop the font files into your Xcode project
2. Make sure "Add to target" is checked for your main app target
3. Choose "Copy items if needed"

### Step 3: Update Info.plist
Add the following to your `Info.plist` file:

```xml
<key>UIAppFonts</key>
<array>
    <string>InstrumentSans-Regular.ttf</string>
    <string>InstrumentSans-Medium.ttf</string>
    <string>InstrumentSans-SemiBold.ttf</string>
    <string>CrimsonPro-Italic.ttf</string>
</array>
```

### Step 4: Verify Font Names
To ensure correct font names, add this temporary code to test:

```swift
// Add to AppDelegate or ContentView to verify font names
for family in UIFont.familyNames.sorted() {
    print("Family: \(family)")
    for name in UIFont.fontNames(forFamilyName: family) {
        print("  Font: \(name)")
    }
}
```

## Font Usage in Code

The typography system automatically handles font loading with fallbacks:

```swift
// Headers & Display
Text("Morning Ritual")
    .font(PremiumDesign.Typography.headlineLargeSafe)

// Body Text  
Text("Journal content")
    .font(PremiumDesign.Typography.bodyLargeSafe)

// Quotes & Affirmations
Text("Today's inspiring quote")
    .font(PremiumDesign.Typography.quoteTextSafe)

// Buttons
Text("Continue")
    .font(PremiumDesign.Typography.buttonLargeSafe)
```

## Fallback System

The design system includes automatic fallbacks:
- If custom fonts aren't available, it gracefully falls back to system fonts
- Maintains the same visual hierarchy and sizing
- Ensures the app works even without custom fonts installed

## Typography Scale

| Usage | Font | Size | Weight |
|-------|------|------|--------|
| Display Large | Instrument Sans | 34pt | SemiBold |
| Display Medium | Instrument Sans | 28pt | SemiBold |  
| Display Small | Instrument Sans | 22pt | Medium |
| Headline Large | Instrument Sans | 20pt | SemiBold |
| Body Large | Instrument Sans | 17pt | Regular |
| Quote Text | Crimson Pro | 18pt | Italic |
| Button Large | Instrument Sans | 17pt | Medium |
| Journal Text | Instrument Sans | 16pt | Regular |

## Design Rationale

### Instrument Sans
- Modern, clean geometric sans-serif
- Excellent readability at all sizes
- Professional yet approachable
- Perfect for wellness/productivity apps

### Crimson Pro  
- Elegant serif for quotes and affirmations
- Adds warmth and literary feeling
- Creates hierarchy and emphasis
- Complements Instrument Sans beautifully

This typography system creates a premium, distinctive brand identity that justifies the $4.99/month pricing while maintaining excellent readability for extended journaling sessions.
