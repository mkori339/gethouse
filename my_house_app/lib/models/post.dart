class Post {
  final int id;
  final int userId;
  final String poster;
  final String category;
  final String type;
  final double amount;
  final String explanation;
  final String region;
  final String district;
  final String street;
  final String roomNo;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> images;
  final Map<String, dynamic> user;

  Post({
    required this.id,
    required this.userId,
    required this.poster,
    required this.category,
    required this.type,
    required this.amount,
    required this.explanation,
    required this.region,
    required this.district,
    required this.street,
    required this.roomNo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    required this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final imgs = <Map<String, dynamic>>[];
    if (json['images'] != null && json['images'] is List) {
      for (var i in json['images']) {
        if (i is Map<String, dynamic>) {
          imgs.add(Map<String, dynamic>.from(i));
        } else if (i is String) {
          imgs.add({'url': i});
        }
      }
    }

    return Post(
      // id: json['id'] as int,
      // userId: json['user_id'] as int,
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(
            json['user_id']?.toString() ?? json['userId']?.toString() ?? '0',
          ) ??
          0,
      poster: json['poster'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      explanation: json['explanation'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      street: json['street'] ?? '',
      roomNo: json['room_no']?.toString() ?? '',
      status: json['status'] ?? '',
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt:
          DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
      images: imgs,
      user: json['user'] is Map ? json['user'] as Map<String, dynamic> : {},
    );
  }
}
