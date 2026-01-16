# Simple iCloud Sync Setup

All custom migration code has been removed. The app now uses the **simplest possible iCloud sync setup**.

## What Changed

### 1. Removed
- ❌ Custom app-specific iCloud container (`iCloud.com.dahlsjoo.manuscript`)
- ❌ All migration code
- ❌ Custom iCloud folder management
- ❌ Migration sheets and prompts

### 2. Simplified
- ✅ Uses generic iCloud Drive (visible to all apps)
- ✅ DocumentGroup handles all file operations automatically
- ✅ No custom container configuration

## How It Works Now

### Entitlements (Manuscript.entitlements)
```xml
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>
```

That's it! No container identifiers, just the CloudDocuments service.

### What This Means

**On macOS:**
- When you create a new document, save it anywhere you want in iCloud Drive
- When you import a Scrivener project, choose where to save it
- Files appear in Finder under iCloud Drive

**On iOS:**
- Files appear in the Files app under iCloud Drive
- The document browser shows all your iCloud Drive locations
- Save files wherever you want in iCloud Drive

**Sync:**
- Both platforms use the SAME iCloud Drive
- Save a file in the same location on both platforms = automatic sync
- No app-specific containers, no hidden folders

## Testing Instructions

### Step 1: Clean Start
1. Delete the app from both iOS and macOS
2. Delete any old files from previous tests
3. Rebuild and install fresh

### Step 2: On macOS
1. Launch the app
2. Create a new document
3. **Save it to: iCloud Drive → Documents** (or any folder you create)
4. Name it something recognizable like "Test Sync"
5. Add some content
6. Save and close

### Step 3: On iOS
1. Launch the app
2. Tap Browse
3. Navigate to **iCloud Drive → Documents**
4. You should see "Test Sync.manuscript"
5. Open it - content should be there!
6. Make an edit
7. Save

### Step 4: Back to macOS
1. Open "Test Sync" document again
2. You should see the edit from iOS

## If Sync Doesn't Work

### Check These:
1. **Same Apple ID** - Both devices signed into the same iCloud account
2. **iCloud Drive enabled** - Settings → [Your Name] → iCloud → iCloud Drive ON
3. **Same location** - Files saved to the exact same folder path on both platforms
4. **Network connection** - Both devices online
5. **Wait** - iCloud can take a few seconds to sync

### Debug Output
When you launch the app, check the console for:
```
=== iCloud Debug Info ===
Platform: iOS (or macOS)
Bundle ID: com.dahlsjoo.manuscript
✅ iCloud container accessible at:
   [path to iCloud Drive]
```

If you see `❌ Cannot access iCloud container`, check:
- iCloud Drive is enabled in System Settings
- App has correct code signing
- Running on a real device (not simulator for iOS)

## Recommended Folder Structure

To keep things organized, create a "Manuscript" folder in iCloud Drive:

```
iCloud Drive/
  └── Documents/
      └── Manuscript/
          ├── Novel Project.manuscript
          ├── Short Story.manuscript
          └── Research Notes.manuscript
```

Save all your `.manuscript` files there, and they'll sync perfectly between macOS and iOS.

## Clean and Simple

No custom containers. No migration. No hidden folders. Just standard iCloud Drive sync that works like any other document-based app (Pages, Numbers, etc.).

Save files to the same folder on both platforms, and they sync automatically.
