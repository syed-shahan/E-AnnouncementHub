import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../widgets/branded_scaffold.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({Key? key}) : super(key: key);

  static final DateFormat _dtFmt = DateFormat('dd MMM yyyy, hh:mm a');

  Stream<QuerySnapshot<Map<String, dynamic>>> _announcementsStream() {
    // Fetch by createdAt only; we'll filter archived in Dart to avoid composite index.
    return FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  int _roleRank(String? role) {
    switch (role) {
      case 'admin':
        return 1;
      case 'principal':
        return 2;
      case 'hod':
        return 3;
      default:
        return 4; // staff / others
    }
  }

  bool _isPinnedImportant(
    Map<String, dynamic> data,
    DateTime now,
  ) {
    // Old helper (no longer used for sorting, but kept untouched).
    final dynamic priorityRaw = data['priority'] ?? 'normal';
    final String priority =
        priorityRaw is String ? priorityRaw : priorityRaw.toString();

    return priority == 'important';
  }

  DateTime _createdAtOrEpoch(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    if (ts is Timestamp) return ts.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _hasValidCreatedAt(Map<String, dynamic> data) {
    return data['createdAt'] is Timestamp;
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      title: 'Public Announcements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row with Archive & Login buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/archive');
                },
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Login'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Latest Announcements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _announcementsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading announcements',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                // 🔹 DEBUG + safety
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('No announcements yet'),
                  );
                }

                print('RAW DOC COUNT: ${snapshot.data!.docs.length}');
                for (final d in snapshot.data!.docs) {
                  print('DOC ${d.id} => ${d.data()}');
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No announcements yet'),
                  );
                }

                final now = DateTime.now();

                // Filter out archived here (no composite index needed)
                final allActiveDocs = snapshot.data!.docs
                    .where((doc) {
                      final data = doc.data();
                      return data['archived'] != true;
                    })
                    .toList();

                if (allActiveDocs.isEmpty) {
                  return const Center(
                    child: Text('No announcements yet'),
                  );
                }

                // --- ARCHIVE LOGIC ---
                // We ONLY archive docs that already have a valid createdAt Timestamp.
                final archivableDocs = allActiveDocs
                    .where((d) => _hasValidCreatedAt(d.data()))
                    .toList();

                // If there are 8 or fewer archivable docs, do NOT archive anything.
                if (archivableDocs.length > 8) {
                  archivableDocs.sort((a, b) {
                    final ad = a.data();
                    final bd = b.data();
                    final aTime = _createdAtOrEpoch(ad);
                    final bTime = _createdAtOrEpoch(bd);
                    // Newer first
                    return bTime.compareTo(aTime);
                  });

                  // 8 newest by time stay on home; rest get archived.
                  final keepTopArchivable = archivableDocs.take(8).toList();
                  final keepIds = keepTopArchivable.map((d) => d.id).toSet();

                  final overflowDocs = archivableDocs
                      .where((d) => !keepIds.contains(d.id))
                      .toList();

                  // Fire-and-forget: mark overflow (oldest) as archived
                  for (final d in overflowDocs) {
                    FirebaseFirestore.instance
                        .collection('announcements')
                        .doc(d.id)
                        .update({
                      'archived': true,
                      'archivedAt': FieldValue.serverTimestamp(),
                    }).catchError((_) {
                      // Ignore archive errors on UI side
                    });
                  }
                }

                // --------- WHAT WE SHOW ON HOME (max ~8) ----------
                //  - All unarchived with valid createdAt that are among the newest 8 (decided above)
                //  - PLUS any unarchived docs that still don't have createdAt yet (never auto-archived)
                final validActiveDocs = allActiveDocs
                    .where((d) => _hasValidCreatedAt(d.data()))
                    .toList();

                validActiveDocs.sort((a, b) {
                  final ad = a.data();
                  final bd = b.data();
                  final aTime = _createdAtOrEpoch(ad);
                  final bTime = _createdAtOrEpoch(bd);
                  return bTime.compareTo(aTime);
                });

                final newestValid = validActiveDocs.take(8).toList();
                final noTimestampDocs = allActiveDocs
                    .where((d) => !_hasValidCreatedAt(d.data()))
                    .toList();

                // Combine: priority is docs with timestamps (up to 8),
                // plus any without timestamp (usually very few, just posted).
                final combinedVisible =
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[
                  ...newestValid,
                  ...noTimestampDocs,
                ];

                // If somehow more than 8, keep the first 8 of this combined list.
                final visibleDocs = combinedVisible.take(8).toList();

                if (visibleDocs.isEmpty) {
                  return const Center(
                    child: Text('No announcements yet'),
                  );
                }

                // ---------- NEW PRIORITY + TIME LOGIC PRECOMPUTE ----------
                // We need to know:
                //  - newest createdAt overall (to detect “empty slot” for repeated)
                //  - whether we have any active repeated (≤ 48 hours)
                DateTime newestCreatedAt =
                    DateTime.fromMillisecondsSinceEpoch(0);
                bool hasAnyCreatedAt = false;
                bool hasActiveRepeated = false;

                for (final doc in visibleDocs) {
                  final data = doc.data();
                  final ts = data['createdAt'];
                  if (ts is Timestamp) {
                    final dt = ts.toDate();
                    if (!hasAnyCreatedAt || dt.isAfter(newestCreatedAt)) {
                      newestCreatedAt = dt;
                      hasAnyCreatedAt = true;
                    }

                    final dynamic prRaw = data['priority'] ?? 'normal';
                    final String pr = prRaw is String
                        ? prRaw.toLowerCase()
                        : prRaw.toString().toLowerCase();

                    if (pr == 'repeated') {
                      final diff = now.difference(dt);
                      if (diff <= const Duration(hours: 48)) {
                        hasActiveRepeated = true;
                      }
                    }
                  }
                }

                bool slotEmptyForRepeat = false;
                if (hasAnyCreatedAt) {
                  final diff = now.difference(newestCreatedAt);
                  // If no new announcements for >4 hours → slot is “empty”
                  slotEmptyForRepeat = diff > const Duration(hours: 4);
                }

                final bool repeatedPinnedMode =
                    slotEmptyForRepeat && hasActiveRepeated;

                // ---------- DISPLAY ORDER WITH TIME WINDOWS ----------
                //
                // Rules:
                // 1) Important:
                //    - Pinned at top for 8 hours from createdAt.
                //    - After 8h behaves like normal (still labeled IMPORTANT).
                //
                // 2) Normal from admin/principal/hod:
                //    - Pinned (just under active important) for 4 hours.
                //    - Any important (within 8h) overrides them.
                //
                // 3) Repeated:
                //    - If there is an “empty slot” (no announcement of any type in last 4 hours)
                //      AND the repeated is ≤ 48h old → it forms a pinned block (under important & high-role normals).
                //    - If any new announcement is posted, the slot is no longer empty → repeated behaves like normal.
                //
                // 4) After their windows, everything is sorted by createdAt desc.

                visibleDocs.sort((a, b) {
                  final ad = a.data();
                  final bd = b.data();

                  final aTime = _createdAtOrEpoch(ad);
                  final bTime = _createdAtOrEpoch(bd);

                  // Priority strings
                  String _prio(Map<String, dynamic> d) {
                    final raw = d['priority'] ?? 'normal';
                    return raw is String
                        ? raw.toLowerCase()
                        : raw.toString().toLowerCase();
                  }

                  final aPr = _prio(ad);
                  final bPr = _prio(bd);

                  // Role ranks
                  final aRole =
                      (ad['createdByRole'] ?? 'staff').toString().toLowerCase();
                  final bRole =
                      (bd['createdByRole'] ?? 'staff').toString().toLowerCase();
                  final aRank = _roleRank(aRole);
                  final bRank = _roleRank(bRole);

                  Duration diffA = now.difference(aTime);
                  Duration diffB = now.difference(bTime);

                  bool aImportantActive =
                      aPr == 'important' && diffA <= const Duration(hours: 8);
                  bool bImportantActive =
                      bPr == 'important' && diffB <= const Duration(hours: 8);

                  // 1) Active important first
                  if (aImportantActive != bImportantActive) {
                    return aImportantActive ? -1 : 1;
                  }

                  // Both actively important: higher role first, then newer
                  if (aImportantActive && bImportantActive) {
                    if (aRank != bRank) {
                      return aRank.compareTo(bRank);
                    }
                    return bTime.compareTo(aTime);
                  }

                  // 2) High-role normals (admin/principal/hod) pinned for 4 hours
                  bool isHighRole(String r) =>
                      r == 'admin' || r == 'principal' || r == 'hod';

                  bool aHighRoleNormalActive = aPr == 'normal' &&
                      isHighRole(aRole) &&
                      diffA <= const Duration(hours: 4);
                  bool bHighRoleNormalActive = bPr == 'normal' &&
                      isHighRole(bRole) &&
                      diffB <= const Duration(hours: 4);

                  if (aHighRoleNormalActive != bHighRoleNormalActive) {
                    return aHighRoleNormalActive ? -1 : 1;
                  }

                  if (aHighRoleNormalActive && bHighRoleNormalActive) {
                    // Among themselves, newer first
                    return bTime.compareTo(aTime);
                  }

                  // 3) Repeated announcements pinned ONLY in "repeatedPinnedMode"
                  bool aRepeatedActive = aPr == 'repeated' &&
                      diffA <= const Duration(hours: 48);
                  bool bRepeatedActive = bPr == 'repeated' &&
                      diffB <= const Duration(hours: 48);

                  bool aRepeatedPinned =
                      repeatedPinnedMode && aRepeatedActive;
                  bool bRepeatedPinned =
                      repeatedPinnedMode && bRepeatedActive;

                  if (aRepeatedPinned != bRepeatedPinned) {
                    return aRepeatedPinned ? -1 : 1;
                  }

                  if (aRepeatedPinned && bRepeatedPinned) {
                    // Among pinned repeated, newer first
                    return bTime.compareTo(aTime);
                  }

                  // 4) Fallback: everything else ordered purely by time (newest first)
                  return bTime.compareTo(aTime);
                });

                // ----- UI for announcements -----
                return ListView.separated(
                  itemCount: visibleDocs.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final data = visibleDocs[index].data();
                    final title = data['title'] ?? '';
                    final body = data['body'] ?? '';

                    final dynamic priorityRaw =
                        data['priority'] ?? 'normal';
                    final String priority = priorityRaw is String
                        ? priorityRaw
                        : priorityRaw.toString();

                    Color badgeColor;
                    String badgeText;
                    String typeLabel;
                    switch (priority) {
                      case 'important':
                        badgeColor = Colors.redAccent;
                        badgeText = 'IMPORTANT';
                        typeLabel = 'Important';
                        break;
                      case 'repeated':
                        badgeColor = Colors.orangeAccent;
                        badgeText = 'REPEATED';
                        typeLabel = 'Repeated';
                        break;
                      default:
                        badgeColor = Colors.blueGrey;
                        badgeText = 'NORMAL';
                        typeLabel = 'Normal';
                    }

                    // New metadata: who + email + role + when
                    final createdBy = ((data['createdByName'] ??
                                data['createdBy'] ??
                                '') as Object)
                            .toString()
                            .trim();
                    final createdByEmail =
                        (data['createdByEmail'] ?? '').toString().trim();
                    final createdByRole =
                        (data['createdByRole'] ?? '').toString().trim();

                    DateTime? createdAt;
                    final ts = data['createdAt'];
                    if (ts is Timestamp) {
                      createdAt = ts.toDate();
                    }

                    final metaParts = <String>[];
                    metaParts.add(typeLabel);
                    if (createdBy.isNotEmpty) {
                      metaParts.add('by $createdBy');
                    }
                    if (createdByEmail.isNotEmpty) {
                      metaParts.add(createdByEmail);
                    }
                    if (createdByRole.isNotEmpty) {
                      metaParts.add(createdByRole);
                    }
                    if (createdAt != null) {
                      metaParts.add(_dtFmt.format(createdAt));
                    }
                    final metaText = metaParts.join('  •  ');

                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              body,
                              style: const TextStyle(fontSize: 14),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}