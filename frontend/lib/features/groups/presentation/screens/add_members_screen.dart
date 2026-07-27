import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/features/groups/presentation/controllers/add_members_controller.dart';
import 'package:split_frontend/features/groups/presentation/widgets/group_members_card.dart';
import 'package:split_frontend/features/groups/presentation/widgets/member_input_bar.dart';

class AddMembersScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddMembersScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends ConsumerState<AddMembersScreen> {
  final _addMemberController = TextEditingController();
  final List<String> _members = [];

  @override
  void dispose() {
    _addMemberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _addMemberController.text.trim();
    if (name.isNotEmpty && !name.toLowerCase().contains('you')) {
      setState(() {
        _members.add(name);
        _addMemberController.clear();
      });
    }
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one member')),
      );
      return;
    }

    final success = await ref
        .read(addMembersControllerProvider.notifier)
        .addMembers(groupId: widget.groupId, memberNames: _members);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Members added successfully')),
      );
      if (context.canPop()) {
        context.pop();
      }
    } else {
      final error = ref.read(addMembersControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Failed to add members')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addMembersControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Members')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add new people to the group.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.lg),
              MemberInputBar(
                controller: _addMemberController,
                label: 'Add Member',
                placeholder: 'Type a name',
                onAdd: _addMember,
                onSubmitted: (_) => _addMember(),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_members.isNotEmpty)
                GroupMembersCard(
                  headerTitle: 'New Members (${_members.length})',
                  ownerName: '',
                  ownerBadgeLabel: '',
                  members: _members,
                  onRemoveMember: _removeMember,
                ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: state.isLoading || _members.isEmpty
                      ? null
                      : _submitForm,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Members'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
