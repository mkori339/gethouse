class Comment {
  final int id;
  final int postId;
  final int userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id:  int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      postId:  int.tryParse(json['post_id']?.toString() ?? '0') ?? 0,
      userId:  int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'user_name': userName,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
