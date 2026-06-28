class Player {
  const Player({
    required this.id,
    required this.name,
    required this.isHost,
    this.roleId,
  });

  final String id;
  final String name;
  final bool isHost;
  final String? roleId;

  factory Player.fromMap(String id, Map<String, dynamic> data) {
    return Player(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Player',
      isHost: data['isHost'] == true,
      roleId: data['roleId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isHost': isHost,
      if (roleId != null) 'roleId': roleId,
    };
  }
}
