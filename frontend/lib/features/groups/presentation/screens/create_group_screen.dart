import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/features/groups/presentation/controllers/create_group_controller.dart';
import 'package:split_frontend/features/groups/presentation/widgets/group_form_text_field.dart';
import 'package:split_frontend/features/groups/presentation/widgets/group_members_card.dart';
import 'package:split_frontend/features/groups/presentation/widgets/member_input_bar.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addMemberController = TextEditingController();

  final List<String> _members = ['Alex', 'Sarah'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.groupNameRequiredError)));
      return;
    }

    final success = await ref
        .read(createGroupControllerProvider.notifier)
        .createGroup(
          name: _nameController.text,
          description: _descController.text,
          memberNames: _members,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.groupCreationSuccess)));
      if (context.canPop()) {
        context.pop();
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.groupCreationError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createGroupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGroupScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GroupFormTextField(
                controller: _nameController,
                label: l10n.groupNameLabel,
                placeholder: l10n.groupNamePlaceholder,
              ),
              const SizedBox(height: AppSpacing.lg),
              GroupFormTextField(
                controller: _descController,
                label: l10n.groupDescriptionLabel,
                placeholder: l10n.groupDescriptionPlaceholder,
                optionalText: l10n.groupDescriptionOptional,
                isSecondaryBackground: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              MemberInputBar(
                controller: _addMemberController,
                label: l10n.addMembersLabel,
                placeholder: l10n.typeANamePlaceholder,
                onAdd: _addMember,
                onSubmitted: (_) => _addMember(),
              ),
              const SizedBox(height: AppSpacing.xl),
              GroupMembersCard(
                headerTitle: l10n.groupMembersHeader(_members.length + 1),
                ownerName: l10n.youMemberName,
                ownerBadgeLabel: l10n.ownerBadge,
                members: _members,
                onRemoveMember: _removeMember,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: state.isLoading ? null : _submitForm,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.createGroupSubmitButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
