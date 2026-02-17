# Minerva Health – Login & Sign-in Setup

## What’s included

- **Login screen** – Shown when the user isn’t signed in; after sign-in, the main app (tabs) is shown.
- **Sign in with Apple** – Works as soon as the capability is enabled (already added in the project).
- **Sign in with Google** – Button is on the login screen; to make it work you need to add the SDK and configure Google Cloud.

## Backend

- **Apple:** `POST /auth/apple` with body `{ "appleId": "...", "email?", "name?" }` → returns `{ "token", "user" }`.
- **Google:** `POST /auth/google` with body `{ "googleId": "...", "email?", "name?" }` → returns `{ "token", "user" }`.

Set `AuthManager.apiBaseURL` (in `AuthManager.swift`) or the `MINERVA_API_URL` environment variable to your backend URL (e.g. your Railway URL).

## Sign in with Apple

1. In Xcode, the **Sign in with Apple** capability is already in **Minerva Health.entitlements**.
2. In App Store Connect / Developer account, ensure your App ID has “Sign in with Apple” enabled.
3. No extra config is required; the login screen uses the system Apple ID flow.

## Sign in with Google (optional)

1. **Add the Google Sign-In package**
   - In Xcode: **File → Add Package Dependencies…**
   - URL: `https://github.com/google/GoogleSignIn-iOS`
   - Add the **GoogleSignIn** product to the Minerva Health target.

2. **Create OAuth credentials**
   - Go to [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials.
   - Create an **OAuth 2.0 Client ID** for **iOS** and use your app’s bundle ID: `Brennon-Doman.Minerva-Health`.
   - Note the **iOS client ID** (e.g. `xxxx.apps.googleusercontent.com`).

3. **Configure the app**
   - In **Info.plist**, add a URL scheme so Google can open your app:
     - Key: **URL types** (or `CFBundleURLTypes`)
     - Add an item with **URL Schemes** = the reversed client ID (e.g. `com.googleusercontent.apps.xxxx`).
   - When you add the GoogleSignIn package, configure `GIDSignIn` at launch with this client ID (e.g. in `WomensHealthApp.swift` or in a helper that runs once):
     ```swift
     GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com")
     ```
   - Update `GoogleSignInHelper` in **LoginView.swift** to call `GIDSignIn.sharedInstance.signIn(withPresenting:)`, get the user’s `userID` (sub) and optional `email`/`name`, then call `auth.loginWithGoogle(googleId:email:name:)`.

4. **Backend**
   - The backend already has `POST /auth/google` and stores users by `googleId`; no backend change needed for basic Google sign-in.

## Account and sign out

- In the app, **Settings** shows an **Account** section with the current user’s name/email (if provided) and a **Sign out** button.
- Signing out clears the stored token and returns the user to the login screen.
