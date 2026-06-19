import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/application_model.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loading = true;

  final _nameCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  String _selectedRole = 'worker';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    
    final dbUser = await FirestoreService.instance.getUser(authUser.uid);
    if (mounted) {
      setState(() {
        _user = dbUser;
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    
    setState(() => _loading = true);
    
    final newUser = AppUser(
      id: authUser.uid,
      name: _nameCtrl.text.trim(),
      phone: authUser.phoneNumber ?? '',
      role: _selectedRole,
      skills: _skillsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      language: 'en',
    );
    
    await FirestoreService.instance.upsertUser(newUser);
    
    setState(() {
      _user = newUser;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildSetupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Complete Your Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'I am a...', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'worker', child: Text('Worker (Looking for jobs)')),
              DropdownMenuItem(value: 'employer', child: Text('Employer (Posting jobs)')),
              DropdownMenuItem(value: 'admin', child: Text('Admin (Manage platform)')),
            ],
            onChanged: (v) => setState(() => _selectedRole = v!),
          ),
          const SizedBox(height: 16),
          if (_selectedRole == 'worker')
            TextField(
              controller: _skillsCtrl,
              decoration: const InputDecoration(labelText: 'Skills (comma separated)', border: OutlineInputBorder()),
              helperText: 'e.g. Painter, Plumber, Carpenter',
            ),
          const SizedBox(height: 32),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            onPressed: _saveProfile,
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.person, size: 40, color: Colors.orange),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_user!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(_user!.phone, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
                      child: Text(_user!.role.toUpperCase(), style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        if (_user!.role == 'worker') ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(alignment: Alignment.centerLeft, child: Text('My Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: StreamBuilder<List<ApplicationModel>>(
              stream: FirestoreService.instance.watchApplicationsForWorker(_user!.id),
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final apps = snap.data!;
                if (apps.isEmpty) return const Center(child: Text('No applications yet'));
                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (ctx, i) {
                    final app = apps[i];
                    return ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text('Applied for Job ID: ${app.jobId.substring(0, 5)}...'),
                      subtitle: Text('Status: ${app.status}'),
                      trailing: Text('${app.appliedAt.day}/${app.appliedAt.month}/${app.appliedAt.year}'),
                    );
                  },
                );
              },
            ),
          ),
        ] else ...[
          const Expanded(
            child: Center(child: Text('You are an employer. Check the Home Screen to manage jobs.')),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator()) 
          : (_user == null ? _buildSetupForm() : _buildProfile()),
    );
  }
}
