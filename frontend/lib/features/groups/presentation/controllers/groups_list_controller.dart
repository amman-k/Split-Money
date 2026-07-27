import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/groups/data/group_repository.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';

class GroupsListController extends AsyncNotifier<List<GroupModel>> {
  @override
  FutureOr<List<GroupModel>> build() async {
    final repo = ref.read(groupRepositoryProvider);
    return repo.getGroups();
  }

  void addGroup(GroupModel group) {
    final currentList = state.asData?.value ?? state.value ?? [];
    final updated = [
      group,
      ...currentList.where((g) => g.id != group.id && g.name != group.name),
    ];
    state = AsyncValue.data(updated);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(groupRepositoryProvider);
      return repo.getGroups();
    });
  }
}

final groupsListControllerProvider =
    AsyncNotifierProvider<GroupsListController, List<GroupModel>>(
      GroupsListController.new,
    );
