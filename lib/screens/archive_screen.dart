import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  static final DateFormat _dtFmt = DateFormat('dd MMM yyyy, hh:mm a');

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _archiveStream() {
    return FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  String _readString(Map<String, dynamic> data, String key,
      {String fallback = ''}) {
    final value = data[key];
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.86),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 🔹 Same idea as BrandedScaffold – big floating panel
                final double panelWidth = (constraints.maxWidth * 0.9)
                    .clamp(360.0, 1100.0);
                final double panelHeight =
                    (constraints.maxHeight - 32).clamp(300.0, constraints.maxHeight);

                return Center(
                  child: SizedBox(
                    width: panelWidth,
                    height: panelHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(
                                  'assets/logo.png',
                                  height: 34,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Archived Announcements',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Search bar
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by title or email...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide:
                                      const BorderSide(color: Colors.black12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide:
                                      const BorderSide(color: Colors.black12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide:
                                      const BorderSide(color: Colors.blue),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.trim().toLowerCase();
                                });
                              },
                            ),

                            const SizedBox(height: 12),

                            // List
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _archiveStream(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasError) {
                                    return const Center(
                                      child: Text(
                                        'Error loading archive',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Center(
                                      child: Text(
                                          'No archived announcements yet'),
                                    );
                                  }

                                  // Only archived == true
                                  final allArchived =
                                      snapshot.data!.docs.where((doc) {
                                    final raw = doc.data();
                                    final data =
                                        raw is Map<String, dynamic>
                                            ? raw
                                            : <String, dynamic>{};
                                    return data['archived'] == true;
                                  }).toList();

                                  if (allArchived.isEmpty) {
                                    return const Center(
                                      child: Text(
                                          'No archived announcements yet'),
                                    );
                                  }

                                  // Search filter
                                  List<QueryDocumentSnapshot> filteredDocs =
                                      allArchived;

                                  if (_searchQuery.isNotEmpty) {
                                    filteredDocs =
                                        allArchived.where((doc) {
                                      final raw = doc.data();
                                      final Map<String, dynamic> data =
                                          raw is Map<String, dynamic>
                                              ? raw
                                              : <String, dynamic>{};

                                      final title = _readString(
                                              data, 'title')
                                          .toLowerCase();
                                      final email = _readString(
                                              data,
                                              'createdByEmail')
                                          .toLowerCase();

                                      return title.contains(_searchQuery) ||
                                          email.contains(_searchQuery);
                                    }).toList();
                                  }

                                  if (filteredDocs.isEmpty) {
                                    return const Center(
                                      child: Text(
                                          'No matching archived announcements'),
                                    );
                                  }

                                  // Newest on top
                                  filteredDocs.sort((a, b) {
                                    final ar = a.data();
                                    final br = b.data();
                                    final ad = ar is Map<String, dynamic>
                                        ? ar
                                        : <String, dynamic>{};
                                    final bd = br is Map<String, dynamic>
                                        ? br
                                        : <String, dynamic>{};

                                    final aTs = ad['createdAt'];
                                    final bTs = bd['createdAt'];

                                    final aTime = aTs is Timestamp
                                        ? aTs.toDate()
                                        : DateTime
                                            .fromMillisecondsSinceEpoch(0);
                                    final bTime = bTs is Timestamp
                                        ? bTs.toDate()
                                        : DateTime
                                            .fromMillisecondsSinceEpoch(0);

                                    return bTime.compareTo(aTime);
                                  });

                                  return ListView.separated(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 16),
                                    itemCount: filteredDocs.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      try {
                                        final raw =
                                            filteredDocs[index].data();
                                        final Map<String, dynamic> data =
                                            raw is Map<String, dynamic>
                                                ? raw
                                                : <String, dynamic>{};

                                        final title = _readString(
                                                data, 'title')
                                            .trim();
                                        final body = _readString(
                                                data, 'body')
                                            .trim();
                                        final priority = _readString(
                                                data, 'priority',
                                                fallback: 'normal')
                                            .toLowerCase();

                                        final createdBy = (_readString(
                                          data,
                                          'createdByName',
                                          fallback: _readString(
                                              data, 'createdBy',
                                              fallback: ''),
                                        ))
                                            .trim();
                                        final createdByEmail =
                                            _readString(
                                                    data,
                                                    'createdByEmail')
                                                .trim();
                                        final createdByRole =
                                            _readString(
                                                    data,
                                                    'createdByRole')
                                                .trim();

                                        DateTime? createdAt;
                                        final ts = data['createdAt'];
                                        if (ts is Timestamp) {
                                          createdAt = ts.toDate();
                                        }

                                        return _archiveCard(
                                          title: title.isEmpty
                                              ? 'Untitled'
                                              : title,
                                          body: body,
                                          priority: priority,
                                          createdBy: createdBy.isEmpty
                                              ? null
                                              : createdBy,
                                          createdByEmail:
                                              createdByEmail.isEmpty
                                                  ? null
                                                  : createdByEmail,
                                          createdByRole:
                                              createdByRole.isEmpty
                                                  ? null
                                                  : createdByRole,
                                          createdAt: createdAt,
                                        );
                                      } catch (e) {
                                        debugPrint(
                                            'Error building archive card: $e');
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _archiveCard({
    required String title,
    required String body,
    required String priority,
    String? createdBy,
    String? createdByEmail,
    String? createdByRole,
    DateTime? createdAt,
  }) {
    final chipText = priority.toUpperCase();

    String typeLabel;
    switch (priority) {
      case 'important':
        typeLabel = 'Important';
        break;
      case 'repeated':
        typeLabel = 'Repeated';
        break;
      default:
        typeLabel = 'Normal';
    }

    final metaParts = <String>[];
    metaParts.add(typeLabel);
    if (createdBy != null && createdBy.isNotEmpty) {
      metaParts.add('by $createdBy');
    }
    if (createdByEmail != null && createdByEmail.isNotEmpty) {
      metaParts.add(createdByEmail);
    }
    if (createdByRole != null && createdByRole.isNotEmpty) {
      metaParts.add(createdByRole);
    }
    if (createdAt != null) {
      metaParts.add(_dtFmt.format(createdAt));
    }
    final metaText = metaParts.join('  •  ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (metaText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      metaText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              chipText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}