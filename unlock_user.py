"""
Manual Premium & Block/Unblock Script for Bharatheeyam App
Usage:
  python unlock_user.py <email> [--days N] [--revoke]
  python unlock_user.py <email> --block [--reason "..."]
  python unlock_user.py <email> --unblock
  
Examples:
  python unlock_user.py user@gmail.com              # Lifetime premium
  python unlock_user.py user@gmail.com --days 365   # 1 year premium  
  python unlock_user.py user@gmail.com --revoke     # Remove premium
  python unlock_user.py user@gmail.com --block --reason "Payment pending"
  python unlock_user.py user@gmail.com --unblock    # Remove block

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
    parser = argparse.ArgumentParser(description='Manage user premium & block status')
    parser.add_argument('email', help='User email (lowercase)')
    parser.add_argument('--days', type=int, help='Number of days for premium (omit for lifetime)')
    parser.add_argument('--revoke', action='store_true', help='Revoke premium')
    parser.add_argument('--block', action='store_true', help='Block user')
    parser.add_argument('--unblock', action='store_true', help='Unblock user')
    parser.add_argument('--reason', default='', help='Block reason (shown to user)')
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

    # ── Block user ──
    if args.block:
        reason = args.reason or f'Blocked on {datetime.now().strftime("%Y-%m-%d")}'
        doc_ref.update({
            'blocked': True,
            'blockedReason': reason,
        })
        print(f"🚫 User BLOCKED: {email}")
        print(f"   Reason: {reason}")
        print(f"   User will see the blocked screen on next app open.")
        return

    # ── Unblock user ──
    if args.unblock:
        doc_ref.update({
            'blocked': False,
            'blockedReason': firestore.DELETE_FIELD,
        })
        print(f"✅ User UNBLOCKED: {email}")
        print(f"   User can use the app normally on next retry/open.")
        return

    # ── Revoke premium ──
    if args.revoke:
        doc_ref.update({
            'manualPremium': False,
            'manualPremiumExpiry': firestore.DELETE_FIELD,
            'manualPremiumNote': firestore.DELETE_FIELD,
        })
        print(f"🔒 Premium REVOKED for {email}")
        return

    # ── Grant premium ──
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
