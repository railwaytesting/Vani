// lib/screens/HomeScreen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../components/GlobalNavbar.dart';
import '../l10n/AppLocalizations.dart';
import 'TranslateScreen.dart';
import 'objectives/AccessibilityPage.dart';
import 'objectives/BridgingGapsPage.dart';
import 'objectives/InclusivityPage.dart';
import 'objectives/PrivacyPage.dart';
import 'objectives/OfflinePage.dart';
import 'objectives/EducationPage.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _kViolet      = Color(0xFF7C3AED);
const _kVioletLight = Color(0xFFA78BFA);
const _kVioletDeep  = Color(0xFF5B21B6);
const _kObsidian    = Color(0xFF040408);
const _kSurface     = Color(0xFF0C0C16);
const _kSurfaceUp   = Color(0xFF111120);
const _kBorder      = Color(0xFF1C1C30);
const _kBorderBrt   = Color(0xFF2C2C46);
const _kTextPri     = Color(0xFFF0EEFF);
const _kTextSec     = Color(0xFF7070A0);
const _kTextMuted   = Color(0xFF38385A);
const _kCrimson     = Color(0xFFDC2626);

// Light mode palette
const _lBg          = Color(0xFFF5F6FE);
const _lSurface     = Color(0xFFFFFFFF);
const _lBorder      = Color(0xFFE4E4F2);
const _lTextPri     = Color(0xFF0A0A20);
const _lTextSec     = Color(0xFF5A5A82);
const _lTextMuted   = Color(0xFFB0B0C8);

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const HomeScreen({super.key, required this.toggleTheme, required this.setLocale});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  bool _statsVisible = false;
  final GlobalKey _statsKey = GlobalKey();

  late AnimationController _heroCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _heroCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _heroFade  = CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _heroCtrl,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOut)));
    _pulse = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _heroCtrl.forward();
    _scroll.addListener(_checkScroll);
  }

  void _checkScroll() {
    if (_statsVisible) return;
    final obj = _statsKey.currentContext?.findRenderObject();
    if (obj is RenderBox) {
      final pos = obj.localToGlobal(Offset.zero).dy;
      if (pos < MediaQuery.of(context).size.height * 0.9)
        setState(() => _statsVisible = true);
    }
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _pulseCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w         = MediaQuery.of(context).size.width;
    final isDesktop = w > 1100;
    final isTablet  = w > 650 && w <= 1100;
    final isMobile  = w <= 650;
    final hPad      = isDesktop ? 96.0 : (isTablet ? 48.0 : 20.0);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final l         = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? _kObsidian : _lBg,
      body: Stack(children: [
        // Background grid
        Positioned.fill(child: _GridTexture(isDark: isDark)),
        // Ambient glows — smaller on mobile to avoid painting lag
        Positioned(top: -180, left: -80,
          child: _AmbientGlow(
            color: _kViolet.withOpacity(isDark ? 0.20 : 0.08),
            size: isMobile ? 420 : 680)),
        Positioned(bottom: -260, right: -160,
          child: _AmbientGlow(
            color: const Color(0xFF1D4ED8).withOpacity(isDark ? 0.12 : 0.05),
            size: isMobile ? 320 : 560)),

        SafeArea(
          child: SingleChildScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              GlobalNavbar(
                  toggleTheme: widget.toggleTheme,
                  setLocale: widget.setLocale,
                  activeRoute: 'home'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(children: [
                  SizedBox(height: isDesktop ? 80 : (isMobile ? 36 : 56)),

                  FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: Column(children: [
                        _StatusChip(l: l, pulse: _pulse, isDark: isDark),
                        SizedBox(height: isDesktop ? 44 : (isMobile ? 24 : 32)),
                        _HeroText(isMobile: isMobile, isTablet: isTablet,
                            isDesktop: isDesktop, l: l, isDark: isDark),
                        SizedBox(height: isDesktop ? 28 : (isMobile ? 16 : 22)),
                        _HeroSub(isMobile: isMobile, isDesktop: isDesktop,
                            l: l, isDark: isDark),
                        SizedBox(height: isDesktop ? 52 : (isMobile ? 32 : 40)),
                        _CTAButton(
                          label: l.t('get_started'),
                          onTap: () => Navigator.push(context, PageRouteBuilder(
                            pageBuilder: (_, __, ___) => TranslateScreen(
                                toggleTheme: widget.toggleTheme,
                                setLocale: widget.setLocale),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 380),
                          )),
                        ),
                      ]),
                    ),
                  ),

                  SizedBox(height: isDesktop ? 120 : (isMobile ? 56 : 88)),
                  _DividerLine(isDark: isDark),
                  SizedBox(height: isDesktop ? 80 : (isMobile ? 48 : 64)),

                  // Stats
                  Container(
                    key: _statsKey,
                    child: _StatsSection(
                      isDesktop: isDesktop,
                      isMobile: isMobile,
                      isVisible: _statsVisible,
                      l: l, isDark: isDark),
                  ),

                  SizedBox(height: isDesktop ? 120 : (isMobile ? 64 : 96)),
                  _SectionLabel(
                    text: l.t('obj_heading'), sub: l.t('obj_sub'), isDark: isDark),
                  SizedBox(height: isDesktop ? 56 : (isMobile ? 28 : 40)),
                  _ObjectivesGrid(
                    isDesktop: isDesktop, isTablet: isTablet, isMobile: isMobile,
                    l: l, isDark: isDark,
                    toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),

                  SizedBox(height: isDesktop ? 120 : (isMobile ? 64 : 96)),
                  _VisionCard(l: l, isDark: isDark, isMobile: isMobile),
                  SizedBox(height: isDesktop ? 80 : (isMobile ? 48 : 64)),
                  _Footer(isDark: isDark),
                  const SizedBox(height: 48),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  GRID TEXTURE
// ─────────────────────────────────────────────
class _GridTexture extends StatelessWidget {
  final bool isDark;
  const _GridTexture({required this.isDark});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GridPainter(isDark: isDark));
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = isDark
          ? const Color(0xFF18182E).withOpacity(0.55)
          : const Color(0xFFE0E0EE).withOpacity(0.75)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width;  x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    final dp = Paint()
      ..color = _kViolet.withOpacity(isDark ? 0.10 : 0.06);
    for (double x = 0; x < size.width;  x += step)
      for (double y = 0; y < size.height; y += step)
        canvas.drawCircle(Offset(x, y), 1.0, dp);
  }
  @override
  bool shouldRepaint(_GridPainter o) => o.isDark != isDark;
}

// ─────────────────────────────────────────────
//  AMBIENT GLOW
// ─────────────────────────────────────────────
class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientGlow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
      child: const SizedBox.expand()),
  );
}

// ─────────────────────────────────────────────
//  STATUS CHIP
// ─────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final AppLocalizations l;
  final Animation<double> pulse;
  final bool isDark;
  const _StatusChip({required this.l, required this.pulse, required this.isDark});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulse,
    builder: (_, __) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? _kSurfaceUp : _lSurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _kViolet.withOpacity(isDark ? 0.32 : 0.18)),
        boxShadow: [BoxShadow(
          color: _kViolet.withOpacity(pulse.value * (isDark ? 0.14 : 0.05)),
          blurRadius: 18)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: _kVioletLight,
            boxShadow: [BoxShadow(
              color: _kVioletLight.withOpacity(pulse.value * 0.75),
              blurRadius: 7, spreadRadius: 1)]),
        ),
        const SizedBox(width: 9),
        Text(l.t('badge'), style: TextStyle(
          color: isDark ? _kVioletLight : _kViolet,
          fontWeight: FontWeight.w600, fontSize: 11.5, letterSpacing: 0.3)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
//  HERO TEXT  — mobile overflow fixed
//  Root cause: letterSpacing: -2.0 + fontSize: 36 + WidgetSpan
//  inside unconstrained RichText causes measurement blowout.
//  Fix: use Column + Text.rich with tighter letterSpacing on mobile,
//  and wrap in a width-constrained box.
// ─────────────────────────────────────────────
class _HeroText extends StatelessWidget {
  final bool isMobile, isTablet, isDesktop;
  final AppLocalizations l;
  final bool isDark;
  const _HeroText({
    required this.isMobile, required this.isTablet,
    required this.isDesktop, required this.l, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final double fs = isDesktop ? 70.0 : (isTablet ? 50.0 : 32.0);
    // On mobile: no negative letter spacing (causes overflow with WidgetSpan)
    final double ls = isDesktop ? -2.0 : (isTablet ? -1.0 : -0.3);
    final color = isDark ? _kTextPri : _lTextPri;

    return LayoutBuilder(builder: (ctx, constraints) {
      return Column(children: [
        // Line 1 — plain text, no gradient
        Text(
          l.t('hero_title_1'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fs, fontWeight: FontWeight.w900,
            color: color, height: 1.10, letterSpacing: ls),
        ),
        // Line 2 — gradient highlight
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_kViolet, _kVioletLight, Color(0xFF60A5FA)],
            stops: [0.0, 0.55, 1.0],
          ).createShader(b),
          child: Text(
            l.t('hero_title_highlight'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fs, fontWeight: FontWeight.w900,
              color: Colors.white, height: 1.10, letterSpacing: ls),
          ),
        ),
        // Line 3
        if (l.t('hero_title_2').isNotEmpty)
          Text(
            l.t('hero_title_2'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fs, fontWeight: FontWeight.w900,
              color: color, height: 1.10, letterSpacing: ls),
          ),
      ]);
    });
  }
}

// ─────────────────────────────────────────────
//  HERO SUBTITLE
// ─────────────────────────────────────────────
class _HeroSub extends StatelessWidget {
  final bool isMobile, isDesktop;
  final AppLocalizations l;
  final bool isDark;
  const _HeroSub({
    required this.isMobile, required this.isDesktop,
    required this.l, required this.isDark});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: isDesktop ? 580 : (isMobile ? 340 : 480)),
    child: Text(
      l.t('hero_sub'),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isDesktop ? 17 : (isMobile ? 14 : 15.5),
        color: isDark ? _kTextSec : _lTextSec,
        height: 1.75, letterSpacing: 0.1),
    ),
  );
}

// ─────────────────────────────────────────────
//  CTA BUTTON
// ─────────────────────────────────────────────
class _CTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _CTAButton({required this.label, required this.onTap});
  @override
  State<_CTAButton> createState() => _CTAButtonState();
}
class _CTAButtonState extends State<_CTAButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _hovered
                ? [const Color(0xFF8B5CF6), _kViolet]
                : [_kViolet, _kVioletDeep],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _kVioletLight.withOpacity(_hovered ? 0.4 : 0.12)),
          boxShadow: [BoxShadow(
            color: _kViolet.withOpacity(_hovered ? 0.50 : 0.28),
            blurRadius: _hovered ? 44 : 22,
            offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.label, style: const TextStyle(
            fontSize: 14.5, fontWeight: FontWeight.w700,
            color: Colors.white, letterSpacing: 0.4)),
          const SizedBox(width: 12),
          AnimatedSlide(
            offset: Offset(_hovered ? 0.25 : 0, 0),
            duration: const Duration(milliseconds: 160),
            child: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 16)),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  DIVIDER
// ─────────────────────────────────────────────
class _DividerLine extends StatelessWidget {
  final bool isDark;
  const _DividerLine({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: BoxDecoration(gradient: LinearGradient(colors: [
      Colors.transparent,
      isDark ? _kBorderBrt : const Color(0xFFCCCCE0),
      Colors.transparent,
    ])),
  );
}

// ─────────────────────────────────────────────
//  STATS SECTION  — mobile overflow fixed
//  Root cause: fontSize 44 + tabular figures on narrow screen.
//  Fix: scale font size by breakpoint.
// ─────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  final bool isDesktop, isMobile, isVisible;
  final AppLocalizations l;
  final bool isDark;
  const _StatsSection({
    required this.isDesktop, required this.isMobile,
    required this.isVisible, required this.l, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (value: '63000000', label: l.t('stat_mute_label'),
       color: _kVioletLight, suffix: '+'),
      (value: '8435000',  label: l.t('stat_isl_label'),
       color: _kVioletLight, suffix: '+'),
      (value: '250',      label: l.t('stat_translators_label'),
       color: _kCrimson,    suffix: ''),
    ];

    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(children: [
          for (int i = 0; i < stats.length; i++) ...[
            Expanded(child: _StatCell(
              value: stats[i].value, label: stats[i].label,
              color: stats[i].color, suffix: stats[i].suffix,
              isVisible: isVisible, isDark: isDark, isMobile: false)),
            if (i < stats.length - 1)
              Container(width: 1,
                color: isDark ? _kBorder : const Color(0xFFDDDDEE)),
          ],
        ]),
      );
    }

    // Mobile / tablet: horizontal card row (3 items side by side with smaller font)
    return Row(children: stats.asMap().entries.map((e) => Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: e.key < stats.length - 1 ? 10 : 0),
        child: _StatCell(
          value: e.value.value, label: e.value.label,
          color: e.value.color, suffix: e.value.suffix,
          isVisible: isVisible, isDark: isDark, isMobile: isMobile),
      ),
    )).toList());
  }
}

class _StatCell extends StatefulWidget {
  final String value, label, suffix;
  final Color color;
  final bool isVisible, isDark, isMobile;
  const _StatCell({
    required this.value, required this.label, required this.color,
    required this.suffix, required this.isVisible,
    required this.isDark, required this.isMobile});
  @override
  State<_StatCell> createState() => _StatCellState();
}

class _StatCellState extends State<_StatCell> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000));
    _anim = Tween<double>(begin: 0, end: double.parse(widget.value))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
  }
  @override
  void didUpdateWidget(_StatCell old) {
    super.didUpdateWidget(old);
    if (widget.isVisible && !old.isVisible) _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(int n) => n.toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    // Scale stat number font to avoid overflow on mobile
    final numFs  = widget.isMobile ? 26.0 : 42.0;
    final sufFs  = widget.isMobile ? 18.0 : 26.0;
    final labFs  = widget.isMobile ? 9.5  : 12.5;
    final vPad   = widget.isMobile ? 20.0 : 36.0;
    final hPad   = widget.isMobile ? 8.0  : 24.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      decoration: widget.isMobile ? BoxDecoration(
        color: widget.isDark ? _kSurface : _lSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? _kBorder : _lBorder),
      ) : null,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(text: TextSpan(children: [
              TextSpan(
                text: _fmt(_anim.value.toInt()),
                style: TextStyle(
                  fontSize: numFs, fontWeight: FontWeight.w900,
                  color: widget.color, letterSpacing: -1.0,
                  fontFeatures: const [FontFeature.tabularFigures()])),
              TextSpan(
                text: widget.suffix,
                style: TextStyle(fontSize: sufFs, fontWeight: FontWeight.w900,
                    color: widget.color.withOpacity(0.55))),
            ])),
            const SizedBox(height: 8),
            Text(widget.label, textAlign: TextAlign.center, style: TextStyle(
              fontSize: labFs, fontWeight: FontWeight.w500,
              color: widget.isDark ? _kTextSec : _lTextSec, letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text, sub;
  final bool isDark;
  const _SectionLabel({required this.text, required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w <= 650;
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: _kViolet.withOpacity(0.28)),
          borderRadius: BorderRadius.circular(6)),
        child: Text('// OBJECTIVES', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: _kViolet.withOpacity(0.75), letterSpacing: 2.0)),
      ),
      const SizedBox(height: 16),
      Text(text, textAlign: TextAlign.center, style: TextStyle(
        fontSize: isMobile ? 26.0 : 34.0,
        fontWeight: FontWeight.w900,
        color: isDark ? _kTextPri : _lTextPri,
        letterSpacing: isMobile ? -0.5 : -0.8, height: 1.15)),
      const SizedBox(height: 10),
      Text(sub, textAlign: TextAlign.center, style: TextStyle(
        fontSize: isMobile ? 13.0 : 14.0,
        color: isDark ? _kTextMuted : _lTextMuted, letterSpacing: 0.15)),
    ]);
  }
}

// ─────────────────────────────────────────────
//  OBJECTIVES GRID
// ─────────────────────────────────────────────
class _ObjectivesGrid extends StatelessWidget {
  final bool isDesktop, isTablet, isMobile;
  final AppLocalizations l;
  final bool isDark;
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;
  const _ObjectivesGrid({
    required this.isDesktop, required this.isTablet, required this.isMobile,
    required this.l, required this.isDark,
    required this.toggleTheme, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (icon: Icons.accessibility_new_rounded, title: l.t('obj_accessibility'),
       desc: l.t('obj_accessibility_desc'), color: const Color(0xFF7C3AED),
       page: AccessibilityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (icon: Icons.connecting_airports_rounded, title: l.t('obj_bridging'),
       desc: l.t('obj_bridging_desc'), color: const Color(0xFF0284C7),
       page: BridgingGapsPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (icon: Icons.people_outline_rounded, title: l.t('obj_inclusivity'),
       desc: l.t('obj_inclusivity_desc'), color: const Color(0xFF059669),
       page: InclusivityPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (icon: Icons.shield_outlined, title: l.t('obj_privacy'),
       desc: l.t('obj_privacy_desc'), color: const Color(0xFFD97706),
       page: PrivacyPage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (icon: Icons.wifi_off_rounded, title: l.t('obj_offline'),
       desc: l.t('obj_offline_desc'), color: const Color(0xFF6366F1),
       page: OfflinePage(toggleTheme: toggleTheme, setLocale: setLocale)),
      (icon: Icons.school_rounded, title: l.t('obj_education'),
       desc: l.t('obj_education_desc'), color: const Color(0xFFDC2626),
       page: EducationPage(toggleTheme: toggleTheme, setLocale: setLocale)),
    ];

    // Mobile: single-column, cards wrap their own content
    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _ObjCard(icon: c.icon, title: c.title, desc: c.desc,
              isDark: isDark, accent: c.color, page: c.page, isMobile: true),
        )).toList(),
      );
    }

    // Tablet: 2 columns, Desktop: 3 columns
    final cols = isDesktop ? 3 : 2;
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols, mainAxisSpacing: 14, crossAxisSpacing: 14,
      childAspectRatio: isDesktop ? 1.6 : 1.45,
      children: cards.map((c) => _ObjCard(
        icon: c.icon, title: c.title, desc: c.desc,
        isDark: isDark, accent: c.color, page: c.page, isMobile: false,
      )).toList(),
    );
  }
}

class _ObjCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final bool isDark, isMobile;
  final Color accent;
  final Widget page;
  const _ObjCard({required this.icon, required this.title, required this.desc,
    required this.isDark, required this.accent, required this.page,
    required this.isMobile});
  @override
  State<_ObjCard> createState() => _ObjCardState();
}

class _ObjCardState extends State<_ObjCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.page,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, 0.03), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child)),
          transitionDuration: const Duration(milliseconds: 320),
        )),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(widget.isMobile ? 18 : 24),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_hovered ? _kSurfaceUp : _kSurface)
                : (_hovered ? Colors.white : const Color(0xFFFAFAFD)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? widget.accent.withOpacity(0.42)
                  : (widget.isDark ? _kBorder : _lBorder),
              width: _hovered ? 1.5 : 1.0),
            boxShadow: _hovered
                ? [BoxShadow(
                    color: widget.accent.withOpacity(widget.isDark ? 0.16 : 0.08),
                    blurRadius: 32, offset: const Offset(0, 10))]
                : [if (!widget.isDark) BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: widget.isMobile ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: widget.isMobile
                ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(widget.isDark ? 0.14 : 0.07),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: widget.accent.withOpacity(_hovered ? 0.38 : 0.14))),
                  child: Icon(widget.icon, color: widget.accent, size: 18)),
                const Spacer(),
                AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(7)),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: widget.accent, size: 13)),
                ),
              ]),
              const SizedBox(height: 14),
              Text(widget.title, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2,
                color: widget.isDark ? _kTextPri : _lTextPri)),
              const SizedBox(height: 5),
              Text(widget.desc, style: TextStyle(
                fontSize: 12.5, height: 1.5,
                color: widget.isDark ? _kTextSec : _lTextSec)),
              const SizedBox(height: 10),
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: Text('Explore →', style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700,
                  color: widget.accent, letterSpacing: 0.2))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  VISION CARD  — mobile overflow fixed
//  Root cause: horizontal padding 40 + inner content was clipping on 375px.
//  Fix: adaptive padding and constrained content.
// ─────────────────────────────────────────────
class _VisionCard extends StatelessWidget {
  final AppLocalizations l;
  final bool isDark, isMobile;
  const _VisionCard({required this.l, required this.isDark, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 20.0 : 40.0;
    final vPad = isMobile ? 36.0 : 52.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          decoration: BoxDecoration(
            color: isDark
                ? _kViolet.withOpacity(0.06)
                : _kViolet.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _kViolet.withOpacity(isDark ? 0.18 : 0.10))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 32, height: 1,
                  color: _kViolet.withOpacity(0.35)),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kViolet.withOpacity(0.10), shape: BoxShape.circle,
                  border: Border.all(color: _kViolet.withOpacity(0.25))),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: _kVioletLight, size: 22)),
              const SizedBox(width: 14),
              Container(width: 32, height: 1,
                  color: _kViolet.withOpacity(0.35)),
            ]),
            const SizedBox(height: 24),
            Text(l.t('vision_title'), textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 18.0 : 22.0,
                fontWeight: FontWeight.w800, color: _kVioletLight,
                letterSpacing: -0.4, height: 1.25)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 320 : 600),
              child: Text(l.t('vision_body'), textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 13.5 : 15.0,
                  color: isDark ? _kTextSec : _lTextSec,
                  height: 1.75))),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _kCrimson.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kCrimson.withOpacity(0.22))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: _kCrimson, shape: BoxShape.circle)),
                const SizedBox(width: 9),
                Text('1 translator : 33,000+ people',
                  style: TextStyle(
                    color: _kCrimson.withOpacity(0.85), fontSize: 12.5,
                    fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FOOTER
// ─────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final bool isDark;
  const _Footer({required this.isDark});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      height: 1,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [
        Colors.transparent,
        isDark ? _kBorderBrt : const Color(0xFFCCCCE0),
        Colors.transparent,
      ])),
    ),
    const SizedBox(height: 28),
    Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 8,
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_kViolet, _kVioletLight]).createShader(b),
          child: const Text('VANI', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w900,
            color: Colors.white, letterSpacing: 5))),
        Container(width: 1, height: 12,
          color: isDark ? _kBorderBrt : const Color(0xFFCCCCDD)),
        Text('© 2026 — Empowering Silence', style: TextStyle(
          fontSize: 11.5,
          color: isDark ? _kTextMuted : const Color(0xFFAAAAAACC),
          letterSpacing: 0.2)),
      ],
    ),
  ]);
}