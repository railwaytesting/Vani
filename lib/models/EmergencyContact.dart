// lib/models/EmergencyContact.dart
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

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
    this.isPrimary = false,
  });

  // Validates phone: strips spaces/dashes, checks it's numeric + correct length
  bool get isValid {
    final cleaned = cleanedPhone;
    return cleaned.isNotEmpty && cleaned.length >= 10 && cleaned.length <= 15;
  }

  // Returns phone stripped of spaces, dashes, parentheses
  String get cleanedPhone {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  }

  // Returns phone with country code for WhatsApp/SMS deep links
  // Defaults to +91 (India) if no country code present
  String get internationalPhone {
    final cleaned = cleanedPhone;
    if (cleaned.startsWith('91') && cleaned.length == 12) return '+$cleaned';
    if (cleaned.length == 10) return '+91$cleaned';
    return '+$cleaned';
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relation': relation,
        'isPrimary': isPrimary,
      };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) =>
      EmergencyContact(
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        relation: map['relation'] ?? '',
        isPrimary: map['isPrimary'] ?? false,
      );

  @override
  String toString() => 'EmergencyContact(name: $name, phone: $phone, relation: $relation)';
}