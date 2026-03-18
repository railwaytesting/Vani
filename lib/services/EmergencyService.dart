// lib/services/EmergencyService.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:shake/shake.dart';

import '../models/EmergencyContact.dart';
import '../Utils/PlatformHelper.dart';
import 'LocationService.dart';
import 'package:flutter/services.dart';

// Predefined SOS message types
enum SOSMessageType { generalHelp, medical, police, fire, custom }

extension SOSMessageTypeExt on SOSMessageType {
  String get label {
    switch (this) {
      case SOSMessageType.generalHelp:
        return 'I need help';
      case SOSMessageType.medical:
        return 'Medical emergency';
      case SOSMessageType.police:
        return 'Call police for me';
      case SOSMessageType.fire:
        return 'Fire nearby';
      case SOSMessageType.custom:
        return 'Custom message';
    }
  }

  String get emoji {
    switch (this) {
      case SOSMessageType.generalHelp:
        return '🆘';
      case SOSMessageType.medical:
        return '🏥';
      case SOSMessageType.police:
        return '👮';
      case SOSMessageType.fire:
        return '🔥';
      case SOSMessageType.custom:
        return '📢';
    }
  }

  String get fullMessage {
    switch (this) {
      case SOSMessageType.generalHelp:
        return 'I need immediate help! I am deaf/mute and cannot speak. Please assist me or call someone.';
      case SOSMessageType.medical:
        return 'MEDICAL EMERGENCY! I need an ambulance immediately. I am deaf/mute and cannot call. Please call 108 or help me get medical attention.';
      case SOSMessageType.police:
        return 'I need police assistance urgently. I am deaf/mute and cannot call 100. Please call the police or help me.';
      case SOSMessageType.fire:
        return 'There is a fire nearby! Please call 101 (Fire) or evacuate. I am deaf/mute and cannot call for help.';
      case SOSMessageType.custom:
        return 'Emergency! I need help immediately. I am deaf/mute.';
    }
  }
}

class EmergencyService {
  static EmergencyService? _instance;
  static EmergencyService get instance => _instance ??= EmergencyService._();
  EmergencyService._();

  // Hive box name for contacts
  static const String _boxName = 'emergency_contacts';

  ShakeDetector? _shakeDetector;
  bool _isTriggering = false; // Prevents double-triggers
  BuildContext? _context; // For showing web modals

  // ─────────────────────────────────────────────
  //  INITIALISATION
  // ─────────────────────────────────────────────

  /// Call this in main.dart after Hive is initialised.
  Future<void> init(BuildContext context) async {
    _context = context;
    await _openBox();
    _startShakeDetection();
  }

  /// Update the context when navigating (call from your root widget)
  void updateContext(BuildContext context) {
    _context = context;
  }

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      Hive.registerAdapter(EmergencyContactAdapter());
      await Hive.openBox<EmergencyContact>(_boxName);
    }
  }

  // ─────────────────────────────────────────────
  //  SHAKE DETECTION (mobile only)
  // ─────────────────────────────────────────────

  void _startShakeDetection() {
    if (!PlatformHelper.supportsShake) return;

    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) =>
          _onShakeDetected(), //made change to onPhoneShake from onPhoneShaked
      minimumShakeCount: 2, // Need 2 shakes to avoid accidental triggers
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity:
          2.7, // Sensitivity: higher = harder to trigger accidentally
    );
  }

  void _onShakeDetected() {
    // Only auto-trigger if at least one contact is configured
    final contacts = getContacts();
    if (contacts.isEmpty) return;
    triggerSOS(type: SOSMessageType.generalHelp, triggeredByShake: true);
  }

  void stopShakeDetection() {
    _shakeDetector?.stopListening();
    _shakeDetector = null;
  }

  // ─────────────────────────────────────────────
  //  CONTACT MANAGEMENT
  // ─────────────────────────────────────────────

  Box<EmergencyContact> get _box => Hive.box<EmergencyContact>(_boxName);

  List<EmergencyContact> getContacts() {
    return _box.values.toList();
  }

  Future<void> addContact(EmergencyContact contact) async {
    // Max 5 contacts allowed
    if (_box.length >= 5) {
      throw Exception('Maximum 5 emergency contacts allowed.');
    }
    // Validate phone before saving
    if (!contact.isValid) {
      throw Exception('Invalid phone number: ${contact.phone}');
    }
    // If this is the first contact, make it primary automatically
    if (_box.isEmpty) contact.isPrimary = true;
    await _box.add(contact);
  }

  Future<void> updateContact(int index, EmergencyContact updated) async {
    if (!updated.isValid) {
      throw Exception('Invalid phone number.');
    }
    await _box.putAt(index, updated);
  }

  Future<void> deleteContact(int index) async {
    await _box.deleteAt(index);
    // If primary was deleted and contacts remain, make first one primary
    final remaining = getContacts();
    if (remaining.isNotEmpty && !remaining.any((c) => c.isPrimary)) {
      remaining.first.isPrimary = true;
      await remaining.first.save();
    }
  }

  Future<void> setPrimary(int index) async {
    final contacts = getContacts();
    for (int i = 0; i < contacts.length; i++) {
      contacts[i].isPrimary = (i == index);
      await contacts[i].save();
    }
  }

  bool get hasContacts => _box.isNotEmpty;
  int get contactCount => _box.length;

  // ─────────────────────────────────────────────
  //  CORE SOS TRIGGER
  // ─────────────────────────────────────────────

  /// The main SOS trigger. Call this from panic buttons or shake detection.
  /// Handles all permutations: no contacts, no GPS, mobile, web, desktop.
  Future<SOSResult> triggerSOS({
    required SOSMessageType type,
    String? customMessage,
    bool triggeredByShake = false,
  }) async {
    // Prevent simultaneous double triggers
    if (_isTriggering) {
      return SOSResult(
        success: false,
        reason: 'SOS already in progress',
        platform: PlatformHelper.platformName,
      );
    }
    _isTriggering = true;

    try {
      final contacts = getContacts();
      final message = customMessage ?? type.fullMessage;

      // ── Step 1: Haptic feedback immediately (don't wait for GPS)
      _triggerHaptics();

      // ── Step 2: Get location (with timeout so SOS is never blocked)
      final location = await LocationService.instance.getLocationWithFallback(
        timeout: const Duration(seconds: 5),
      );

      // ── Step 3: Build the full message with location
      final fullMsg = LocationService.instance.buildEmergencyMessage(
        baseMessage: message,
        location: location,
      );

      // ── Step 4: No contacts saved — show guidance modal
      if (contacts.isEmpty) {
        if (_context != null) {
          _showNoContactsDialog(_context!);
        }
        return SOSResult(
          success: false,
          reason: 'No emergency contacts configured',
          platform: PlatformHelper.platformName,
        );
      }

      // ── Step 5: Platform-specific sending
      if (PlatformHelper.isMobile) {
        return await _sendMobileSOS(
          contacts: contacts,
          message: fullMsg,
          location: location,
          type: type,
        );
      } else if (PlatformHelper.isWeb) {
        return await _sendWebSOS(
          contacts: contacts,
          message: fullMsg,
          location: location,
          type: type,
        );
      } else {
        // Desktop — show copy-to-clipboard modal
        if (_context != null) {
          _showDesktopSOSDialog(_context!, fullMsg, contacts);
        }
        return SOSResult(
          success: true,
          reason: 'Desktop SOS dialog shown',
          platform: PlatformHelper.platformName,
        );
      }
    } finally {
      // Reset trigger lock after a delay to prevent rapid re-triggers
      await Future.delayed(const Duration(seconds: 3));
      _isTriggering = false;
    }
  }

  // ─────────────────────────────────────────────
  //  MOBILE SOS (Android / iOS)
  // ─────────────────────────────────────────────

  Future<SOSResult> _sendMobileSOS({
    required List<EmergencyContact> contacts,
    required String message,
    required LocationResult location,
    required SOSMessageType type,
  }) async {
    int sent = 0;
    final List<String> errors = [];

    for (final contact in contacts) {
      if (!contact.isValid) {
        errors.add('Skipped ${contact.name}: invalid number');
        continue;
      }

      // Try SMS first
      final smsUri = Uri(
        scheme: 'sms',
        path: contact.internationalPhone,
        queryParameters: {'body': message},
      );

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          sent++;
        } else {
          // SMS failed — try WhatsApp as fallback
          final waFallback = _buildWhatsAppUrl(
            contact.internationalPhone,
            message,
          );
          final waUri = Uri.parse(waFallback);
          if (await canLaunchUrl(waUri)) {
            await launchUrl(waUri, mode: LaunchMode.externalApplication);
            sent++;
          } else {
            errors.add('Could not reach ${contact.name}');
          }
        }
      } catch (e) {
        errors.add('Error for ${contact.name}: $e');
      }

      // Brief delay between SMS launches on mobile to avoid OS throttling
      if (contacts.indexOf(contact) < contacts.length - 1) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    return SOSResult(
      success: sent > 0,
      sentCount: sent,
      totalContacts: contacts.length,
      errors: errors,
      reason: sent > 0 ? 'SMS sent to $sent contacts' : 'Failed to send SMS',
      platform: PlatformHelper.platformName,
    );
  }

  // ─────────────────────────────────────────────
  //  WEB SOS (Browser)
  // ─────────────────────────────────────────────

  // Web can't auto-send SMS. Best strategy:
  // 1. Show a modal with per-contact WhatsApp + tel links
  // 2. Show the full message pre-written so user can copy-paste
  // 3. Show a mailto link as final fallback
  Future<SOSResult> _sendWebSOS({
    required List<EmergencyContact> contacts,
    required String message,
    required LocationResult location,
    required SOSMessageType type,
  }) async {
    if (_context == null) {
      return SOSResult(
        success: false,
        reason: 'No context for web modal',
        platform: PlatformHelper.platformName,
      );
    }

    // Show the web SOS modal — this is the primary mechanism on web
    _showWebSOSModal(
      context: _context!,
      contacts: contacts,
      message: message,
      location: location,
      type: type,
    );

    // Try to auto-open WhatsApp for the primary contact
    final primary = contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => contacts.first,
    );

    try {
      final waUrl = _buildWhatsAppUrl(primary.internationalPhone, message);
      final uri = Uri.parse(waUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // WhatsApp not available — modal handles it
    }

    return SOSResult(
      success: true,
      reason: 'Web SOS modal shown',
      platform: PlatformHelper.platformName,
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  String _buildWhatsAppUrl(String phone, String message) {
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$phone?text=$encoded';
  }

  void _triggerHaptics() {
    if (!PlatformHelper.canVibrate) return;
    try {
      Vibration.vibrate(
        pattern: [0, 400, 200, 400, 200, 800], // SOS-like pattern
        intensities: [0, 255, 0, 255, 0, 255],
      );
    } catch (_) {
      // Vibration not available — silently ignore
    }
  }

  // ─────────────────────────────────────────────
  //  DIALOGS
  // ─────────────────────────────────────────────

  void _showNoContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text(
              'No contacts saved',
              style: TextStyle(
                color: Color(0xFFF0EEFF),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'You have not saved any emergency contacts yet.\n\nPlease go to Emergency Settings and add at least one contact.',
          style: TextStyle(color: Color(0xFF7A7A9A), height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  void _showDesktopSOSDialog(
    BuildContext context,
    String message,
    List<EmergencyContact> contacts,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🆘 Emergency Message',
          style: TextStyle(
            color: Color(0xFFF0EEFF),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copy this message and send to:',
              style: TextStyle(color: Color(0xFF7A7A9A)),
            ),
            const SizedBox(height: 8),
            ...contacts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${c.name}: ${c.phone}',
                  style: const TextStyle(color: Color(0xFFA78BFA)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(
                  color: Color(0xFFF0EEFF),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }

  void _showWebSOSModal({
    required BuildContext context,
    required List<EmergencyContact> contacts,
    required String message,
    required LocationResult location,
    required SOSMessageType type,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WebSOSModal(
        contacts: contacts,
        message: message,
        location: location,
        type: type,
        onClose: () => Navigator.pop(ctx),
        buildWhatsApp: _buildWhatsAppUrl,
      ),
    );
  }

  void dispose() {
    stopShakeDetection();
  }
}

// ─────────────────────────────────────────────
//  SOS RESULT
// ─────────────────────────────────────────────

class SOSResult {
  final bool success;
  final String reason;
  final String platform;
  final int sentCount;
  final int totalContacts;
  final List<String> errors;

  const SOSResult({
    required this.success,
    required this.reason,
    required this.platform,
    this.sentCount = 0,
    this.totalContacts = 0,
    this.errors = const [],
  });

  @override
  String toString() =>
      'SOSResult(success: $success, sent: $sentCount/$totalContacts, reason: $reason, platform: $platform)';
}

// ─────────────────────────────────────────────
//  WEB SOS MODAL WIDGET
// ─────────────────────────────────────────────

class _WebSOSModal extends StatefulWidget {
  final List<EmergencyContact> contacts;
  final String message;
  final LocationResult location;
  final SOSMessageType type;
  final VoidCallback onClose;
  final String Function(String, String) buildWhatsApp;

  const _WebSOSModal({
    required this.contacts,
    required this.message,
    required this.location,
    required this.type,
    required this.onClose,
    required this.buildWhatsApp,
  });

  @override
  State<_WebSOSModal> createState() => _WebSOSModalState();
}

class _WebSOSModalState extends State<_WebSOSModal> {
  bool _messageCopied = false;

  Future<void> _openWhatsApp(EmergencyContact contact) async {
    final url = widget.buildWhatsApp(
      contact.internationalPhone,
      widget.message,
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTel(EmergencyContact contact) async {
    final uri = Uri(scheme: 'tel', path: contact.internationalPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openEmail(EmergencyContact contact) async {
    final subject = Uri.encodeComponent('EMERGENCY - Needs Help');
    final body = Uri.encodeComponent(widget.message);
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message));
    setState(() => _messageCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _messageCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C0C14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🆘', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency SOS Activated',
                        style: TextStyle(
                          color: Color(0xFFF0EEFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.type.label,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Location status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.location.isAvailable
                    ? const Color(0xFF059669).withOpacity(0.12)
                    : const Color(0xFFD97706).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    widget.location.isAvailable ? '📍' : '⚠️',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.location.isAvailable
                          ? 'Location attached: ${widget.location.displayString}'
                          : 'Location unavailable — message sent without coordinates',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.location.isAvailable
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contact buttons
            const Text(
              'Send to your emergency contacts:',
              style: TextStyle(
                color: Color(0xFF7A7A9A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            ...widget.contacts.map(
              (contact) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121220),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2E2E48)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            color: Color(0xFFF0EEFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            contact.relation,
                            style: const TextStyle(
                              color: Color(0xFFA78BFA),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (contact.isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // WhatsApp button
                        Expanded(
                          child: _WebContactButton(
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () => _openWhatsApp(contact),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Call button
                        Expanded(
                          child: _WebContactButton(
                            label: 'Call',
                            color: const Color(0xFF0284C7),
                            onTap: () => _openTel(contact),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Copy message button
            GestureDetector(
              onTap: _copyMessage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _messageCopied
                      ? const Color(0xFF059669).withOpacity(0.15)
                      : const Color(0xFF1E1E30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _messageCopied
                        ? const Color(0xFF059669).withOpacity(0.4)
                        : const Color(0xFF2E2E48),
                  ),
                ),
                child: Text(
                  _messageCopied
                      ? '✓ Message copied!'
                      : '📋 Copy emergency message',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _messageCopied
                        ? const Color(0xFF059669)
                        : const Color(0xFF7A7A9A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dismiss
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onClose,
                child: const Text(
                  'I am safe now — Close',
                  style: TextStyle(color: Color(0xFF7A7A9A)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebContactButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _WebContactButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
