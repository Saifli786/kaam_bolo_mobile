class ApplicationModel {
  final String id;
  final String jobId;
  final String workerId;
  final DateTime appliedAt;
  final String status; // pending/accepted/rejected

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.appliedAt,
    required this.status,
  });

  factory ApplicationModel.fromMap(String id, Map<String, dynamic> data) {
    return ApplicationModel(
      id: id,
      jobId: (data['job_id'] ?? '') as String,
      workerId: (data['worker_id'] ?? '') as String,
      appliedAt: DateTime.fromMillisecondsSinceEpoch(((data['applied_at'] ?? 0) as num).toInt()),
      status: (data['status'] ?? 'pending') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'worker_id': workerId,
      'applied_at': appliedAt.millisecondsSinceEpoch,
      'status': status,
    };
  }
}


