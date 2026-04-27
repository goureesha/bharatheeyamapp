# Firebase Setup Guide (Free Tier)

**Yes, Firebase is 100% FREE for our needs.** 
We will use the **"Spark Plan"** (the free tier). It allows for 50,000 document reads, 20,000 document writes, and unlimited Push Notifications EVERY SINGLE DAY. For a single astrologer accepting appointments, you will never even come close to these limits!

Here is the exact step-by-step guide to setting it up for your app:

## Part 1: Create the Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Sign in with your Google Account.
3. Click **"Add project"**.
4. Enter a name (e.g., `Bharatheeyam App`).
5. Click **Continue**. You can disable Google Analytics to skip the extra stuff, then click **Create project**.

## Part 2: Register the Android App
1. On your new project's dashboard, you will see icons for iOS, Android, and Web. Click the **Android icon** (an outline of an Android robot).
2. **Android package name:** Type `com.bharatheeyam.app`
3. **App nickname:** Type `Bharatheeyam Android`
4. Leave SHA-1 blank for now. Click **Register app**.
5. Click the blue button **Download `google-services.json`**.
   *(Save this file on your computer. You will need to drop it in the folder `android/app/` in your code later, or you can send it to me to put there).*
6. Click **Next** until you finish the Android setup.

## Part 3: Set up the Database (Firestore)
1. In the left-hand menu of the Firebase Console, find the **Build** drop-down and click **Firestore Database**.
2. Click the **Create database** button.
3. Choose the geographical location closest to you (e.g., `asia-south1 (Mumbai)`) and click **Next**.
4. Choose **Start in test mode** and click **Create**.
5. *Important:* "Test mode" allows anyone with your config to read/write for 30 days. Let me know when you reach this step, and I will write proper security rules to ensure ONLY your website can create appointments and ONLY your app can read your appointments.

## Part 4: Register the Website (for the booking page)
1. Go back to the Project Overview (click the home icon top left).
2. Click the **+ Add app** button and choose the **Web icon** (`</>`).
3. **App nickname:** Type `Bharatheeyam Web Booking` -> Click **Register app**.
4. Firebase will show you a block of code starting with `const firebaseConfig = { ... }`.
   **Copy that entire piece of code.** It will look something like this:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSyc...",
     authDomain: "bharatheeyam-xxx.firebaseapp.com",
     projectId: "bharatheeyam-xxx",
     storageBucket: "bharatheeyam-xxx.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abcdef123"
   };
   ```

## Final Step: Hand it over to me!
Once you have done this:
1. Please paste the **Web configuration code block** here in the chat.
2. Please place that downloaded `google-services.json` file exactly inside the `android/app/` folder of this repository.

I will take it from there and write the code that connects your Booking Page to your Android app!
