import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common.dart';
import '../services/google_auth_service.dart';
import '../services/device_binding_service.dart';
import '../services/app_access_service.dart';
import '../main.dart';

enum SupportLockType { general, muhurta, student }

class SupportScreen extends StatefulWidget {
  final SupportLockType lockType;
  const SupportScreen({super.key, this.lockType = SupportLockType.general});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const _supportPhone = '+918762629847';
  static const _supportEmail = 'goureesh3690@gmail.com';
  bool _signingIn = false;

  static String _ls(Map<String,String> m) {
    final lang = AppLocale.current;
    return m[lang] ?? m['en'] ?? m.values.first;
  }

  Future<void> _handleGmailSignIn() async {
    setState(() => _signingIn = true);
    try {
      final ok = await GoogleAuthService.signIn();
      if (ok && mounted) {
        // After sign-in, register device binding + check admin access
        await DeviceBindingService.checkBinding();
        await AppAccessService.checkAdminAccess();
        await AppAccessService.syncTrialWithFirestore();
        deviceBindingNotifier.value = await DeviceBindingService.checkBinding();

        if (AppAccessService.hasAccess && mounted) {
          // User has access now — refresh the whole app
          deviceBindingNotifier.value = true;
          // Force app rebuild by notifying
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ ${GoogleAuthService.userEmail} — signed in!'), backgroundColor: Colors.green),
          );
          // Trigger rebuild
          (context as Element).markNeedsBuild();
        } else if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signed in as ${GoogleAuthService.userEmail}'), backgroundColor: kPurple2),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _signingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = GoogleAuthService.isSignedIn;
    final email = GoogleAuthService.userEmail ?? 'Not signed in';

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ResponsiveCenter(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset('assets/images/logo.png', width: 90, height: 90),
                const SizedBox(height: 16),
                Text(AppLocale.l('appName'), style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: kOrange,
                  letterSpacing: 1.5,
                )),
                const SizedBox(height: 4),
                Text(AppLocale.l('vedicAstrology'), style: TextStyle(
                  fontSize: 14, color: kMuted, letterSpacing: 0.5,
                )),
                const SizedBox(height: 32),

                // Access info
                _buildLockInfo(widget.lockType),
                const SizedBox(height: 16),

                // ── Contact Support (shown immediately after trial ended) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF25D366).withOpacity(0.08), Color(0xFF128C7E).withOpacity(0.12)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFF25D366).withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.support_agent, color: Color(0xFF25D366), size: 26),
                      const SizedBox(width: 8),
                      Text('Contact Support',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF25D366))),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      _ls({'kn':'\u0CB9\u0CC6\u0C9A\u0CCD\u0C9A\u0CBF\u0CA8 \u0CAE\u0CBE\u0CB9\u0CBF\u0CA4\u0CBF\u0C97\u0CBE\u0C97\u0CBF \u0CB8\u0C82\u0CAA\u0CB0\u0CCD\u0C95\u0CBF\u0CB8\u0CBF', 'hi':'\u0905\u0927\u093F\u0915 \u091C\u093E\u0928\u0915\u093E\u0930\u0940 \u0915\u0947 \u0932\u093F\u090F \u0938\u0902\u092A\u0930\u094D\u0915 \u0915\u0930\u0947\u0902', 'ta':'\u0BAE\u0BC7\u0BB2\u0BC1\u0BAE\u0BCD \u0BA4\u0B95\u0BB5\u0BB2\u0BC1\u0B95\u0BCD\u0B95\u0BC1 \u0BA4\u0BCA\u0B9F\u0BB0\u0BCD\u0BAA\u0BC1 \u0B95\u0BCA\u0BB3\u0BCD\u0BB3\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD', 'te':'\u0C2E\u0C30\u0C3F\u0C02\u0C24 \u0C38\u0C2E\u0C3E\u0C1A\u0C3E\u0C30\u0C02\u0C15\u0C4B\u0C38\u0C02 \u0C38\u0C02\u0C2A\u0C30\u0C4D\u0C15\u0C3F\u0C02\u0C1A\u0C02\u0C21\u0C3F', 'ml':'\u0D15\u0D42\u0D1F\u0D41\u0D24\u0D32\u0D4D \u0D35\u0D3F\u0D35\u0D30\u0D19\u0D4D\u0D19\u0D33\u0D4D\u0D15\u0D4D\u0D15\u0D4D \u0D2C\u0D28\u0D4D\u0D27\u0D2A\u0D4D\u0D2A\u0D46\u0D1F\u0D41\u0D15', 'en':'Contact support for more info.'}),
                      style: TextStyle(fontSize: 12, color: kMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _supportPhone,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText, letterSpacing: 1),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FutureBuilder<String>(
                        future: DeviceBindingService.getDeviceId(),
                        builder: (context, snapshot) {
                          final deviceId = snapshot.data ?? '';
                          final email = GoogleAuthService.userEmail ?? '';
                          return ElevatedButton.icon(
                            onPressed: () async {
                              final msg = Uri.encodeComponent(
                                'Hi, I need more info about Bharatheeyam app.');
                              final url = Uri.parse('https://wa.me/${_supportPhone.replaceAll('+', '')}?text=$msg');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.chat, size: 20),
                            label: Text(_ls({'kn':'WhatsApp \u0CA8\u0CB2\u0CCD\u0CB2\u0CBF \u0CB8\u0C82\u0CA6\u0CC7\u0CB6', 'hi':'WhatsApp \u092A\u0930 \u0938\u0902\u0926\u0947\u0936', 'ta':'WhatsApp \u0BB5\u0BB4\u0BBF \u0BA4\u0BCA\u0B9F\u0BB0\u0BCD\u0BAA\u0BC1', 'te':'WhatsApp \u0C32\u0C4B \u0C38\u0C02\u0C2A\u0C30\u0C4D\u0C15\u0C3F\u0C02\u0C1A\u0C02\u0C21\u0C3F', 'ml':'WhatsApp \u0D35\u0D34\u0D3F \u0D2C\u0D28\u0D4D\u0D27\u0D2A\u0D4D\u0D2A\u0D46\u0D1F\u0D41\u0D15', 'en':'Message on WhatsApp'}),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── App Demo Video ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.withOpacity(0.08), kOrange.withOpacity(0.08)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    Icon(Icons.play_circle_fill, color: Colors.red, size: 44),
                    const SizedBox(height: 8),
                    Text('ಆ್ಯಪ್ ಡೆಮೋ ವೀಡಿಯೋ', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
                    const SizedBox(height: 4),
                    Text('ಭಾರತೀಯಮ್ ಆ್ಯಪ್‌ನ ಸಂಪೂರ್ಣ ವೈಶಿಷ್ಟ್ಯಗಳನ್ನು ನೋಡಿ',
                      style: TextStyle(fontSize: 12, color: kMuted),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('https://youtu.be/j4-4O-t7VYw');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.ondemand_video, size: 20),
                        label: Text('Watch Demo Video',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── App Features ──
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ವೈಶಿಷ್ಟ್ಯಗಳು / Features', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kPurple2)),
                      const SizedBox(height: 12),
                      _featureRow(Icons.auto_awesome, 'ಕುಂಡಲಿ — ರಾಶಿ, ನವಾಂಶ, ಭಾವ, ದಶಾ, ಯೋಗ, ಗೋಚಾರ'),
                      _featureRow(Icons.calendar_month, 'ಪಂಚಾಂಗ — ತಿಥಿ, ನಕ್ಷತ್ರ, ರಾಹುಕಾಲ'),
                      _featureRow(Icons.stars_rounded, 'ತಾರಾನುಕೂಲ — ಶುಭ ದಿನ ಆಯ್ಕೆ, ಮುಹೂರ್ತ'),
                      _featureRow(Icons.favorite, 'ಗುಣ ಮಿಲನ — ಅಷ್ಟಕೂಟ ಹೊಂದಾಣಿಕೆ'),
                      _featureRow(Icons.home_work_rounded, 'ವಾಸ್ತು — ಪರಿಧಿ ಮತ್ತು ಚದರ ಅಡಿ'),
                      _featureRow(Icons.blur_circular, 'ಗ್ರಹ ಸ್ಥಿತಿ — ನವಗ್ರಹ ಸ್ಥಾನ'),
                      _featureRow(Icons.watch_later_rounded, 'ವೈದಿಕ ಗಡಿಯಾರ — ಘಟಿ, ಪಲ'),
                      _featureRow(Icons.language, '6 ಭಾಷೆ — ಕನ್ನಡ, ಹಿಂದಿ, ತಮಿಳು, ತೆಲುಗು, ಮಲಯಾಳಂ, English'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Gmail Sign-In (if not signed in) ──
                if (!isSignedIn) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPurple2.withOpacity(0.08), kOrange.withOpacity(0.08)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kPurple2.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      Icon(Icons.account_circle, color: kPurple2, size: 48),
                      const SizedBox(height: 12),
                      Text('Gmail Login Required',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
                      const SizedBox(height: 4),
                      Text(AppLocale.l('gmailLoginHint'),
                        style: TextStyle(fontSize: 12, color: kMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _signingIn ? null : _handleGmailSignIn,
                          icon: _signingIn
                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.login),
                          label: Text(_signingIn ? 'Signing in...' : 'Sign in with Google',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPurple2,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Your details card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Details', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kPurple2)),
                      const SizedBox(height: 14),
                      _infoRow(Icons.email_outlined, 'Gmail', email, context),
                      const SizedBox(height: 10),
                      FutureBuilder<String>(
                        future: DeviceBindingService.getDeviceId(),
                        builder: (context, snapshot) {
                          final deviceId = snapshot.data ?? 'Loading...';
                          return _infoRow(Icons.smartphone, 'Device ID', deviceId, context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Support card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_ls({'kn':'\u0CB8\u0C82\u0CAA\u0CB0\u0CCD\u0C95 \u0CB5\u0CBF\u0CB5\u0CB0', 'hi':'\u0938\u0939\u093E\u092F\u0924\u093E \u0938\u0902\u092A\u0930\u094D\u0915', 'ta':'\u0B86\u0BA4\u0BB0\u0BB5\u0BC1 \u0BA4\u0BCA\u0B9F\u0BB0\u0BCD\u0BAA\u0BC1', 'te':'\u0C38\u0C39\u0C3E\u0C2F\u0C02 \u0C38\u0C02\u0C2A\u0C30\u0C4D\u0C15\u0C3F\u0C02\u0C1A\u0C3F', 'ml':'\u0D38\u0D39\u0D3E\u0D2F\u0D02 \u0D15\u0D23\u0D4D\u0D26\u0D46\u0D15\u0D4D\u0D15\u0D41\u0D15', 'en':'Contact Support'}), style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kPurple2)),
                      const SizedBox(height: 14),
                      _infoRow(Icons.phone, 'Phone', _supportPhone, context),
                      const SizedBox(height: 10),
                      _infoRow(Icons.email, 'Email', _supportEmail, context),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Copy details button
                SizedBox(
                  width: double.infinity,
                  child: FutureBuilder<String>(
                    future: DeviceBindingService.getDeviceId(),
                    builder: (context, snapshot) {
                      final deviceId = snapshot.data ?? '';
                      return ElevatedButton.icon(
                        onPressed: () {
                          final text = 'Gmail: $email\nDevice ID: $deviceId';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Details copied!'), backgroundColor: Colors.green),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy My Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPurple2,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // WhatsApp button
                SizedBox(
                  width: double.infinity,
                  child: FutureBuilder<String>(
                    future: DeviceBindingService.getDeviceId(),
                    builder: (context, snapshot) {
                      final deviceId = snapshot.data ?? '';
                      return OutlinedButton.icon(
                        onPressed: () async {
                          final msg = Uri.encodeComponent(
                            'Bharatheeyam Support\nGmail: $email\nDevice ID: $deviceId');
                          final url = Uri.parse('https://wa.me/${_supportPhone.replaceAll('+', '')}?text=$msg');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Contact Support',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kGreen,
                          side: BorderSide(color: kGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),

                // ── Re-check Access button (if signed in but locked out) ──
                if (isSignedIn) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AppAccessService.checkAdminAccess();
                        if (AppAccessService.hasAccess && mounted) {
                          deviceBindingNotifier.value = true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Access restored!'), backgroundColor: Colors.green),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No active access found'), backgroundColor: Colors.orange),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-check Access',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPurple2,
                        side: BorderSide(color: kPurple2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildLockInfo(SupportLockType lockType) {
    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    switch (lockType) {
      case SupportLockType.muhurta:
        icon = Icons.auto_awesome;
        iconColor = Colors.purple;
        title = 'ಮುಹೂರ್ತ ವೈಶಿಷ್ಟ್ಯ ಲಾಕ್ ಆಗಿದೆ';
        subtitle = 'ಈ ವೈಶಿಷ್ಟ್ಯವನ್ನು ಪ್ರವೇಶಿಸಲು ದಯವಿಟ್ಟು ಬೆಂಬಲವನ್ನು ಸಂಪರ್ಕಿಸಿ';
        break;
      case SupportLockType.student:
        icon = Icons.school;
        iconColor = Colors.orange;
        title = 'ವಿದ್ಯಾರ್ಥಿ ಮೋಡ್';
        subtitle = 'ಈ ವಿಭಾಗವು ವಿದ್ಯಾರ್ಥಿ ಖಾತೆಗೆ ಲಭ್ಯವಿಲ್ಲ. ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಲು ಬೆಂಬಲವನ್ನು ಸಂಪರ್ಕಿಸಿ';
        break;
      case SupportLockType.general:
        icon = Icons.info_outline;
        iconColor = kMuted;
        title = AppLocale.l('trialExpired');
        subtitle = AppLocale.l('trialExpiredSub');
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBorder.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder.withOpacity(0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: iconColor, size: 40),
        const SizedBox(height: 12),
        Text(title,
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800,
            color: kText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(subtitle,
          style: TextStyle(fontSize: 13, color: kMuted),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  static Widget _infoRow(IconData icon, String label, String value, BuildContext context) {
    return Row(children: [
      Icon(icon, color: kMuted, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: kMuted)),
          Text(value, style: TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w600)),
        ],
      )),
      IconButton(
        icon: Icon(Icons.copy, size: 16, color: kMuted),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label copied!'), duration: const Duration(seconds: 1)),
          );
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ]);
  }

  static Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: kOrange, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText))),
      ]),
    );
  }
}
