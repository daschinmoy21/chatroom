class Server {
  final int id;
  final String name;
  final String icon;

  Server({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
    );
  }
} 