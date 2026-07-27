import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/groups/data/group_repository.dart';
import 'package:split_frontend/features/groups/presentation/controllers/group_details_controller.dart';

class AddMembersController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<bool> addMembers({
    required String groupId,
    required List<String> memberNames,
  }) async {
    if (memberNames.isEmpty) return true;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final members = memberNames
          .map((name) => {'name': name, 'is_owner': false})
          .toList();

      await ref
          .read(groupRepositoryProvider)
          .addMembers(groupId: groupId, members: members);

      // Invalidate the group details provider to refresh the state
      ref.invalidate(groupDetailsControllerProvider(groupId));

      return true;
    });

    return !state.hasError;
  }
}

final addMembersControllerProvider =
    AsyncNotifierProvider<AddMembersController, bool>(AddMembersController.new);
