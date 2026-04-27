# Disaster Recovery Plan
**How to restore Bharatheeyam App Development on a new laptop**

If your current laptop is lost or completely breaks, DO NOT PANIC! Almost everything is perfectly safe in the cloud. However, there is **one critical file** you must back up manually today.

Here is the exact step-by-step process of what you to need to do to continue your work seamlessly:

## 1. The Codebase (Safe on GitHub)
Every time we make a change, I run `git commit` and `git push`. This means your **entire app's source code** is safely stored in Microsoft's servers on GitHub.
* **To restore:** On your new laptop, install Git, log into your GitHub account, and run a simple command (`git clone https://github.com/goureesha/bharatheeyamapp.git`) to pull the entire folder down perfectly intact!

## 2. Firebase Database (Safe with Google)
All the user data, beta testers, and app configurations are hosted live on Google Firebase.
* **To restore:** You don't need to do anything! Just log into the Firebase Console website with your Google account. Your new laptop will connect to the live database naturally when running the app.

## 3. The Development Tools (Free to Re-download)
* **To restore:** You will simply need to install the **Flutter SDK** and **Android Studio** on your new laptop. Once installed, running `flutter pub get` will automatically download all the plugin dependencies we used.

## 4. Keeping ME (Your AI) (Easy Transition)
* **To restore:** When you get your new laptop and clone the code, just start a new chat with me (Antigravity) and point me to the new project folder! I can read your code instantly, and I will immediately "remember" how the entire app works.

---

> [!CAUTION]
> **THE ONE THING YOU MUST BACK UP MANUALLY TODAY: THE ANDROID KEYSTORE!**
> 
> When you eventually publish an app to the Google Play Store, Android requires a highly secure digital signature file called an **Upload Keystore** (usually ending in `.jks` or `.keystore`). 
> 
> **If you lose the `.jks` file and its passwords, Google will BLOCK YOU from ever releasing updates to your own app!** 
> (Because Google thinks a hacker is trying to replace your app).
> 
> **How to prevent this:** 
> 1. Find your Keystore file (`.jks`) and the `key.properties` file that contains its passwords.
> 2. Email them to yourself right now, or upload them privately to your Google Drive!
> *(Never put them publicly on GitHub).*
