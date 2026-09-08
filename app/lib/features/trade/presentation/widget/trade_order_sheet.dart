import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/trade_session.dart';
import '../../domain/entity/trade_side.dart';
import '../../domain/ledger/trade_cost.dart';
import '../../domain/ledger/trade_sizing.dart';
import '../../domain/trade_rules.dart';
import '../format/trade_format.dart';

/// 매수·매도 수량을 정하는 바텀시트.
///
/// 주문을 직접 넣지 않는다 — 확인을 누르면 수량만 돌려주고 닫힌다. 시트가
/// 닫히는 순간 이 위젯의 `BuildContext` 도 사라져서, 결과 스낵바를 여기서
/// 띄우면 화면 없는 곳에 띄우는 셈이 된다(`ReportSheet` 와 같은 이유).
///
/// 계산은 [TradeSizing] 이 한다. 여기서 곱하고 나누기 시작하면 서버가 쓰는
/// 규칙과 화면이 조용히 어긋난다 — 정본은 RPC 고, [TradeSizing] 은 그것을
/// 미리 보여주기 위한 같은 규칙의 사본이다.
class TradeOrderSheet extends StatefulWidget {
  const TradeOrderSheet({required this.side, required this.session, super.key});

  final TradeSide side;
  final TradeSession session;

  /// 시트를 띄우고 사용자가 정한 수량을 돌려준다. 그냥 닫으면 null 이다.
  static Future<double?> show(
    BuildContext context, {
    required TradeSide side,
    required TradeSession session,
  }) => showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    builder: (_) => TradeOrderSheet(side: side, session: session),
  );

  /// 프리셋 비율. 25% · 50% · 100%.
  static const fractions = [0.25, 0.5, 1.0];

  @override
  State<TradeOrderSheet> createState() => _TradeOrderSheetState();
}

/// 매수에서 직접 입력하는 값의 뜻. 매도는 항상 수량이다.
enum _OrderInputMode { amount, quantity }

class _TradeOrderSheetState extends State<TradeOrderSheet> {
  /// 부동소수점 비교에 쓰는 여유. 잔고와 딱 맞는 주문이 반올림 오차 하나로
  /// "잔고 부족"이 되는 것을 막는다.
  static const _epsilon = 1e-9;

  final _controller = TextEditingController();
  _OrderInputMode _mode = _OrderInputMode.amount;

  bool get _isBuy => widget.side == TradeSide.buy;

  double get _price => widget.session.currentClose;

  /// 입력·프리셋이 가리키는 주문 수량. 소수 6자리로 내림한 값이다.
  double get _quantity {
    final input = double.tryParse(_controller.text.trim()) ?? 0;
    if (input <= 0) return 0;
    if (_isBuy && _mode == _OrderInputMode.amount) {
      return TradeSizing.quantityForAmount(
        amount: input,
        price: _price,
        feeRate: TradeRules.feeRate,
      );
    }
    return TradeSizing.floorQuantity(input);
  }

  TradeCost get _cost => _isBuy
      ? TradeSizing.buyCost(
          quantity: _quantity,
          price: _price,
          feeRate: TradeRules.feeRate,
        )
      : TradeSizing.sellProceeds(
          quantity: _quantity,
          price: _price,
          feeRate: TradeRules.feeRate,
        );

  /// 잔고·보유량을 넘었는지. 넘지 않았으면 null.
  ///
  /// 최종 판단은 서버가 한다. 여기서 막는 것은 확실히 거절당할 주문을 보내
  /// 사용자가 오류 스낵바로 알게 되는 일을 줄이기 위해서다.
  String? _warning(AppLocalizations l10n) {
    if (_quantity <= 0) return null;
    if (_isBuy && _cost.total > widget.session.cash + _epsilon) {
      return l10n.failureTradeInsufficientCash;
    }
    if (!_isBuy && _quantity > widget.session.quantity + _epsilon) {
      return l10n.failureTradeInsufficientQuantity;
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 프리셋을 입력란에 적는다.
  ///
  /// 프리셋을 따로 들고 있지 않고 입력란 한 곳만 정본으로 둔다 — 눌러 놓은
  /// 비율과 그 뒤에 고친 숫자가 서로 다른 답을 가리키는 상태를 만들지 않기
  /// 위해서다.
  void _applyFraction(double fraction) {
    final session = widget.session;
    final text = switch ((widget.side, _mode)) {
      // 금액은 화면에 소수 두 자리로 적히므로, 올림으로 잔고를 넘기지
      // 않도록 내림해서 적는다.
      (TradeSide.buy, _OrderInputMode.amount) =>
        ((session.cash * fraction * 100).floor() / 100).toStringAsFixed(2),
      (TradeSide.buy, _OrderInputMode.quantity) => TradeFormat.quantity(
        TradeSizing.buyQuantity(
          cash: session.cash,
          price: _price,
          feeRate: TradeRules.feeRate,
          fraction: fraction,
        ),
      ),
      (TradeSide.sell, _) => TradeFormat.quantity(
        TradeSizing.sellQuantity(
          quantity: session.quantity,
          fraction: fraction,
        ),
      ),
    };
    setState(() => _controller.text = text);
  }

  /// 금액↔수량을 바꾸면 입력란을 비운다. 같은 숫자가 다른 뜻이 되므로,
  /// 남겨 두면 방금 정한 것과 전혀 다른 주문이 만들어진다.
  void _changeMode(_OrderInputMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final quantity = _quantity;
    final warning = _warning(l10n);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBuy ? l10n.tradeBuy : l10n.tradeSell,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    for (final fraction in TradeOrderSheet.fractions) ...[
                      Expanded(
                        child: AppButton.secondary(
                          label: l10n.tradeFractionLabel(
                            (fraction * 100).round(),
                          ),
                          onPressed: () => _applyFraction(fraction),
                        ),
                      ),
                      if (fraction != TradeOrderSheet.fractions.last)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isBuy)
                  SegmentedButton<_OrderInputMode>(
                    segments: [
                      ButtonSegment(
                        value: _OrderInputMode.amount,
                        label: Text(l10n.tradeByAmount),
                      ),
                      ButtonSegment(
                        value: _OrderInputMode.quantity,
                        label: Text(l10n.tradeByQuantity),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) =>
                        _changeMode(selection.first),
                  )
                else
                  Text(
                    l10n.tradeByQuantity,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(hintText: '0'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                _PreviewList(
                  side: widget.side,
                  session: widget.session,
                  quantity: quantity,
                  cost: _cost,
                ),
                if (warning != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    warning,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: l10n.tradeConfirmOrder,
                    onPressed: quantity > 0 && warning == null
                        ? () => Navigator.of(context).pop(quantity)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 주문을 넣기 전에 무슨 일이 일어날지 미리 적는다.
class _PreviewList extends StatelessWidget {
  const _PreviewList({
    required this.side,
    required this.session,
    required this.quantity,
    required this.cost,
  });

  final TradeSide side;
  final TradeSession session;
  final double quantity;
  final TradeCost cost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    // 잔고를 넘긴 입력은 확인 버튼이 이미 막고 오류 문구가 따로 붙는다.
    // 여기까지 음수로 적으면 같은 말을 두 번 하는 데다, 빼기 부호 표기가
    // 금액 포맷과 어긋난다.
    final remainingCash = (session.cash - cost.total).clamp(
      0.0,
      double.infinity,
    );
    final remainingQuantity = (session.quantity - quantity).clamp(
      0.0,
      double.infinity,
    );

    return Column(
      children: switch (side) {
        TradeSide.buy => [
          _PreviewRow(
            label: l10n.tradeExpectedQuantity,
            value: TradeFormat.quantity(quantity),
          ),
          _PreviewRow(
            label: l10n.tradeFee,
            value: TradeFormat.amount(cost.fee, locale),
          ),
          _PreviewRow(
            label: l10n.tradeRemainingCash,
            value: TradeFormat.amount(remainingCash, locale),
          ),
        ],
        TradeSide.sell => [
          _PreviewRow(
            label: l10n.tradeExpectedProceeds,
            value: TradeFormat.amount(cost.total, locale),
          ),
          _PreviewRow(
            label: l10n.tradeFee,
            value: TradeFormat.amount(cost.fee, locale),
          ),
          _PreviewRow(
            label: l10n.tradeRemainingQuantity,
            value: TradeFormat.quantity(remainingQuantity),
          ),
        ],
      },
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
