"""
Manual Premium Unlock Script for Bharatheeyam App
Usage:
  python unlock_user.py <email> [--days N] [--revoke]
  
Examples:
  python unlock_user.py user@gmail.com              # Lifetime premium
  python unlock_user.py user@gmail.com --days 365   # 1 year premium  
  python unlock_user.py user@gmail.com --revoke     # Remove premium

Requirements:
  pip install firebase-admin
  Place your Firebase service account JSON key in the same directory as 'service_account.json'
"""

import sys
import argparse
from datetime import datetime, timedelta

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("Install firebase-admin: pip install firebase-admin")
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Unlock premium for a user')
    parser.add_argument('email', help='User email (lowercase)')
    parser.add_argument('--days', type=int, help='Number of days (omit for lifetime)')
    parser.add_argument('--revoke', action='store_true', help='Revoke premium')
    parser.add_argument('--note', default='', help='Payment note')
    args = parser.parse_args()

    # Initialize Firebase
    cred = credentials.Certificate('service_account.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    email = args.email.lower().strip()
    doc_ref = db.collection('device_bindings').document(email)
    doc = doc_ref.get()

    if not doc.exists:
        print(f"❌ No device binding found for {email}")
        print("   User must sign in to the app first.")
        return

    if args.revoke:
        doc_ref.update({
            'manualPremium': False,
            'manualPremiumExpiry': firestore.DELETE_FIELD,
            'manualPremiumNote': firestore.DELETE_FIELD,
        })
        print(f"🔒 Premium REVOKED for {email}")
        return

    update = {
        'manualPremium': True,
        'manualPremiumNote': args.note or f'Unlocked on {datetime.now().strftime("%Y-%m-%d")}',
    }

    if args.days:
        expiry = datetime.utcnow() + timedelta(days=args.days)
        update['manualPremiumExpiry'] = expiry
        print(f"✅ Premium granted to {email} for {args.days} days (expires {expiry.strftime('%Y-%m-%d')})")
    else:
        update['manualPremiumExpiry'] = firestore.DELETE_FIELD
        print(f"✅ LIFETIME premium granted to {email}")

    doc_ref.update(update)
    print(f"   User should restart the app to activate.")

if __name__ == '__main__':
    main()
