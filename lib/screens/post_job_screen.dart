import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _titleCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _payCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  bool _loading = false;

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _skillCtrl.text.isEmpty || _payCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _loading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final pos = await LocationService.instance.getCurrentPosition();

      final job = Job(
        id: '', // Firebase will generate
        title: _titleCtrl.text.trim(),
        skillRequired: _skillCtrl.text.trim(),
        pay: double.tryParse(_payCtrl.text.trim()) ?? 0.0,
        duration: _durationCtrl.text.trim(),
        employerId: user.uid,
        locationLat: pos.latitude,
        locationLng: pos.longitude,
        description: _descCtrl.text.trim(),
        createdAt: DateTime.now(),
        status: 'open',
      );

      await FirestoreService.instance.createJob(job);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job posted successfully!')));
        // Clear form
        _titleCtrl.clear();
        _skillCtrl.clear();
        _payCtrl.clear();
        _durationCtrl.clear();
        _descCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Job Title *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _skillCtrl,
              decoration: const InputDecoration(labelText: 'Skill Required *', border: OutlineInputBorder(), helperText: 'e.g. Painter, Plumber'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _payCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pay (₹) *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationCtrl,
              decoration: const InputDecoration(labelText: 'Duration', border: OutlineInputBorder(), helperText: 'e.g. 2 days, 1 week'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('Post Job'),
            ),
          ],
        ),
      ),
    );
  }
}
