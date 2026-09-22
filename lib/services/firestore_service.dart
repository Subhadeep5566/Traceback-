import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../models/found_item.dart';
import '../models/incident.dart';
import '../models/recovery_report.dart';
import '../models/user_profile.dart';

class FirestoreService {
  FirebaseFirestore? _firestore;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    if (Firebase.apps.isNotEmpty) {
      _firestore = FirebaseFirestore.instance;
      return _firestore;
    }
    return null;
  }

  bool get isAvailable => _db != null;

  // Collection References
  CollectionReference<Map<String, dynamic>>? get _usersRef => _db?.collection('users');
  CollectionReference<Map<String, dynamic>>? get _itemsRef => _db?.collection('items');
  CollectionReference<Map<String, dynamic>>? get _belongingsRef => _db?.collection('belongings');
  CollectionReference<Map<String, dynamic>>? get _foundItemsRef => _db?.collection('found_items');
  CollectionReference<Map<String, dynamic>>? get _foundReportsRef => _db?.collection('found_reports');
  CollectionReference<Map<String, dynamic>>? get _incidentsRef => _db?.collection('incidents');
  CollectionReference<Map<String, dynamic>>? get _notificationsRef => _db?.collection('notifications');

  // ==========================================
  // 1. USER PROFILES (/users/{uid})
  // ==========================================

  Future<void> saveUserProfile(UserProfile profile) async {
    final ref = _usersRef;
    if (ref == null) return;

    try {
      await ref.doc(profile.userId).set({
        ...profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService saveUserProfile error: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final ref = _usersRef;
    if (ref == null) return null;

    try {
      final doc = await ref.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('FirestoreService getUserProfile error: $e');
    }
    return null;
  }

  Stream<UserProfile?> streamUserProfile(String userId) {
    final ref = _usersRef;
    if (ref == null) return Stream.value(null);

    return ref.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    }).handleError((e) {
      debugPrint('FirestoreService streamUserProfile error: $e');
      return null;
    });
  }

  // ==========================================
  // 2. REGISTERED BELONGINGS (/items/{itemId})
  // ==========================================

  Future<void> saveItem(Asset asset) async {
    final json = {
      ...asset.toJson(),
      'updatedAtTimestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_itemsRef != null) {
        await _itemsRef!.doc(asset.id).set(json, SetOptions(merge: true));
      }
      if (_belongingsRef != null) {
        await _belongingsRef!.doc(asset.id).set(json, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FirestoreService saveItem error: $e');
    }
  }

  Future<void> saveBelonging(Asset asset) => saveItem(asset);

  Future<void> updateItemStatus(
    String assetId,
    AssetStatus status, {
    String? foundLocation,
    String? finderNote,
    String? finderPhoto,
    double? latitude,
    double? longitude,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'statusName': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedAtTimestamp': FieldValue.serverTimestamp(),
    };

    if (status == AssetStatus.found) {
      updates['foundAt'] = DateTime.now().toIso8601String();
      if (foundLocation != null) updates['foundLocation'] = foundLocation;
      if (finderNote != null) updates['finderNote'] = finderNote;
      if (finderPhoto != null) updates['finderPhoto'] = finderPhoto;
    } else if (status == AssetStatus.recovered) {
      updates['recoveredAt'] = DateTime.now().toIso8601String();
      updates['trackingEnabled'] = false;
    }

    if (latitude != null && longitude != null) {
      updates['latitude'] = latitude;
      updates['longitude'] = longitude;
    }

    try {
      if (_itemsRef != null) {
        await _itemsRef!.doc(assetId).update(updates);
      }
      if (_belongingsRef != null) {
        await _belongingsRef!.doc(assetId).update(updates);
      }
    } catch (e) {
      debugPrint('FirestoreService updateItemStatus error: $e');
    }
  }

  Future<void> updateBelongingStatus(
    String assetId,
    AssetStatus status, {
    String? foundLocation,
    String? finderNote,
    String? finderPhoto,
    double? latitude,
    double? longitude,
  }) =>
      updateItemStatus(
        assetId,
        status,
        foundLocation: foundLocation,
        finderNote: finderNote,
        finderPhoto: finderPhoto,
        latitude: latitude,
        longitude: longitude,
      );

  Future<void> deleteItem(String assetId) async {
    try {
      if (_itemsRef != null) await _itemsRef!.doc(assetId).delete();
      if (_belongingsRef != null) await _belongingsRef!.doc(assetId).delete();
    } catch (e) {
      debugPrint('FirestoreService deleteItem error: $e');
    }
  }

  Future<void> deleteBelonging(String assetId) => deleteItem(assetId);

  Future<List<Asset>> getUserItems(String ownerId) async {
    final ref = _itemsRef ?? _belongingsRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref.where('ownerId', isEqualTo: ownerId).get();
      return snapshot.docs.map((doc) => Asset.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirestoreService getUserItems error: $e');
      return [];
    }
  }

  Future<List<Asset>> getUserBelongings(String ownerId) => getUserItems(ownerId);

  Stream<List<Asset>> streamUserItems(String ownerId) {
    final ref = _itemsRef ?? _belongingsRef;
    if (ref == null) return Stream.value([]);

    return ref.where('ownerId', isEqualTo: ownerId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Asset.fromJson(doc.data())).toList();
    }).handleError((e) {
      debugPrint('FirestoreService streamUserItems error: $e');
      return <Asset>[];
    });
  }

  Stream<List<Asset>> streamUserBelongings(String ownerId) => streamUserItems(ownerId);

  Stream<List<Asset>> streamAllItems() {
    final ref = _itemsRef ?? _belongingsRef;
    if (ref == null) return Stream.value([]);

    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Asset.fromJson(doc.data())).toList();
    }).handleError((e) {
      debugPrint('FirestoreService streamAllItems error: $e');
      return <Asset>[];
    });
  }

  Stream<List<Asset>> streamAllBelongings() => streamAllItems();

  Future<Asset?> lookupByTracebackId(String tracebackId) async {
    final cleanId = tracebackId.trim().toUpperCase();

    try {
      if (_itemsRef != null) {
        final snapshot = await _itemsRef!.where('tracebackId', isEqualTo: cleanId).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          return Asset.fromJson(snapshot.docs.first.data());
        }
      }

      if (_belongingsRef != null) {
        final snapshot = await _belongingsRef!.where('tracebackId', isEqualTo: cleanId).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          return Asset.fromJson(snapshot.docs.first.data());
        }
      }
    } catch (e) {
      debugPrint('FirestoreService lookupByTracebackId error: $e');
    }
    return null;
  }

  Future<Asset?> findBelongingByTracebackId(String tracebackId) => lookupByTracebackId(tracebackId);

  // ==========================================
  // 3. FOUND ITEMS (/found_items/{foundItemId})
  // ==========================================

  Future<void> saveFoundItem(FoundItem item) async {
    final json = {
      ...item.toJson(),
      'updatedAtTimestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_foundItemsRef != null) {
        await _foundItemsRef!.doc(item.foundItemId).set(json, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FirestoreService saveFoundItem error: $e');
    }
  }

  Future<FoundItem?> getFoundItem(String foundItemId) async {
    if (_foundItemsRef == null) return null;
    try {
      final doc = await _foundItemsRef!.doc(foundItemId).get();
      if (doc.exists && doc.data() != null) {
        return FoundItem.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('FirestoreService getFoundItem error: $e');
    }
    return null;
  }

  Stream<List<FoundItem>> streamAllFoundItems() {
    final ref = _foundItemsRef;
    if (ref == null) return Stream.value([]);

    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FoundItem.fromJson(doc.data())).toList();
    }).handleError((e) {
      debugPrint('FirestoreService streamAllFoundItems error: $e');
      return <FoundItem>[];
    });
  }

  Future<void> updateFoundItemStatus(
    String foundItemId,
    FoundItemStatus status, {
    String? matchedItemId,
    String? matchedOwnerId,
  }) async {
    if (_foundItemsRef == null) return;
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedAtTimestamp': FieldValue.serverTimestamp(),
      };
      if (matchedItemId != null) updates['matchedItemId'] = matchedItemId;
      if (matchedOwnerId != null) updates['matchedOwnerId'] = matchedOwnerId;

      await _foundItemsRef!.doc(foundItemId).update(updates);
    } catch (e) {
      debugPrint('FirestoreService updateFoundItemStatus error: $e');
    }
  }

  // ==========================================
  // 4. FOUND REPORTS & RECOVERY REPORTS
  // ==========================================

  Future<void> saveFoundReport(RecoveryReport report) async {
    final ref = _foundReportsRef;
    if (ref == null) return;

    try {
      await ref.doc(report.reportId).set({
        ...report.toJson(),
        'createdAtTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService saveFoundReport error: $e');
    }
  }

  Future<List<RecoveryReport>> getReportsForAsset(String assetId) async {
    final ref = _foundReportsRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref
          .where('assetId', isEqualTo: assetId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => RecoveryReport.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirestoreService getReportsForAsset error: $e');
      return [];
    }
  }

  // ==========================================
  // 5. INCIDENTS & TIMELINE
  // ==========================================

  Future<void> saveIncident(Incident incident) async {
    final ref = _incidentsRef;
    if (ref == null) return;

    try {
      await ref.doc(incident.id).set({
        ...incident.toJson(),
        'updatedAtTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService saveIncident error: $e');
    }
  }

  Future<List<Incident>> getIncidentsForAsset(String assetId) async {
    final ref = _incidentsRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref.where('assetId', isEqualTo: assetId).get();
      return snapshot.docs.map((doc) => Incident.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirestoreService getIncidentsForAsset error: $e');
      return [];
    }
  }

  // ==========================================
  // 6. ACTIVITY NOTIFICATIONS
  // ==========================================

  Future<void> sendNotification(Map<String, dynamic> notifData) async {
    final ref = _notificationsRef;
    if (ref == null) return;

    try {
      final id = notifData['id'] ?? 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
      await ref.doc(id).set({
        ...notifData,
        'createdAtTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService sendNotification error: $e');
    }
  }

  // ==========================================
  // 7. ADMIN DASHBOARD METRICS (Live Aggregation)
  // ==========================================

  Future<Map<String, int>> getAdminStats() async {
    int totalUsers = 0;
    int registered = 0;
    int lost = 0;
    int found = 0;
    int recovered = 0;
    int totalItems = 0;

    try {
      if (_usersRef != null) {
        final usersSnap = await _usersRef!.get();
        totalUsers = usersSnap.docs.length;
      }

      final itemsSnap = await (_itemsRef ?? _belongingsRef)?.get();
      if (itemsSnap != null) {
        totalItems = itemsSnap.docs.length;
        for (final doc in itemsSnap.docs) {
          final data = doc.data();
          final status = (data['status'] as String? ?? '').toLowerCase();
          if (status == 'registered' || status == 'secure') {
            registered++;
          } else if (status == 'lost' || status == 'stolen') {
            lost++;
          } else if (status == 'found') {
            found++;
          } else if (status == 'recovered') {
            recovered++;
          }
        }
      }

      // Also check found_items collection for additional reported found items
      if (_foundItemsRef != null) {
        final foundSnap = await _foundItemsRef!.get();
        for (final doc in foundSnap.docs) {
          final st = (doc.data()['status'] as String? ?? '').toLowerCase();
          if (st == 'reported' || st == 'matched') {
            found++;
          } else if (st == 'returned' || st == 'recovered') {
            recovered++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'registeredItems': registered,
        'lostItems': lost,
        'foundItems': found,
        'recoveredItems': recovered,
        'total': totalItems,
        'lost': lost,
        'found': found,
        'recovered': recovered,
      };
    } catch (e) {
      debugPrint('FirestoreService getAdminStats error: $e');
      return {
        'totalUsers': 0,
        'registeredItems': 0,
        'lostItems': 0,
        'foundItems': 0,
        'recoveredItems': 0,
        'total': 0,
        'lost': 0,
        'found': 0,
        'recovered': 0,
      };
    }
  }
}

