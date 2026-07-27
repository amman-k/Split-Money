import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/groups/data/group_repository.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';
import 'package:split_frontend/features/groups/presentation/controllers/groups_list_controller.dart';

class CreateGroupController extends AsyncNotifier<GroupModel?> {
  @override
  FutureOr<GroupModel?> build() {
    return null;
  }

  Future<bool> createGroup({
    required String name,
    required String description,
    required List<String> memberNames,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(groupRepositoryProvider);

      final List<Map<String, dynamic>> membersList = [
        {'name': 'You', 'is_owner': true},
        for (final mName in memberNames)
          if (mName.trim().isNotEmpty && mName.trim().toLowerCase() != 'you')
            {'name': mName.trim(), 'is_owner': false},
      ];

      final createdGroup = await repo.createGroup(
        name: name.trim(),
        description: description.trim(),
        members: membersList,
      );

      // Optimistically push directly into groupsListController state
      ref.read(groupsListControllerProvider.notifier).addGroup(createdGroup);
      return createdGroup;
    });

    final success = !state.hasError && state.value != null;
    if (success) {
      ref.invalidate(groupsListControllerProvider);
    }
    return success;
  }
}

final createGroupControllerProvider =
    AsyncNotifierProvider<CreateGroupController, GroupModel?>(
      CreateGroupController.new,
    );
