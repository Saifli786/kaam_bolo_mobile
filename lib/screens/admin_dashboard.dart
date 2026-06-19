import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Platform Metrics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Users', FirestoreService.instance.watchAllUsersCount(), Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Jobs', FirestoreService.instance.watchAllJobsCount(), Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Apps', FirestoreService.instance.watchAllApplicationsCount(), Colors.green)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Recent Jobs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: FirestoreService.instance.watchAllJobs(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final jobs = snap.data!;
                if (jobs.isEmpty) return const Text('No jobs on platform.');
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jobs.length,
                  itemBuilder: (ctx, i) {
                    final job = jobs[i];
                    return Card(
                      child: ListTile(
                        title: Text(job.title),
                        subtitle: Text('Status: ${job.status} | By: ${job.employerId.substring(0, 5)}...'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => FirestoreService.instance.deleteJob(job.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, Stream<int> stream, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<int>(
              stream: stream,
              builder: (ctx, snap) {
                if (!snap.hasData) return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
                return Text('${snap.data}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color));
              },
            ),
          ],
        ),
      ),
    );
  }
}
