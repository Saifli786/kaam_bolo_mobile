class RatingModel {
  final String id;
  final String raterId;
  final String revieweeId;
  final double score;
  final String comment;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.raterId,
    required this.revieweeId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromMap(String id, Map<String, dynamic> data) {
    return RatingModel(
      id: id,
      raterId: (data['rater_id'] ?? '') as String,
      revieweeId: (data['reviewee_id'] ?? '') as String,
      score: ((data['score'] ?? 0) as num).toDouble(),
      comment: (data['comment'] ?? '') as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(((data['created_at'] ?? 0) as num).toInt()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rater_id': raterId,
      'reviewee_id': revieweeId,
      'score': score,
      'comment': comment,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}


