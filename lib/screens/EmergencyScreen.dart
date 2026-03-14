// lib/screens/EmergencyScreen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/GlobalNavbar.dart';
import '../services/EmergencyService.dart';
import '../Utils/PlatformHelper.dart';
import 'EmergencySetupScreen.dart';

// ── Accent colours (mode-invariant) ─────────────────────────────
const _kCrimson     = Color(0xFFDC2626);
const _kCrimsonSoft = Color(0xFFEF4444);
const _kViolet      = Color(0xFF7C3AED);
const _kVioletLight = Color(0xFFA78BFA);
const _kAmber       = Color(0xFFD97706);
const _kAmberSoft   = Color(0xFFFBBF24);
const _kBlue        = Color(0xFF0284C7);
const _kBlueSoft    = Color(0xFF38BDF8);
const _kGreen       = Color(0xFF059669);
const _kGreenSoft   = Color(0xFF34D399);
const _kOrange      = Color(0xFFEA580C);
const _kOrangeSoft  = Color(0xFFFB923C);
const _kPurple      = Color(0xFF7E22CE);
const _kPurpleSoft  = Color(0xFFC084FC);
const _kTeal        = Color(0xFF0F766E);
const _kTealSoft    = Color(0xFF2DD4BF);

// ── Theme helper ─────────────────────────────────────────────────
class _T {
  final bool d;
  const _T(this.d);
  Color get scaffold  => d ? const Color(0xFF020205) : const Color(0xFFF4F6FD);
  Color get surface   => d ? const Color(0xFF0A0A12) : Colors.white;
  Color get surfaceUp => d ? const Color(0xFF0F0F1A) : const Color(0xFFF8F8FC);
  Color get surfaceHi => d ? const Color(0xFF141428) : const Color(0xFFEEEEF8);
  Color get border    => d ? const Color(0xFF1C1C2E) : const Color(0xFFE0E0EE);
  Color get borderBrt => d ? const Color(0xFF252540) : const Color(0xFFCCCCDD);
  Color get textPri   => d ? const Color(0xFFF2F0FF) : const Color(0xFF0A0A1F);
  Color get textSec   => d ? const Color(0xFF6B6B8A) : const Color(0xFF6A6A8A);
  Color get textMuted => d ? const Color(0xFF2E2E4A) : const Color(0xFFAAAAAA);
  Color get gridLine  => d
      ? const Color(0xFF12122A).withOpacity(0.5)
      : const Color(0xFFE0E0F0).withOpacity(0.8);
}

// ── SOS scenario data model ──────────────────────────────────────
class _SOSScenario {
  final SOSMessageType type;
  final String icon;
  final String title;
  final String subtitle;
  final String signDescription; // what ISL sign triggers this
  final Color color;
  final Color soft;
  final String formalSMSMessage;
  final String helplineNumber;
  final String helplineName;

  const _SOSScenario({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.signDescription,
    required this.color,
    required this.soft,
    required this.formalSMSMessage,
    required this.helplineNumber,
    required this.helplineName,
  });
}

// ── All real-world SOS scenarios ─────────────────────────────────
// These cover the most common emergencies faced by deaf/mute individuals
// in India. Messages are formal, clear, and actionable.
const List<_SOSScenario> _kScenarios = [

  _SOSScenario(
    type: SOSMessageType.generalHelp,
    icon: '🆘',
    title: 'I Need Help',
    subtitle: 'General distress — immediate assistance required',
    signDescription: 'Detected: "HELP" sign',
    color: _kCrimson,
    soft: _kCrimsonSoft,
    helplineNumber: '112',
    helplineName: 'National Emergency',
    formalSMSMessage:
        'URGENT — EMERGENCY ALERT\n\n'
        'This is an automated alert from the VANI app.\n\n'
        'The person who sent this message is DEAF or MUTE and is unable to speak or call for help. '
        'They require immediate assistance.\n\n'
        'Please call them back, go to their location, or contact emergency services (112) on their behalf.\n\n'
        'They will respond via text or sign language.\n\n'
        '📍 Current location: {LOCATION}\n\n'
        'Time of alert: {TIME}\n'
        '— Sent via VANI Emergency SOS',
  ),

  _SOSScenario(
    type: SOSMessageType.medical,
    icon: '🏥',
    title: 'Medical Emergency',
    subtitle: 'Injury, chest pain, seizure, or health crisis',
    signDescription: 'Detected: "DOCTOR" / "PAIN" sign',
    color: _kOrange,
    soft: _kOrangeSoft,
    helplineNumber: '108',
    helplineName: 'Ambulance',
    formalSMSMessage:
        'URGENT — MEDICAL EMERGENCY\n\n'
        'This is an automated alert from the VANI app.\n\n'
        'The person who sent this message is DEAF or MUTE and is experiencing a medical emergency. '
        'They cannot call for help verbally.\n\n'
        'Please do one or more of the following immediately:\n'
        '• Call an ambulance: dial 108\n'
        '• Go to their location\n'
        '• Contact a nearby doctor or hospital\n\n'
        '📍 Current location: {LOCATION}\n\n'
        'Time of alert: {TIME}\n'
        '— Sent via VANI Emergency SOS',
  ),

  _SOSScenario(
    type: SOSMessageType.police,
    icon: '👮',
    title: 'I Feel Unsafe',
    subtitle: 'Threat, harassment, assault, or danger',
    signDescription: 'Detected: "DANGER" / "POLICE" sign',
    color: _kBlue,
    soft: _kBlueSoft,
    helplineNumber: '100',
    helplineName: 'Police',
    formalSMSMessage:
        'URGENT — SAFETY EMERGENCY\n\n'
        'This is an automated alert from the VANI app.\n\n'
        'The person who sent this message is DEAF or MUTE and feels unsafe or is in danger. '
        'They are unable to call police verbally.\n\n'
        'Please do one or more of the following immediately:\n'
        '• Call the police: dial 100\n'
        '• Go to their location\n'
        '• Alert someone nearby to assist them\n\n'
        '📍 Current location: {LOCATION}\n\n'
        'Time of alert: {TIME}\n'
        '— Sent via VANI Emergency SOS',
  ),

  _SOSScenario(
    type: SOSMessageType.fire,
    icon: '🔥',
    title: 'Fire or Smoke',
    subtitle: 'Fire, gas leak, or smoke detected nearby',
    signDescription: 'Detected: "FIRE" sign',
    color: _kAmber,
    soft: _kAmberSoft,
    helplineNumber: '101',
    helplineName: 'Fire Brigade',
    formalSMSMessage:
        'URGENT — FIRE / SMOKE EMERGENCY\n\n'
        'This is an automated alert from the VANI app.\n\n'
        'The person who sent this message is DEAF or MUTE and is reporting a fire or smoke emergency. '
        'They cannot call the fire brigade verbally.\n\n'
        'Please do one or more of the following immediately:\n'
        '• Call the fire brigade: dial 101\n'
        '• Evacuate the building\n'
        '• Alert people near this location\n\n'
        '📍 Current location: {LOCATION}\n\n'
        'Time of alert: {TIME}\n'
        '— Sent via VANI Emergency SOS',
  ),

  _SOSScenario(
    type: SOSMessageType.custom,
    icon: '🚗',
    title: 'Road Accident',
    subtitle: 'Vehicle accident — injuries possible',
    signDescription: 'Detected: "CAR" + "ACCIDENT" sign',
    color: _kPurple,
    soft: _kPurpleSoft,
    helplineNumber: '1033',
    helplineName: 'Highway Helpline',
    formalSMSMessage:
        'URGENT — ROAD ACCIDENT\n\n'
        'This is an automated alert from the VANI app.\n\n'
        'The person who sent this message is DEAF or MUTE and has been involved in or witnessed a road accident. '
        'They cannot call for help verbally.\n\n'
        'Please do one or more of the following immediately:\n'
        '• Call ambulance: dial 108\n'
        '• Call highway helpline: dial 1033\n'
        '• Go to their location and assist\n\n'
        '📍 Current location: {LOCATION}\n\n'
        'Time of alert: {TIME}\n'
        '— Sent via VANI Emergency SOS',
  ),

  _SOSScenario(
    type: SOSMessageType.custom,
    icon: '🧒',
    title: 'Child in Danger',
    subtitle: 'Child missing, lost, or in distress',
    signDescription: 'Detected: "CHILD" + "LOST" sign',
    color: _kTeal,
    soft: _kTealSoft,
    helplineNumber: '1098',
    helplineName: 'Childline',
    formalSMSMessage:
        'URGENT — CHILD SAFETY ALERT\n\n'
        'This is an automated alert from the VANI app.\n\n'
        'The person who sent this message is DEAF or MUTE and is reporting a child safety emergency — '
        'a child may be missing, lost, or in distress. They cannot call for help verbally.\n\n'
        'Please do one or more of the following immediately:\n'
        '• Call Childline: dial 1098\n'
        '• Call police: dial 100\n'
        '• Assist at this location immediately\n\n'
        '📍 Current location: {LOCATION}\n\n'
        'Time of alert: {TIME}\n'
        '— Sent via VANI Emergency SOS',
  ),
];

// ════════════════════════════════════════════════════════════════
//  EMERGENCY SCREEN
// ════════════════════════════════════════════════════════════════

class EmergencyScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;

  // Optional: ISL translation can pass detected sign text here
  // e.g. EmergencyScreen(detectedSign: "HELP")
  final String? detectedSign;

  const EmergencyScreen({
    super.key,
    required this.toggleTheme,
    required this.setLocale,
    this.detectedSign,
  });

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  final _service = EmergencyService.instance;

  bool _isSending = false;
  int? _activeSendIndex;
  String? _statusMessage;
  bool _statusIsSuccess = false;
  _SOSScenario? _autoDetectedScenario;

  late AnimationController _ambientCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _ambientAnim;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _service.updateContext(context);

    _ambientCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _ambientAnim =
        CurvedAnimation(parent: _ambientCtrl, curve: Curves.easeInOut);
    _pulseAnim =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    ));

    _entryCtrl.forward();

    // Auto-detect scenario from ISL sign if passed in
    if (widget.detectedSign != null) {
      _autoDetectedScenario = _matchSignToScenario(widget.detectedSign!);
    }
  }

  /// Maps an ISL sign string to a scenario
  _SOSScenario? _matchSignToScenario(String sign) {
    final s = sign.toLowerCase();
    if (s.contains('help') || s.contains('sos'))     return _kScenarios[0];
    if (s.contains('doctor') || s.contains('pain') ||
        s.contains('sick')   || s.contains('medical')) return _kScenarios[1];
    if (s.contains('danger') || s.contains('police') ||
        s.contains('unsafe') || s.contains('fear'))  return _kScenarios[2];
    if (s.contains('fire')   || s.contains('smoke')) return _kScenarios[3];
    if (s.contains('accident')|| s.contains('car'))  return _kScenarios[4];
    if (s.contains('child')  || s.contains('lost'))  return _kScenarios[5];
    return _kScenarios[0]; // fallback to general help
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS(int scenarioIndex) async {
    if (_isSending) return;
    final scenario = _kScenarios[scenarioIndex];

    HapticFeedback.heavyImpact();

    setState(() {
      _isSending = true;
      _activeSendIndex = scenarioIndex;
      _statusMessage = null;
    });

    final result = await _service.triggerSOS(
      type: scenario.type,
      customMessage: scenario.formalSMSMessage,
    );

    if (mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isSending = false;
        _activeSendIndex = null;
        _statusIsSuccess = result.success;
        _statusMessage = result.success
            ? (PlatformHelper.isMobile
                ? 'Alert dispatched to ${result.sentCount} contact${result.sentCount == 1 ? '' : 's'}. Help is on the way.'
                : 'Contact panel open — tap WhatsApp or Call to send your alert.')
            : result.reason;
      });
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _statusMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final t         = _T(isDark);
    final w         = MediaQuery.of(context).size.width;
    final isDesktop = w > 1100;
    final isTablet  = w > 700 && w <= 1100;
    final hPad      = isDesktop ? 100.0 : (isTablet ? 56.0 : 20.0);

    return Scaffold(
      backgroundColor: t.scaffold,
      body: Stack(children: [

        // ── Ambient glow ─────────────────────────────────────────
        AnimatedBuilder(
          animation: _ambientAnim,
          builder: (_, __) => Stack(children: [
            Positioned(
              top: -200, left: w * 0.05,
              child: _GlowBlob(
                color: _kCrimson.withOpacity(isDark
                    ? (_isSending ? 0.22 : 0.09) + _ambientAnim.value * 0.05
                    : (_isSending ? 0.08 : 0.03) + _ambientAnim.value * 0.015),
                size: 600,
              ),
            ),
            Positioned(
              bottom: -250, right: -80,
              child: _GlowBlob(
                color: _kViolet.withOpacity(isDark
                    ? 0.07 + _ambientAnim.value * 0.03
                    : 0.025 + _ambientAnim.value * 0.01),
                size: 450,
              ),
            ),
          ]),
        ),

        Positioned.fill(child: CustomPaint(painter: _GridPainter(t: t))),

        SafeArea(
          child: Column(children: [
            GlobalNavbar(
              toggleTheme: widget.toggleTheme,
              setLocale: widget.setLocale,
              activeRoute: 'emergency',
            ),
            Expanded(
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 60),
                    physics: const BouncingScrollPhysics(),
                    child: isDesktop
                        ? _buildDesktopLayout(t, w)
                        : _buildMobileLayout(t, isTablet),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Layouts ──────────────────────────────────────────────────

  Widget _buildDesktopLayout(_T t, double w) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Left column
      Expanded(
        flex: 4,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHero(t),
          const SizedBox(height: 28),
          if (_autoDetectedScenario != null) ...[
            _buildAutoDetectBanner(t),
            const SizedBox(height: 20),
          ],
          if (_statusMessage != null) ...[
            _buildStatusBar(t),
            const SizedBox(height: 20),
          ],
          if (!_service.hasContacts) ...[
            _buildNoContactsBanner(t),
            const SizedBox(height: 20),
          ],
          _buildInfoRow(t),
          const SizedBox(height: 20),
          if (PlatformHelper.supportsShake) _buildShakeCard(t),
          const SizedBox(height: 16),
          _buildContactsButton(t),
        ]),
      ),
      const SizedBox(width: 36),
      // Right column — scenarios
      Expanded(
        flex: 6,
        child: _buildScenariosGrid(t, twoColumns: true),
      ),
    ]);
  }

  Widget _buildMobileLayout(_T t, bool isTablet) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildHero(t),
      const SizedBox(height: 24),
      if (_autoDetectedScenario != null) ...[
        _buildAutoDetectBanner(t),
        const SizedBox(height: 16),
      ],
      if (_statusMessage != null) ...[
        _buildStatusBar(t),
        const SizedBox(height: 16),
      ],
      if (!_service.hasContacts) ...[
        _buildNoContactsBanner(t),
        const SizedBox(height: 16),
      ],
      _buildScenariosGrid(t, twoColumns: isTablet),
      const SizedBox(height: 20),
      _buildInfoRow(t),
      const SizedBox(height: 16),
      if (PlatformHelper.supportsShake) ...[
        _buildShakeCard(t),
        const SizedBox(height: 14),
      ],
      _buildContactsButton(t),
    ]);
  }

  // ── Hero section ─────────────────────────────────────────────

  Widget _buildHero(_T t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Live badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: _kCrimson.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kCrimson.withOpacity(0.22)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kCrimsonSoft,
                boxShadow: [BoxShadow(
                  color: _kCrimsonSoft.withOpacity(_pulseAnim.value * 0.85),
                  blurRadius: 8, spreadRadius: 1,
                )],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            PlatformHelper.isMobile
                ? 'LIVE — SHAKE OR TAP ANY BUTTON'
                : 'EMERGENCY SOS — TAP TO ALERT',
            style: const TextStyle(
              color: _kCrimsonSoft, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.6,
            ),
          ),
        ]),
      ),

      const SizedBox(height: 18),

      Text(
        'Emergency\nAlert Centre',
        style: TextStyle(
          color: t.textPri, fontSize: 44,
          fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -2.0,
        ),
      ),

      const SizedBox(height: 12),

      Text(
        'Select the type of emergency below. A formal alert with your GPS location will be sent instantly to all your emergency contacts.',
        style: TextStyle(
          color: t.textSec, fontSize: 13, height: 1.75, letterSpacing: 0.1,
        ),
      ),
    ]);
  }

  // ── Auto-detect banner (when navigated from TranslateScreen) ──

  Widget _buildAutoDetectBanner(_T t) {
    final s = _autoDetectedScenario!;
    return GestureDetector(
      onTap: () => _triggerSOS(_kScenarios.indexOf(s)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: s.color.withOpacity(t.d ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.color.withOpacity(0.35), width: 1.5),
          boxShadow: [BoxShadow(
            color: s.color.withOpacity(t.d ? 0.15 : 0.08),
            blurRadius: 20, offset: const Offset(0, 6),
          )],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.color.withOpacity(0.3)),
            ),
            child: Center(child: Text(s.icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'ISL Sign Detected: "${widget.detectedSign}"',
              style: TextStyle(color: s.soft, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            const SizedBox(height: 3),
            Text(
              'Suggested: ${s.title} — Tap here to send this alert immediately',
              style: TextStyle(color: t.textPri, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ])),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_forward_rounded, color: s.soft, size: 16),
          ),
        ]),
      ),
    );
  }

  // ── Status bar ───────────────────────────────────────────────

  Widget _buildStatusBar(_T t) {
    final color = _statusIsSuccess ? _kGreen : _kCrimsonSoft;
    final icon  = _statusIsSuccess
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(t.d ? 0.07 : 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(_statusMessage!,
              style: TextStyle(color: color, fontSize: 13,
                  fontWeight: FontWeight.w600, height: 1.4))),
        ]),
      ),
    );
  }

  // ── No contacts banner ───────────────────────────────────────

  Widget _buildNoContactsBanner(_T t) {
    return GestureDetector(
      onTap: () => Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, a, __) => EmergencySetupScreen(
            toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kAmber.withOpacity(t.d ? 0.06 : 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kAmber.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: _kAmber, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('No emergency contacts configured',
                style: TextStyle(color: _kAmber, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('SOS alerts cannot be sent without contacts. Tap here to add them.',
                style: TextStyle(color: _kAmber.withOpacity(0.75), fontSize: 11, height: 1.4)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: _kAmber, size: 12),
        ]),
      ),
    );
  }

  // ── Scenarios grid ───────────────────────────────────────────

  Widget _buildScenariosGrid(_T t, {required bool twoColumns}) {
    if (twoColumns) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: _kScenarios.asMap().entries.map((e) =>
            _ScenarioCard(
              scenario: e.value,
              index: e.key,
              t: t,
              pulseAnim: _pulseAnim,
              isSending:  _isSending && _activeSendIndex == e.key,
              isDisabled: _isSending && _activeSendIndex != e.key,
              isAutoDetected: _autoDetectedScenario == e.value,
              onTap: () => _triggerSOS(e.key),
            )).toList(),
      );
    }

    return Column(
      children: _kScenarios.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ScenarioCard(
          scenario: e.value,
          index: e.key,
          t: t,
          pulseAnim: _pulseAnim,
          isSending:  _isSending && _activeSendIndex == e.key,
          isDisabled: _isSending && _activeSendIndex != e.key,
          isAutoDetected: _autoDetectedScenario == e.value,
          onTap: () => _triggerSOS(e.key),
        ),
      )).toList(),
    );
  }

  // ── Info row (helplines) ─────────────────────────────────────

  Widget _buildInfoRow(_T t) {
    final items = [
      ('112', 'National\nEmergency', _kCrimson),
      ('108', 'Ambulance', _kOrange),
      ('100', 'Police', _kBlue),
      ('101', 'Fire', _kAmber),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceUp,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick helpline reference',
            style: TextStyle(
              color: t.textSec, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.0,
            )),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.map((item) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: item == items.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: item.$3.withOpacity(t.d ? 0.07 : 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.$3.withOpacity(0.18)),
              ),
              child: Column(children: [
                Text(item.$1,
                    style: TextStyle(
                      color: item.$3,
                      fontSize: 16, fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(height: 2),
                Text(item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: t.textSec, fontSize: 9, height: 1.3,
                    )),
              ]),
            ),
          )).toList(),
        ),
      ]),
    );
  }

  // ── Shake card ───────────────────────────────────────────────

  Widget _buildShakeCard(_T t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceUp,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _kViolet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: _kViolet.withOpacity(0.15 + _pulseAnim.value * 0.15)),
            ),
            child: const Center(child: Text('📳', style: TextStyle(fontSize: 20))),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Shake to send "I Need Help"',
              style: TextStyle(color: t.textPri, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            'Works from any screen — shake the phone twice to instantly send a General Help alert to all contacts.',
            style: TextStyle(color: t.textSec, fontSize: 11, height: 1.5),
          ),
        ])),
      ]),
    );
  }

  // ── Contacts button ──────────────────────────────────────────

  Widget _buildContactsButton(_T t) {
    final count = _service.contactCount;
    return GestureDetector(
      onTap: () => Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, a, __) => EmergencySetupScreen(
            toggleTheme: widget.toggleTheme, setLocale: widget.setLocale),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      )),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: t.surfaceUp,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: _kViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.contacts_rounded, color: _kVioletLight, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(
            count > 0
                ? '$count emergency contact${count == 1 ? '' : 's'} configured'
                : 'Set up emergency contacts',
            style: TextStyle(color: t.textSec, fontSize: 13, fontWeight: FontWeight.w600),
          )),
          Icon(Icons.arrow_forward_ios_rounded, color: t.textMuted, size: 12),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  SCENARIO CARD
// ════════════════════════════════════════════════════════════════

class _ScenarioCard extends StatefulWidget {
  final _SOSScenario scenario;
  final int index;
  final _T t;
  final Animation<double> pulseAnim;
  final bool isSending, isDisabled, isAutoDetected;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario, required this.index, required this.t,
    required this.pulseAnim,
    required this.isSending, required this.isDisabled,
    required this.isAutoDetected, required this.onTap,
  });

  @override
  State<_ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<_ScenarioCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _hoverAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _hoverAnim = CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _hoverCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s  = widget.scenario;
    final t  = widget.t;
    final c  = s.color;
    final sc = s.soft;

    return MouseRegion(
      onEnter: (_) { if (!widget.isDisabled) _hoverCtrl.forward(); },
      onExit:  (_) => _hoverCtrl.reverse(),
      child: GestureDetector(
        onTapDown:   (_) { if (!widget.isDisabled) setState(() => _pressed = true); },
        onTapUp:     (_) { setState(() => _pressed = false); if (!widget.isDisabled) widget.onTap(); },
        onTapCancel: ()  { setState(() => _pressed = false); },
        child: AnimatedBuilder(
          animation: _hoverAnim,
          builder: (_, __) {
            final hv = _hoverAnim.value;
            return AnimatedScale(
              scale: _pressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 90),
              child: AnimatedOpacity(
                opacity: widget.isDisabled ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      t.surfaceUp,
                      c.withOpacity(t.d ? 0.13 : 0.07),
                      widget.isAutoDetected ? 0.6 : (widget.isSending ? 1.0 : hv),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.withOpacity(
                          widget.isSending || widget.isAutoDetected
                              ? 0.6
                              : (0.18 + hv * 0.3)),
                      width: (widget.isSending || widget.isAutoDetected) ? 1.5 : 1.0,
                    ),
                    boxShadow: [BoxShadow(
                      color: c.withOpacity(
                          widget.isSending ? (t.d ? 0.28 : 0.14)
                          : widget.isAutoDetected ? (t.d ? 0.18 : 0.08)
                          : hv * (t.d ? 0.12 : 0.06)),
                      blurRadius: widget.isSending ? 32 : 20,
                      offset: const Offset(0, 6),
                    )],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      // Top row: icon + status indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: c.withOpacity(t.d ? 0.12 : 0.08),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                  color: c.withOpacity(0.2 + hv * 0.2)),
                            ),
                            child: Center(child: widget.isSending
                                ? SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: sc))
                                : Text(s.icon,
                                    style: const TextStyle(fontSize: 22))),
                          ),

                          // Helpline badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.withOpacity(t.d ? 0.1 : 0.07),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: c.withOpacity(0.2)),
                            ),
                            child: Text(
                              s.helplineNumber,
                              style: TextStyle(
                                color: sc, fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Title
                      Text(
                        widget.isSending ? 'Sending alert...' : s.title,
                        style: TextStyle(
                          color: widget.isSending ? sc : t.textPri,
                          fontSize: 14, fontWeight: FontWeight.w800,
                          letterSpacing: -0.3, height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        widget.isSending
                            ? 'Contacting ${_service.contactCount} person${_service.contactCount == 1 ? '' : 's'}...'
                            : s.subtitle,
                        style: TextStyle(
                          color: widget.isSending
                              ? sc.withOpacity(0.7)
                              : t.textSec,
                          fontSize: 10, height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // ISL sign label (shown when auto-detected or on hover)
                      if (widget.isAutoDetected || hv > 0.3) ...[
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          opacity: widget.isAutoDetected ? 1.0 : hv,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              s.signDescription,
                              style: TextStyle(
                                color: sc.withOpacity(0.8),
                                fontSize: 9, fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  EmergencyService get _service => EmergencyService.instance;
}

// ════════════════════════════════════════════════════════════════
//  BACKGROUND HELPERS
// ════════════════════════════════════════════════════════════════

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 130, sigmaY: 130),
      child: const SizedBox.expand(),
    ),
  );
}

class _GridPainter extends CustomPainter {
  final _T t;
  const _GridPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = t.gridLine..strokeWidth = 0.5;
    const step = 52.0;
    for (double x = 0; x < size.width;  x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    final dp = Paint()
      ..color = _kCrimson.withOpacity(t.d ? 0.035 : 0.02);
    for (double x = 0; x < size.width;  x += step)
      for (double y = 0; y < size.height; y += step)
        canvas.drawCircle(Offset(x, y), 0.9, dp);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.t.d != t.d;
}