class Like {
  final int id;
  final int postId;
  final int userId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
