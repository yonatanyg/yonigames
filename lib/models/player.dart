class Player {
  const Player({required this.id, required this.name, required this.isHost});

  final String id;
  final String name;
  final bool isHost;

  factory Player.fromMap(String id, Map<String, dynamic> data) {
    return Player(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Player',
      isHost: data['isHost'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'isHost': isHost};
  }
}
