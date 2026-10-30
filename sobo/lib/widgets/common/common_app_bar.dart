import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
  });

  final String title;
  final VoidCallback? onBack; // 뒤로가기 콜백 함수
  final List<Widget>? actions; // AppBar 오른쪽에 표시할 위젯 목록
  final bool centerTitle; // 제목 가운데 정렬 여부

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      title: Text(title),
      centerTitle: centerTitle,
      leading:
          onBack ==
              null // 삼항 연산자로 뒤로가기 없으면 버튼도 없고 뒤로가기 있으면 IconButton 표시
          ? null
          : IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
