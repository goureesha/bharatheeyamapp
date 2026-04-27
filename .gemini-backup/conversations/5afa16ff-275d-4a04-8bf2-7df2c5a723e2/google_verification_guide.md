# Why Google Sign-In is Failing on the Web App

> [!WARNING]
> The issue you are experiencing is `FedCM get() rejects with NetworkError: Error retrieving a token` in the browser console. This happens because Google's security blocks login attempts from unregistered websites.

When you test Flutter Web on your own computer (localhost), Google allows it. However, the exact moment we deployed the app publicly to **GitHub Pages** (`https://goureesha.github.io`), Google began rejecting the logins because that public web address is not authorized in your Google Cloud Console.

I have not broken the code, but you must register the new website URL to allow Google Sign-In to work on the web!

### How to Fix Web Login (Takes 1 minute):

1. Go to your [Google Cloud Console Credentials Page](https://console.cloud.google.com/apis/credentials).
2. Look for your **OAuth 2.0 Client IDs** list.
3. Click on your **Web client** (the one that ends with `...gia4puva.apps.googleusercontent.com`).
4. Scroll down to the **Authorized JavaScript origins** section.
5. Click **Add URI** and paste exactly this:
   `https://goureesha.github.io`
6. Click **Save** at the bottom.

**Note**: It can take anywhere from 5 minutes to a few hours for Google's servers to update the new authorized domain. Once it propagates, the Google Sign-In button will instantly start working on the web app!
