class AppUser {
  final String id;
  final String name;
  final String phone;
  final String role; // 'worker' or 'employer'
  final List<String> skills;
  final String language;
  final double? locationLat;
  final double? locationLng;
  final double rating;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.skills,
    required this.language,
    this.locationLat,
    this.locationLng,
    this.rating = 0,
    this.photoUrl,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: (data['name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      role: (data['role'] ?? 'worker') as String,
      skills: List<String>.from((data['skills'] ?? const []) as List),
      language: (data['language'] ?? 'en') as String,
      locationLat: (data['location_lat'] as num?)?.toDouble(),
      locationLng: (data['location_lng'] as num?)?.toDouble(),
      rating: ((data['rating'] ?? 0) as num).toDouble(),
      photoUrl: data['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'skills': skills,
      'language': language,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'rating': rating,
      'photo_url': photoUrl,
    };
  }
}


