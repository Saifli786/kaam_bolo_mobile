import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/job_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/voice_assistant.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _listening = false;
  bool _loading = true;
  Position? _position;
  List<Job> _jobs = const [];
  String _skillFilter = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await VoiceAssistant.instance.init();
    _position = await LocationService.instance.getCurrentPosition();
    await _loadJobs();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadJobs() async {
    if (_position == null) return;
    final jobs = await FirestoreService.instance.fetchJobsNearby(
      centerLat: _position!.latitude,
      centerLng: _position!.longitude,
      radiusKm: 25,
      skill: _skillFilter.isEmpty ? null : _skillFilter,
    );
    if (mounted) setState(() => _jobs = jobs);
  }

  void _handleVoiceCommand(String text) async {
    final lower = text.toLowerCase();
    if (lower.contains('post job')) {
      if (!mounted) return; 
      Navigator.of(context).pushNamed('/post');
      return;
    }
    if (lower.contains('my profile')) {
      if (!mounted) return;
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    // find painter jobs near me -> extract first word after 'find'
    if (lower.startsWith('find')) {
      final parts = lower.split(' ');
      if (parts.length >= 2) {
        setState(() => _skillFilter = parts[1]);
        await VoiceAssistant.instance.speak('Searching for ${parts[1]} jobs near you');
        await _loadJobs();
        return;
      }
    }
    await VoiceAssistant.instance.speak('Sorry, I did not understand');
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await VoiceAssistant.instance.stopListening();
      setState(() => _listening = false);
    } else {
      final started = await VoiceAssistant.instance.startListening(_handleVoiceCommand);
      setState(() => _listening = started);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Jobs'),
        actions: [
          IconButton(
            onPressed: _toggleMic,
            icon: Icon(_listening ? Icons.mic : Icons.mic_none),
            tooltip: 'Voice',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _jobs.length,
          itemBuilder: (context, index) {
            final job = _jobs[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(job.title),
                subtitle: Text('${job.skillRequired} • ₹${job.pay.toStringAsFixed(0)} • ${job.duration}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _loadJobs();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }
}


