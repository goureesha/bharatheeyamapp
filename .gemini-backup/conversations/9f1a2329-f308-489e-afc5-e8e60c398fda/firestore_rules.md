# Firestore Security Rules — Apply in Firebase Console

## Steps to Apply

1. Go to **[Firebase Console](https://console.firebase.google.com/project/bharatheeyam-app/firestore/rules)**
2. Click **Rules** tab
3. Replace the existing rules with the rules below
4. Click **Publish**

## Recommended Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Device bindings — any authenticated user can read/write their own binding
    match /device_bindings/{email} {
      allow read, write: if request.auth != null 
                         && request.auth.token.email == email;
    }

    // User data backup — authenticated user can read/write their own backup
    match /user_data/{email} {
      allow read, write: if request.auth != null 
                         && request.auth.token.email == email;
    }

    // User data chunks (for large backups)
    match /user_data/{email}/chunks/{chunkId} {
      allow read, write: if request.auth != null 
                         && request.auth.token.email == email;
    }

    // Appointments — authenticated user can read/write their own appointments
    match /appointments/{email} {
      allow read, write: if request.auth != null 
                         && request.auth.token.email == email;
    }
    match /appointments/{email}/requests/{requestId} {
      allow read, write: if request.auth != null 
                         && request.auth.token.email == email;
    }

    // Testers collection — any authenticated user can read their own doc
    match /testers/{email} {
      allow read: if request.auth != null 
                  && request.auth.token.email == email;
      allow write: if false; // Admin-only via Firebase Console
    }

    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

> [!IMPORTANT]
> If you currently have `allow read, write: if true;` (test mode), these new rules will be **more secure** — each user can only access their own data. If you already have strict rules like `allow read, write: if false;`, that's why the app is getting **permission-denied**. Apply the rules above to fix it.

> [!WARNING]
> **SHA-1 fingerprint**: Firebase Auth with Google Sign-In on Android requires your app's SHA-1 fingerprint to be registered in Firebase Console → Project Settings → Your Apps → Android app → Add fingerprint. Your CI/CD signing key's SHA-1 must also be added.
