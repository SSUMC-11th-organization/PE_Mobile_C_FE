// 프로필(닉네임) 수정 화면
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/movielog_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (a) => a.member?.email,
    );

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.status == EditProfileStatus.saving;
        return PopScope(
          canPop: !saving,
          child: Scaffold(
            appBar: CommonAppBar(
              title: '프로필 수정',
              centerTitle: true,
              // 저장 중에는 PopScope처럼 뒤로가기를 막습니다.
              onBack: saving ? null : () => context.pop(),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  LabeledTextField(
                    label: '이메일 (변경할 수 없습니다)',
                    initialValue: email,
                    enabled: false, // email은 읽기 전용입니다.
                  ),
                  const SizedBox(height: 24),
                  LabeledTextField(
                    label: '닉네임',
                    controller: _controller,
                    enabled: !saving,
                    maxLength: 12,
                    errorText: viewModel.nicknameError,
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
  }
}
