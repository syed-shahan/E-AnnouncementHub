class AdminCreatedUser {
  final String uid;
  final String email;
  final String role; // 'staff' | 'hod' | 'principal' | 'admin'

  AdminCreatedUser({required this.uid, required this.email, required this.role});

  factory AdminCreatedUser.fromMap(Map<String, dynamic> m) {
    return AdminCreatedUser(uid: m['uid'] ?? '', email: m['email'] ?? '', role: m['role'] ?? 'staff');
  }

  Map<String, dynamic> toMap() => {'uid': uid, 'email': email, 'role': role};
}
