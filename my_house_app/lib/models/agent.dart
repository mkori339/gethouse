class Agent {
  final int id;
  final String agentName;
  final String region;
  final String phone;
  final String status;

  Agent({
    required this.id,
    required this.agentName,
    required this.region,
    required this.phone,
    required this.status,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as int,
      agentName: json['agent_name'] ?? '',
      region: json['region'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
