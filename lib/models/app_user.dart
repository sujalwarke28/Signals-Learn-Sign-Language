import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  learner,
  admin;

  static UserRole fromName(String? name) =>
      UserRole.values.firstWhere((r) => r.name == name, orElse: () => UserRole.learner);

  bool get isAdmin => this == UserRole.admin;
}

/// The Firestore `users/{uid}` document.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.createdAt,
    this.soundEnabled = true,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime? createdAt;
  final bool soundEnabled;

  bool get isAdmin => role.isAdmin;

  /// First name, or a friendly fallback, for greeting copy.
  String get firstName {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      role: UserRole.fromName(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      soundEnabled: (data['soundEnabled'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'soundEnabled': soundEnabled,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  AppUser copyWith({String? displayName, UserRole? role, bool? soundEnabled}) => AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        createdAt: createdAt,
        soundEnabled: soundEnabled ?? this.soundEnabled,
      );
}
