import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/application_model.dart';
import '../services/firestore_service.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: StreamBuilder<List<ApplicationModel>>(
        stream: FirestoreService.instance.watchApplicationsForWorker(user.uid),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final apps = snap.data!;
          if (apps.isEmpty) {
            return const Center(child: Text('You have not applied for any jobs yet.'));
          }

          final pending = apps.where((a) => a.status == 'pending').toList();
          final active = apps.where((a) => a.status == 'accepted').toList();
          final completed = apps.where((a) => a.status == 'completed' || a.status == 'rejected').toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Active'),
                    Tab(text: 'Pending'),
                    Tab(text: 'History'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(active, 'No active tasks. Wait for an employer to accept you!'),
                      _buildList(pending, 'No pending applications.'),
                      _buildList(completed, 'No task history yet.'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<ApplicationModel> apps, String emptyMsg) {
    if (apps.isEmpty) return Center(child: Text(emptyMsg));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: apps.length,
      itemBuilder: (ctx, i) {
        final app = apps[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              app.status == 'accepted' ? Icons.work 
                : app.status == 'rejected' ? Icons.cancel 
                : app.status == 'completed' ? Icons.check_circle 
                : Icons.hourglass_empty,
              color: app.status == 'accepted' ? Colors.green
                : app.status == 'rejected' ? Colors.red 
                : app.status == 'completed' ? Colors.blue 
                : Colors.orange,
            ),
            title: Text('Job Application (ID: ${app.jobId.substring(0, 5)})'),
            subtitle: Text('Status: ${app.status.toUpperCase()}\nApplied on: ${app.appliedAt.toString().substring(0, 10)}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
