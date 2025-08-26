# Daily Ritual iOS Setup Guide

## Quick Setup for Physical Device Testing

### 1. Start the Backend Server

First, let's get your backend running:

```bash
# Navigate to backend directory
cd /Users/vinhnguyen/projects/DailyRitual/DailyRitualBackend

# Install dependencies (if not already done)
npm install

# Start the development server
npm run dev
```

The backend will be available at `http://localhost:3000`

### 2. Configure iOS App for Device Testing

#### Option A: Using Xcode (Recommended)

1. **Open the project in Xcode:**
   ```bash
   open "/Users/vinhnguyen/projects/DailyRitual/DailyRitualSwiftiOS/Your Daily Dose.xcodeproj"
   ```

2. **Connect your iPhone/iPad via USB**

3. **Select your device:**
   - In Xcode, click on the device selector (top left, next to the play button)
   - Choose your connected device instead of "Simulator"

4. **Configure signing:**
   - Select the project name in the navigator (top item)
   - Go to "Signing & Capabilities" tab
   - Make sure "Automatically manage signing" is checked
   - Select your Apple ID team

5. **Trust your developer certificate on device:**
   - On your device: Settings > General > VPN & Device Management
   - Find your Apple ID and tap "Trust"

6. **Run the app:**
   - Press Cmd+R or click the play button
   - The app should build and install on your device

#### Option B: Using Command Line

```bash
# Navigate to iOS project
cd "/Users/vinhnguyen/projects/DailyRitual/DailyRitualSwiftiOS"

# Build for device (replace with your device ID)
xcodebuild -project "Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination "id=YOUR_DEVICE_ID" build

# Install on device
xcrun devicectl device install app --device YOUR_DEVICE_ID "build/path/to/Your Daily Dose.app"
```

### 3. Testing the Morning Reflection

Once the app is running on your device:

1. **Open the app** - you should see the main dashboard
2. **Tap "Morning Ritual"** - this will open the morning reflection flow
3. **Fill out each step:**
   - **Goals**: Write 3 goals for today
   - **Gratitude**: Write 3 things you're grateful for  
   - **Affirmation**: Tap "Generate Affirmation" to get an AI-powered affirmation
   - **Other Thoughts**: Any additional thoughts
4. **Complete the ritual** - tap the checkmark on the final step
5. **Check the backend logs** - you should see API calls being made

### 4. Network Configuration for Device Testing

Since your device needs to connect to your local backend:

#### Find your Mac's IP address:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

#### Update the iOS app's backend URL:
In `SupabaseManager.swift`, change:
```swift
private let baseURL = "http://localhost:3000/api/v1"
```
to:
```swift
private let baseURL = "http://YOUR_MAC_IP:3000/api/v1"  // e.g., "http://192.168.1.100:3000/api/v1"
```

### 5. Troubleshooting

#### Common Issues:

**App won't install on device:**
- Make sure you have a valid Apple Developer account
- Check that your device is trusted in Xcode
- Verify the bundle identifier is unique

**Network connection fails:**
- Ensure your Mac and iPhone are on the same WiFi network
- Check that the backend server is running on `http://localhost:3000`
- Try accessing `http://YOUR_MAC_IP:3000/api/v1/health` from your device's browser

**Build errors:**
- Clean build folder: Product > Clean Build Folder in Xcode
- Restart Xcode
- Check that all files are properly included in the project

#### Debug Network Requests:

Add this to see network calls in the iOS app:
```swift
// In SupabaseManager.swift, add to network calls:
print("Making request to: \(url)")
print("Response: \(String(data: data, encoding: .utf8) ?? "No data")")
```

### 6. Expected Behavior

When everything is working correctly:

1. **Morning ritual completion** should:
   - Send a POST request to `/api/v1/daily-entries/YYYY-MM-DD/morning`
   - Receive back an AI-generated affirmation
   - Show a completion screen
   - Update the local entry with completion timestamp

2. **Backend logs** should show:
   ```
   POST /api/v1/daily-entries/2024-01-01/morning
   Calling Claude API for affirmation generation...
   Morning ritual completed successfully
   ```

3. **App state** should:
   - Mark morning as completed
   - Show the affirmation in the UI
   - Update any progress indicators

### 7. Next Steps

Once the basic morning reflection is working:

1. **Test on different days** - create entries for multiple dates
2. **Add evening reflection** - complete the full daily cycle
3. **Test AI insights** - generate weekly insights
4. **Add workout reflections** - test the post-training flow

### 8. Production Deployment

When ready to deploy:

1. **Deploy backend** to a cloud service (Railway, Render, Fly.io)
2. **Update iOS app** with production backend URL
3. **Set up proper authentication** with Supabase Auth
4. **Configure push notifications** for daily reminders
5. **Submit to App Store** for distribution

---

**Need help?** Check the console logs in both Xcode and your terminal running the backend for detailed error messages.
