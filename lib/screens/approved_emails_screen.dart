import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovedEmailsScreen extends StatelessWidget {
  approve(id, email) async {
    await FirebaseFirestore.instance.collection("approved_emails").add({"email": email});
    await FirebaseFirestore.instance.collection("pending_emails").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Approve Emails"), backgroundColor: Colors.black),
      backgroundColor: Color(0xff111827),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("pending_emails").snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());

          return ListView(
            children: snap.data!.docs.map<Widget>((d) {
              return Card(
                color: Colors.white10,
                child: ListTile(
                  title: Text(d['email'], style: TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => approve(d.id, d['email']),
                  ),
                ),
              );
            }).toList(),
          );
        }
      ),
    );
  }
}
