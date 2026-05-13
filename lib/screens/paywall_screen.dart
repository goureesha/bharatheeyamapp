import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common.dart';
import '../services/google_auth_service.dart';
import '../services/device_binding_service.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _supportPhone = '+918762629847';
  static const _supportEmail = 'goureesh3690@gmail.com';

  @override
  Widget build(BuildContext context) {
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

                // Trial expired message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(children: [
                    Icon(Icons.timer_off, color: Colors.red.shade700, size: 40),
                    const SizedBox(height: 12),
                    Text(AppLocale.l('trialExpired'),
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: Colors.red.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(AppLocale.l('trialExpiredSub'),
                      style: TextStyle(fontSize: 13, color: Colors.red.shade600),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

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
                      Text('Contact Support', style: TextStyle(
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
              ],
            )),
          ),
        ),
      ),
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
}
