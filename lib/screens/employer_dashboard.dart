import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../services/firestore_service.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Posted Jobs')),
      body: StreamBuilder<List<Job>>(
        stream: FirestoreService.instance.watchJobsByEmployer(user.uid),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final jobs = snap.data!;
          if (jobs.isEmpty) {
            return const Center(child: Text('You have not posted any jobs yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (ctx, i) {
              final job = jobs[i];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${job.status.toUpperCase()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (job.status == 'open')
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          tooltip: 'Mark Completed',
                          onPressed: () => FirestoreService.instance.updateJobStatus(job.id, 'completed'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Job',
                        onPressed: () => FirestoreService.instance.deleteJob(job.id),
                      ),
                    ],
                  ),
                  children: [
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Applicants', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    StreamBuilder<List<ApplicationModel>>(
                      stream: FirestoreService.instance.watchApplicationsForJob(job.id),
                      builder: (c, s) {
                        if (!s.hasData) return const CircularProgressIndicator();
                        final apps = s.data!;
                        if (apps.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No applicants yet.'));
                        return Column(
                          children: apps.map((app) {
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text('Worker ID: ${app.workerId.substring(0,5)}...'),
                              subtitle: Text('Status: ${app.status}'),
                              trailing: app.status == 'pending' 
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => FirestoreService.instance.updateApplicationStatus(app.id, 'accepted'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => FirestoreService.instance.updateApplicationStatus(app.id, 'rejected'),
                                      ),
                                    ],
                                  )
                                : null,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
