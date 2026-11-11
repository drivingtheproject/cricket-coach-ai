class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  factory User.fromRow(Map<String, Object?> row) => User(
        id: row['id']! as String,
        email: row['email']! as String,
        displayName: row['display_name']! as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      );

  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  /// First word of the display name, for greetings.
  String get firstName => displayName.trim().split(RegExp(r'\s+')).first;
}
