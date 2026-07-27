import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/groups/data/group_repository.dart';
import 'package:split_frontend/features/groups/presentation/controllers/groups_list_controller.dart';

class DeleteGroupController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<bool> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(groupRepositoryProvider).deleteGroup(groupId);
      // Invalidate the groups list so the dashboard refreshes
      ref.invalidate(groupsListControllerProvider);
      return true;
    });

    return !state.hasError;
  }
}

final deleteGroupControllerProvider =
    AsyncNotifierProvider<DeleteGroupController, bool>(
      DeleteGroupController.new,
    );
