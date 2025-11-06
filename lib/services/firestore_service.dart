import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/rating_model.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance
    ..settings = const Settings(persistenceEnabled: true);

  // Collections
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _jobs => _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get _applications => _db.collection('applications');
  CollectionReference<Map<String, dynamic>> get _ratings => _db.collection('ratings');

  // Users
  Future<void> upsertUser(AppUser user) async {
    await _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUser?> getUser(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  // Jobs
  Future<String> createJob(Job job) async {
    final ref = await _jobs.add(job.toMap());
    return ref.id;
  }

  Stream<List<Job>> watchJobs() {
    return _jobs.where('status', isEqualTo: 'open').orderBy('created_at', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => Job.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<List<Job>> fetchJobsNearby({
    required double centerLat,
    required double centerLng,
    double radiusKm = 20,
    String? skill,
  }) async {
    // Basic approach: fetch recent open jobs and filter by distance (client-side)
    final snap = await _jobs.where('status', isEqualTo: 'open').orderBy('created_at', descending: true).limit(200).get();
    final jobs = snap.docs.map((d) => Job.fromMap(d.id, d.data())).where((j) {
      if (skill != null && skill.isNotEmpty && j.skillRequired.toLowerCase() != skill.toLowerCase()) return false;
      final d = _distanceKm(centerLat, centerLng, j.locationLat, j.locationLng);
      return d <= radiusKm;
    }).toList();

    jobs.sort((a, b) {
      final da = _distanceKm(centerLat, centerLng, a.locationLat, a.locationLng);
      final db = _distanceKm(centerLat, centerLng, b.locationLat, b.locationLng);
      return da.compareTo(db);
    });
    return jobs;
  }

  // Applications
  Future<String> createApplication(ApplicationModel application) async {
    final ref = await _applications.add(application.toMap());
    return ref.id;
  }

  Stream<List<ApplicationModel>> watchApplicationsForWorker(String workerId) {
    return _applications.where('worker_id', isEqualTo: workerId).orderBy('applied_at', descending: true).snapshots().map(
          (s) => s.docs.map((d) => ApplicationModel.fromMap(d.id, d.data())).toList(),
        );
  }

  // Ratings
  Future<String> createRating(RatingModel rating) async {
    final ref = await _ratings.add(rating.toMap());
    return ref.id;
  }

  // Helpers
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // pi/180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2*R; R = 6371 km
  }
}


