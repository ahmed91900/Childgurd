import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../../family/data/family_repository.dart';
import '../../family/domain/family.dart';

const firebaseConfig = String.fromEnvironment('FIREBASE_CONFIG');
final cloudProvider = ChangeNotifierProvider(
  (ref) => CloudSync(ref.read(familyProvider)),
);

class CloudSync extends ChangeNotifier {
  CloudSync(this.local) {
    local.addListener(_localChanged);
  }
  final FamilyRepository local;
  bool initialized = false, working = false;
  bool get configured => firebaseConfig.isNotEmpty;
  String role = '', familyId = '', childId = '';
  String? error;
  Map<String, dynamic> ads = {};
  String? pendingMedia, pendingMediaOwner;
  Future<String> uploadMedia() async {
    final path = pendingMedia, uid = auth.currentUser?.uid;
    if (path == null || uid == null || uid != pendingMediaOwner) {
      throw StateError('Select media first');
    }
    final file = File(path);
    if (await file.length() > 20 * 1024 * 1024) {
      throw StateError('Media too large');
    }
    final ext = path.split('.').last.toLowerCase();
    final type = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
    }[ext];
    if (type == null) throw StateError('Unsupported media');
    final ref = FirebaseStorage.instance.ref(
      'advertising/${uid}_${DateTime.now().microsecondsSinceEpoch}.$ext',
    );
    await ref.putFile(
      file,
      SettableMetadata(contentType: type, customMetadata: {'owner': uid}),
    );
    final url = await ref.getDownloadURL();
    pendingMedia = null;
    pendingMediaOwner = null;
    return url;
  }

  final _subscriptions = <StreamSubscription<dynamic>>[];
  Timer? _debounce, _retry;
  int _session = 0;
  bool _receiving = false;
  bool get synchronizing => working || _receiving;
  bool _dirty = false;
  Future<void>? _initializing;
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get db => FirebaseFirestore.instance;
  FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (initialized || !configured) return;
    final j = jsonDecode(firebaseConfig) as Map<String, dynamic>;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: j['apiKey'] as String,
        appId: j['appId'] as String,
        messagingSenderId: j['messagingSenderId'] as String,
        projectId: j['projectId'] as String,
        storageBucket: j['storageBucket'] as String?,
      ),
    );
    initialized = true;
    // Restore scoped child identity without delaying offline PIN entry.
    unawaited(
      _restoreChild().catchError((Object _) {
        error = 'cloudError';
        notifyListeners();
      }),
    );
  }

  Future<void> _restoreChild() async {
    final user = auth.currentUser;
    if (user == null || !user.isAnonymous) return;
    final link = await db.doc('devices/${user.uid}').get();
    if (link.exists &&
        link.data()!['active'] == true &&
        auth.currentUser?.uid == user.uid) {
      final d = link.data()!;
      familyId = d['family'] as String;
      childId = d['child'] as String;
      role = 'child';
      await _listen();
    }
  }

  Future<void> parentLogin(
    String email,
    String password, {
    bool create = false,
  }) async {
    await initialize();
    if (!initialized) throw StateError('Firebase is not configured');
    _session++;
    pendingMedia = null;
    pendingMediaOwner = null;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    final credential = create
        ? await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
        : await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
    final user = credential.user!;
    await user.reload();
    if (!auth.currentUser!.emailVerified) {
      await user.sendEmailVerification();
      throw StateError('Verify your email and sign in again.');
    }
    await auth.currentUser!.getIdToken(true);
    await functions.httpsCallable('registerParent').call();
    familyId = user.uid;
    await local.remoteUpdate((f) {
      if (f.cloudFamily.isNotEmpty &&
          (f.cloudFamily != familyId || f.cloudChild.isNotEmpty)) {
        f.clearLearning();
      }
      f.cloudFamily = familyId;
      f.cloudChild = '';
    });
    role = 'parent';
    await db.doc('families/$familyId').set({
      'owner': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _listen();
    await flush();
  }

  Future<String> pairingCode(String child) async {
    final r = await functions.httpsCallable('createPairing').call({
      'child': child,
    });
    return (r.data as Map)['code'] as String;
  }

  Future<void> pair(String code) async {
    await initialize();
    if (!initialized) throw StateError('Firebase is not configured');
    await logout();
    await auth.signInAnonymously();
    final r = await functions.httpsCallable('redeemPairing').call({
      'code': code.trim(),
    });
    final d = Map<String, dynamic>.from(r.data as Map);
    familyId = d['family'] as String;
    childId = d['child'] as String;
    await local.remoteUpdate((f) {
      if (f.cloudFamily != familyId || f.cloudChild != childId) {
        f.clearLearning();
      }
      f.cloudFamily = familyId;
      f.cloudChild = childId;
    });
    role = 'child';
    await _listen();
  }

  Future<void> _receive(int session, void Function(Family) action) =>
      local.remoteUpdate((f) {
        if (session == _session) action(f);
      });
  Future<void> _listen() async {
    final session = ++_session;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _subscriptions.add(
      db
          .doc('publicConfig/monetization')
          .snapshots(includeMetadataChanges: true)
          .takeWhile((_) => session == _session)
          .listen(
            (s) {
              ads = s.metadata.isFromCache ? {} : s.data() ?? {};
              notifyListeners();
            },
            onError: (_) {
              error = 'cloudError';
              notifyListeners();
            },
          ),
    );
    if (role == 'parent') {
      _subscriptions.add(
        db
            .collection('families/$familyId/children')
            .snapshots()
            .takeWhile((_) => session == _session)
            .listen(
              (snap) async {
                if (local.family == null) return;
                _receiving = true;
                try {
                  await _receive(session, (f) {
                    for (final doc in snap.docs) {
                      final data = doc.data();
                      if (data['profile'] is! Map) continue;
                      final child = ChildProfile.fromJson(
                        Map<String, dynamic>.from(data['profile'] as Map),
                      );
                      if (!f.children.any((c) => c.id == child.id) &&
                          f.children.length < 8) {
                        f.children.add(child);
                      }
                    }
                  });
                } catch (_) {
                  error = 'cloudError';
                } finally {
                  _receiving = false;
                }
              },
              onError: (_) {
                error = 'cloudError';
                notifyListeners();
              },
            ),
      );
      _subscriptions.add(
        db
            .collectionGroup('progress')
            .where('family', isEqualTo: familyId)
            .snapshots()
            .takeWhile((_) => session == _session)
            .listen(
              (snap) async {
                if (local.family == null) return;
                _receiving = true;
                try {
                  await _receive(session, (f) {
                    for (final doc in snap.docs) {
                      final d = doc.data();
                      final id = d['child'] as String;
                      final tally = d['tally'] as int? ?? 0;
                      if (tally > (f.totals[id] ?? 0)) f.totals[id] = tally;
                      final date = d['date'] as String;
                      f.days['$id:$date'] = {
                        'done': List<String>.from(d['done'] as List? ?? []),
                        'points': d['points'] ?? 0,
                        'seconds': d['seconds'] ?? 0,
                        'bonus': d['bonus'] ?? 0,
                      };
                    }
                    for (final c in f.children) {
                      final sum = f.days.entries
                          .where((e) => e.key.startsWith('${c.id}:'))
                          .fold(0, (a, e) => a + (e.value['points'] as int));
                      if (sum > (f.totals[c.id] ?? 0)) {
                        f.totals[c.id] = sum;
                      }
                    }
                  });
                } catch (_) {
                  error = 'cloudError';
                } finally {
                  _receiving = false;
                }
              },
              onError: (_) {
                error = 'cloudError';
                notifyListeners();
              },
            ),
      );
      _subscriptions.add(
        db
            .collectionGroup('requests')
            .where('family', isEqualTo: familyId)
            .snapshots()
            .takeWhile((_) => session == _session)
            .listen(
              (snap) async {
                if (local.family == null) return;
                _receiving = true;
                try {
                  await _receive(session, (f) {
                    for (final doc in snap.docs) {
                      final data = doc.data();
                      final r = <String, dynamic>{
                        for (final key in [
                          'id',
                          'child',
                          'date',
                          'status',
                          'minutes',
                        ])
                          key: data[key],
                      };
                      final existing = f.requests.where(
                        (x) => x['id'] == r['id'],
                      );
                      if (existing.isNotEmpty &&
                          existing.first['status'] != 'pending') {
                        r['status'] = existing.first['status'];
                      }
                      f.requests.removeWhere((x) => x['id'] == r['id']);
                      f.requests.add(r);
                      if (f.requests.length > 200) f.requests.removeAt(0);
                    }
                  });
                } catch (_) {
                  error = 'cloudError';
                } finally {
                  _receiving = false;
                }
              },
              onError: (_) {
                error = 'cloudError';
                notifyListeners();
              },
            ),
      );
    } else {
      _subscriptions.add(
        db
            .doc('families/$familyId/children/$childId')
            .snapshots()
            .takeWhile((_) => session == _session)
            .listen(
              (doc) async {
                final data = doc.data();
                if (data == null || local.family == null) return;
                _receiving = true;
                try {
                  await _receive(session, (f) {
                    final p = Map<String, dynamic>.from(data['profile'] as Map);
                    p['id'] = 'child';
                    f.children[0] = ChildProfile.fromJson(p);
                    f.customTasks.removeWhere((t) => t.childId == 'child');
                    for (final raw in data['custom'] as List? ?? []) {
                      final t = Map<String, dynamic>.from(raw as Map);
                      t['childId'] = 'child';
                      f.customTasks.add(LearningTask.fromJson(t));
                    }
                    f.videos.removeWhere((v) => v['child'] == 'child');
                    for (final raw in data['videos'] as List? ?? []) {
                      f.videos.add({
                        ...Map<String, dynamic>.from(raw as Map),
                        'child': 'child',
                      });
                    }
                    final decisions = Map<String, dynamic>.from(
                      data['decisions'] as Map? ?? {},
                    );
                    for (final entry in decisions.entries) {
                      if (f.requests.any((r) => r['id'] == entry.key)) {
                        f.decide(
                          entry.key,
                          entry.value == true,
                          dayKey(DateTime.now()),
                        );
                      }
                    }
                  });
                } catch (_) {
                  error = 'cloudError';
                } finally {
                  _receiving = false;
                }
              },
              onError: (_) {
                error = 'cloudError';
                notifyListeners();
              },
            ),
      );
      _subscriptions.add(
        db
            .collection('families/$familyId/children/$childId/progress')
            .snapshots()
            .takeWhile((_) => session == _session)
            .listen(
              (snap) async {
                if (local.family == null) return;
                _receiving = true;
                try {
                  await _receive(session, (f) {
                    for (final doc in snap.docs) {
                      final d = doc.data();
                      final tally = d['tally'] as int? ?? 0;
                      if (tally > (f.totals['child'] ?? 0)) {
                        f.totals['child'] = tally;
                      }
                      final record = f.day('child', doc.id);
                      record['done'] = {
                        ...List<String>.from(record['done'] as List),
                        ...List<String>.from(d['done'] as List? ?? []),
                      }.toList();
                      for (final key in ['points', 'seconds']) {
                        final n = (d[key] as int?) ?? 0;
                        if (n > (record[key] as int)) record[key] = n;
                      }
                    }
                    final sum = f.days.entries
                        .where((e) => e.key.startsWith('child:'))
                        .fold(0, (a, e) => a + (e.value['points'] as int));
                    if (sum > (f.totals['child'] ?? 0)) f.totals['child'] = sum;
                  });
                } catch (_) {
                  error = 'cloudError';
                } finally {
                  _receiving = false;
                }
              },
              onError: (_) {
                error = 'cloudError';
                notifyListeners();
              },
            ),
      );
    }
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      final status = await FirebaseMessaging.instance.requestPermission();
      if (status.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await functions.httpsCallable('registerPushToken').call({
            'token': token,
          });
        }
      }
      _subscriptions.add(
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
          try {
            await functions.httpsCallable('registerPushToken').call({
              'token': token,
            });
          } catch (_) {
            error = 'cloudError';
          }
        }),
      );
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((_) {
          _localChanged();
        }),
      );
    } catch (_) {
      /* Firestore sync remains useful without notifications. */
    }
    _localChanged(); // Replay the durable outbox after pairing or restoring a session.
    notifyListeners();
  }

  void _localChanged() {
    if (local.fromRemote || local.busy || role.isEmpty || !initialized) return;
    _dirty = true;
    if (_debounce?.isActive ?? false) return;
    _debounce = Timer(const Duration(seconds: 5), () {
      flush().catchError((Object _) {
        error = 'cloudError';
        notifyListeners();
      });
    });
  }

  Future<void> flush() async {
    if (working || role.isEmpty || local.family == null) return;
    final session = _session,
        syncFamily = familyId,
        syncChild = childId,
        syncRole = role;
    working = true;
    _dirty = false;
    try {
      final f = Family.decode(local.family!.encode());
      if (syncRole == 'parent') {
        for (final c in f.children) {
          if (session != _session) return;
          final decisions = {
            for (final r in f.requests.where(
              (r) => r['child'] == c.id && r['status'] != 'pending',
            ))
              r['id'] as String: r['status'] == 'approved',
          };
          await db
              .doc('families/$syncFamily/children/${c.id}')
              .set(
                {
                  'profile': c.toJson(),
                  'custom': f.customTasks
                      .where((t) => t.childId == c.id)
                      .map((t) => t.toJson())
                      .toList(),
                  'videos': f.videos.where((v) => v['child'] == c.id).toList(),
                  'decisions': decisions,
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(
                  mergeFields: [
                    'profile',
                    'custom',
                    'videos',
                    'decisions',
                    'updatedAt',
                  ],
                ),
              )
              .timeout(const Duration(seconds: 15));
        }
      } else {
        final uid = auth.currentUser!.uid;
        for (final entry in f.days.entries.where(
          (e) => e.key.startsWith('child:') && f.pendingDays.contains(e.key),
        )) {
          if (session != _session) return;
          final date = entry.key.substring(6), d = entry.value;
          await db
              .doc('families/$syncFamily/children/$syncChild/progress/$date')
              .set({
                'family': syncFamily,
                'child': syncChild,
                'date': date,
                'device': uid,
                'done': d['done'],
                'points': d['points'],
                'tally': f.totals['child'] ?? 0,
                'seconds': d['seconds'],
                'bonus': d['bonus'],
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(const Duration(seconds: 15));
          await _receive(session, (v) {
            if (jsonEncode(v.days[entry.key]) == jsonEncode(d)) {
              v.pendingDays.remove(entry.key);
            }
          });
        }
        for (final r in f.requests.where(
          (r) =>
              r['child'] == 'child' &&
              r['status'] == 'pending' &&
              r['sent'] != true,
        )) {
          if (session != _session) return;
          await db
              .doc(
                'families/$syncFamily/children/$syncChild/requests/${r['id']}',
              )
              .set({
                'id': r['id'],
                'date': r['date'],
                'minutes': 10,
                'status': 'pending',
                'child': syncChild,
                'family': syncFamily,
                'device': uid,
                'updatedAt': FieldValue.serverTimestamp(),
              })
              .timeout(const Duration(seconds: 15));
          await _receive(session, (v) {
            for (final request in v.requests) {
              if (request['id'] == r['id']) request['sent'] = true;
            }
          });
        }
      }
      error = null;
      _retry?.cancel();
    } catch (_) {
      error = 'cloudError';
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 30), () {
        if (session == _session) _localChanged();
      });
      rethrow;
    } finally {
      working = false;
      notifyListeners();
      if (_dirty || session != _session) _localChanged();
    }
  }

  Future<void> enterKid() async {
    try {
      await initialize();
    } catch (_) {
      error = 'cloudError';
      return;
    }
    if (initialized &&
        auth.currentUser != null &&
        !auth.currentUser!.isAnonymous) {
      await logout();
    }
  }

  Future<void> logout() async {
    pendingMedia = null;
    pendingMediaOwner = null;
    _session++;
    _debounce?.cancel();
    _retry?.cancel();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    if (initialized) {
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      unawaited(
        FirebaseMessaging.instance.deleteToken().catchError((Object _) {}),
      );
      await auth.signOut();
    }
    role = '';
    familyId = '';
    childId = '';
    ads = {};
    notifyListeners();
  }

  @override
  void dispose() {
    local.removeListener(_localChanged);
    _debounce?.cancel();
    _retry?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
