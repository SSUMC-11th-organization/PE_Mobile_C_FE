import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6750A4); // Figma Primary
  static const surface = Color(0xFFFAF9F5); // Figma Surface

  static const violet = Color(0xFF6750A4);

  static const warmWhite = Color(0xFFFAF9F5);
  static const white = Color(0xFFFFFFFF);

  static const black = Color(0xFF1C1B1F);
  static const gray = Color(0xFF79747E);

  static const background = Color(0xFFFAF9F5);

  static const inputFill = Color(0xFFF5F3F0); // Figma Input 배경
  static const inputBorder = Color(0xFFCBC4D2); // Figma Input 테두리

  // [추가] 오류 상태용 색. 아래 값은 Material 기본 오류색으로 임시 지정한 것이라 Figma W2-02에서 실제 값 확인 후 교체 필요
  static const error = Color(0xFFB3261E); // 오류 테두리, 아이콘, 문구 색
  // [기존] Material 기본 오류 배경색(임시값). Figma W2-02 오류 입력창 값(#FFDAD6)을 확인해서 아래 줄로 교체함
  // static const errorFill = Color(0xFFF9DEDC); // 오류 상태 입력창 배경색
  static const errorFill = Color(
    0xFFFFDAD6,
  ); // 오류 상태 입력창 배경색 (Figma W2-02 Input 채우기 #FFDAD6)

  static const buttonDisabled = Color(
    0xFFCCC2DC,
  ); // [추가] 비활성 가입하기 버튼 배경색 (Figma W2-01 Button 색상 #CCC2DC)

  static const secondaryContainer = Color(0xFFE8DEF8); // 선택된 탭, 칩 배경
  static const star = Color(0xFF6750A4); // 별점 아이콘
}
