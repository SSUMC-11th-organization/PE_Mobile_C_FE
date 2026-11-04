import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/member/member_api_service.dart';

class MemberRatings extends StatefulWidget {
  const MemberRatings({
    super.key,
    required this.memberId,
  });

  final int memberId;

  @override
  State<MemberRatings> createState() => _MemberRatingsState();
}

class _MemberRatingsState extends State<MemberRatings> {
  bool loading = false;
  String errorMessage = '';
  List<Map<String, dynamic>>? ratings;

  Future<void> _loadRatings() async {
    setState(() {
      loading = true;
      errorMessage = '';
      ratings = null;
    });

    try {
      final data = await MemberApiService.getRatings(widget.memberId);

      if (!mounted) return;

      setState(() {
        ratings = data;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = '평점 조회 실패: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ratings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '회원 ${widget.memberId}의 평점',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: loading ? null : _loadRatings,
          child: Text(loading ? '조회 중...' : '평점 조회'),
        ),
        if (errorMessage.isNotEmpty)
          Text(errorMessage),
        if (data != null) ...[
          if (data.isEmpty)
            const Text('등록된 평점이 없습니다.'),
          for (final rating in data)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '영화 ${rating['movieId']} · ${rating['score']}점',
              ),
              subtitle: Text(
                rating['comment'] as String? ?? '코멘트 없음',
              ),
            ),
          const SizedBox(height: 8),
          const Text('서버 응답 JSON'),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(data),
          ),
        ],
      ],
    );
  }
}