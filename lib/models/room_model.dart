class RoomModel {
  final String id;
  final String name;

  RoomModel({
    required this.id,
    required this.name,
  });

  factory RoomModel.fromMap(Map<String, dynamic> data, String docId) {
    return RoomModel(
      id: docId,
      name: data['name'] ?? 'Senza nome',
    );
  }

  Map<String, dynamic> toMap() => {'name': name};
}
