class GroupMemberModel {
  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.isOwner,
  });

  final String id;
  final String groupId;
  final String name;
  final bool isOwner;

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isOwner: json['is_owner'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'name': name,
    'is_owner': isOwner,
  };

  GroupMemberModel copyWith({
    String? id,
    String? groupId,
    String? name,
    bool? isOwner,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMemberModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          groupId == other.groupId &&
          name == other.name &&
          isOwner == other.isOwner;

  @override
  int get hashCode =>
      id.hashCode ^ groupId.hashCode ^ name.hashCode ^ isOwner.hashCode;
}

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.members,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<GroupMemberModel> members;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? [];
    final membersList = rawMembers
        .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return GroupModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      members: membersList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'owner_id': ownerId,
    'members': members.map((m) => m.toJson()).toList(),
  };

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<GroupMemberModel>? members,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          ownerId == other.ownerId &&
          _listEquals(members, other.members);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      ownerId.hashCode ^
      members.hashCode;
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
