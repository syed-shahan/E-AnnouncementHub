// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  /// Post announcement - client-side guard plus server rules will also be used.
  static Future<void> postAnnouncement({
    required String posterUid,
    required String posterRole,
    required String title,
    required String body,
    required String priority, // 'normal','hod','principal','important'
  }) async {
    // Client-side guard: role -> allowed priorities (updated per your request)
    final allowed = _isPriorityAllowedForRole(role: posterRole, priority: priority);
    if (!allowed) throw Exception('Your role "$posterRole" cannot post priority "$priority"');

    final data = {
      'title': title,
      'body': body,
      'priority': priority,
      'posterUid': posterUid,
      'posterRole': posterRole,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _db.collection('announcements').add(data);
  }

  // Updated role logic: principal & hod allowed to post 'important' now
  static bool _isPriorityAllowedForRole({required String role, required String priority}) {
    if (role == 'admin') return true;
    if (role == 'principal') return ['normal', 'hod', 'principal', 'important'].contains(priority);
    if (role == 'hod') return ['normal', 'hod', 'important'].contains(priority);
    if (role == 'staff') return ['normal'].contains(priority);
    return false;
  }

  // Pending email + approve helpers (unchanged)
  static Future<void> addPendingEmail(String email) {
    final id = _db.collection('pending_emails').doc().id;
    return _db.collection('pending_emails').doc(id).set({
      'email': email.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> approveEmail(String docId, Map<String, dynamic> data) async {
    final batch = _db.batch();
    final approvedRef = _db.collection('approved_email_list').doc();
    batch.set(approvedRef, {...data, 'approvedAt': FieldValue.serverTimestamp()});
    batch.delete(_db.collection('pending_emails').doc(docId));
    await batch.commit();
  }

  static Future<void> createAdminCreatedUserDoc({
    required String uid,
    required String email,
    required String role, // 'staff','hod','principal'
  }) {
    final ref = _db.collection('admin_created_users').doc(uid);
    return ref.set({'uid': uid, 'email': email.toLowerCase(), 'role': role});
  }

  static Future<DocumentSnapshot> getAdminCreatedUserDoc(String uid) {
    return _db.collection('admin_created_users').doc(uid).get();
  }
}
