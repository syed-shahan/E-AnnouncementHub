import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_announcement_screen.dart';
import 'email_collection_screen.dart';

class AnnouncementHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Announcements"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => EmailScreen()),
              );
            },
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PostAnnouncement()));
        },
        child: Icon(Icons.add),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("announcements").orderBy("time", descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());

          return ListView(
            children: snap.data!.docs.map((doc) {
              return Card(
                child: ListTile(
                  title: Text(doc["title"]),
                  subtitle: Text(doc["desc"]),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
