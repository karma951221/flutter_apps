import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import '../../domain/entity/report_reason.dart';
import '../../domain/entity/report_target.dart';
import '../../domain/report_policy.dart';
import '../cubit/report_cubit.dart';
import '../cubit/report_state.dart';
import '../report_reason_localizations.dart';

/// 신고 바텀시트.
///
/// 성공 스낵바는 여기서 띄우지 않는다 — 시트가 닫히면 이 위젯의
/// `BuildContext` 도 함께 사라지므로, 접수 여부(`bool`)만 돌려주고 스낵바는
/// 호출한 화면이 자신의 `BuildContext` 로 띄운다.
class ReportSheet extends StatelessWidget {
  const ReportSheet({required this.target, super.key});

  final ReportTarget target;

  static Future<bool> show(BuildContext context, ReportTarget target) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReportSheet(target: target),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ReportCubit>(),
    child: _ReportSheetView(target: target),
  );
}

class _ReportSheetView extends StatefulWidget {
  const _ReportSheetView({required this.target});

  final ReportTarget target;

  @override
  State<_ReportSheetView> createState() => _ReportSheetViewState();
}

class _ReportSheetViewState extends State<_ReportSheetView> {
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) => AbsorbPointer(
            absorbing: state.isSubmitting,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.safetyReportTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (state.failure != null) ...[
                      Text(
                        state.failure?.localizedMessage(context) ??
                            l10n.safetyReportFailed,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    RadioGroup<ReportReason>(
                      groupValue: state.reason,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<ReportCubit>().selectReason(value);
                        }
                      },
                      child: Column(
                        children: [
                          for (final reason in ReportReason.values)
                            RadioListTile<ReportReason>(
                              value: reason,
                              title: Text(reason.localized(l10n)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _detailController,
                      maxLength: ReportPolicy.maxDetailLength,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.safetyReportDetailLabel,
                        hintText: l10n.safetyReportDetailHint,
                      ),
                      onChanged: context.read<ReportCubit>().changeDetail,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        label: l10n.safetyReportAction,
                        isLoading: state.isSubmitting,
                        onPressed: state.canSubmit
                            ? () => _submit(context)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<ReportCubit>();
    final succeeded = await cubit.submit(widget.target);
    if (!context.mounted) return;
    if (succeeded) {
      Navigator.of(context).pop(true);
    }
  }
}
