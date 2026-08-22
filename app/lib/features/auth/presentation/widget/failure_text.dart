import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../design_system/theme/app_spacing.dart';

/// Failure 를 사용자에게 보여줄 문구로 옮긴다.
///
/// 화면마다 이 변환을 반복하지 않도록 한 곳에 모은다.
String failureMessage(Failure failure) => switch (failure) {
  NetworkFailure(:final message) => message ?? '네트워크에 연결할 수 없습니다',
  AuthFailure(:final message) => message ?? '인증에 실패했습니다',
  ForbiddenFailure(:final message) => message ?? '권한이 없습니다',
  NotFoundFailure(:final message) => message ?? '대상을 찾을 수 없습니다',
  ValidationFailure(:final message) => message ?? '입력값을 확인하세요',
  ServerFailure(:final message) => message ?? '서버 오류가 발생했습니다',
  UnknownFailure(:final message) => message ?? '알 수 없는 오류가 발생했습니다',
};

class FailureText extends StatelessWidget {
  const FailureText(this.failure, {super.key});

  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final f = failure;
    if (f == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        failureMessage(f),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
