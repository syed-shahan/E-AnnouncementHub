// lib/screens/pending_email_approval_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/branded_scaffold.dart';

class PendingEmailApprovalScreen extends StatelessWidget {
  const PendingEmailApprovalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qs = FirebaseFirestore.instance.collection('pending_emails').orderBy('createdAt', descending: true).snapshots();
    return BrandedScaffold(
      title: 'Pending Emails',
      child: StreamBuilder<QuerySnapshot>(stream: qs, builder: (c, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(12), child: Text('No pending emails')));
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final email = d['email'] ?? '';
              return ListTile(
                title: Text(email),
                trailing: Wrap(spacing: 8, children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('approved_email_list').add({'email': email, 'approvedAt': FieldValue.serverTimestamp()});
                      await FirebaseFirestore.instance.collection('pending_emails').doc(docs[i].id).delete();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance.collection('pending_emails').doc(docs[i].id).delete(),
                  )
                ]),
              );
            },
          ),
        );
      }),
    );
  }
}
