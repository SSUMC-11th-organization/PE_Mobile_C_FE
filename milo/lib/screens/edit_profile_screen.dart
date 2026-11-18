import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final member = context.read<AuthViewModel>().member;
    _controller = TextEditingController(text: member?.nickname ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      router.pop(); // 마이페이지로 돌아가면 새 닉네임이 이미 반영되어 있습니다.
    } else if (viewModel.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
  }

  Future<bool?> _confirmDiscard() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('변경 내용이 있어요'),
        content: const Text('저장하지 않고 나가면 수정한 닉네임이 사라져요.\n나갈까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (a) => a.member?.email,
    );
    final original =
        context.select<AuthViewModel, String?>((a) => a.member?.nickname) ?? '';

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.status == EditProfileStatus.saving;
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller, // 입력할 때마다 dirty를 다시 계산합니다.
          builder: (context, value, _) {
            final dirty = value.text.trim() != original;
            return PopScope(
              canPop: !saving && !dirty,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop || saving) return;
                final router = GoRouter.of(context);
                final leave = await _confirmDiscard();
                if (leave == true && mounted) router.pop(); // 확인 → 마이페이지로
                // 취소 → 아무것도 하지 않아 현재 화면에 머뭅니다.
              },
              child: Scaffold(
                appBar: AppBar(centerTitle: true, title: const Text('프로필 수정')),
                body: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: email,
                        enabled: false, // email은 읽기 전용입니다.
                        decoration: const InputDecoration(labelText: '이메일'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        enabled: !saving,
                        maxLength: 12,
                        decoration: InputDecoration(
                          labelText: '닉네임',
                          errorText: viewModel.nicknameError,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: MovieLogButton(
                          label: '저장',
                          isLoading: saving,
                          onPressed: saving ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
