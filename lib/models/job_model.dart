class Job {
  final String id;
  final String title;
  final String skillRequired;
  final double pay;
  final String duration;
  final String employerId;
  final double locationLat;
  final double locationLng;
  final String description;
  final DateTime createdAt;
  final String status; // open/closed

  const Job({
    required this.id,
    required this.title,
    required this.skillRequired,
    required this.pay,
    required this.duration,
    required this.employerId,
    required this.locationLat,
    required this.locationLng,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  factory Job.fromMap(String id, Map<String, dynamic> data) {
    return Job(
      id: id,
      title: (data['title'] ?? '') as String,
      skillRequired: (data['skill_required'] ?? '') as String,
      pay: ((data['pay'] ?? 0) as num).toDouble(),
      duration: (data['duration'] ?? '') as String,
      employerId: (data['employer_id'] ?? '') as String,
      locationLat: ((data['location_lat'] ?? 0) as num).toDouble(),
      locationLng: ((data['location_lng'] ?? 0) as num).toDouble(),
      description: (data['description'] ?? '') as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(((data['created_at'] ?? 0) as num).toInt()),
      status: (data['status'] ?? 'open') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'skill_required': skillRequired,
      'pay': pay,
      'duration': duration,
      'employer_id': employerId,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }
}


