import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// Shared app-wide decorators / constants
// ─────────────────────────────────────────────

const Color kPurple1 = Color(0xFF8E2DE2);
const Color kPurple2 = Color(0xFF4A00E0);
const Color kOrange  = Color(0xFFDD6B20);
const Color kOrange2 = Color(0xFFC05621);
const Color kTeal    = Color(0xFF319795);
const Color kGreen   = Color(0xFF047857);
const Color kBg      = Color(0xFFFFFDF7);
const Color kCard    = Color(0xFFFFFFFF);
const Color kBorder  = Color(0xFFE2E8F0);
const Color kText    = Color(0xFF2D3748);
const Color kMuted   = Color(0xFF718096);

// ─────────────────────────────────────────────
// Header widget (purple gradient banner)
// ─────────────────────────────────────────────
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPurple1, kPurple2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPurple2.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
        border: const Border(bottom: BorderSide(color: Color(0xFFF6D365), width: 4)),
      ),
      child: Center(
        child: Text(
          'ಭಾರತೀಯಮ್',
          style: GoogleFonts.notoSansKannada(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card wrapper
// ─────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: GoogleFonts.notoSansKannada(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color ?? const Color(0xFF2B6CB0),
        ),
      ),
    );
  }
}
