import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/asset.dart';
import '../models/incident.dart';
import '../models/recovery_report.dart';
import '../models/user_profile.dart';
import '../services/demo_data_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/telematics_service.dart';

class AppActivityNotification {
  final String id;
  final String title;
  final String subtitle;
  final String assetId;
  final String tracebackId;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'found', 'lost', 'recovered', 'trace'
  final UserRole? targetRole; // null for both, or specific role

  AppActivityNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetId,
    required this.tracebackId,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.targetRole,
  });

  AppActivityNotification copyWith({bool? isRead}) {
    return AppActivityNotification(
      id: id,
      title: title,
      subtitle: subtitle,
      assetId: assetId,
      tracebackId: tracebackId,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
      targetRole: targetRole,
    );
  }
}

class AssetProvider extends ChangeNotifier {
  final TelematicsService _telematicsService = TelematicsService();
  final StorageService _storageService;

  List<Asset> _assets = [];
  List<Incident> _incidents = [];
  List<RecoveryReport> _reports = [];
  List<AppActivityNotification> _notifications = [];
  String? _selectedAssetId;
  String _selectedFilter = 'all'; // 'all', 'safe'/'secure', 'lost'/'stolen', 'found', 'recovered'
  String _searchQuery = '';
  bool _isInitialized = false;
  bool _isDemoMode = false;
  String _currentOwnerId = 'student_current';

  AssetProvider([StorageService? storageService])
      : _storageService = storageService ?? StorageService() {
    _initData();
  }

  Future<void> _initData() async {
    try {
      await _storageService.init();
      _loadFromStorage();
      if (_assets.isEmpty) {
        _assets = _telematicsService.getInitialAssets();
        _incidents = _telematicsService.getInitialIncidents();
        await _persistAll();
      }
      _initInitialNotifications();
      if (_assets.isNotEmpty) {
        _selectedAssetId = _assets.first.id;
      }
    } catch (e) {
      debugPrint('AssetProvider init error: $e');
      if (_assets.isEmpty) {
        _assets = _telematicsService.getInitialAssets();
        _incidents = _telematicsService.getInitialIncidents();
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _initInitialNotifications() {
    final now = DateTime.now();
    _notifications = [
      AppActivityNotification(
        id: 'NOTIF-01',
        title: 'Active Trace Mode',
        subtitle: 'Student Laptop (TB-LAPTOP-002) is actively transmitting location pings.',
        assetId: 'AST-002',
        tracebackId: 'TB-LAPTOP-002',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: 'trace',
      ),
      AppActivityNotification(
        id: 'NOTIF-02',
        title: 'Item Recovered & Verified',
        subtitle: 'Smartphone (TB-PHONE-003) was successfully retrieved.',
        assetId: 'AST-003',
        tracebackId: 'TB-PHONE-003',
        timestamp: now.subtract(const Duration(days: 1)),
        type: 'recovered',
      ),
    ];
  }

  void setOwner(String ownerId) {
    _currentOwnerId = ownerId;
    notifyListeners();
  }

  bool get isInitialized => _isInitialized;
  bool get isDemoMode => _isDemoMode;

  void loadDemoData() {
    _isDemoMode = true;
    _assets = DemoDataService.getDemoAssets();
    _incidents = DemoDataService.getDemoIncidents();
    _selectedAssetId = _assets.isNotEmpty ? _assets.first.id : null;
    _selectedFilter = 'all';
    _searchQuery = '';
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> resetToProduction() async {
    _isDemoMode = false;
    _loadFromStorage();
    if (_assets.isEmpty) {
      _assets = _telematicsService.getInitialAssets();
      _incidents = _telematicsService.getInitialIncidents();
    }
    _selectedAssetId = _assets.isNotEmpty ? _assets.first.id : null;
    _selectedFilter = 'all';
    _searchQuery = '';
    notifyListeners();
  }

  void _loadFromStorage() {
    _assets = _storageService.loadAssets();
    _incidents = _storageService.loadIncidents();
    _reports = _storageService.loadReports();
  }

  Future<void> _persistAll() async {
    if (_isDemoMode) return;
    await _storageService.saveAssets(_assets);
    await _storageService.saveIncidents(_incidents);
    await _storageService.saveReports(_reports);
  }

  // Getters
  List<Asset> get allAssets => _assets;
  List<Asset> get myBelongings => _assets; // Dedicated student inventory
  List<Asset> get lostAssets => _assets.where((a) => a.status == AssetStatus.stolen).toList();
  List<Asset> get foundAssets => _assets.where((a) => a.status == AssetStatus.found).toList();
  List<Asset> get secureAssets => _assets.where((a) => a.status == AssetStatus.safe).toList();
  List<Asset> get recoveredAssets => _assets.where((a) => a.status == AssetStatus.recovered).toList();
  List<Asset> get activeTrackedAssets => _assets.where((a) => a.trackingEnabled || a.status == AssetStatus.stolen).toList();
  List<Incident> get allIncidents => _incidents;
  List<RecoveryReport> get allReports => _reports;
  List<RecoveryReport> reportsForAsset(String assetId) => _reports.where((r) => r.assetId == assetId).toList();
  List<RecoveryReport> getReportsForAsset(String assetId) => reportsForAsset(assetId);
  List<Asset> get activeCases => _assets.where((a) => a.isLost || a.isFound).toList();
  List<Asset> get foundCases => _assets.where((a) => a.isFound).toList();
  List<Asset> get lostCases => _assets.where((a) => a.status == AssetStatus.stolen).toList();
  List<Asset> get resolvedCases => _assets.where((a) => a.isRecovered).toList();
  List<AppActivityNotification> get notifications => _notifications;
  List<AppActivityNotification> notificationsForRole(UserRole role) =>
      _notifications.where((n) => n.targetRole == null || n.targetRole == role).toList();
  String? get selectedAssetId => _selectedAssetId;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  Asset? get selectedAsset {
    if (_selectedAssetId == null) return _assets.isNotEmpty ? _assets.first : null;
    try {
      return _assets.firstWhere((a) => a.id == _selectedAssetId);
    } catch (_) {
      return _assets.isNotEmpty ? _assets.first : null;
    }
  }

  List<Asset> get filteredAssets {
    return _assets.where((asset) {
      bool matchesFilter = true;
      final f = _selectedFilter.toLowerCase();
      if (f == 'safe' || f == 'secure') {
        matchesFilter = asset.status == AssetStatus.safe;
      } else if (f == 'stolen' || f == 'lost') {
        matchesFilter = asset.status == AssetStatus.stolen;
      } else if (f == 'found') {
        matchesFilter = asset.status == AssetStatus.found;
      } else if (f == 'recovered') {
        matchesFilter = asset.status == AssetStatus.recovered;
      }

      bool matchesQuery = true;
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesQuery = asset.name.toLowerCase().contains(query) ||
            asset.tracebackId.toLowerCase().contains(query) ||
            asset.id.toLowerCase().contains(query) ||
            asset.brand.toLowerCase().contains(query) ||
            asset.model.toLowerCase().contains(query) ||
            asset.address.toLowerCase().contains(query) ||
            asset.category.displayName.toLowerCase().contains(query);
      }

      return matchesFilter && matchesQuery;
    }).toList();
  }

  int get totalAssetCount => _assets.length;
  int get secureCount => _assets.where((a) => a.status == AssetStatus.safe).length;
  int get safeCount => secureCount;
  int get lostCount => _assets.where((a) => a.status == AssetStatus.stolen).length;
  int get inRecoveryCount => lostCount;
  int get stolenCount => lostCount;
  int get foundCount => _assets.where((a) => a.status == AssetStatus.found).length;
  int get recoveredCount => _assets.where((a) => a.status == AssetStatus.recovered).length;
  int get resolvedCount => recoveredCount;

  List<Incident> incidentsForAsset(String assetId) {
    return _incidents.where((inc) => inc.assetId == assetId).toList();
  }

  Asset? getAssetById(String id) {
    try {
      return _assets.firstWhere((a) => a.id == id || a.tracebackId.toUpperCase() == id.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  List<IncidentTimelineStep> getAssetHistory(String assetId) {
    final list = <IncidentTimelineStep>[];
    for (final inc in incidentsForAsset(assetId)) {
      list.addAll(inc.timeline);
    }
    return list;
  }

  Incident? getLatestIncidentForAsset(String assetId) {
    final incs = incidentsForAsset(assetId);
    return incs.isNotEmpty ? incs.first : null;
  }

  // Traceback ID Generator
  String generateUniqueTracebackId(AssetCategory category) {
    final prefix = 'TB-${category.idPrefix}';
    int maxSeq = 0;

    for (final a in _assets) {
      if (a.tracebackId.startsWith(prefix)) {
        final parts = a.tracebackId.split('-');
        if (parts.length >= 3) {
          final numPart = int.tryParse(parts.last) ?? 0;
          if (numPart > maxSeq) maxSeq = numPart;
        }
      }
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(3, '0');
    return '$prefix-$nextSeq';
  }

  // Register Belonging Flow
  Future<Asset> registerBelonging({
    required String name,
    required AssetCategory category,
    String brand = '',
    String model = '',
    String color = '',
    String description = '',
    String? customTracebackId,
    String? address,
    LatLng? location,
  }) async {
    final now = DateTime.now();
    final tracebackId = customTracebackId?.isNotEmpty == true
        ? customTracebackId!.toUpperCase()
        : generateUniqueTracebackId(category);

    final uniqueId = 'AST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final targetLatLng = location ?? LocationService.bguCampusCenter;
    final itemAddress = address?.isNotEmpty == true
        ? address!
        : 'Birla Global University, Gothapatna, Bhubaneswar';

    final newAsset = Asset(
      id: uniqueId,
      tracebackId: tracebackId,
      ownerId: _currentOwnerId,
      name: name.trim(),
      category: category,
      brand: brand.trim(),
      model: model.trim(),
      color: color.trim(),
      description: description.trim(),
      status: AssetStatus.safe,
      trackingEnabled: false,
      createdAt: now,
      updatedAt: now,
      latitude: targetLatLng.latitude,
      longitude: targetLatLng.longitude,
      locationAccuracy: 8.0,
      address: itemAddress,
      lastPing: now,
      locationHistory: [
        LocationPoint(
          latitude: targetLatLng.latitude,
          longitude: targetLatLng.longitude,
          timestamp: now,
        ),
      ],
    );

    final initialIncident = Incident(
      id: 'INC-$uniqueId-01',
      assetId: uniqueId,
      assetName: '${newAsset.name} ($tracebackId)',
      timestamp: now,
      type: 'Asset Registration',
      status: 'Secure',
      description: 'Registered into personal inventory with tag $tracebackId.',
      latitude: targetLatLng.latitude,
      longitude: targetLatLng.longitude,
      timeline: [
        IncidentTimelineStep(
          title: 'Registered',
          description: 'Belonging registered with unique tag $tracebackId.',
          timestamp: now,
        ),
        IncidentTimelineStep(
          title: 'Tag Active & Secured',
          description: 'Cryptographic tag ready for verification.',
          timestamp: now,
        ),
      ],
    );

    _assets.insert(0, newAsset);
    _incidents.insert(0, initialIncident);
    _selectedAssetId = newAsset.id;

    _notifications.insert(
      0,
      AppActivityNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Belonging Registered',
        subtitle: '${newAsset.name} was tagged with ID $tracebackId.',
        assetId: newAsset.id,
        tracebackId: tracebackId,
        timestamp: now,
        type: 'recovered',
      ),
    );

    await _persistAll();
    notifyListeners();
    return newAsset;
  }

  // Generic & Role-Aware Reporting Flow
  Future<RecoveryReport> submitReport({
    required String assetId,
    required ReportType reportType,
    required String location,
    required String description,
    required UserRole reporterRole,
    required String reporterId,
    required String reporterName,
    required String reporterContact,
    String? image,
    LatLng? coordinates,
  }) async {
    final assetIndex = _assets.indexWhere(
      (a) => a.id.toUpperCase() == assetId.toUpperCase() || a.tracebackId.toUpperCase() == assetId.toUpperCase(),
    );
    if (assetIndex == -1) {
      throw Exception('Belonging not found');
    }

    final target = _assets[assetIndex];
    final now = DateTime.now();
    final lat = coordinates?.latitude ?? target.latitude;
    final lng = coordinates?.longitude ?? target.longitude;

    final report = RecoveryReport(
      reportId: 'REP-${DateTime.now().millisecondsSinceEpoch}',
      reporterId: reporterId,
      reporterRole: reporterRole,
      reporterName: reporterName,
      reporterContact: reporterContact,
      assetId: target.id,
      tracebackId: target.tracebackId,
      reportType: reportType,
      location: location.isNotEmpty ? location : target.address,
      timestamp: now,
      description: description,
      image: image,
      status: reportType == ReportType.found ? 'Located' : 'Active',
    );

    _reports.insert(0, report);

    final newStatus = (reportType == ReportType.found) ? AssetStatus.found : AssetStatus.stolen;
    _assets[assetIndex] = target.copyWith(
      status: newStatus,
      address: location.isNotEmpty ? location : target.address,
      latitude: lat,
      longitude: lng,
      updatedAt: now,
    );

    // Create / Update timeline step
    final stepTitle = reportType == ReportType.found ? 'Found Report' : '${reportType.displayName} Report';
    final roleLabel = reporterRole == UserRole.admin ? 'College Admin' : 'Student';
    final timelineStep = IncidentTimelineStep(
      title: stepTitle,
      description: description.isNotEmpty
          ? '$description (Reported near $location)'
          : 'Reported by $reporterName ($roleLabel) at $location.',
      timestamp: now,
      actor: reporterName,
      actorRole: reporterRole,
      action: 'Reported ${reportType.displayName}',
      location: location,
      note: description,
    );

    bool updatedIncident = false;
    for (int i = 0; i < _incidents.length; i++) {
      if (_incidents[i].assetId == target.id && _incidents[i].status != 'Recovered') {
        final updatedTimeline = List<IncidentTimelineStep>.from(_incidents[i].timeline)..add(timelineStep);
        _incidents[i] = _incidents[i].copyWith(
          status: reportType == ReportType.found ? 'Found' : 'Tracking',
          latitude: lat,
          longitude: lng,
          timeline: updatedTimeline,
        );
        updatedIncident = true;
        break;
      }
    }

    if (!updatedIncident) {
      final newIncident = Incident(
        id: 'INC-${DateTime.now().millisecondsSinceEpoch}',
        assetId: target.id,
        assetName: '${target.name} (${target.tracebackId})',
        timestamp: now,
        type: '${reportType.displayName} Report',
        status: reportType == ReportType.found ? 'Found' : 'Tracking',
        description: description,
        latitude: lat,
        longitude: lng,
        timeline: [timelineStep],
      );
      _incidents.insert(0, newIncident);
    }

    // Bi-directional Notifications
    if (reporterRole == UserRole.admin) {
      // Admin filed -> Notify Owner / Student
      _notifications.insert(
        0,
        AppActivityNotification(
          id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
          title: reportType == ReportType.found ? 'Item Found by College Admin' : 'Admin Filed Report',
          subtitle: 'College Admin ($reporterName) filed a ${reportType.displayName} report for ${target.name}.',
          assetId: target.id,
          tracebackId: target.tracebackId,
          timestamp: now,
          type: reportType == ReportType.found ? 'found' : 'lost',
          targetRole: UserRole.student,
        ),
      );
    } else {
      // Student filed -> Notify Admin Dashboard
      _notifications.insert(
        0,
        AppActivityNotification(
          id: 'NOTIF-ADM-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Case Filed: ${target.name}',
          subtitle: '$reporterName reported ${target.tracebackId} as ${reportType.displayName}.',
          assetId: target.id,
          tracebackId: target.tracebackId,
          timestamp: now,
          type: reportType == ReportType.found ? 'found' : 'lost',
          targetRole: UserRole.admin,
        ),
      );

      if (reportType == ReportType.found) {
        // Also notify owner if reported found by a campus peer
        _notifications.insert(
          0,
          AppActivityNotification(
            id: 'NOTIF-OWN-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Your Belonging Was Found!',
            subtitle: '${target.name} (${target.tracebackId}) was reported found at $location by $reporterName.',
            assetId: target.id,
            tracebackId: target.tracebackId,
            timestamp: now,
            type: 'found',
            targetRole: UserRole.student,
          ),
        );
      }
    }

    _selectedAssetId = target.id;
    await _persistAll();
    notifyListeners();
    return report;
  }

  // Report Lost / Stolen Flow
  Future<void> reportLostOrStolen({
    required String assetId,
    required String reason, // 'Lost' or 'Stolen'
    String? locationAddress,
    String? notes,
    LatLng? coordinates,
    UserRole reporterRole = UserRole.student,
    String reporterName = 'Student Owner',
    String reporterId = 'student_current',
    String reporterContact = '',
  }) async {
    final reportType = reason.toLowerCase() == 'stolen' ? ReportType.stolen : ReportType.lost;
    await submitReport(
      assetId: assetId,
      reportType: reportType,
      location: locationAddress ?? 'BGU Campus',
      description: notes ?? '$reason report filed.',
      reporterRole: reporterRole,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterContact: reporterContact,
      coordinates: coordinates,
    );
  }

  // Backward compatibility alias for existing incident_report_screen
  void reportStolen({
    required String assetId,
    required String description,
  }) {
    reportLostOrStolen(
      assetId: assetId,
      reason: 'Stolen',
      notes: description,
    );
  }

  // Activate Real Trace with GPS
  Future<bool> activateTrace(String assetId) async {
    final index = _assets.indexWhere((a) => a.id == assetId);
    if (index == -1) return false;

    final target = _assets[index];
    final locationResult = await LocationService.getCurrentLocation(
      fallbackAddress: target.address,
      fallbackLatLng: target.latLng,
    );

    final now = DateTime.now();
    final updatedHistory = List<LocationPoint>.from(target.locationHistory)
      ..add(LocationPoint(
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
        timestamp: locationResult.timestamp,
      ));

    _assets[index] = target.copyWith(
      status: AssetStatus.stolen,
      trackingEnabled: true,
      latitude: locationResult.latitude,
      longitude: locationResult.longitude,
      locationAccuracy: locationResult.accuracy,
      address: locationResult.address,
      lastPing: locationResult.timestamp,
      updatedAt: now,
      locationHistory: updatedHistory,
    );

    // Update matching incident timeline
    for (int i = 0; i < _incidents.length; i++) {
      if (_incidents[i].assetId == assetId && _incidents[i].status != 'Recovered') {
        final updatedTimeline = List<IncidentTimelineStep>.from(_incidents[i].timeline)
          ..add(IncidentTimelineStep(
            title: 'Trace Activated',
            description: 'GPS telemetry active (±${locationResult.accuracy.toStringAsFixed(0)}m). Location: ${locationResult.address}',
            timestamp: now,
            actor: 'Owner / Traceback System',
            actorRole: UserRole.student,
            action: 'Trace Activated',
            location: locationResult.address,
          ));
        _incidents[i] = _incidents[i].copyWith(
          status: 'Tracking',
          latitude: locationResult.latitude,
          longitude: locationResult.longitude,
          timeline: updatedTimeline,
        );
        break;
      }
    }

    _notifications.insert(
      0,
      AppActivityNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Trace Activated',
        subtitle: 'Live GPS location detected for ${target.name}.',
        assetId: target.id,
        tracebackId: target.tracebackId,
        timestamp: now,
        type: 'trace',
        targetRole: UserRole.student,
      ),
    );

    await _persistAll();
    notifyListeners();
    return locationResult.isRealGps;
  }

  // Stop Trace
  Future<void> stopTrace(String assetId) async {
    final index = _assets.indexWhere((a) => a.id == assetId);
    if (index == -1) return;

    final target = _assets[index];
    final now = DateTime.now();

    _assets[index] = target.copyWith(
      trackingEnabled: false,
      updatedAt: now,
    );

    for (int i = 0; i < _incidents.length; i++) {
      if (_incidents[i].assetId == assetId && _incidents[i].status == 'Tracking') {
        final updatedTimeline = List<IncidentTimelineStep>.from(_incidents[i].timeline)
          ..add(IncidentTimelineStep(
            title: 'Trace Deactivated',
            description: 'GPS telemetry stopped by owner.',
            timestamp: now,
            actor: 'Owner',
            actorRole: UserRole.student,
            action: 'Trace Stopped',
          ));
        _incidents[i] = _incidents[i].copyWith(timeline: updatedTimeline);
        break;
      }
    }

    await _persistAll();
    notifyListeners();
  }

  // Finder / Student / Admin Flow: Report Found
  Future<void> reportFound({
    required String assetId,
    required String foundLocation,
    String? note,
    LatLng? coordinates,
    UserRole reporterRole = UserRole.student,
    String reporterName = 'Campus Finder',
    String reporterId = 'finder_user',
    String reporterContact = '',
  }) async {
    await submitReport(
      assetId: assetId,
      reportType: ReportType.found,
      location: foundLocation,
      description: note ?? 'Reported found on campus.',
      reporterRole: reporterRole,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterContact: reporterContact,
      coordinates: coordinates,
    );
  }

  // Admin specific helper: Report Found directly via Traceback ID or Asset ID
  Future<void> adminReportFound({
    required String identifier,
    required String location,
    required String notes,
    required UserProfile adminProfile,
    LatLng? coordinates,
  }) async {
    await submitReport(
      assetId: identifier,
      reportType: ReportType.found,
      location: location,
      description: notes.isNotEmpty ? notes : 'Secured at ${adminProfile.office}',
      reporterRole: UserRole.admin,
      reporterId: adminProfile.userId,
      reporterName: adminProfile.name,
      reporterContact: '${adminProfile.phone} (${adminProfile.office})',
      coordinates: coordinates,
    );
  }

  // Admin specific helper: Report Lost on Behalf of Student
  Future<void> adminReportOnBehalf({
    required String assetId,
    required ReportType reportType,
    required String location,
    required String notes,
    required UserProfile adminProfile,
    LatLng? coordinates,
  }) async {
    await submitReport(
      assetId: assetId,
      reportType: reportType,
      location: location,
      description: notes.isNotEmpty ? notes : 'Report filed by ${adminProfile.name} on behalf of student.',
      reporterRole: UserRole.admin,
      reporterId: adminProfile.userId,
      reporterName: adminProfile.name,
      reporterContact: adminProfile.phone,
      coordinates: coordinates,
    );
  }

  // Admin records verified recovery handover
  Future<void> adminRecordRecovery(
    String assetId, {
    required String handoverNotes,
    required UserProfile adminProfile,
  }) async {
    final index = _assets.indexWhere(
      (a) => a.id.toUpperCase() == assetId.toUpperCase() || a.tracebackId.toUpperCase() == assetId.toUpperCase(),
    );
    if (index == -1) return;

    final target = _assets[index];
    final now = DateTime.now();

    _assets[index] = target.copyWith(
      status: AssetStatus.recovered,
      trackingEnabled: false,
      updatedAt: now,
    );

    final step = IncidentTimelineStep(
      title: 'Recovery Handover Verified',
      description: handoverNotes.isNotEmpty
          ? handoverNotes
          : 'Official handover verified by ${adminProfile.name} (${adminProfile.office}).',
      timestamp: now,
      actor: adminProfile.name,
      actorRole: UserRole.admin,
      action: 'Verified Handover',
      note: handoverNotes,
    );

    for (int i = 0; i < _incidents.length; i++) {
      if (_incidents[i].assetId == target.id && _incidents[i].status != 'Recovered') {
        final updatedTimeline = List<IncidentTimelineStep>.from(_incidents[i].timeline)..add(step);
        _incidents[i] = _incidents[i].copyWith(
          status: 'Recovered',
          timeline: updatedTimeline,
        );
      }
    }

    _notifications.insert(
      0,
      AppActivityNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Recovery Handover Verified',
        subtitle: '${adminProfile.office} recorded verified handoff for ${target.name}.',
        assetId: target.id,
        tracebackId: target.tracebackId,
        timestamp: now,
        type: 'recovered',
        targetRole: UserRole.student,
      ),
    );

    await _persistAll();
    notifyListeners();
  }

  // Admin updates case status / adds case note
  Future<void> updateCaseStatus(
    String assetId, {
    required String newStatus,
    required String note,
    required UserRole actorRole,
    required String actorName,
  }) async {
    final index = _assets.indexWhere(
      (a) => a.id.toUpperCase() == assetId.toUpperCase() || a.tracebackId.toUpperCase() == assetId.toUpperCase(),
    );
    if (index == -1) return;

    final target = _assets[index];
    final now = DateTime.now();

    final step = IncidentTimelineStep(
      title: 'Case Update: $newStatus',
      description: note.isNotEmpty ? note : 'Case status updated to $newStatus by $actorName.',
      timestamp: now,
      actor: actorName,
      actorRole: actorRole,
      action: 'Status Update',
      note: note,
    );

    for (int i = 0; i < _incidents.length; i++) {
      if (_incidents[i].assetId == target.id) {
        final updatedTimeline = List<IncidentTimelineStep>.from(_incidents[i].timeline)..add(step);
        _incidents[i] = _incidents[i].copyWith(
          status: newStatus,
          timeline: updatedTimeline,
        );
        break;
      }
    }

    await _persistAll();
    notifyListeners();
  }

  // Owner Confirms Recovery Flow
  Future<void> confirmRecovery(String assetId) async {
    final index = _assets.indexWhere((a) => a.id == assetId);
    if (index == -1) return;

    final target = _assets[index];
    final now = DateTime.now();

    // Change status to recovered, stop tracking automatically
    _assets[index] = target.copyWith(
      status: AssetStatus.recovered,
      trackingEnabled: false,
      updatedAt: now,
    );

    for (int i = 0; i < _incidents.length; i++) {
      if (_incidents[i].assetId == assetId && _incidents[i].status != 'Recovered') {
        final updatedTimeline = List<IncidentTimelineStep>.from(_incidents[i].timeline)
          ..add(IncidentTimelineStep(
            title: 'Recovered & Verified',
            description: 'Owner confirmed possession and verified Traceback tag.',
            timestamp: now,
          ));

        _incidents[i] = _incidents[i].copyWith(
          status: 'Recovered',
          timeline: updatedTimeline,
        );
      }
    }

    _notifications.insert(
      0,
      AppActivityNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Belonging Recovered',
        subtitle: 'You confirmed recovery for ${target.name}. Recovery history saved.',
        assetId: target.id,
        tracebackId: target.tracebackId,
        timestamp: now,
        type: 'recovered',
      ),
    );

    await _persistAll();
    notifyListeners();
  }

  // Compatibility alias for markAsRecovered
  void markAsRecovered(String assetId) {
    confirmRecovery(assetId);
  }

  void recordRecovery(String assetId, {String? note}) {
    confirmRecovery(assetId);
  }

  // Mark/Re-secure Belonging
  Future<void> markAsSafe(String assetId) async {
    final index = _assets.indexWhere((a) => a.id == assetId);
    if (index == -1) return;

    final target = _assets[index];
    final now = DateTime.now();

    _assets[index] = target.copyWith(
      status: AssetStatus.safe,
      trackingEnabled: false,
      updatedAt: now,
    );

    for (int i = 0; i < _incidents.length; i++) {
      if (_incidents[i].assetId == assetId && _incidents[i].status != 'Recovered') {
        final updatedTimeline = List<IncidentTimelineStep>.from(_incidents[i].timeline)
          ..add(IncidentTimelineStep(
            title: 'Item Secured & Safe',
            description: 'Owner confirmed possession in personal inventory.',
            timestamp: now,
          ));

        _incidents[i] = _incidents[i].copyWith(
          status: 'Recovered',
          timeline: updatedTimeline,
        );
      }
    }

    await _persistAll();
    notifyListeners();
  }

  void selectAsset(String id) {
    _selectedAssetId = id;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> addAsset(Asset asset) async {
    _assets.add(asset);
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateAsset(Asset asset) async {
    final index = _assets.indexWhere((a) => a.id == asset.id);
    if (index != -1) {
      _assets[index] = asset;
      await _persistAll();
      notifyListeners();
    }
  }

  Future<void> removeAsset(String assetId) async {
    _assets.removeWhere((a) => a.id == assetId);
    _incidents.removeWhere((i) => i.assetId == assetId);
    await _persistAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _telematicsService.dispose();
    _storageService.close();
    super.dispose();
  }
}
