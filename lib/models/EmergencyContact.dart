// lib/models/EmergencyContact.dart
//
// Added: `supabaseId` field (HiveField 4) — stores the UUID row id from
// the `emergency_contacts` Supabase table so we can update/delete remotely.
// The Hive typeId and all existing fields are unchanged.

import 'package:hive/hive.dart';

part 'EmergencyContact.g.dart';

@HiveType(typeId: 0)
class EmergencyContact extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phone;

  @HiveField(2)
  String relation;

  @HiveField(3)
  bool isPrimary;

  /// Supabase row UUID — null if contact only exists locally (not yet synced).
  @HiveField(4)
  String? supabaseId;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
    this.isPrimary = false,
    this.supabaseId,
  });

  // ── Validation ─────────────────────────────

  bool get isValid {
    final cleaned = cleanedPhone;
    return cleaned.isNotEmpty && cleaned.length >= 10 && cleaned.length <= 15;
  }

  String get cleanedPhone => phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

  /// Returns phone with +91 country code for WhatsApp/SMS deep-links.
  String get internationalPhone {
    final cleaned = cleanedPhone;
    if (cleaned.startsWith('91') && cleaned.length == 12) return '+$cleaned';
    if (cleaned.length == 10) return '+91$cleaned';
    return '+$cleaned';
  }

  // ── Serialisation ──────────────────────────

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'relation': relation,
    'isPrimary': isPrimary,
    'supabaseId': supabaseId,
  };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) =>
      EmergencyContact(
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        relation: map['relation'] ?? '',
        isPrimary: map['isPrimary'] ?? false,
        supabaseId: map['supabaseId'] as String?,
      );

  @override
  String toString() =>
      'EmergencyContact(name: $name, phone: $phone, '
      'relation: $relation, supabaseId: $supabaseId)';
}
