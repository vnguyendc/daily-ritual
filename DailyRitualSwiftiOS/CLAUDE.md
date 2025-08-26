# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS SwiftUI application called "Your Daily Dose" built with Swift 5.0 and targeting iOS 18.5+. The app uses SwiftData for data persistence and follows the standard iOS app architecture.

## Development Commands

### Building and Running
- Build the project: Open `Your Daily Dose.xcodeproj` in Xcode and use Cmd+B to build
- Run the app: Use Cmd+R in Xcode to build and run on simulator or device
- Run on device: Connect iOS device and select it as target before running

### Testing
- Run unit tests: Use Cmd+U in Xcode or select "Your Daily DoseTests" scheme
- Run UI tests: Select "Your Daily DoseUITests" scheme and run
- The project uses Swift Testing framework (not XCTest) as indicated by `import Testing`

### Project Configuration
- Bundle ID: `revitalized.Your-Daily-Dose`
- Deployment target: iOS 18.5+
- Swift version: 5.0
- Uses automatic code signing

## Architecture

### App Structure
- **App Entry Point**: `Your_Daily_DoseApp.swift` - Main app file with SwiftData model container setup
- **Main View**: `ContentView.swift` - Primary interface using NavigationSplitView with master-detail layout
- **Data Model**: `Item.swift` - SwiftData model with timestamp property
- **Data Persistence**: Uses SwiftData with shared ModelContainer configured for the Item model

### Key Patterns
- **SwiftUI + SwiftData**: Modern iOS development stack
- **MVVM Pattern**: Implicit through SwiftUI's view model binding
- **Navigation**: Uses NavigationSplitView for adaptive layout (works on both iPhone and iPad)
- **Data Management**: SwiftData handles persistence automatically with @Query and modelContext

### File Organization
```
Your Daily Dose/
├── Your_Daily_DoseApp.swift     # App entry point and data setup
├── ContentView.swift            # Main UI view
├── Item.swift                   # Data model
├── Assets.xcassets/             # App assets and icons
├── Info.plist                   # App configuration (supports remote notifications)
└── Your_Daily_Dose.entitlements # App entitlements
```

### Testing Structure
- Unit tests in `Your Daily DoseTests/` using Swift Testing framework
- UI tests in `Your Daily DoseUITests/` for interface testing
- Both test targets are configured to test the main app target

## Development Notes

- The app implements a complete 7-step daily ritual system (4 morning + 3 evening steps)
- Uses mock SupabaseManager for development - ready for real backend integration
- AI integration hooks are in place for affirmation and quote generation
- Freemium model with premium feature gates implemented
- Complete user flow from onboarding through daily practice completion
- Remote notification capability is enabled in Info.plist

## Recent Build Fixes Applied

- Fixed async function parameter issues (changed `inout` to return-based pattern)
- Fixed SwiftUI preview issues with `@Previewable @State` syntax
- Removed old SwiftData dependencies and Item model references
- Updated app entry point to use new authentication and tab-based structure

## Phase 1 Architecture Improvements Applied

Following John Ousterhout's "A Philosophy of Software Design" principles:

### Deep Modules Implementation
- **Enhanced Models**: Added validation and completion logic directly to `DailyEntry`, `MorningStep`, and `EveningStep` models
- **Simple Interfaces**: Complex validation logic is hidden behind simple method calls like `entry.canCompleteMorning`
- **Centralized Logic**: Business rules are encapsulated within the data models themselves

### Information Hiding
- **Validation Logic**: Step validation details are hidden within enum methods (`step.isValid(in: entry)`)
- **Completion Progress**: Complex progress calculation is encapsulated in `entry.completionProgress`
- **Error Messages**: Validation messages are provided by the models themselves

### Consistency
- **Uniform Patterns**: All validation follows the same pattern across morning and evening steps
- **Consistent Error Handling**: Standardized error messaging and validation feedback
- **Naming Conventions**: Clear, descriptive method names that express intent

### Code Organization Improvements
- **Extracted Business Logic**: Removed complex validation logic from Views
- **Simplified ViewModels**: ViewModels now focus on UI state management rather than business rules
- **Enhanced Data Models**: Models now contain their own validation and completion logic

### Benefits Achieved
- **Reduced Complexity**: Views are simpler and focus purely on presentation
- **Better Testability**: Business logic is now easily testable within models
- **Improved Maintainability**: Changes to validation rules only require model updates
- **Enhanced Reusability**: Validation logic can be used across different UI contexts